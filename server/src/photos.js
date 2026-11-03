// ==== [ DAFFA - BACKEND ] ==== //
const sharp = require('sharp');
const { createHash } = require('node:crypto');
const { GalatApi } = require('./security');
async function siapkanFoto(base64) {
  if (typeof base64 !== 'string' || base64.length === 0 || base64.length > 11200000 || !/^[A-Za-z0-9+/]+={0,2}$/.test(base64)) throw new GalatApi(400, 'Foto tidak valid atau lebih dari 8 MB.');
  const input = Buffer.from(base64, 'base64');
  if (input.length > 8 * 1024 * 1024) throw new GalatApi(400, 'Foto maksimal 8 MB.');
  try {
    const image = sharp(input, { limitInputPixels: 20_000_000, animated: false });
    const metadata = await image.metadata();
    if (!['jpeg', 'png', 'webp'].includes(metadata.format)) throw new Error('format');
    const photo = await image.rotate().resize(1280, 1280, { fit: 'inside', withoutEnlargement: true }).jpeg({ quality: 80 }).toBuffer();
    const pixels = await sharp(photo).resize(9, 8, { fit: 'fill' }).greyscale().raw().toBuffer();
    let bits = 0n;
    for (let y = 0; y < 8; y++) for (let x = 0; x < 8; x++) bits = (bits << 1n) | (pixels[y * 9 + x] > pixels[y * 9 + x + 1] ? 1n : 0n);
    return { photo, imageHash: createHash('sha256').update(input).digest('hex'), perceptualHash: bits.toString(16).padStart(16, '0') };
  } catch (_) { throw new GalatApi(400, 'Gunakan foto JPG, PNG, atau WebP yang valid.'); }
}
function hashSerupa(a, b) {
  if (!/^[a-f0-9]{16}$/i.test(a || '') || !/^[a-f0-9]{16}$/i.test(b || '')) return false;
  let bits = BigInt(`0x${a}`) ^ BigInt(`0x${b}`), count = 0;
  while (bits > 0n) { bits &= bits - 1n; if (++count > 4) return false; }
  return true;
}
module.exports = { siapkanFoto, hashSerupa };
