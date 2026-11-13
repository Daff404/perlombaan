// ==== [ DAFFA - BACKEND ] ==== //
const { GalatApi, teks, surel, telepon, hashKataSandi, cocokkanKataSandi, buatSesi } = require('../security');
const { penggunaPublik, keadaanPengguna, id } = require('../state');
module.exports = (router, c) => {
  const mulaiSesi = async (db, user) => {
    const created = buatSesi(user.id, c.sessionDays);
    db.sessions = db.sessions.filter(s => Date.parse(s.expiresAt) > Date.now());
    db.sessions.push(created.session);
    return { token: created.token, expiresAt: created.session.expiresAt, state: keadaanPengguna(db, user.id) };
  };
  router.post('/auth/register', c.loginLimit, async (req, res) => {
    const user = { id: id(), name: teks(req.body.name, 'Nama', 2, 80), email: surel(req.body.email), phone: telepon(req.body.phone), role: 'user', createdAt: new Date().toISOString(), passwordHash: await hashKataSandi(req.body.password) };
    user.username = require('../db').namaPenggunaUntuk(user);
    const result = await c.db.transaksi(async db => {
      if (db.users.some(u => u.email === user.email)) throw new GalatApi(409, 'Email sudah terdaftar. Silakan masuk.', 'EMAIL_EXISTS');
      db.users.push(user);
      return mulaiSesi(db, user);
    });
    c.ok(res, result, 201);
  });
  router.post('/auth/login', c.loginLimit, async (req, res) => {
    const address = surel(req.body.email);
    const user = c.db.baca(db => db.users.find(u => u.email === address));
    // Hash a dummy password too, so unknown email addresses do not skip the slow check.
    const valid = user ? await cocokkanKataSandi(req.body.password, user.passwordHash) : (await hashKataSandi('dummy-password-never-used'), false);
    if (!valid || user.disabled) throw new GalatApi(401, 'Email atau kata sandi belum cocok.', 'INVALID_CREDENTIALS');
    c.ok(res, await c.db.transaksi(db => mulaiSesi(db, db.users.find(u => u.id === user.id))));
  });
  router.put('/auth/password', c.auth, c.loginLimit, async (req, res) => {
    const current = c.db.baca(db => db.users.find(u => u.id === req.user.id));
    if (!await cocokkanKataSandi(req.body.currentPassword, current.passwordHash)) throw new GalatApi(400, 'Kata sandi lama belum cocok.');
    const passwordHash = await hashKataSandi(teks(req.body.newPassword, 'Kata sandi baru (12–128 karakter)', 12, 128));
    await c.db.transaksi(db => {
      const user = db.users.find(u => u.id === req.user.id);
      if (user.passwordHash !== current.passwordHash) throw new GalatApi(409, 'Kata sandi telah berubah. Coba lagi.');
      user.passwordHash = passwordHash;
      db.sessions = db.sessions.filter(s => s.userId !== user.id || s.tokenHash === req.session.tokenHash);
    });
    c.ok(res, { changed: true });
  });
  router.get('/auth/me', c.auth, (req, res) => c.ok(res, { user: penggunaPublik(req.user), expiresAt: req.session.expiresAt }));
  router.post('/auth/logout', c.auth, async (req, res) => {
    await c.db.transaksi(db => { db.sessions = db.sessions.filter(s => s.tokenHash !== req.session.tokenHash); });
    c.ok(res, { loggedOut: true });
  });
};
