// ==== [ DAFFA - BACKEND ] ==== //
const { randomUUID } = require('node:crypto');
const rewards = [
  { id: 'transport', title: 'Potongan Transportasi Rp10.000', cost: 150, photo: 'assets/images/transport.png' },
  { id: 'tumbler', title: 'Tumbler Ramah Lingkungan', cost: 250, photo: 'assets/images/reuse.png' },
  { id: 'shopping', title: 'Voucher Produk Hijau Rp20.000', cost: 300, photo: 'assets/images/organic.png' },
];
const penggunaPublik = user => ({ id: user.id, username: user.username, name: user.name, email: user.email, phone: user.phone, role: user.role, createdAt: user.createdAt });
const dataMilik = (db, key, userId) => db[key].filter(r => r.userId === userId);
const saldoPoin = (db, userId) => dataMilik(db, 'ledger', userId).reduce((sum, r) => sum + r.delta, 0);
function daftarNotifikasi(db, userId) {
  const read = new Set(db.notificationReads.filter(r => r.userId === userId).map(r => r.notificationId));
  const user = db.users.find(u => u.id === userId);
  return db.notifications.filter(n => (n.recipientId === userId || (n.recipientId === null && (n.recipientIds ? n.recipientIds.includes(userId) : user.role === 'user' && n.createdAt >= user.createdAt))))
    .map(n => ({ id: n.id, title: n.judul ?? n.title, body: n.desk ?? n.body, gambar: n.gambar || null, createdAt: n.createdAt, read: read.has(n.id) }));
}
function keadaanPengguna(db, userId) {
  const user = db.users.find(u => u.id === userId);
  const scans = dataMilik(db, 'scans', userId).map(({ photoFile, ...r }) => ({ ...r, hasPhoto: Boolean(photoFile) }));
  const result = { revision: db.revision || 0, user: penggunaPublik(user), points: saldoPoin(db, userId), lastDetection: scans[0] ?? null, scans, rewards };
  for (const key of ['deposits', 'ledger', 'vouchers', 'guides', 'activities', 'places', 'messages']) result[key] = dataMilik(db, key, userId);
  result.notifications = daftarNotifikasi(db, userId);
  return result;
}
function catatPoin(db, userId, kind, description, delta, referenceId) {
  const id = `${kind}-${referenceId}`;
  if (db.ledger.some(r => r.id === id)) return;
  db.ledger.unshift({ id, userId, kind, description, delta, createdAt: new Date().toISOString() });
}
function papanPeringkat(db, metric, userId) {
  const users = db.users.filter(u => u.role === 'user' && !u.disabled).map(u => {
    const completed = dataMilik(db, 'deposits', u.id).filter(d => d.status === 'Selesai');
    const points = dataMilik(db, 'ledger', u.id).filter(l => l.delta > 0).reduce((a, l) => a + l.delta, 0);
    return { id: u.id, name: u.name, points, deposits: completed.length,
      totalKg: completed.filter(d => d.unit === 'kg').reduce((a, d) => a + d.quantity, 0),
      totalUnits: completed.filter(d => d.unit === 'satuan').reduce((a, d) => a + d.quantity, 0),
      joinedAt: u.createdAt };
  }).sort((a, b) => b[metric] - a[metric] || a.joinedAt.localeCompare(b.joinedAt) || a.id.localeCompare(b.id));
  let rank = 0, previousScore = null;
  const rows = users.map((u, index) => {
    if (u[metric] !== previousScore) rank = index + 1;
    previousScore = u[metric];
    const { joinedAt, ...safe } = u;
    return { ...safe, rank, isMe: u.id === userId };
  });
  return { metric, totalUsers: users.length, rows: rows.slice(0, 100), me: rows.find(r => r.id === userId) ?? null };
}
module.exports = { rewards, penggunaPublik, dataMilik, saldoPoin, daftarNotifikasi, keadaanPengguna, catatPoin, papanPeringkat, id: randomUUID };
