// Daftar kelurahan di Jawa Barat tersimpan bersama server.
const { GalatApi, teks } = require('../security');
const wilayah = require('../jabar-kelurahan.json');
const daftarKota = Object.values(wilayah);
const cacheLokasi = new Map();
let antrean = Promise.resolve();
let permintaanTerakhir = 0;
const identitas = 'SHION/1.0 (aplikasi pengelolaan sampah)';

function normal(nama) {
  return String(nama || '').toLowerCase().replace(/^kab\.?\s+/, 'kabupaten ')
    .replace(/[^a-z0-9 ]/g, '').replace(/\s+/g, ' ').trim();
}
function cariKota(nama) {
  const input = normal(nama);
  const tepat = daftarKota.find(k => normal(k.city) === input);
  if (tepat) return tepat;
  const ringkas = input.replace(/^(kota|kabupaten) /, '');
  return daftarKota.find(k => normal(k.city) === 'kota ' + ringkas)
    || daftarKota.find(k => normal(k.city) === 'kabupaten ' + ringkas);
}
async function permintaanGeografi(url) {
  const tugas = antrean.then(async () => {
    const tunggu = 1100 - (Date.now() - permintaanTerakhir);
    if (tunggu > 0) await new Promise(resolve => setTimeout(resolve, tunggu));
    permintaanTerakhir = Date.now();
    const response = await fetch(url, {
      headers: { 'User-Agent': identitas, 'Accept-Language': 'id' },
      signal: AbortSignal.timeout(7000),
    });
    if (!response.ok) throw new Error('Geografi belum tersedia');
    return response.json();
  });
  antrean = tugas.catch(() => {});
  return tugas;
}
function hasil(kota, center) {
  const villages = kota.villages.map(v => ({ id: v.id, name: v.name, district: v.district, type: 'Kelurahan' }));
  return {
    city: kota.city, center, villages, places: [],
    summary: `Ditemukan ${villages.length} kelurahan di ${kota.city}.`,
  };
}
module.exports = (router, c) => {
  router.get('/places/search', c.auth, c.placeLimit, async (req, res) => {
    const query = teks(req.query.query, 'Kota', 2, 120);
    const kota = cariKota(query);
    if (!kota) throw new GalatApi(404, 'Kota atau kabupaten di Jawa Barat belum ditemukan. Masukkan nama kota lengkap.', 'CITY_NOT_FOUND');
    let center = null;
    try {
      const url = new URL('https://nominatim.openstreetmap.org/search');
      url.search = new URLSearchParams({ q: `${kota.city}, Jawa Barat, Indonesia`, format: 'jsonv2', limit: '1', countrycodes: 'id' });
      const geo = await permintaanGeografi(url);
      if (geo[0]) center = { lat: Number(geo[0].lat), lng: Number(geo[0].lon) };
    } catch (_) { /* Daftar lokal tetap tersedia ketika pencarian titik peta lambat. */ }
    c.ok(res, hasil(kota, center));
  });
  router.get('/places/nearby', c.auth, c.placeLimit, async (req, res) => {
    const lat = Number(req.query.lat), lng = Number(req.query.lng);
    if (!Number.isFinite(lat) || Math.abs(lat) > 90 || !Number.isFinite(lng) || Math.abs(lng) > 180)
      throw new GalatApi(400, 'Koordinat lokasi tidak valid.', 'VALIDATION');
    const center = { lat, lng };
    const key = `${lat.toFixed(2)}:${lng.toFixed(2)}`;
    let nama = cacheLokasi.get(key)?.name;
    if (!nama) {
      try {
        const url = new URL('https://nominatim.openstreetmap.org/reverse');
        url.search = new URLSearchParams({ lat: String(lat), lon: String(lng), format: 'jsonv2', addressdetails: '1' });
        const geo = await permintaanGeografi(url);
        const a = geo.address || {};
        nama = [a.city, a.municipality, a.county, a.town].find(x => cariKota(x));
        if (nama) cacheLokasi.set(key, { name: nama });
      } catch (_) { /* Pengguna dapat mencari kota secara manual. */ }
    }
    const kota = cariKota(nama);
    if (!kota) throw new GalatApi(404, 'Kota belum dapat dikenali dari GPS. Cari berdasarkan nama kota Jawa Barat.', 'CITY_NOT_FOUND');
    c.ok(res, hasil(kota, center));
  });
};
