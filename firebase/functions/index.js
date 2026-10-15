'use strict';
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {initializeApp} = require('firebase-admin/app');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
const {positive, pointsFor, redemption} = require('./domain');
initializeApp();
const db = getFirestore();
const stamp = () => FieldValue.serverTimestamp();
const endpoint = handler => onCall(async request => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Silakan masuk.');
  try { return await handler(request.auth, request.data || {}); }
  catch (error) { if (error instanceof HttpsError) throw error; throw new HttpsError('failed-precondition', error.message); }
});
function id(value) { if (typeof value !== 'string' || !/^[a-zA-Z0-9_-]{1,128}$/.test(value)) throw new Error('ID tidak valid'); return value; }
function category(value) { if (!['plastik','kertas','organik'].includes(value)) throw new Error('Kategori tidak valid'); return value; }
exports.submitDeposit = endpoint(async (auth, data) => {
  const bankId = id(data.bankId), type = category(data.category), estimatedKg = positive(data.estimatedKg);
  const ref = db.collection('waste_deposits').doc();
  await db.runTransaction(async tx => {
    const bank = await tx.get(db.doc(`recycling_banks/${bankId}`));
    if (!bank.exists || !bank.get('active') || !bank.get('categories')?.includes(type)) throw new Error('Mitra tidak menerima kategori ini');
    tx.create(ref, {uid: auth.uid, bankId, category: type, estimatedKg, status: 'Menunggu', createdAt: stamp()});
  });
  return {id: ref.id};
});
exports.verifyDeposit = endpoint(async (auth, data) => {
  const ref = db.doc(`waste_deposits/${id(data.depositId)}`);
  const kg = positive(data.actualKg);
  return db.runTransaction(async tx => {
    const deposit = await tx.get(ref);
    if (!deposit.exists) throw new Error('Setoran tidak ditemukan');
    const d = deposit.data();
    const bank = await tx.get(db.doc(`recycling_banks/${d.bankId}`));
    if (auth.token.role !== 'admin' && !(auth.token.role === 'staff' && bank.get('staffUids')?.includes(auth.uid))) throw new HttpsError('permission-denied', 'Akses ditolak');
    if (d.status === 'Selesai') return {points: d.points};
    if (!['Menunggu','Diproses'].includes(d.status)) throw new Error('Status tidak dapat diverifikasi');
    const rate = await tx.get(db.doc(`point_rates/${d.category}`));
    const points = pointsFor(kg, rate.get('pointsPerKg'));
    const userRef = db.doc(`users/${d.uid}`), user = await tx.get(userRef);
    tx.set(userRef, {balance: (user.data()?.balance || 0) + points, earned: (user.data()?.earned || 0) + points}, {merge:true});
    tx.update(ref, {actualKg: kg, points, status: 'Selesai', verifiedBy: auth.uid, verifiedAt: stamp()});
    tx.create(db.doc(`point_transactions/deposit_${ref.id}`), {uid:d.uid, points, depositId:ref.id, type:'credit', createdAt:stamp()});
    return {points};
  });
});
exports.redeemReward = endpoint(async (auth, data) => {
  const rewardId = id(data.rewardId), requestId = id(data.requestId);
  const ref = db.doc(`redemptions/${auth.uid}_${requestId}`);
  return db.runTransaction(async tx => {
    const previous = await tx.get(ref);
    if (previous.exists) { if (previous.get('rewardId') !== rewardId) throw new Error('Kode permintaan sudah digunakan'); return {id:ref.id}; }
    const rewardRef = db.doc(`rewards/${rewardId}`), userRef = db.doc(`users/${auth.uid}`);
    const reward = await tx.get(rewardRef), user = await tx.get(userRef);
    const r = reward.data();
    if (!r || !r.active || !r.partnerIntegrated || !['transport','eco_product'].includes(r.category)) throw new Error('Penukaran mitra belum tersedia');
    const result = redemption(user.data()?.balance || 0, r.cost, r.stock);
    tx.set(userRef, {balance:result.balance, spent:(user.data()?.spent || 0) + r.cost}, {merge:true});
    tx.update(rewardRef, {stock:result.stock});
    tx.create(ref, {uid:auth.uid, rewardId, points:r.cost, status:'Menunggu', createdAt:stamp()});
    tx.create(db.doc(`point_transactions/redeem_${ref.id}`), {uid:auth.uid, points:-r.cost, redemptionId:ref.id, type:'debit', createdAt:stamp()});
    return {id:ref.id};
  });
});
exports.recordCarbon = endpoint(async (auth, data) => {
  const mode = id(data.mode), amount = positive(data.amount, 1000000);
  const date = new Date(data.date);
  if (!Number.isFinite(date.getTime()) || date > new Date()) throw new Error('Tanggal tidak valid');
  const factor = await db.doc(`emission_factors/${mode}`).get();
  if (!factor.exists || !factor.get('active') || !factor.get('source') || !['km','kWh'].includes(factor.get('unit'))) throw new Error('Faktor emisi bersumber belum dikonfigurasi');
  const value = factor.get('kgCO2ePerUnit');
  if (typeof value !== 'number' || !Number.isFinite(value) || value < 0) throw new Error('Faktor emisi tidak valid');
  const ref = await db.collection('carbon_records').add({uid:auth.uid, mode, amount, date, kgCO2e:amount * value, factor:value, source:factor.get('source'), unit:factor.get('unit'), boundary:factor.get('boundary') || '', createdAt:stamp()});
  return {id:ref.id};
});
