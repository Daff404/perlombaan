// ==== [ DAFFA - BACKEND ] ==== //
const fs = require('node:fs/promises');
const path = require('node:path');
const { GalatApi, teks } = require('../security');
const { siapkanFoto, hashSerupa } = require('../photos');
const { validasiHasil } = require('../ai');
const { keadaanPengguna, dataMilik, catatPoin, id } = require('../state');
const wilayah = require('../jabar-kelurahan.json');
const kelurahanById = new Map(Object.values(wilayah).flatMap(k => k.villages.map(v => [v.id, { ...v, city: k.city }])));
function simpanPemindaian(scan) { return { points: scan.earnedPoints, reason: scan.pointsReason }; }
module.exports = (router, c) => {
  router.post('/scans', c.auth, c.aiLimit, async (req, res) => {
    const requestId = teks(req.body.requestId, 'ID permintaan', 8, 100);
    const existing = c.db.baca(db => db.scans.find(s => s.userId === req.user.id && s.requestId === requestId));
    if (existing) { const { photoFile: _, ...safe } = existing; return c.ok(res, { scan: safe, save: simpanPemindaian(existing), state: c.db.baca(db => keadaanPengguna(db, req.user.id)) }); }
    const prepared = await siapkanFoto(req.body.photoBase64);
    const result = validasiHasil(await c.ai.classify(prepared.photo));
    const scanId = id(), photoFile = `${scanId}.jpg`, photoSession = req.user.username;
    const photoDir = path.join(c.db.sessionDir, photoSession, 'scan-media');
    await fs.mkdir(photoDir, { recursive: true });
    await fs.writeFile(path.join(photoDir, photoFile), prepared.photo, { mode: 0o600 });
    try {
      const response = await c.db.transaksi(db => {
        const repeated = db.scans.find(s => s.userId === req.user.id && s.requestId === requestId);
        if (repeated) return { scan: repeated, save: simpanPemindaian(repeated), state: keadaanPengguna(db, req.user.id) };
        const now = new Date().toISOString(), today = now.slice(0, 10);
        const duplicate = db.scans.some(s => s.imageHash === prepared.imageHash || hashSerupa(s.perceptualHash, prepared.perceptualHash));
        const eligible = result.isWaste && result.category !== 'Tidak jelas' && result.confidence >= .65;
        const rewardedToday = dataMilik(db, 'ledger', req.user.id).filter(l => l.kind === 'scan' && l.createdAt.startsWith(today)).length;
        const points = !duplicate && eligible && rewardedToday < 5 ? 1 : 0;
        const reason = duplicate ? 'Foto sama atau sangat mirip sudah tercatat. Tidak ada poin tambahan.' : !eligible ? 'Objek belum cukup jelas dikenali sebagai sampah.' : rewardedToday >= 5 ? 'Batas 5 scan berpoin per hari telah tercapai.' : 'Scan AI baru berhasil dicatat.';
        const scan = { ...result, duplicate, id: scanId, userId: req.user.id, requestId, createdAt: now, classification: 'AI Detector', model: c.ai.model || 'server', imageHash: prepared.imageHash, perceptualHash: prepared.perceptualHash, photoFile, photoSession, earnedPoints: points, pointsReason: reason };
        db.scans.unshift(scan);
        if (points) catatPoin(db, req.user.id, 'scan', `Pindai ${result.name}`, points, scanId);
        return { scan, save: simpanPemindaian(scan), state: keadaanPengguna(db, req.user.id) };
      });
      if (response.scan.id !== scanId) await fs.unlink(path.join(photoDir, photoFile)).catch(() => {});
      const { photoFile: _, ...safe } = response.scan;
      c.ok(res, { ...response, scan: safe }, 201);
    } catch (error) { await fs.unlink(path.join(photoDir, photoFile)).catch(() => {}); throw error; }
  });
  router.get('/scans/:id/photo', c.auth, async (req, res) => {
    const scan = c.db.baca(db => db.scans.find(s => s.id === req.params.id && s.userId === req.user.id));
    if (!scan?.photoFile) throw new GalatApi(404, 'Foto tidak ditemukan.');
    const dir = scan.photoSession ? path.join(c.db.sessionDir, scan.photoSession, 'scan-media') : c.uploadsDir;
    res.type('jpeg').send(await fs.readFile(path.join(dir, scan.photoFile)));
  });
  router.post('/deposits', c.auth, async (req, res) => {
    const requestId = teks(req.body.requestId, 'ID permintaan', 8, 100);
    const quantity = req.body.quantity, unit = req.body.unit;
    const kelurahan = kelurahanById.get(teks(req.body.kelurahanId, 'Kelurahan tujuan', 8, 40));
    if (!kelurahan) throw new GalatApi(400, 'Pilih kelurahan dari daftar wilayah yang tersedia.');
    if (!['kg', 'satuan'].includes(unit) || !Number.isFinite(quantity) || quantity <= 0 || quantity > 1000 || (unit === 'satuan' && !Number.isInteger(quantity))) throw new GalatApi(400, 'Jumlah atau satuan setoran tidak valid.');
    c.ok(res, await c.db.transaksi(db => {
      if (db.deposits.some(d => d.userId === req.user.id && d.requestId === requestId)) return keadaanPengguna(db, req.user.id);
      const scan = db.scans.find(s => s.id === req.body.scanId && s.userId === req.user.id && s.isWaste && !s.duplicate && s.confidence >= .65);
      if (!scan) throw new GalatApi(400, 'Pilih hasil scan AI yang valid dari akunmu.');
      if (scan.depositedAt || db.deposits.some(d => d.scanId === scan.id)) throw new GalatApi(409, 'Hasil scan ini sudah digunakan untuk setoran.');
      if (!['Plastik', 'Kertas', 'Organik', 'Logam', 'Kaca', 'Elektronik', 'B3', 'Residu'].includes(scan.category)) throw new GalatApi(400, 'Kategori belum didukung untuk setoran.');
      const deposit = { id: id(), userId: req.user.id, requestId, scanId: scan.id, category: scan.category, quantity, unit, ...(unit === 'kg' ? { estimatedKg: quantity } : {}), kelurahanId: kelurahan.id, city: kelurahan.city, destination: `Kelurahan ${kelurahan.name}`, status: 'Disimpan', points: 0, createdAt: new Date().toISOString() };
      db.deposits.unshift(deposit); scan.depositedAt = deposit.createdAt;
      return keadaanPengguna(db, req.user.id);
    }), 201);
  });
};
