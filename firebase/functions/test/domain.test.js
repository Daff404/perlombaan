const {test} = require('node:test');
const assert = require('node:assert/strict');
const {positive, pointsFor, redemption} = require('../domain');
test('poin memakai berat aktual dan dibulatkan ke bawah', () => assert.equal(pointsFor(2.55, 10), 25));
test('tolak NaN, berat negatif, dan berat melebihi batas', () => { for (const value of [NaN, Infinity, -1, 0, 10001, '2']) assert.throws(() => positive(value)); });
test('penukaran mengurangi saldo dan stok', () => assert.deepEqual(redemption(100, 70, 2), {balance:30, stock:1}));
test('tolak saldo kurang, stok kosong, biaya negatif dan pecahan', () => { for (const args of [[10,20,1],[100,20,0],[100,-2,1],[100,1.2,2]]) assert.throws(() => redemption(...args)); });
