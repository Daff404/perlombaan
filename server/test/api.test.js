// ==== [ DAFFA - BACKEND ] ==== //
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const os = require('node:os');
const path = require('node:path');
const sharp = require('sharp');
const { BasisDataJson } = require('../src/db');
const { buatAplikasi } = require('../src/app');
const { hashKataSandi } = require('../src/security');

const result = { isWaste: true, name: 'Botol plastik', category: 'Plastik', material: 'Plastik PET', recyclable: true, steps: ['Kosongkan', 'Bilas', 'Keringkan'], warning: '', confidence: .95 };

test('SHION authenticated API and durable transactions', async t => {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'shion-api-'));
  let db = await new BasisDataJson(path.join(dir, 'db.json')).buka();
  let aiFailure = false;
  const ai = { model: 'test-only', classify: async () => ({ ...result }), guide: async () => { if (aiFailure) throw new Error('AI unavailable'); return 'Panduan aman dan terperinci. '.repeat(10); }, chat: async () => 'Pisahkan plastik yang bersih dan kering.' };
  const app = await buatAplikasi({ db, uploadsDir: path.join(dir, 'uploads'), ai, limits: false });
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  const base = `http://127.0.0.1:${server.address().port}/api`;
  t.after(async () => { await new Promise(resolve => server.close(resolve)); await db.tutup(); await fs.rm(dir, { recursive: true, force: true }); });
  const call = async (url, { method = 'GET', body, token } = {}) => {
    const res = await fetch(base + url, { method, headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) }, ...(body === undefined ? {} : { body: JSON.stringify(body) }) });
    return { status: res.status, data: await res.json() };
  };
  const register = async (name, role = 'user') => {
    const response = await call('/auth/register', { method: 'POST', body: { name, email: `${name.toLowerCase()}@example.com`, phone: '081234567890', password: 'password-123', role } });
    assert.equal(response.status, 201);
    return response.data.data;
  };
  let alice, bob, adminToken, scanId, scan2Id;
  await t.test('registration is always user; plaintext passwords and tokens are not stored', async () => {
    alice = await register('Alice', 'admin'); bob = await register('Bob');
    assert.equal(alice.state.user.role, 'user');
    assert.equal(alice.state.user.passwordHash, undefined);
    const stored = JSON.parse(await fs.readFile(path.join(dir, 'db.json'), 'utf8'));
    assert.match(stored[0].passwordHash, /^scrypt:/);
    assert.equal(JSON.stringify(stored).includes(alice.token), false);
    assert.equal(JSON.stringify(stored).includes('password-123'), false);
  });
  await t.test('login/restore and ownership do not expose another account', async () => {
    assert.equal((await call('/state')).status, 401);
    const wrong = await call('/auth/login', { method: 'POST', body: { email: 'alice@example.com', password: 'wrong' } });
    assert.equal(wrong.status, 401);
    const login = await call('/auth/login', { method: 'POST', body: { email: 'alice@example.com', password: 'password-123' } });
    assert.equal(login.status, 200);
    assert.equal((await call('/state', { token: login.data.data.token })).data.data.user.name, 'Alice');
    assert.equal((await call('/admin/users', { token: alice.token })).status, 403);
    const profile = await call('/profile', { method: 'PUT', token: alice.token, body: { name: 'Alice', email: 'alice@example.com', phone: '081234567890', role: 'admin', points: 999999 } });
    assert.equal(profile.data.data.user.role, 'user'); assert.equal(profile.data.data.points, 0);
  });
  await t.test('server classifies, saves and credits scan once despite concurrent retries', async () => {
    const photoBase64 = (await sharp({ create: { width: 120, height: 100, channels: 3, background: '#9bde7f' } }).png().toBuffer()).toString('base64');
    const request = { method: 'POST', token: alice.token, body: { photoBase64, requestId: 'same-scan-request', result: { category: 'Logam' }, earnedPoints: 999 } };
    const saved = await Promise.all([call('/scans', request), call('/scans', request)]);
    assert.equal(saved[0].status, 201); assert.equal(saved[1].status, 201);
    scanId = saved[0].data.data.scan.id; assert.equal(scanId, saved[1].data.data.scan.id);
    assert.equal(saved[0].data.data.scan.category, 'Plastik');
    const state = (await call('/state', { token: alice.token })).data.data;
    assert.equal(state.scans.length, 1); assert.equal(state.points, 1);
    assert.equal(state.scans[0].photoFile, undefined);
    assert.equal((await fetch(`${base}/scans/${scanId}/photo`, { headers: { Authorization: `Bearer ${bob.token}` } })).status, 404);
    const duplicate = await call('/scans', { ...request, body: { photoBase64, requestId: 'another-scan-request' } });
    scan2Id = duplicate.data.data.scan.id;
    assert.equal(duplicate.data.data.save.points, 0);
  });
  await t.test('deposits require own unused scan; amounts/rates/credits cannot be forged', async () => {
    const body = { scanId, quantity: 2, unit: 'kg', kelurahanId: '32.72.01.1001', requestId: 'one-deposit-request', points: 100000 };
    assert.equal((await call('/deposits', { method: 'POST', token: bob.token, body })).status, 400);
    const deposits = await Promise.all([call('/deposits', { method: 'POST', token: alice.token, body }), call('/deposits', { method: 'POST', token: alice.token, body })]);
    assert.equal(deposits[0].status, 201); assert.equal(deposits[1].status, 201);
    assert.equal(deposits[0].data.data.deposits[0].status, 'Disimpan');
    assert.equal(deposits[0].data.data.deposits[0].points, 0);
    assert.equal(deposits[0].data.data.points, 1);
    assert.equal((await call('/deposits', { method: 'POST', token: alice.token, body: { ...body, requestId: 'new-deposit-request' } })).status, 409);
    assert.equal((await call('/deposits', { method: 'POST', token: alice.token, body: { ...body, scanId: scan2Id, requestId: 'invalid-units', unit: 'satuan', quantity: 1.2 } })).status, 400);
  });
  await t.test('reward double-spend and guide failure are atomic', async () => {
    await db.transaksi(d => d.ledger.push({ id: 'test-credit', userId: alice.state.user.id, kind: 'test', delta: 249, createdAt: new Date().toISOString() }));
    const requests = await Promise.all(['redemption-one', 'redemption-two'].map(requestId => call('/rewards/tumbler/redeem', { method: 'POST', token: alice.token, body: { requestId } })));
    assert.deepEqual(requests.map(r => r.status).sort(), [201, 409]);
    assert.equal((await call('/state', { token: alice.token })).data.data.points, 0);
    await db.transaksi(d => d.ledger.push({ id: 'guide-credit', userId: alice.state.user.id, kind: 'test', delta: 40, createdAt: new Date().toISOString() }));
    aiFailure = true;
    assert.equal((await call('/guides', { method: 'POST', token: alice.token, body: { requestId: 'guide-one' } })).status, 500);
    assert.equal((await call('/state', { token: alice.token })).data.data.points, 40);
    aiFailure = false;
    const guide = await call('/guides', { method: 'POST', token: alice.token, body: { requestId: 'guide-one' } });
    const retry = await call('/guides', { method: 'POST', token: alice.token, body: { requestId: 'guide-one' } });
    assert.equal(guide.data.data.state.points, 20); assert.equal(retry.data.data.state.points, 20);
  });
  await t.test('leaderboards calculate earned points and count deposits, with no private details', async () => {
    for (const metric of ['points', 'deposits']) {
      const result = (await call(`/leaderboard?metric=${metric}`, { token: bob.token })).data.data;
      assert.equal(result.rows[0].name, 'Alice'); assert.equal(result.rows[0].rank, 1);
      assert.equal(result.rows[0].email, undefined); assert.equal(result.rows[0].phone, undefined);
      assert.equal(result.me.name, 'Bob'); assert.equal(result.rows[0].points, 290);
      assert.equal(result.rows[0].deposits, 0); assert.equal(result.rows[0].totalKg, 0);
    }
  });
  await t.test('admin broadcasts to all users, rejects targeting and isolates read receipts', async () => {
    const admin = { id: 'admin-id', name: 'Admin', email: 'admin@example.com', phone: '081234567891', role: 'admin', passwordHash: await hashKataSandi('unique-admin-password'), createdAt: new Date().toISOString() };
    await db.transaksi(d => d.users.push(admin));
    adminToken = (await call('/auth/login', { method: 'POST', body: { email: admin.email, password: 'unique-admin-password' } })).data.data.token;
    const depositId = (await call('/state', { token: alice.token })).data.data.deposits[0].id;
    const qr = (await call(`/deposits/${depositId}/qr`, { method: 'POST', token: alice.token, body: {} })).data.data;
    const renewed = (await call(`/deposits/${depositId}/qr`, { method: 'POST', token: alice.token, body: {} })).data.data;
    assert.notEqual(qr.payload, renewed.payload);
    assert.equal((await call('/admin/deposits/resolve', { method: 'POST', token: adminToken, body: { payload: qr.payload } })).status, 409);
    qr.payload = renewed.payload;
    assert.equal((await call('/admin/deposits/resolve', { method: 'POST', token: bob.token, body: { payload: qr.payload } })).status, 403);
    assert.equal((await call('/admin/deposits/resolve', { method: 'POST', token: adminToken, body: { payload: qr.payload } })).data.data.depositId, depositId);
    const collected = await Promise.all([1, 2].map(() => call('/admin/deposits/collect', { method: 'POST', token: adminToken, body: { payload: qr.payload, amount: 1, requestId: 'collect-deposit-one' } })));
    assert.deepEqual(collected.map(r => r.status), [201, 201]);
    assert.equal((await call('/state', { token: alice.token })).data.data.deposits[0].status, 'Selesai');
    assert.equal((await call('/state', { token: alice.token })).data.data.points, 21);
    assert.equal((await call('/admin/deposits/collect', { method: 'POST', token: adminToken, body: { payload: qr.payload, amount: 3, requestId: 'collect-deposit-two' } })).status, 409);

    assert.equal((await call('/admin/notifications', { method: 'POST', token: alice.token, body: { title: 'Illegal', body: 'Forbidden message' } })).status, 403);
    const targeted = await call('/admin/notifications', { method: 'POST', token: adminToken, body: { requestId: 'not-supported-target', title: 'Judul', body: 'Pesan', recipientId: alice.state.user.id } });
    assert.equal(targeted.status, 400);
    const request = { method: 'POST', token: adminToken, body: { requestId: 'admin-broadcast-one', title: 'Kabar bersama', body: 'Ayo pilah sampah hari ini', gambar: 'https://example.com/cover.jpg' } };
    const sent = await call('/admin/notifications', request);
    assert.equal(sent.data.data.recipients, 2);
    const resent = await call('/admin/notifications', request);
    assert.equal(resent.data.data.notification.id, sent.data.data.notification.id);
    const notificationId = sent.data.data.notification.id;
    assert.equal((await call('/notifications', { token: bob.token })).data.data.notifications.length, 1);
    await call('/notifications/read', { method: 'POST', token: bob.token, body: { ids: [notificationId] } });
    assert.equal((await call('/notifications', { token: alice.token })).data.data.notifications.find(n => n.id === notificationId).read, false);
    await call('/notifications/read', { method: 'POST', token: alice.token, body: { ids: [notificationId] } });
    assert.equal((await call('/notifications', { token: alice.token })).data.data.notifications.find(n => n.id === notificationId).read, true);
    const onDisk = JSON.parse(await fs.readFile(path.join(dir, 'content/notifikasi.json')));
    assert.equal(onDisk[0].judul, 'Kabar bersama'); assert.equal(onDisk[0].desk, 'Ayo pilah sampah hari ini'); assert.equal(onDisk[0].title, undefined);
    assert.equal(onDisk[0].gambar, 'https://example.com/cover.jpg');
    const board = (await call('/leaderboard', { token: bob.token })).data.data;
    assert.equal(board.totalUsers, 2);
  });
  await t.test('activities, saved places and chat survive on server with account isolation', async () => {
    const activity = await call('/activities', { method: 'POST', token: alice.token, body: { activity: 'Sepeda motor', amount: 2, unit: 'km', factor: .1, co2Kg: 999 } });
    assert.equal(activity.status, 201); assert.equal(activity.data.data.activities[0].co2Kg, .2);
    const place = await call('/places', { method: 'POST', token: alice.token, body: { osmId: 'node:123', name: 'Bank Sampah', lat: -6.9, lon: 106.9, address: 'Sukabumi', hours: '08:00-16:00', materials: ['plastik'] } });
    assert.equal(place.status, 201); assert.equal(place.data.data.places[0].lat, -6.9);
    const chat = await call('/chat', { method: 'POST', token: alice.token, body: { message: 'Bagaimana memilah plastik?', requestId: 'chat-one' } });
    assert.equal(chat.data.data.state.messages.length, 2);
    assert.equal((await call('/state', { token: bob.token })).data.data.messages.length, 0);
  });
  await t.test('education publishing, file isolation, idempotency and deletion require admin', async () => {
    const body = { requestId: 'education-request-one', judul: 'Memilah plastik di rumah', desk: 'Langkah sederhana sebelum menyetor.', kategori: 'Daur Ulang', konten: '## Mulai dari rumah\n\nBilas kemasan dan keringkan sebelum disetor.', gambar: '' };
    assert.equal((await call('/admin/education', { method: 'POST', token: alice.token, body })).status, 403);
    const created = await call('/admin/education', { method: 'POST', token: adminToken, body });
    assert.equal(created.status, 201);
    const repeat = await call('/admin/education', { method: 'POST', token: adminToken, body });
    assert.equal(repeat.data.data.article.id, created.data.data.article.id);
    const rows = (await call('/education', { token: bob.token })).data.data.articles;
    assert.equal(rows.length, 1);
    const file = path.join(dir, 'content/edukasi', rows[0].id + '.json');
    assert.equal(JSON.parse(await fs.readFile(file)).konten, body.konten);
    const invalid = await call('/admin/education', { method: 'POST', token: adminToken, body: { ...body, gambar: 'file:///etc/passwd' } });
    assert.equal(invalid.status, 400);
    assert.equal((await call('/admin/education/' + rows[0].id, { method: 'DELETE', token: bob.token })).status, 403);
    assert.equal((await call('/admin/education/' + rows[0].id, { method: 'DELETE', token: adminToken })).status, 200);
    await assert.rejects(fs.access(file));
  });
  await t.test('accounts contain no sessions or activity; hashed sessions use stable username folders', async () => {
    const accounts = JSON.parse(await fs.readFile(path.join(dir, 'db.json')));
    assert.ok(Array.isArray(accounts)); assert.equal(accounts[0].sessions, undefined); assert.equal(accounts[0].ledger, undefined);
    const folder = path.join(dir, 'session', accounts[0].username);
    const files = await fs.readdir(folder); assert.ok(files.length > 0);
    const session = JSON.parse(await fs.readFile(path.join(folder, files.find(f => /^[a-f0-9]{64}\.json$/.test(f)))));
    assert.match(session.tokenHash, /^[a-f0-9]{64}$/); assert.equal(session.token, undefined);
    assert.equal(session.userId, accounts[0].id);
    const activity = JSON.parse(await fs.readFile(path.join(dir, 'storage/activity.json')));
    assert.equal(activity.users, undefined); assert.equal(activity.sessions, undefined); assert.equal(activity.notifications, undefined);
    assert.equal(activity.education, undefined); assert.equal(activity.deposits, undefined);
    assert.equal(JSON.parse(await fs.readFile(path.join(folder, 'deposits.json'))).length, 1);
  });
  await t.test('password change verifies old password and revokes other device sessions', async () => {
    const second = await call('/auth/login', { method: 'POST', body: { email: 'alice@example.com', password: 'password-123' } });
    const request = { method: 'PUT', token: alice.token, body: { currentPassword: 'wrong', newPassword: 'changed-password-123' } };
    assert.equal((await call('/auth/password', request)).status, 400);
    request.body.currentPassword = 'password-123';
    assert.equal((await call('/auth/password', request)).status, 200);
    assert.equal((await call('/state', { token: alice.token })).status, 200);
    assert.equal((await call('/state', { token: second.data.data.token })).status, 401);
    assert.equal((await call('/auth/login', { method: 'POST', body: { email: 'alice@example.com', password: 'password-123' } })).status, 401);
  });
  await t.test('expired and logged-out tokens are rejected', async () => {
    const logout = await call('/auth/logout', { method: 'POST', token: bob.token, body: {} });
    assert.equal(logout.status, 200); assert.equal((await call('/state', { token: bob.token })).status, 401);
    await db.transaksi(d => { const session = d.sessions.find(s => s.userId === 'admin-id'); session.expiresAt = new Date(0).toISOString(); });
    assert.equal((await call('/admin/users', { token: adminToken })).status, 401);
  });
  await t.test('database can reopen after restart; a second writer is blocked', async () => {
    await assert.rejects(new BasisDataJson(path.join(dir, 'db.json')).buka());
    await db.tutup();
    const reopened = await new BasisDataJson(path.join(dir, 'db.json')).buka();
    assert.equal(reopened.baca(d => d.users.length), 3);
    assert.equal(reopened.baca(d => d.deposits.length), 1);
    assert.equal(reopened.baca(d => d.messages.length), 2);
    await reopened.tutup();
    // Keep the original DB object for app cleanup; no more API writes follow.
  });
});

