// ==== [ DAFFA - BACKEND ] ==== //
const path = require('node:path');
const { BasisDataJson } = require('./src/db');
const { buatAplikasi } = require('./src/app');
async function jalankanServer() {
  const port = Number(process.env.PORT || 3000), days = Number(process.env.SESSION_DAYS || 30), trust = Number(process.env.TRUST_PROXY_HOPS || 0);
  if (!Number.isInteger(port) || port < 1 || port > 65535 || !Number.isFinite(days) || days <= 0 || days > 90 || !Number.isInteger(trust) || trust < 0 || trust > 5) throw new Error('Konfigurasi PORT, SESSION_DAYS atau TRUST_PROXY_HOPS tidak valid.');
  const berkasKonfigurasi = path.resolve(process.env.DATABASE_FILE || 'database/account.json');
  const berkasAkun = path.basename(berkasKonfigurasi) === 'shion.json' ? path.join(path.dirname(berkasKonfigurasi), 'account.json') : berkasKonfigurasi;
  const db = await new BasisDataJson(berkasAkun).buka();
  try {
    await require('./src/migrate_photos').pindahkanFoto(db, path.resolve(process.env.UPLOADS_DIR || 'uploads'));
    const app = await buatAplikasi({ db, uploadsDir: path.resolve(process.env.UPLOADS_DIR || 'uploads'), sessionDays: days, trustProxyHops: trust, corsOrigins: (process.env.CORS_ORIGINS || 'https://app.daffaputra.id').split(',').map(s => s.trim()).filter(Boolean) });
    const server = app.listen(port, process.env.HOST || '0.0.0.0', () => console.log(`[SHION] REST API listening on port ${port}`));
    let closing = false;
    const stop = () => { if (closing) return; closing = true; server.close(async () => { await db.tutup(); process.exit(0); }); };
    process.once('SIGINT', stop); process.once('SIGTERM', stop);
    server.on('error', async error => { console.error(error.message); await db.tutup(); process.exit(1); });
  } catch (error) { await db.tutup(); throw error; }
}
jalankanServer().catch(error => { console.error(error.message); process.exitCode = 1; });
