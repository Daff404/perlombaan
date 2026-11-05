// ==== [ DAFFA - BACKEND ] ==== //
const { randomBytes } = require('node:crypto');
const { GalatApi, teks, hashToken } = require('../security');
const { id, catatPoin, saldoPoin } = require('../state');
function hashMuatanQr(value) {
  if (typeof value !== 'string' || !/^shion:points:[A-Za-z0-9_-]{43}$/.test(value)) throw new GalatApi(400, 'Ini bukan QR poin SHION.');
  return hashToken(value.slice(13));
}
function qrTersedia(db, hash) {
  const qr = db.pointQrs.find(q => q.tokenHash === hash);
  if (!qr || qr.usedAt || Date.parse(qr.expiresAt) <= Date.now() || !db.sessions.some(s => s.tokenHash === qr.sessionHash && Date.parse(s.expiresAt) > Date.now())) throw new GalatApi(409, 'QR sudah dipakai atau kedaluwarsa. Minta pengguna membuka QR baru.');
  const user = db.users.find(u => u.id === qr.userId && u.role === 'user' && !u.disabled);
  if (!user) throw new GalatApi(404, 'Akun penerima tidak tersedia.');
  return { qr, user };
}
module.exports = (router, c) => {
  router.post('/points/qr', c.auth, async (req, res) => {
    if (req.user.role !== 'user') throw new GalatApi(403, 'QR penerima hanya untuk akun pengguna.');
    const token = randomBytes(32).toString('base64url');
    c.ok(res, await c.db.transaksi(db => {
      db.pointQrs = db.pointQrs.filter(q => q.usedAt || q.userId !== req.user.id);
      const qr = { id: id(), userId: req.user.id, sessionHash: req.session.tokenHash, tokenHash: hashToken(token), expiresAt: new Date(Date.now() + 300000).toISOString() };
      db.pointQrs.push(qr);
      return { id: qr.id, payload: `shion:points:${token}`, expiresAt: qr.expiresAt };
    }));
  });
  router.get('/points/qr/:id', c.auth, (req, res) => c.ok(res, c.db.baca(db => {
    const qr = db.pointQrs.find(q => q.id === req.params.id && q.userId === req.user.id);
    return { used: Boolean(qr?.usedAt), amount: qr?.amount || 0, expired: !qr || Date.parse(qr.expiresAt) <= Date.now(), points: saldoPoin(db, req.user.id) };
  })));
  router.post('/admin/points/resolve', c.auth, c.admin, (req, res) => {
    const hash = hashMuatanQr(req.body.payload);
    c.ok(res, c.db.baca(db => { const { qr, user } = qrTersedia(db, hash); return { qrId: qr.id, expiresAt: qr.expiresAt, user: { id: user.id, name: user.name, username: user.username } }; }));
  });
  router.post('/admin/points/credit', c.auth, c.admin, async (req, res) => {
    const hash = hashMuatanQr(req.body.payload), requestId = teks(req.body.requestId, 'ID permintaan', 8, 100), amount = req.body.amount;
    if (!Number.isSafeInteger(amount) || amount < 1 || amount > 100000) throw new GalatApi(400, 'Jumlah harus bilangan bulat 1–100.000 poin.');
    c.ok(res, await c.db.transaksi(db => {
      const previous = db.pointQrs.find(q => q.adminId === req.user.id && q.requestId === requestId);
      if (previous) {
        if (previous.tokenHash !== hash || previous.amount !== amount) throw new GalatApi(409, 'ID transaksi sudah dipakai untuk nilai lain.');
        return { amount, userId: previous.userId, receiptId: previous.id, points: saldoPoin(db, previous.userId) };
      }
      const { qr, user } = qrTersedia(db, hash);
      if (!Number.isSafeInteger(saldoPoin(db, user.id) + amount)) throw new GalatApi(409, 'Batas saldo tercapai.');
      Object.assign(qr, { usedAt: new Date().toISOString(), adminId: req.user.id, amount, requestId });
      catatPoin(db, user.id, 'admin-qr', `Poin dari admin • ${qr.id.slice(0, 8)}`, amount, qr.id);
      db.notifications.unshift({ id: id(), recipientId: user.id, judul: 'Poin berhasil masuk', desk: `${amount} poin ditambahkan oleh admin.`, createdAt: qr.usedAt });
      return { amount, userId: user.id, receiptId: qr.id, points: saldoPoin(db, user.id) };
    }), 201);
  });
};
