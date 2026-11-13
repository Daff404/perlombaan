// ==== [ DAFFA - BACKEND ] ==== //
const { GalatApi, teks } = require('../security');
const { id, papanPeringkat, daftarNotifikasi, keadaanPengguna } = require('../state');
module.exports = (router, c) => {
  router.get('/leaderboard', c.auth, (req, res) => {
    const metric = req.query.metric || 'points';
    if (!['points', 'deposits'].includes(metric)) throw new GalatApi(400, 'Pilih papan poin atau setoran.');
    c.ok(res, c.db.baca(db => papanPeringkat(db, metric, req.user.id)));
  });
  router.get('/notifications', c.auth, (req, res) => c.ok(res, { notifications: c.db.baca(db => daftarNotifikasi(db, req.user.id)) }));
  router.post('/notifications/read', c.auth, async (req, res) => {
    const ids = req.body.ids;
    if (!Array.isArray(ids) || ids.length > 200 || ids.some(id => typeof id !== 'string')) throw new GalatApi(400, 'Daftar notifikasi tidak valid.');
    c.ok(res, await c.db.transaksi(db => {
      const visible = new Set(daftarNotifikasi(db, req.user.id).map(n => n.id));
      for (const notificationId of ids) if (visible.has(notificationId) && !db.notificationReads.some(r => r.userId === req.user.id && r.notificationId === notificationId)) db.notificationReads.push({ userId: req.user.id, notificationId, readAt: new Date().toISOString() });
      return keadaanPengguna(db, req.user.id);
    }));
  });
  router.get('/admin/users', c.auth, c.admin, (req, res) => c.ok(res, { users: c.db.baca(db => db.users.filter(u => u.role === 'user').map(({ id, name, surel }) => ({ id, name, surel }))) }));
  router.get('/admin/notifications', c.auth, c.admin, (req, res) => c.ok(res, { notifications: c.db.baca(db => db.notifications.filter(n => n.recipientId === null).slice(0, 100)) }));
  router.post('/admin/notifications', c.auth, c.admin, async (req, res) => {
    const requestId = teks(req.body.requestId, 'ID permintaan', 8, 100);
    const title = teks(req.body.title, 'Judul', 3, 100), body = teks(req.body.body, 'Pesan', 3, 2000);
    if (req.body.recipientId) throw new GalatApi(400, 'Notifikasi hanya dikirim ke semua pengguna.');
    const recipientId = null;
    const gambar = require('../image_url').urlGambar(req.body.gambar);
    c.ok(res, await c.db.transaksi(db => {
      const existing = db.notifications.find(n => n.senderId === req.user.id && n.requestId === requestId);
      if (existing) return { notification: existing, recipients: existing.recipients };
      if (recipientId && !db.users.some(u => u.id === recipientId && u.role === 'user')) throw new GalatApi(400, 'Penerima tidak ditemukan.');
      const recipientIds = db.users.filter(u => u.role === 'user' && !u.disabled && (!recipientId || u.id === recipientId)).map(u => u.id);
      const notification = { id: id(), requestId, judul: title, desk: body, ...(gambar ? { gambar } : {}), recipientId, recipientIds, senderId: req.user.id, createdAt: new Date().toISOString() };
      db.notifications.unshift(notification);
      const recipients = recipientIds.length;
      notification.recipients = recipients;
      return { notification, recipients };
    }), 201);
  });
};
