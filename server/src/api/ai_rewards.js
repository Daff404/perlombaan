// ==== [ DAFFA - BACKEND ] ==== //
const { GalatApi, teks } = require('../security');
const { rewards, dataMilik, saldoPoin, catatPoin, keadaanPengguna, id } = require('../state');
module.exports = (router, c) => {
  router.post('/rewards/:id/redeem', c.auth, async (req, res) => {
    const requestId = teks(req.body.requestId, 'ID permintaan', 8, 100);
    const reward = rewards.find(r => r.id === req.params.id);
    if (!reward) throw new GalatApi(404, 'Reward tidak tersedia.');
    c.ok(res, await c.db.transaksi(db => {
      const existing = db.vouchers.find(v => v.userId === req.user.id && v.requestId === requestId);
      if (existing) return { code: existing.code, state: keadaanPengguna(db, req.user.id) };
      if (saldoPoin(db, req.user.id) < reward.cost) throw new GalatApi(409, 'Poin belum cukup.');
      const voucher = { id: id(), userId: req.user.id, requestId, rewardId: reward.id, title: reward.title, code: `SHION-${id().replace(/-/g, '').slice(0, 12).toUpperCase()}`, cost: reward.cost, used: false, createdAt: new Date().toISOString() };
      db.vouchers.unshift(voucher);
      catatPoin(db, req.user.id, 'reward', reward.title, -reward.cost, voucher.id);
      return { code: voucher.code, state: keadaanPengguna(db, req.user.id) };
    }), 201);
  });
  router.post('/guides', c.auth, c.aiLimit, async (req, res) => {
    const requestId = teks(req.body.requestId, 'ID permintaan', 8, 100);
    const existing = c.db.baca(db => db.guides.find(g => g.userId === req.user.id && g.requestId === requestId));
    if (existing) return c.ok(res, { guide: existing.text, state: c.db.baca(db => keadaanPengguna(db, req.user.id)) });
    if (c.db.baca(db => saldoPoin(db, req.user.id)) < 20) throw new GalatApi(409, 'Poin belum cukup.');
    const guide = await c.ai.guide(c.db.baca(db => dataMilik(db, 'scans', req.user.id)));
    c.ok(res, await c.db.transaksi(db => {
      const repeated = db.guides.find(g => g.userId === req.user.id && g.requestId === requestId);
      if (repeated) return { guide: repeated.text, state: keadaanPengguna(db, req.user.id) };
      if (saldoPoin(db, req.user.id) < 20) throw new GalatApi(409, 'Poin belum cukup.');
      const record = { id: id(), userId: req.user.id, requestId, text: guide, createdAt: new Date().toISOString() };
      db.guides.unshift(record);
      catatPoin(db, req.user.id, 'guide', 'Panduan Pilah Personal', -20, record.id);
      return { guide, state: keadaanPengguna(db, req.user.id) };
    }), 201);
  });
  router.post('/chat', c.auth, c.aiLimit, async (req, res) => {
    const message = teks(req.body.message, 'Pesan', 1, 2000), requestId = teks(req.body.requestId, 'ID permintaan', 8, 100);
    const getPrevious = db => db.messages.find(m => m.userId === req.user.id && m.requestId === requestId && !m.isUser);
    const existing = c.db.baca(getPrevious);
    if (existing) return c.ok(res, { answer: existing.text, state: c.db.baca(db => keadaanPengguna(db, req.user.id)) });
    const history = c.db.baca(db => dataMilik(db, 'messages', req.user.id));
    const answer = await c.ai.chat(message, history);
    c.ok(res, await c.db.transaksi(db => {
      const repeated = getPrevious(db);
      if (!repeated) db.messages.push(
        { id: id(), userId: req.user.id, requestId, isUser: true, text: message, createdAt: new Date().toISOString() },
        { id: id(), userId: req.user.id, requestId, isUser: false, text: answer, createdAt: new Date().toISOString() });
      return { answer: repeated?.text || answer, state: keadaanPengguna(db, req.user.id) };
    }));
  });
};
