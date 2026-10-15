'use strict';
function positive(value, maximum = 10000) {
  if (typeof value !== 'number' || !Number.isFinite(value) || value <= 0 || value > maximum) throw new Error('Jumlah tidak valid');
  return value;
}
function pointsFor(kg, rate) {
  positive(kg); positive(rate, 1000000);
  const points = Math.floor(kg * rate);
  if (!Number.isSafeInteger(points) || points < 1) throw new Error('Poin tidak valid');
  return points;
}
function redemption(balance, cost, stock) {
  if (![balance, cost, stock].every(Number.isSafeInteger) || cost <= 0 || stock <= 0 || balance < cost) throw new Error('Saldo atau stok tidak mencukupi');
  return {balance: balance - cost, stock: stock - 1};
}
module.exports = {positive, pointsFor, redemption};
