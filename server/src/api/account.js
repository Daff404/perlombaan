// ==== [ DAFFA - BACKEND ] ==== //
const { GalatApi, teks, surel, telepon } = require('../security');
const { keadaanPengguna, id } = require('../state');
const fs = require('node:fs/promises');
const path = require('node:path');
const { siapkanFoto } = require('../photos');
module.exports = (router, c) => {
  router.get('/profile/photo', c.auth, (req, res) => res.type('jpeg').sendFile(path.join(c.db.sessionDir, req.user.username, 'profile.jpg')));
  router.post('/profile/photo', c.auth, async (req, res) => {
    const { photo } = await siapkanFoto(req.body.photoBase64);
    const dir = path.join(c.db.sessionDir, req.user.username); await fs.mkdir(dir, { recursive: true });
    const target = path.join(dir, 'profile.jpg'), temp = `${target}.tmp`;
    await fs.writeFile(temp, photo, { mode: 0o600 }); await fs.rename(temp, target);
    c.ok(res, { saved: true });
  });
  router.delete('/profile/photo', c.auth, async (req, res) => { await fs.unlink(path.join(c.db.sessionDir, req.user.username, 'profile.jpg')).catch(e => { if (e.code !== 'ENOENT') throw e; }); c.ok(res, { deleted: true }); });
  router.get('/state', c.auth, (req, res) => c.ok(res, c.db.baca(db => keadaanPengguna(db, req.user.id))));
  router.put('/profile', c.auth, async (req, res) => {
    const profile = { name: teks(req.body.name, 'Nama', 2, 80), email: surel(req.body.email), phone: req.user.role === 'admin' && req.body.phone === '' ? '' : telepon(req.body.phone) };
    c.ok(res, await c.db.transaksi(db => {
      if (db.users.some(u => u.id !== req.user.id && u.email === profile.email)) throw new GalatApi(409, 'Email sudah digunakan.');
      Object.assign(db.users.find(u => u.id === req.user.id), profile);
      return keadaanPengguna(db, req.user.id);
    }));
  });
  router.post('/activities', c.auth, async (req, res) => {
    const activity = teks(req.body.activity, 'Aktivitas', 1, 80);
    const allowed = { 'Sepeda motor': 'km', 'Motor': 'km', 'Mobil': 'km', 'Transportasi umum': 'km', 'Jalan kaki': 'km', 'Sepeda': 'km', 'Listrik': 'kWh' };
    // Labels in the existing activity form are also accepted; the server still fixes the unit.
    const factor = req.body.factor;
    if (!Number.isFinite(factor) || factor < 0 || factor > 100) throw new GalatApi(400, 'Faktor emisi tidak valid.');
    const activityUnits = { 'Perjalanan motor': 'km', 'Perjalanan mobil': 'km', 'Pemakaian listrik': 'kWh', ...allowed };
    if (!activityUnits[activity] || req.body.unit !== activityUnits[activity] || !Number.isFinite(req.body.amount) || req.body.amount <= 0 || req.body.amount > 100000) throw new GalatApi(400, 'Aktivitas atau jumlah tidak valid.');
    c.ok(res, await c.db.transaksi(db => { db.activities.unshift({ id: id(), userId: req.user.id, activity, amount: req.body.amount, unit: activityUnits[activity], factor, co2Kg: req.body.amount * factor, factorSource: 'Asumsi pengguna', createdAt: new Date().toISOString() }); return keadaanPengguna(db, req.user.id); }), 201);
  });
  router.post('/places', c.auth, async (req, res) => {
    const name = teks(req.body.name, 'Nama tempat', 1, 200);
    const latitude = req.body.lat, longitude = req.body.lon;
    if (!Number.isFinite(latitude) || latitude < -90 || latitude > 90 || !Number.isFinite(longitude) || longitude < -180 || longitude > 180) throw new GalatApi(400, 'Koordinat tidak valid.');
    c.ok(res, await c.db.transaksi(db => {
      if (!db.places.some(p => p.userId === req.user.id && p.lat === latitude && p.lon === longitude)) db.places.unshift({ id: id(), userId: req.user.id, name, lat: latitude, lon: longitude, osmId: teks(req.body.osmId, 'ID tempat', 1, 100), hours: String(req.body.hours || '').slice(0, 300), materials: Array.isArray(req.body.materials) ? req.body.materials.filter(m => typeof m === 'string').slice(0, 30).map(m => m.slice(0, 100)) : [], address: String(req.body.address || '').slice(0, 500), type: String(req.body.type || '').slice(0, 100), source: String(req.body.source || '').slice(0, 100), createdAt: new Date().toISOString() });
      return keadaanPengguna(db, req.user.id);
    }), 201);
  });
};
