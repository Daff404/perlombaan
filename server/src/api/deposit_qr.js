const { randomBytes } = require('node:crypto');
const { GalatApi, teks, hashToken } = require('../security');
const { id, catatPoin, saldoPoin } = require('../state');

function hashPayload(payload) {
  if (typeof payload !== 'string' || !/^shion:deposit:[A-Za-z0-9_-]{43}$/.test(payload)) throw new GalatApi(400, 'QR setoran tidak valid.');
  return hashToken(payload.slice(14));
}
function cari(db, hash) {
  const deposit = db.deposits.find(d => d.qrTokenHash === hash && d.status === 'Disimpan' && Date.parse(d.qrExpiresAt) > Date.now());
  if (!deposit) throw new GalatApi(409, 'QR setoran sudah dipakai atau kedaluwarsa. Buka ulang QR setoran.');
  const user = db.users.find(u => u.id === deposit.userId && u.role === 'user' && !u.disabled);
  if (!user) throw new GalatApi(404, 'Pemilik setoran tidak ditemukan.');
  return { deposit, user };
}
module.exports = (router, c) => {
  router.post('/deposits/:id/qr', c.auth, async (req, res) => {
    const token = randomBytes(32).toString('base64url');
    c.ok(res, await c.db.transaksi(db => {
      const deposit = db.deposits.find(d => d.id === req.params.id && d.userId === req.user.id);
      if (!deposit || deposit.status !== 'Disimpan') throw new GalatApi(409, 'Setoran tidak menunggu pengumpulan.');
      deposit.qrTokenHash = hashToken(token);
      deposit.qrExpiresAt = new Date(Date.now() + 300000).toISOString();
      return { depositId: deposit.id, payload: `shion:deposit:${token}`, expiresAt: deposit.qrExpiresAt };
    }));
  });
  router.post('/admin/deposits/resolve', c.auth, c.admin, (req, res) => {
    const hash = hashPayload(req.body.payload);
    c.ok(res, c.db.baca(db => {
      const { deposit, user } = cari(db, hash);
      return { depositId: deposit.id, user: { id: user.id, name: user.name || user.username }, category: deposit.category, quantity: deposit.quantity, unit: deposit.unit, destination: deposit.destination, city: deposit.city };
    }));
  });
  router.post('/admin/deposits/collect', c.auth, c.admin, async (req, res) => {
    const hash = hashPayload(req.body.payload);
    const requestId = teks(req.body.requestId, 'ID permintaan', 8, 100);
    const amount = req.body.amount;
    if (!Number.isSafeInteger(amount) || amount < 1 || amount > 100000) throw new GalatApi(400, 'Masukkan 1–100.000 poin.');
    c.ok(res, await c.db.transaksi(db => {
      const previous = db.deposits.find(d => d.collectAdminId === req.user.id && d.collectRequestId === requestId);
      if (previous) {
        if (previous.collectedQrHash !== hash || previous.points !== amount) throw new GalatApi(409, 'ID transaksi dipakai untuk setoran atau poin lain.');
        return { depositId: previous.id, amount, userId: previous.userId, points: saldoPoin(db, previous.userId) };
      }
      const { deposit, user } = cari(db, hash);
      if (!Number.isSafeInteger(saldoPoin(db, user.id) + amount)) throw new GalatApi(409, 'Batas saldo tercapai.');
      deposit.status = 'Selesai';
      deposit.points = amount;
      deposit.collectedAt = new Date().toISOString();
      deposit.collectAdminId = req.user.id;
      deposit.collectRequestId = requestId;
      deposit.collectedQrHash = hash;
      delete deposit.qrTokenHash;
      delete deposit.qrExpiresAt;
      catatPoin(db, user.id, 'deposit', `Setoran ${deposit.category} • ${deposit.destination}`, amount, deposit.id);
      db.notifications.unshift({ id: id(), recipientId: user.id, judul: 'Setoran sudah dikumpulkan', desk: `${deposit.destination} • ${amount} poin diterima.`, createdAt: deposit.collectedAt });
      return { depositId: deposit.id, amount, userId: user.id, points: saldoPoin(db, user.id) };
    }), 201);
  });
};
