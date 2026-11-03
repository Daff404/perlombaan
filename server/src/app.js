// ==== [ DAFFA - BACKEND ] ==== //
const express = require('express');
const fs = require('node:fs/promises');
const path = require('node:path');
const { GalatApi, hashToken, batasiPermintaan } = require('./security');
const { LayananGemini } = require('./ai');
async function buatAplikasi({ db, uploadsDir, ai, sessionDays = 30, corsOrigins = [], trustProxyHops = 0, limits = true } = {}) {
  await fs.mkdir(uploadsDir, { recursive: true });
  const app = express();
  app.disable('x-powered-by'); app.disable('etag');
  if (trustProxyHops) app.set('trust proxy', trustProxyHops);
  app.use((req, res, next) => {
    res.set({ 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff', 'X-Frame-Options': 'DENY', 'Referrer-Policy': 'no-referrer' });
    const origin = req.get('Origin');
    if (origin && corsOrigins.includes(origin)) {
      res.set({ 'Access-Control-Allow-Origin': origin, 'Vary': 'Origin', 'Access-Control-Allow-Headers': 'Authorization, Content-Type', 'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS' });
    } else if (origin) return next(new GalatApi(403, 'Origin tidak diizinkan.'));
    if (req.method === 'OPTIONS') return res.sendStatus(204);
    next();
  });
  if (limits) app.use(batasiPermintaan({ windowMs: 60000, max: 240 }));
  app.use(express.json({ limit: '12mb' }));
  app.use((req, res, next) => {
    if (req.method === 'POST' && /^\/api\/groups\/[a-f0-9-]+\/media$/.test(req.path) && req.is('application/octet-stream')) return next();
    if (['POST', 'PUT'].includes(req.method) && (!req.body || typeof req.body !== 'object' || Array.isArray(req.body))) return next(new GalatApi(400, 'Kirim objek JSON pada body permintaan.'));
    next();
  });
  const noLimit = (_, __, next) => next();
  const c = {
    db, uploadsDir, ai: ai || new LayananGemini(process.env.GEMINI_API_KEY, process.env.GEMINI_MODEL || 'gemini-2.5-flash'),
    sessionDays, ok: (res, data, code = 200) => res.status(code).json({ status: true, data }),
    loginLimit: limits ? batasiPermintaan({ windowMs: 900000, max: 30 }) : noLimit,
    aiLimit: limits ? batasiPermintaan({ windowMs: 60000, max: 12, key: req => req.user.id }) : noLimit,
    auth: (req, res, next) => {
      const token = req.get('Authorization')?.match(/^Bearer ([A-Za-z0-9_-]{40,100})$/)?.[1];
      const session = token && db.baca(d => d.sessions.find(s => s.tokenHash === hashToken(token) && Date.parse(s.expiresAt) > Date.now()));
      const user = session && db.baca(d => d.users.find(u => u.id === session.userId && !u.disabled));
      if (!user) return next(new GalatApi(401, 'Sesi berakhir. Silakan masuk kembali.', 'SESSION_EXPIRED'));
      req.user = user; req.session = session; next();
    },
    admin: (req, res, next) => req.user.role === 'admin' ? next() : next(new GalatApi(403, 'Akses khusus admin.', 'FORBIDDEN')),
  };
  const router = express.Router();
  // Same modular Express route pattern as the supplied ZIP; no bot components.
  const files = (await fs.readdir(path.join(__dirname, 'api'))).filter(f => f.endsWith('.js')).sort();
  for (const file of files) require(path.join(__dirname, 'api', file))(router, c);
  app.get('/', (_, res) => c.ok(res, { name: 'SHION REST API', version: '1.0.0' }));
  app.get('/api/health', (_, res) => c.ok(res, { service: 'SHION', database: 'ready', aiConfigured: Boolean(ai || process.env.GEMINI_API_KEY), notifications: 'server-polling' }));
  app.use('/api', router);
  app.use((_, __, next) => next(new GalatApi(404, 'Endpoint tidak ditemukan.', 'NOT_FOUND')));
  app.use((error, req, res, next) => {
    if (res.headersSent) return next(error);
    const status = error.status || (error.type === 'entity.too.large' ? 413 : 500);
    if (error.type === 'entity.parse.failed') error.message = 'JSON permintaan tidak valid.';
    if (status >= 500) console.error('[API]', error.message);
    res.status(status).json({ status: false, error: { code: error.code || 'SERVER_ERROR', message: status < 500 || error instanceof GalatApi ? error.message : 'Server belum dapat memproses permintaan.' } });
  });
  return app;
}
module.exports = { buatAplikasi };
