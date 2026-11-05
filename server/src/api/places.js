// ==== [ DAFFA - BACKEND ] ==== //
const { GalatApi, teks } = require('../security');

const URL_NOMINATIM = 'https://nominatim.openstreetmap.org/search';
const URL_OVERPASS = 'https://overpass-api.de/api/interpreter';
const identitasAplikasi = 'SHION/1.0 (aplikasi pengelolaan sampah)';
const cacheTempat = new Map();
const cacheGeokode = new Map();
let antreanNominatim = Promise.resolve();
let waktuNominatimTerakhir = 0;

async function fetchTerbatas(url, opsi = {}, waktu = 25000) {
  const jawaban = await fetch(url, { ...opsi, signal: AbortSignal.timeout(waktu) });
  if (!jawaban.ok) throw new GalatApi(502, 'Data lokasi OpenStreetMap sementara tidak tersedia.', 'PLACES_UPSTREAM');
  return jawaban.json();
}

// Nominatim publik dibatasi maksimal satu permintaan per detik; semua pencarian server diantrikan.
function geokode(wilayah) {
  const kunci = wilayah.toLocaleLowerCase('id-ID');
  const tersimpan = cacheGeokode.get(kunci);
  if (tersimpan && tersimpan.sampai > Date.now()) return Promise.resolve(tersimpan.pusat);
  const tugas = antreanNominatim.then(async () => {
    const jeda = 1100 - (Date.now() - waktuNominatimTerakhir);
    if (jeda > 0) await new Promise(selesai => setTimeout(selesai, jeda));
    waktuNominatimTerakhir = Date.now();
    const url = new URL(URL_NOMINATIM);
    url.search = new URLSearchParams({ q: `${wilayah}, Indonesia`, format: 'jsonv2', limit: '1', countrycodes: 'id' });
    const hasil = await fetchTerbatas(url, { headers: { 'User-Agent': identitasAplikasi, 'Accept-Language': 'id' } }, 12000);
    const titik = hasil[0];
    if (!titik) throw new GalatApi(404, 'Wilayah tidak ditemukan di OpenStreetMap.', 'PLACE_NOT_FOUND');
    const pusat = { lat: Number(titik.lat), lng: Number(titik.lon) };
    cacheGeokode.set(kunci, { pusat, sampai: Date.now() + 24 * 60 * 60 * 1000 });
    if (cacheGeokode.size > 1000) cacheGeokode.delete(cacheGeokode.keys().next().value);
    return pusat;
  });
  antreanNominatim = tugas.catch(() => {});
  return tugas;
}

function kueriOverpass(pusat, radius) {
  return `[out:json][timeout:20];(node["amenity"="recycling"](around:${radius},${pusat.lat},${pusat.lng});way["amenity"="recycling"](around:${radius},${pusat.lat},${pusat.lng});relation["amenity"="recycling"](around:${radius},${pusat.lat},${pusat.lng});node["name"~"bank sampah|kantor kelurahan|kantor desa",i](around:${radius},${pusat.lat},${pusat.lng});way["name"~"bank sampah|kantor kelurahan|kantor desa",i](around:${radius},${pusat.lat},${pusat.lng});relation["name"~"bank sampah|kantor kelurahan|kantor desa",i](around:${radius},${pusat.lat},${pusat.lng}););out center tags;`;
}

function rapikanElemen(elemen) {
  const tag = elemen.tags || {};
  const nama = tag.name || tag['name:id'] || tag.operator || '';
  if (!nama) return null;
  const lat = Number(elemen.lat ?? elemen.center?.lat);
  const lng = Number(elemen.lon ?? elemen.center?.lon);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  const teksNama = nama.toLowerCase();
  const kantor = /kelurahan|kantor desa|kantor lurah|balai desa/.test(teksNama) || tag.government === 'administrative';
  const daurUlang = tag.amenity === 'recycling' || tag.recycling_type === 'centre' || /bank sampah/.test(teksNama);
  if (!kantor && !daurUlang) return null;
  const alamat = [tag['addr:street'], tag['addr:suburb'], tag['addr:city'], tag['addr:district']].filter(Boolean).join(', ');
  return {
    id: `${elemen.type}-${elemen.id}`,
    name: nama,
    address: alamat,
    lat,
    lng,
    category: kantor ? 'kelurahan' : 'bank_sampah',
    sourceUrl: `https://www.openstreetmap.org/${elemen.type}/${elemen.id}`,
  };
}

async function cariTempat(pusat, radius) {
  const kunciCache = `${pusat.lat.toFixed(3)}:${pusat.lng.toFixed(3)}:${radius}`;
  const tersedia = cacheTempat.get(kunciCache);
  if (tersedia && tersedia.sampai > Date.now()) return tersedia.tempat;
  const jawaban = await fetchTerbatas(URL_OVERPASS, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8', 'User-Agent': identitasAplikasi },
    body: new URLSearchParams({ data: kueriOverpass(pusat, radius) }).toString(),
  });
  const unik = new Map();
  for (const elemen of jawaban.elements || []) {
    const tempat = rapikanElemen(elemen);
    if (tempat) unik.set(tempat.id, tempat);
  }
  const tempat = [...unik.values()];
  cacheTempat.set(kunciCache, { tempat, sampai: Date.now() + 5 * 60 * 1000 });
  if (cacheTempat.size > 250) cacheTempat.delete(cacheTempat.keys().next().value);
  return tempat;
}

module.exports = (router, c) => {
  async function kirimHasil(req, res, pusat) {
    const radius = Math.min(50000, Math.max(1000, Number(req.query.radius) || 15000));
    const places = await cariTempat(pusat, radius);
    c.ok(res, { center: pusat, radius, places, sumber: 'OpenStreetMap' });
  }

  router.get('/places/nearby', c.auth, c.placeLimit, async (req, res) => {
    const lat = Number(req.query.lat), lng = Number(req.query.lng);
    if (!Number.isFinite(lat) || lat < -90 || lat > 90 || !Number.isFinite(lng) || lng < -180 || lng > 180) {
      throw new GalatApi(400, 'Koordinat lokasi tidak valid.', 'VALIDATION');
    }
    await kirimHasil(req, res, { lat, lng });
  });

  router.get('/places/search', c.auth, c.placeLimit, async (req, res) => {
    const wilayah = teks(req.query.query, 'Wilayah', 2, 120);
    const pusat = await geokode(wilayah);
    await kirimHasil(req, res, pusat);
  });
};
