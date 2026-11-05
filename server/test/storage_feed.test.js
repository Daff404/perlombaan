// ==== [ DAFFA - BACKEND ] ==== //
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const os = require('node:os');
const { BasisDataJson, dataKosong } = require('../src/db');
const { hashKataSandi, cocokkanKataSandi, buatSesi } = require('../src/security');
test('v3 split storage upgrades to per-user files without losing notifications, education, photos or points', async t => {
 const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'shion-v3-migration-'));
 const username = 'old-user', session = buatSesi('old', 30).session;
 await fs.mkdir(path.join(dir, 'database/edukasi'), { recursive: true });
 await fs.mkdir(path.join(dir, 'storage')); await fs.mkdir(path.join(dir, 'uploads'));
 await fs.mkdir(path.join(dir, 'session', username), { recursive: true });
 await fs.writeFile(path.join(dir, 'database/account.json'), JSON.stringify([{ id: 'old', username, role: 'user', name: 'Old user' }]));
 await fs.writeFile(path.join(dir, 'database/notifikasi.json'), JSON.stringify([{ id: 'notice', judul: 'Lama', desk: 'Tersimpan', recipientId: 'old' }]));
 await fs.writeFile(path.join(dir, 'database/edukasi/article.json'), JSON.stringify({ id: 'article', judul: 'Edukasi lama' }));
 await fs.writeFile(path.join(dir, 'storage/activity.json'), JSON.stringify({ scans: [{ id: 'scan', userId: 'old', photoFile: 'old-photo.jpg' }], ledger: [{ id: 'credit', userId: 'old', delta: 123 }], messages: [{ userId: 'old', text: 'Percakapan lama' }] }));
 await fs.writeFile(path.join(dir, 'session', username, session.tokenHash + '.json'), JSON.stringify(session));
 await fs.writeFile(path.join(dir, 'uploads/old-photo.jpg'), Buffer.from('photo-fixture'));
 let db = await new BasisDataJson(path.join(dir, 'database/account.json')).buka();
 t.after(async () => { await db.tutup(); await fs.rm(dir, { recursive: true, force: true }); });
 await require('../src/migrate_photos').pindahkanFoto(db, path.join(dir, 'uploads'));
 assert.equal(db.baca(d => d.ledger[0].delta), 123);
 assert.equal(db.baca(d => d.notifications[0].id), 'notice');
 assert.equal(db.baca(d => d.education[0].id), 'article');
 assert.equal(db.baca(d => d.scans[0].photoSession), username);
 assert.deepEqual((await fs.readdir(path.join(dir, 'database'))).filter(f => !f.endsWith('.lock')), ['account.json']);
 assert.equal(await fs.readFile(path.join(dir, 'session', username, 'scan-media/old-photo.jpg'), 'utf8'), 'photo-fixture');
 await assert.rejects(fs.access(path.join(dir, 'uploads/old-photo.jpg')));
 await db.tutup(); db = await new BasisDataJson(path.join(dir, 'database/account.json')).buka();
 assert.equal(db.baca(d => d.ledger[0].delta), 123); assert.equal(db.baca(d => d.messages[0].text), 'Percakapan lama');
 assert.equal(db.baca(d => d.sessions[0].tokenHash), session.tokenHash);
});
test('legacy upgrade preserves users, ledger, chat and sessions in separate files', async () => {
 const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'shion-upgrade-'));
 let db;
 try {
  await fs.mkdir(path.join(dir, 'database'));
  const legacy = dataKosong(); legacy.users.push({id:'old-id', email:'old@example.com', name:'Old',role:'user'});
  legacy.sessions.push(buatSesi('old-id',30).session); legacy.ledger.push({userId:'old-id',delta:50});legacy.messages.push({userId:'old-id',text:'Riwayat'});
  await fs.writeFile(path.join(dir,'database/shion.json'),JSON.stringify(legacy));
  db=await new BasisDataJson(path.join(dir,'database/account.json')).buka();
  assert.equal(db.baca(d=>d.ledger[0].delta),50); assert.equal(db.baca(d=>d.sessions.length),1);
  await assert.rejects(fs.access(path.join(dir,'database/shion.json')));
  const users=JSON.parse(await fs.readFile(path.join(dir,'database/account.json')));assert.equal(users.length,1);assert.equal(users[0].sessions,undefined);
  await db.tutup(); db=await new BasisDataJson(path.join(dir,'database/account.json')).buka();
  assert.equal(db.baca(d=>d.messages[0].text),'Riwayat');assert.equal(db.baca(d=>d.sessions.length),1);
 } finally { if(db) await db.tutup();await fs.rm(dir,{recursive:true,force:true}); }
});
test('durable write journal recovers interrupted multi-file commits on restart', async () => {
 const dir=await fs.mkdtemp(path.join(os.tmpdir(),'shion-recovery-')); let db;
 try {
  const file=path.join(dir,'database/account.json'); db=await new BasisDataJson(file).buka();await db.tutup();
  const activity={...dataKosong(),revision:77};delete activity.users;delete activity.sessions;delete activity.notifications;delete activity.education;
  activity.ledger=[{id:'recovered',userId:'u',delta:20}];
  await fs.writeFile(path.join(dir,'storage/transaction.json'),JSON.stringify([{file:'storage/activity.json',data:activity},{file:'content/notifikasi.json',data:[{id:'n',judul:'Recovered',desk:'Message'}]}]));
  db=await new BasisDataJson(file).buka();assert.equal(db.baca(d=>d.revision),77);assert.equal(db.baca(d=>d.ledger[0].delta),20);assert.equal(db.baca(d=>d.notifications[0].judul),'Recovered');await assert.rejects(fs.access(db.journal));
 } finally { if(db) await db.tutup();await fs.rm(dir,{recursive:true,force:true}); }
});
test('admin langsung tersimpan dan dimuat dari database/account.json',async()=>{
 const dir=await fs.mkdtemp(path.join(os.tmpdir(),'shion-akun-awal-'));let db;
 try {
  const file=path.join(dir,'database/account.json');await fs.mkdir(path.dirname(file),{recursive:true});
  const kataSandi=await hashKataSandi('ShionBumi#2026');
  await fs.writeFile(file,JSON.stringify([{id:'admin-awal',username:'admin-shion',email:'admin@shion.app',name:'Administrator SHION',phone:'',role:'admin',passwordHash:kataSandi,createdAt:new Date().toISOString()}]));
  db=await new BasisDataJson(file).buka();
  assert.equal(db.baca(d=>d.users[0].role),'admin');
  assert.ok(await cocokkanKataSandi('ShionBumi#2026',db.baca(d=>d.users[0].passwordHash)));
  const hashBaru=await hashKataSandi('KataSandiBaru#2026');
  await db.transaksi(d=>{d.users[0].passwordHash=hashBaru;});
  assert.ok(await cocokkanKataSandi('KataSandiBaru#2026',db.baca(d=>d.users[0].passwordHash)));
 } finally {if(db) await db.tutup();await fs.rm(dir,{recursive:true,force:true});}
});
