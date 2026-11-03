// ==== [ DAFFA - BACKEND ] ==== //
const { randomBytes, createHash, scrypt: scryptCallback, timingSafeEqual } = require('node:crypto');
const { promisify } = require('node:util');
const scrypt = promisify(scryptCallback);
class GalatApi extends Error {
  constructor(status, message, code = 'REQUEST_FAILED') { super(message); this.status = status; this.code = code; }
}
function teks(value, label, min = 1, max = 200) {
  if (typeof value !== 'string' || value.trim().length < min || value.trim().length > max) throw new GalatApi(400, `${label} tidak valid.`, 'VALIDATION');
  return value.trim();
}
function surel(value) {
  const v = teks(value, 'Email', 5, 254).toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v)) throw new GalatApi(400, 'Email tidak valid.', 'VALIDATION');
  return v;
}
function telepon(value) {
  const v = teks(value, 'Nomor telepon', 9, 25);
  if (!/^\+?[\d\s()-]+$/.test(v) || v.replace(/\D/g, '').length < 9) throw new GalatApi(400, 'Nomor telepon tidak valid.', 'VALIDATION');
  return v;
}
async function hashKataSandi(value) {
  if (typeof value !== 'string' || value.length < 8 || value.length > 128) throw new GalatApi(400, 'Kata sandi harus 8–128 karakter.', 'VALIDATION');
  const salt = randomBytes(16).toString('hex');
  const hash = await scrypt(value, salt, 64);
  return `scrypt:${salt}:${hash.toString('hex')}`;
}
async function cocokkanKataSandi(value, stored) {
  if (typeof value !== 'string' || value.length > 128) return false;
  const [algorithm, salt, hex] = String(stored).split(':');
  if (algorithm !== 'scrypt' || !salt || !hex) return false;
  const hash = await scrypt(value, salt, 64);
  const expected = Buffer.from(hex, 'hex');
  return hash.length === expected.length && timingSafeEqual(hash, expected);
}
const hashToken = token => createHash('sha256').update(token).digest('hex');
function buatSesi(userId, ttlDays) {
  const token = randomBytes(32).toString('base64url');
  return { token, session: { userId, tokenHash: hashToken(token), createdAt: new Date().toISOString(), expiresAt: new Date(Date.now() + ttlDays * 86400000).toISOString() } };
}
function batasiPermintaan({ windowMs, max, key = req => req.ip }) {
  const buckets = new Map();
  let lastCleanup = 0;
  return (req, res, next) => {
    const now = Date.now();
    if (now - lastCleanup > windowMs) {
      for (const [k, b] of buckets) if (b.until <= now) buckets.delete(k);
      lastCleanup = now;
    }
    const k = key(req);
    let bucket = buckets.get(k);
    if (!bucket || bucket.until <= now) { bucket = { count: 0, until: now + windowMs }; buckets.set(k, bucket); }
    if (++bucket.count > max) {
      res.set('Retry-After', String(Math.ceil((bucket.until - now) / 1000)));
      return next(new GalatApi(429, 'Terlalu banyak permintaan. Coba lagi sebentar.', 'RATE_LIMIT'));
    }
    next();
  };
}
module.exports = { GalatApi, teks, surel, telepon, hashKataSandi, cocokkanKataSandi, hashToken, buatSesi, batasiPermintaan };
