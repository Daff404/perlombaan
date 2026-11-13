// ==== [ DAFFA - BACKEND ] ==== //
const express = require('express');
const fs = require('node:fs/promises');
const path = require('node:path');
const sharp = require('sharp');
const { siapkanFoto } = require('../photos');
const { GalatApi, teks } = require('../security');
const { id } = require('../state');
const waktuSekarang = () => new Date().toISOString();
function ambilGrup(d, gid) { const g = d.groups.find(g => g.id === gid && !g.archived); if (!g) throw new GalatApi(404, 'Grup tidak ditemukan.'); return g; }
function validasiAnggota(g, uid, admin = false) { const m = g.members.find(m => m.userId === uid); if (!m || (admin && m.role !== 'admin')) throw new GalatApi(403, admin ? 'Hanya admin grup yang dapat melakukan ini.' : 'Kamu bukan anggota grup ini.'); return m; }
function kirimNotifikasi(d, users, title, body, groupId) { for (const userId of new Set(users)) d.notifications.unshift({ id: id(), recipientId: userId, judul: title, desk: body, groupId, createdAt: waktuSekarang() }); }
function tambahAnggota(g, uid) { if (!g.members.some(m => m.userId === uid)) { if (g.members.length >= 200) throw new GalatApi(409, 'Maksimal 200 anggota per grup.'); g.members.push({ userId: uid, role: 'member', joinedAt: waktuSekarang() }); } }
function grupAman(g, uid) { return { id: g.id, name: g.name, description: g.description, createdAt: g.createdAt, approvalRequired: g.approvalRequired, memberCount: g.members.length, myRole: g.members.find(m => m.userId === uid)?.role || null, hasPhoto: Boolean(g.avatarFile) }; }
function buatPesanSistem(d, g, body, event) { d.groupMessages.push({ id: id(), groupId: g.id, userId: null, name: 'SHION', body, type: 'system', event, createdAt: waktuSekarang() }); }
function buatPesanGrup(d, g, uid, body, requestId, media, replyToId) {
  const old = d.groupMessages.find(m => m.groupId === g.id && m.userId === uid && m.requestId === requestId);
  if (old) return old;
  const m = { id: id(), groupId: g.id, userId: uid, body, requestId, createdAt: waktuSekarang(), ...(replyToId ? { replyToId } : {}), ...(media ? { media } : {}) };
  d.groupMessages.push(m);
  kirimNotifikasi(d, g.members.filter(m => m.userId !== uid).map(m => m.userId), g.name, media ? 'Media baru di komunitasmu.' : 'Pesan baru di komunitasmu.', g.id);
  return m;
}
module.exports = (r, c) => {
  r.get('/groups', c.auth, (req, res) => c.ok(res, c.db.baca(d => {
    const q = String(req.query.q || '').toLocaleLowerCase().slice(0, 100);
    return { groups: d.groups.filter(g => !g.archived && g.name.toLocaleLowerCase().includes(q)).slice(0, 100).map(g => ({ ...grupAman(g, req.user.id), pending: d.groupRequests.some(x => x.groupId === g.id && x.userId === req.user.id && x.status === 'pending') })), invites: d.groupInvites.filter(i => i.userId === req.user.id && i.status === 'pending' && d.groups.some(g => g.id === i.groupId && !g.archived)).map(i => ({ id: i.id, groupId: i.groupId, groupName: d.groups.find(g => g.id === i.groupId).name, inviter: d.users.find(u => u.id === i.inviterId)?.name || 'Anggota' })) };
  })));
  r.post('/groups', c.auth, async (req, res) => {
    const name = teks(req.body.name, 'Nama grup', 3, 70), description = teks(req.body.description || '', 'Deskripsi', 0, 500), requestId = teks(req.body.requestId, 'ID permintaan', 8, 100);
    c.ok(res, await c.db.transaksi(d => {
      const old = d.groups.find(g => g.createdBy === req.user.id && g.requestId === requestId); if (old) return grupAman(old, req.user.id);
      if (d.groups.filter(g => g.createdBy === req.user.id && !g.archived).length >= 10) throw new GalatApi(409, 'Maksimal 10 grup aktif per pembuat.');
      const g = { id: id(), name, description, requestId, createdBy: req.user.id, createdAt: waktuSekarang(), approvalRequired: req.body.approvalRequired === true, members: [{ userId: req.user.id, role: 'admin', joinedAt: waktuSekarang() }], pinnedIds: [] };
      d.groups.push(g); return grupAman(g, req.user.id);
    }), 201);
  });
  r.get('/groups/:id', c.auth, (req, res) => c.ok(res, c.db.baca(d => {
    const g = ambilGrup(d, req.params.id), me = validasiAnggota(g, req.user.id);
    const before = req.query.before ? Date.parse(String(req.query.before)) : Infinity;
    if (Number.isNaN(before)) throw new GalatApi(400, 'Waktu tidak valid.');
    const safe = m => ({ id: m.id, userId: m.userId, name: m.type === 'system' ? 'SHION' : d.users.find(u => u.id === m.userId)?.name || 'Pengguna', body: m.deletedForAll ? 'Pesan ini dihapus' : m.body, deletedForAll: m.deletedForAll === true, type: m.type || 'message', event: m.event || null, createdAt: m.createdAt, pinned: g.pinnedIds.includes(m.id), ...(m.replyToId ? { reply: (() => { const p = d.groupMessages.find(x => x.id === m.replyToId && x.groupId === g.id); return p ? { id: p.id, name: d.users.find(u => u.id === p.userId)?.name || 'Pengguna', body: p.deletedForAll ? 'Pesan ini dihapus' : p.body, media: Boolean(p.media) } : null; })() } : {}), ...(m.media && !m.deletedForAll ? { media: { kind: m.media.kind, url: `/groups/${g.id}/media/${m.id}` } } : {}) });
    const all = d.groupMessages.filter(m => m.groupId === g.id && Date.parse(m.createdAt) < before);
    return { group: grupAman(g, req.user.id), members: g.members.map(m => ({ ...m, name: d.users.find(u => u.id === m.userId)?.name || 'Pengguna', username: d.users.find(u => u.id === m.userId)?.username })), messages: all.slice(-100).map(safe), hasMore: all.length > 100, pinned: d.groupMessages.filter(m => m.groupId === g.id && g.pinnedIds.includes(m.id)).map(safe), requests: me.role === 'admin' ? d.groupRequests.filter(x => x.groupId === g.id && x.status === 'pending').map(x => ({ id: x.id, name: d.users.find(u => u.id === x.userId)?.name || 'Pengguna' })) : [] };
  })));
  r.get('/groups/:id/avatar', c.auth, (req, res) => {
    const file = c.db.baca(d => { const g = ambilGrup(d, req.params.id); validasiAnggota(g, req.user.id); return g.avatarFile && g.avatarUsername ? path.join(c.db.sessionDir, g.avatarUsername, 'media', g.avatarFile) : null; });
    if (!file) throw new GalatApi(404, 'Foto grup belum dipasang.'); res.type('jpeg').sendFile(file);
  });
  r.get('/groups/:id/members/:userId/avatar', c.auth, (req, res) => {
    const file = c.db.baca(d => {
      const g = ambilGrup(d, req.params.id); validasiAnggota(g, req.user.id);
      if (!g.members.some(m => m.userId === req.params.userId)) throw new GalatApi(404, 'Anggota tidak ditemukan.');
      const user = d.users.find(u => u.id === req.params.userId); if (!user) throw new GalatApi(404, 'Anggota tidak ditemukan.');
      return path.join(c.db.sessionDir, user.username, 'profile.jpg');
    });
    res.type('jpeg').sendFile(file);
  });
  r.post('/groups/:id/avatar', c.auth, async (req, res) => {
    const { photo } = await siapkanFoto(req.body.photoBase64);
    const dir = path.join(c.db.sessionDir, req.user.username, 'media'); await fs.mkdir(dir, { recursive: true });
    const file = `group-${req.params.id}.jpg`, target = path.join(dir, file), temp = `${target}.tmp`;
    await fs.writeFile(temp, photo, { mode: 0o600 }); await fs.rename(temp, target);
    try { await c.db.transaksi(d => { const g = ambilGrup(d, req.params.id); validasiAnggota(g, req.user.id, true); g.avatarFile = file; g.avatarUsername = req.user.username; }); }
    catch (e) { await fs.unlink(target).catch(() => {}); throw e; }
    c.ok(res, { saved: true });
  });
  r.post('/groups/:id/join', c.auth, async (req, res) => c.ok(res, await c.db.transaksi(d => {
    const g = ambilGrup(d, req.params.id);
    if (g.members.some(m => m.userId === req.user.id)) return { joined: true };
    if (!g.approvalRequired) { tambahAnggota(g, req.user.id); buatPesanSistem(d, g, `${req.user.name} bergabung`, 'join'); return { joined: true }; }
    if (!d.groupRequests.some(x => x.groupId === g.id && x.userId === req.user.id && x.status === 'pending')) { d.groupRequests.push({ id: id(), groupId: g.id, userId: req.user.id, status: 'pending', createdAt: waktuSekarang() }); kirimNotifikasi(d, g.members.filter(m => m.role === 'admin').map(m => m.userId), 'Permintaan bergabung', `${req.user.name} ingin bergabung ke ${g.name}.`, g.id); }
    return { joined: false, pending: true };
  })));
  r.post('/groups/:id/invite', c.auth, async (req, res) => {
    const username = teks(req.body.username, 'Username akun', 1, 80).toLowerCase();
    c.ok(res, await c.db.transaksi(d => {
      const g = ambilGrup(d, req.params.id); validasiAnggota(g, req.user.id);
      const u = d.users.find(u => u.username === username && !u.disabled);
      if (!u) throw new GalatApi(404, 'Username tidak ditemukan. Minta username dari halaman QR atau profil pengguna.');
      if (g.members.some(m => m.userId === u.id)) throw new GalatApi(409, 'Pengguna sudah menjadi anggota.');
      let invite = d.groupInvites.find(i => i.groupId === g.id && i.userId === u.id && i.status === 'pending');
      if (!invite) { invite = { id: id(), groupId: g.id, userId: u.id, inviterId: req.user.id, status: 'pending', createdAt: waktuSekarang() }; d.groupInvites.push(invite); kirimNotifikasi(d, [u.id], 'Undangan komunitas', `${req.user.name} mengundangmu ke ${g.name}. Terima atau tolak di menu Komunitas.`, g.id); }
      return { invited: true };
    }));
  });
  r.post('/group-invites/:id/respond', c.auth, async (req, res) => c.ok(res, await c.db.transaksi(d => {
    if (typeof req.body.accept !== 'boolean') throw new GalatApi(400, 'Pilih terima atau tolak.');
    const i = d.groupInvites.find(i => i.id === req.params.id && i.userId === req.user.id);
    if (!i) throw new GalatApi(404, 'Undangan tidak ditemukan.');
    if (i.status !== 'pending') return { status: i.status };
    const g = ambilGrup(d, i.groupId);
    if (!req.body.accept) { i.status = 'rejected'; return { status: i.status }; }
    // Consent is never bypassed. With approval on, consent creates a join request.
    if (g.approvalRequired && !g.members.some(m => m.userId === req.user.id)) {
      if (!d.groupRequests.some(x => x.groupId === g.id && x.userId === req.user.id && x.status === 'pending')) d.groupRequests.push({ id: id(), groupId: g.id, userId: req.user.id, status: 'pending', createdAt: waktuSekarang() });
      kirimNotifikasi(d, g.members.filter(m => m.role === 'admin').map(m => m.userId), 'Persetujuan anggota', `${req.user.name} menerima undangan ke ${g.name}.`, g.id); i.status = 'awaiting-approval';
    } else { tambahAnggota(g, req.user.id); buatPesanSistem(d, g, `${req.user.name} bergabung`, 'join'); i.status = 'accepted'; }
    return { status: i.status };
  })));
  r.post('/groups/:id/requests/:requestId', c.auth, async (req, res) => c.ok(res, await c.db.transaksi(d => {
    const g = ambilGrup(d, req.params.id); validasiAnggota(g, req.user.id, true);
    if (typeof req.body.accept !== 'boolean') throw new GalatApi(400, 'Pilih setuju atau tolak.');
    const x = d.groupRequests.find(x => x.id === req.params.requestId && x.groupId === g.id);
    if (!x) throw new GalatApi(404, 'Permintaan tidak ditemukan.');
    if (x.status === 'pending') { if (req.body.accept) { tambahAnggota(g, x.userId); const user = d.users.find(u => u.id === x.userId); buatPesanSistem(d, g, `${user?.name || 'Pengguna'} bergabung`, 'join'); } x.status = req.body.accept ? 'accepted' : 'rejected'; kirimNotifikasi(d, [x.userId], 'Permintaan grup diperbarui', `${g.name}: ${req.body.accept ? 'kamu sudah bergabung' : 'permintaan belum disetujui'}.`, g.id); }
    return { status: x.status };
  })));
  r.put('/groups/:id/settings', c.auth, async (req, res) => c.ok(res, await c.db.transaksi(d => {
    const g = ambilGrup(d, req.params.id); validasiAnggota(g, req.user.id, true);
    if (typeof req.body.approvalRequired !== 'boolean') throw new GalatApi(400, 'Pengaturan tidak valid.');
    g.approvalRequired = req.body.approvalRequired; return grupAman(g, req.user.id);
  })));
  r.post('/groups/:id/promote', c.auth, async (req, res) => c.ok(res, await c.db.transaksi(d => {
    const g = ambilGrup(d, req.params.id); validasiAnggota(g, req.user.id, true); validasiAnggota(g, req.body.userId).role = 'admin'; return { promoted: true };
  })));
  r.post('/groups/:id/leave', c.auth, async (req, res) => c.ok(res, await c.db.transaksi(d => {
    const g = ambilGrup(d, req.params.id), m = validasiAnggota(g, req.user.id);
    if (m.role === 'admin' && g.members.length > 1 && g.members.filter(m => m.role === 'admin').length === 1) throw new GalatApi(409, 'Jadikan anggota lain admin terlebih dahulu sebelum keluar.');
    g.members = g.members.filter(m => m.userId !== req.user.id); buatPesanSistem(d, g, `${req.user.name} keluar`, 'leave'); if (!g.members.length) g.archived = true;
    return { left: true };
  })));
  r.post('/groups/:id/messages', c.auth, async (req, res) => {
    const body = teks(req.body.body, 'Pesan', 1, 4000), requestId = teks(req.body.requestId, 'ID permintaan', 8, 100), replyToId = req.body.replyToId == null ? null : teks(req.body.replyToId, 'Pesan balasan', 1, 100);
    c.ok(res, await c.db.transaksi(d => { const g = ambilGrup(d, req.params.id); validasiAnggota(g, req.user.id); if (replyToId && !d.groupMessages.some(m => m.id === replyToId && m.groupId === g.id)) throw new GalatApi(404, 'Pesan yang dibalas tidak ditemukan.'); const m = buatPesanGrup(d, g, req.user.id, body, requestId, null, replyToId); return { id: m.id }; }), 201);
  });
  r.delete('/groups/:id/messages/:messageId', c.auth, async (req, res) => {
    const result = await c.db.transaksi(d => {
      const g = ambilGrup(d, req.params.id); validasiAnggota(g, req.user.id);
      const m = d.groupMessages.find(m => m.id === req.params.messageId && m.groupId === g.id && m.type !== 'system');
      if (!m) throw new GalatApi(404, 'Pesan tidak ditemukan.');
      if (m.userId !== req.user.id && !g.members.some(x => x.userId === req.user.id && x.role === 'admin')) throw new GalatApi(403, 'Kamu hanya dapat menghapus pesanmu sendiri.');
      const media = m.media; m.deletedForAll = true; m.body = ''; delete m.media; g.pinnedIds = g.pinnedIds.filter(x => x !== m.id); return media;
    });
    if (result) await fs.unlink(path.join(c.db.sessionDir, result.username, 'media', result.file)).catch(e => { if (e.code !== 'ENOENT') throw e; });
    c.ok(res, { deleted: true });
  });
  r.post('/groups/:id/pin', c.auth, async (req, res) => c.ok(res, await c.db.transaksi(d => {
    const g = ambilGrup(d, req.params.id); validasiAnggota(g, req.user.id, true);
    if (!d.groupMessages.some(m => m.id === req.body.messageId && m.groupId === g.id) || typeof req.body.pinned !== 'boolean') throw new GalatApi(400, 'Pesan tidak valid.');
    g.pinnedIds = g.pinnedIds.filter(x => x !== req.body.messageId);
    if (req.body.pinned) { if (g.pinnedIds.length >= 3) throw new GalatApi(409, 'Maksimal tiga pesan disematkan.'); g.pinnedIds.push(req.body.messageId); }
    return { pinnedIds: g.pinnedIds };
  })));
  r.post('/groups/:id/media', c.auth, (req, res, next) => { try { c.db.baca(d => validasiAnggota(ambilGrup(d, req.params.id), req.user.id)); next(); } catch (e) { next(e); } }, express.raw({ type: 'application/octet-stream', limit: '20mb' }), async (req, res) => {
    const requestId = teks(req.query.requestId, 'ID permintaan', 8, 100), kind = req.query.kind, replyToId = req.query.replyToId ? teks(req.query.replyToId, 'Pesan balasan', 1, 100) : null;
    if (!Buffer.isBuffer(req.body) || !req.body.length || !['image', 'video'].includes(kind)) throw new GalatApi(400, 'Media tidak valid.');
    let bytes = req.body, ext;
    if (kind === 'image') {
      try { bytes = await sharp(bytes, { limitInputPixels: 20000000, animated: false }).rotate().resize({ width: 1600, height: 1600, fit: 'inside', withoutEnlargement: true }).jpeg({ quality: 85 }).toBuffer(); ext = 'jpg'; } catch (_) { throw new GalatApi(400, 'Gambar tidak didukung atau terlalu besar.'); }
    } else { if (bytes.length < 16 || bytes.toString('ascii', 4, 8) !== 'ftyp') throw new GalatApi(400, 'Gunakan video MP4/MOV.'); ext = 'mp4'; }
    const file = `${id()}.${ext}`, dir = path.join(c.db.sessionDir, req.user.username, 'media'); await fs.mkdir(dir, { recursive: true }); await fs.writeFile(path.join(dir, file), bytes, { mode: 0o600 });
    try {
      const saved = await c.db.transaksi(d => { const g = ambilGrup(d, req.params.id); validasiAnggota(g, req.user.id); if (replyToId && !d.groupMessages.some(m => m.id === replyToId && m.groupId === g.id)) throw new GalatApi(404, 'Pesan yang dibalas tidak ditemukan.'); return buatPesanGrup(d, g, req.user.id, '', requestId, { kind, file, username: req.user.username }, replyToId); });
      if (saved.media?.file !== file) await fs.unlink(path.join(dir, file));
      c.ok(res, { id: saved.id }, 201);
    } catch (e) { await fs.unlink(path.join(dir, file)).catch(() => {}); throw e; }
  });
  r.get('/groups/:id/media/:messageId', c.auth, (req, res) => {
    const media = c.db.baca(d => { const g = ambilGrup(d, req.params.id); validasiAnggota(g, req.user.id); return d.groupMessages.find(m => m.groupId === g.id && m.id === req.params.messageId)?.media; });
    if (!media) throw new GalatApi(404, 'Media tidak ditemukan.');
    res.type(media.kind === 'image' ? 'jpeg' : 'video/mp4').sendFile(path.join(c.db.sessionDir, media.username, 'media', media.file));
  });
};
