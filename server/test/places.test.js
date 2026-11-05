// ==== [ DAFFA - BACKEND ] ==== //
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const os = require('node:os');
const path = require('node:path');
const { BasisDataJson } = require('../src/db');
const { buatAplikasi } = require('../src/app');

test('pencarian lokasi publik OSM memerlukan sesi, memvalidasi koordinat dan mengelompokkan hasil', async t => {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'shion-places-'));
  const db = await new BasisDataJson(path.join(dir, 'database', 'account.json')).buka();
  const app = await buatAplikasi({ db, uploadsDir: path.join(dir, 'uploads'), limits: false });
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  const alamat = `http://127.0.0.1:${server.address().port}/api`;
  const fetchAsli = global.fetch;
  global.fetch = async (url, options = {}) => {
    if (String(url).startsWith('https://nominatim.openstreetmap.org/search?')) {
      assert.match(options.headers['User-Agent'], /^SHION\//);
      return Response.json([{ lat: '-6.92', lon: '106.93' }]);
    }
    if (String(url) === 'https://overpass-api.de/api/interpreter') {
      assert.equal(options.method, 'POST');
      assert.match(new URLSearchParams(options.body).get('data'), /bank sampah/i);
      return Response.json({ elements: [
        { type: 'node', id: 1, lat: -6.91, lon: 106.92, tags: { name: 'Bank Sampah Sukabumi', amenity: 'recycling' } },
        { type: 'way', id: 2, center: { lat: -6.92, lon: 106.94 }, tags: { name: 'Kantor Kelurahan', office: 'government' } },
        { type: 'node', id: 3, lat: -6.90, lon: 106.91, tags: { amenity: 'recycling' } },
      ] });
    }
    return fetchAsli(url, options);
  };
  t.after(async () => { global.fetch = fetchAsli; await new Promise(resolve => server.close(resolve)); await db.tutup(); await fs.rm(dir, { recursive: true, force: true }); });
  const daftar = await (await fetch(`${alamat}/auth/register`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ name: 'Lokasi User', email: 'lokasi@example.com', phone: '081234567890', password: 'password-123' }) })).json();
  const token = daftar.data.token;
  assert.equal((await fetch(`${alamat}/places/nearby?lat=999&lng=106.9`, { headers: { Authorization: `Bearer ${token}` } })).status, 400);
  assert.equal((await fetch(`${alamat}/places/nearby?lat=-6.9&lng=106.9`)).status, 401);
  const response = await fetch(`${alamat}/places/search?query=Sukabumi`, { headers: { Authorization: `Bearer ${token}` } });
  const hasil = await response.json();
  assert.equal(response.status, 200);
  assert.equal(hasil.data.places.length, 2);
  assert.deepEqual(hasil.data.places.map(lokasi => lokasi.category), ['bank_sampah', 'kelurahan']);
  assert.deepEqual(hasil.data.center, { lat: -6.92, lng: 106.93 });
});
