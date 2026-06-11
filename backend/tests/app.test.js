'use strict';
const { test } = require('node:test');
const assert   = require('node:assert');

test('express module loads', () => {
  const express = require('express');
  assert.strictEqual(typeof express, 'function');
});

test('bcryptjs hashes and verifies passwords', async () => {
  const bcrypt = require('bcryptjs');
  const hash = await bcrypt.hash('testpass', 10);
  const valid = await bcrypt.compare('testpass', hash);
  assert.strictEqual(valid, true);
});

test('jsonwebtoken signs and verifies tokens', () => {
  const jwt = require('jsonwebtoken');
  const token = jwt.sign({ id: 1, role: 'admin' }, 'testsecret');
  const decoded = jwt.verify(token, 'testsecret');
  assert.strictEqual(decoded.role, 'admin');
});
