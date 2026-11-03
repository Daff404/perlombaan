// ==== [ DAFFA - BACKEND ] ==== //
const { GalatApi } = require('./security');
function urlGambar(value) {
  if (value === undefined || value === null || value === '') return null;
  if (typeof value !== 'string' || value.length > 2048) throw new GalatApi(400, 'URL gambar tidak valid.');
  let url; try { url = new URL(value); } catch { throw new GalatApi(400, 'Gunakan URL gambar HTTPS.'); }
  if (url.protocol !== 'https:' || url.username || url.password) throw new GalatApi(400, 'Gunakan URL gambar HTTPS.');
  return url.href;
}
module.exports = { urlGambar };
