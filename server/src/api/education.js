// ==== [ DAFFA - BACKEND ] ==== //
const { teks, GalatApi } = require('../security');
const { id } = require('../state');
const { urlGambar } = require('../image_url');
module.exports = (router, c) => {
  router.get('/education', c.auth, (req, res) => {
    const local = c.db.baca(db => db.education.slice().sort((a,b) => b.createdAt.localeCompare(a.createdAt)));
    c.ok(res, { articles: local });
  });
  router.get('/admin/education', c.auth, c.admin, (req, res) => c.ok(res, { articles: c.db.baca(db => db.education) }));
  router.post('/admin/education', c.auth, c.admin, async (req, res) => {
    const requestId = teks(req.body.requestId, 'ID permintaan', 8, 100);
    const record = { id: id(), requestId, judul: teks(req.body.judul, 'Judul', 3, 180), desk: teks(req.body.desk, 'Ringkasan', 3, 500), konten: teks(req.body.konten, 'Isi edukasi', 20, 30000), kategori: teks(req.body.kategori, 'Kategori', 2, 60), gambar: urlGambar(req.body.gambar), sumber: 'Tim SHION', authorId: req.user.id, external: false, createdAt: new Date().toISOString() };
    c.ok(res, await c.db.transaksi(db => {
      const existing = db.education.find(a => a.authorId === req.user.id && a.requestId === requestId);
      if (existing) return { article: existing };
      db.education.unshift(record); return { article: record };
    }), 201);
  });
  router.delete('/admin/education/:id', c.auth, c.admin, async (req, res) => {
    await c.db.transaksi(db => {
      if (!db.education.some(a => a.id === req.params.id)) throw new GalatApi(404, 'Edukasi tidak ditemukan.');
      db.education = db.education.filter(a => a.id !== req.params.id);
    }); c.ok(res, { deleted: true });
  });
};
