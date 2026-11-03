// ==== [ DAFFA - BACKEND ] ==== //
const fs = require('node:fs/promises');
const path = require('node:path');
const { createHash } = require('node:crypto');
const personalKeys = ['scans', 'deposits', 'ledger', 'vouchers', 'guides', 'activities', 'places', 'notificationReads', 'messages', 'pointQrs', 'groupMessages', 'groupInvites', 'groupRequests'];
const extraKeys = ['pointQrs', 'groups', 'groupMessages', 'groupInvites', 'groupRequests'];
const dataKosong = () => ({ schemaVersion: 1, revision: 0, users: [], sessions: [], scans: [], deposits: [], ledger: [], vouchers: [], guides: [], activities: [], places: [], notifications: [], notificationReads: [], messages: [], education: [], ...Object.fromEntries(extraKeys.map(k => [k, []])) });
const namaPenggunaUntuk = u => u.username || `${(u.email || u.name || 'akun').split('@')[0].toLowerCase().replace(/[^a-z0-9_-]/g, '').slice(0, 30) || 'akun'}-${createHash('sha256').update(u.id).digest('hex').slice(0, 8)}`;
async function bacaJson(file, fallback) { try { return JSON.parse(await fs.readFile(file, 'utf8')); } catch (e) { if (e.code === 'ENOENT') return fallback; throw e; } }
async function simpanAtomik(file, data) {
  await fs.mkdir(path.dirname(file), { recursive: true });
  const handle = await fs.open(`${file}.tmp`, 'w', 0o600);
  try { await handle.writeFile(JSON.stringify(data, null, 2)); await handle.sync(); } finally { await handle.close(); }
  await fs.rename(`${file}.tmp`, file);
}
class BasisDataJson {
  constructor(file) {
    this.file = file;
    this.root = path.basename(path.dirname(file)) === 'database' ? path.dirname(path.dirname(file)) : path.dirname(file);
    this.databaseDir = path.dirname(file);
    this.activityFile = path.join(this.root, 'storage/activity.json');
    this.sessionDir = path.join(this.root, 'session');
    this.educationDir = path.join(this.root, 'content/edukasi');
    this.notificationsFile = path.join(this.root, 'content/notifikasi.json');
    this.journal = path.join(this.root, 'storage/transaction.json');
    this.pending = Promise.resolve();
  }
  async buka() {
    await fs.mkdir(path.dirname(this.file), { recursive: true });
    this.lock = await fs.open(`${this.file}.lock`, 'wx', 0o600).catch(() => { throw new Error('Database sedang digunakan proses lain. Jalankan satu instance saja.'); });
    try {
      for (const folder of [this.sessionDir, this.educationDir, path.dirname(this.activityFile)]) await fs.mkdir(folder, { recursive: true });
      const pending = await bacaJson(this.journal, null);
      if (pending) await this.terapkan(pending);
      let accounts = await bacaJson(this.file, null);
      // Upgrade an earlier unified database without discarding existing users or balances.
      const legacy = accounts && !Array.isArray(accounts) ? accounts : accounts === null ? await bacaJson(path.join(this.databaseDir, 'shion.json'), null) : null;
      if (legacy) {
        const keys = Object.keys(dataKosong()).filter(k => !['schemaVersion', 'revision', 'education', ...extraKeys].includes(k));
        if (legacy.schemaVersion !== 1 || keys.some(k => !Array.isArray(legacy[k]))) throw new Error('Skema database lama tidak valid.');
        this.data = { ...dataKosong(), ...legacy };
        await simpanAtomik(path.join(this.root, 'storage/legacy-backup.json'), legacy);
        await this.simpan(this.data);
        const legacyPath = path.join(this.databaseDir, 'shion.json');
        if (legacyPath !== this.file) await fs.unlink(legacyPath).catch(e => { if (e.code !== 'ENOENT') throw e; });
      } else {
        if (accounts !== null && !Array.isArray(accounts)) throw new Error('account.json harus berupa array akun.');
        const activity = await bacaJson(this.activityFile, {});
        this.data = { ...dataKosong(), ...activity, users: accounts || [], sessions: [], notifications: await bacaJson(this.notificationsFile, await bacaJson(path.join(this.databaseDir, 'notifikasi.json'), [])), education: [] };
        const community = await bacaJson(path.join(this.root, 'content/community.json'), {});
        this.data.groups = community.groups || this.data.groups;
        for (const user of this.data.users) {
          const dir = path.join(this.sessionDir, namaPenggunaUntuk(user));
          for (const key of personalKeys) {
            const rows = await bacaJson(path.join(dir, `${key}.json`), null);
            if (rows !== null) this.data[key] = [...this.data[key].filter(r => r.userId !== user.id), ...rows];
          }
        }
        this.data.groupMessages = [...new Map(this.data.groupMessages.map(message => [message.id, message])).values()];
        for (const folder of await fs.readdir(this.sessionDir, { withFileTypes: true })) {
          if (!folder.isDirectory() || !/^[a-z0-9_-]+$/.test(folder.name)) continue;
          for (const file of await fs.readdir(path.join(this.sessionDir, folder.name))) if (/^[a-f0-9]{64}\.json$/.test(file)) this.data.sessions.push(await bacaJson(path.join(this.sessionDir, folder.name, file), null));
        }
        for (const file of await fs.readdir(this.educationDir)) if (/^[a-zA-Z0-9_-]+\.json$/.test(file)) this.data.education.push(await bacaJson(path.join(this.educationDir, file), null));
        if (!this.data.education.length) for (const file of await fs.readdir(path.join(this.databaseDir, 'edukasi')).catch(e => { if (e.code === 'ENOENT') return []; throw e; })) if (/^[a-zA-Z0-9_-]+\.json$/.test(file)) this.data.education.push(await bacaJson(path.join(this.databaseDir, 'edukasi', file), null));
        const arrays = Object.keys(dataKosong()).filter(k => !['schemaVersion', 'revision'].includes(k));
        if (arrays.some(k => !Array.isArray(this.data[k]))) throw new Error('Berkas data tidak valid.');
        this.data.sessions = this.data.sessions.filter(s => s && Date.parse(s.expiresAt) > Date.now() && this.data.users.some(u => u.id === s.userId));
        await this.simpan(this.data);
      }
    } catch (e) { await this.tutup(); throw e; }
    return this;
  }
  baca(fn) { return structuredClone(fn(this.data)); }
  transaksi(fn) {
    const result = this.pending.then(async () => {
      if (this.faulted) throw new Error('Penyimpanan terhenti. Restart server untuk pemulihan transaksi.');
      const draft = structuredClone(this.data); draft.revision++;
      const value = await fn(draft);
      await this.simpan(draft); this.data = draft; return structuredClone(value);
    });
    this.pending = result.catch(() => {}); return result;
  }
  async terapkan(ops) {
    for (const op of ops) {
      const target = path.resolve(this.root, op.file);
      if (!target.startsWith(`${path.resolve(this.root)}${path.sep}`)) throw new Error('Jalur transaksi tidak valid.');
      if (op.delete) await fs.unlink(target).catch(e => { if (e.code !== 'ENOENT') throw e; });
      else await simpanAtomik(target, op.data);
    }
    await fs.unlink(this.journal);
  }
  async simpan(data) {
    data.users.forEach(u => { u.username = namaPenggunaUntuk(u); if (!/^[a-z0-9_-]{1,80}$/.test(u.username)) throw new Error('Username tidak valid.'); });
    const { users, sessions, notifications, education, ...activity } = data;
    for (const key of personalKeys) delete activity[key];
    delete activity.devices; delete activity.pushJobs;
    const community = {};
    community.groups = data.groups; delete activity.groups;
    const entries = [[this.file, users], [this.activityFile, activity], [this.notificationsFile, notifications.map(n => {
      const { title, body, image, ...rest } = n;
      return { ...rest, judul: n.judul ?? title, desk: n.desk ?? body, ...(n.gambar || image ? { gambar: n.gambar || image } : {}) };
    })]];
    entries.push([path.join(this.root, 'content/community.json'), community]);
    const desired = new Set();
    for (const user of users) {
      const dir = path.join(this.sessionDir, user.username); await fs.mkdir(dir, { recursive: true });
      for (const key of personalKeys) entries.push([path.join(dir, `${key}.json`), data[key].filter(r => r.userId === user.id || (key === 'groupMessages' && r.type === 'system' && data.groups.some(g => g.id === r.groupId && g.members.some(m => m.userId === user.id))))]);
      for (const s of sessions.filter(s => s.userId === user.id)) {
        if (!/^[a-f0-9]{64}$/.test(s.tokenHash)) throw new Error('Hash sesi tidak valid.');
        const file = path.join(dir, `${s.tokenHash}.json`); entries.push([file, s]); desired.add(file);
      }
    }
    for (const article of education) {
      if (!/^[a-zA-Z0-9_-]+$/.test(article.id)) throw new Error('ID edukasi tidak valid.');
      const file = path.join(this.educationDir, `${article.id}.json`); entries.push([file, article]); desired.add(file);
    }
    const ops = entries.map(([file, value]) => ({ file: path.relative(this.root, file), data: value }));
    // Old shared files are removed only after their migrated copies are journaled.
    for (const name of await fs.readdir(path.join(this.databaseDir, 'edukasi')).catch(e => { if (e.code === 'ENOENT') return []; throw e; })) if (/^[a-zA-Z0-9_-]+\.json$/.test(name)) ops.push({ file: path.relative(this.root, path.join(this.databaseDir, 'edukasi', name)), delete: true });
    ops.push({ file: path.relative(this.root, path.join(this.databaseDir, 'notifikasi.json')), delete: true });
    for (const folder of await fs.readdir(this.sessionDir, { withFileTypes: true })) if (folder.isDirectory() && /^[a-z0-9_-]+$/.test(folder.name)) {
      for (const name of await fs.readdir(path.join(this.sessionDir, folder.name))) {
        const file = path.join(this.sessionDir, folder.name, name);
        if (/^[a-f0-9]{64}\.json$/.test(name) && !desired.has(file)) ops.push({ file: path.relative(this.root, file), delete: true });
      }
    }
    for (const name of await fs.readdir(this.educationDir)) {
      const file = path.join(this.educationDir, name);
      if (/^[a-zA-Z0-9_-]+\.json$/.test(name) && !desired.has(file)) ops.push({ file: path.relative(this.root, file), delete: true });
    }
    try { await simpanAtomik(this.journal, ops); await this.terapkan(ops); await fs.rmdir(path.join(this.databaseDir, 'edukasi')).catch(() => {}); }
    catch (e) { this.faulted = true; throw e; }
  }
  async tutup() { await this.pending; if (this.lock) { await this.lock.close(); this.lock = null; await fs.unlink(`${this.file}.lock`).catch(() => {}); } }
}
module.exports = { BasisDataJson, dataKosong, namaPenggunaUntuk };
