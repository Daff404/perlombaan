// ==== [ DAFFA - BACKEND ] ==== //
const fs = require('node:fs/promises');
const path = require('node:path');
async function pindahkanFoto(db, oldUploads) {
  const scans = db.baca(d => d.scans.filter(s => s.photoFile && !s.photoSession).map(s => ({ ...s, username: d.users.find(u => u.id === s.userId)?.username })));
  for (const scan of scans) {
    if (!scan.username || !/^[a-z0-9_-]+$/.test(scan.username) || !/^[a-zA-Z0-9_-]+\.jpg$/.test(scan.photoFile)) continue;
    const source = path.join(oldUploads, scan.photoFile), dir = path.join(db.sessionDir, scan.username, 'scan-media');
    await fs.mkdir(dir, { recursive: true });
    try { await fs.copyFile(source, path.join(dir, scan.photoFile)); }
    catch (e) { if (e.code === 'ENOENT') { console.warn('[migration] Foto lama tidak tersedia:', scan.id); continue; } throw e; }
    await db.transaksi(d => { d.scans.find(s => s.id === scan.id).photoSession = scan.username; });
    await fs.unlink(source).catch(e => { if (e.code !== 'ENOENT') console.warn('[migration] Salinan lama belum dibersihkan:', scan.id); });
  }
}
module.exports = { pindahkanFoto };
