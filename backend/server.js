'use strict';
const express = require('express');
const cors    = require('cors');
const path    = require('path');
require('dotenv').config();

const db        = require('./db');
const auth      = require('./routes/auth');
const products  = require('./routes/products');
const orders    = require('./routes/orders');
const reports   = require('./routes/reports');
const customers = require('./routes/customers');
const dashboard = require('./routes/dashboard');

const app  = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use('/admin', express.static(path.join(__dirname, '..', 'frontend', 'admin')));

app.get('/', (req, res) => {
  res.redirect('/admin/login.html');
});

app.get('/health', async (req, res) => {
  try {
    await db.query('SELECT 1');
    res.status(200).json({ status: 'ok' });
  } catch {
    res.status(503).json({ status: 'error' });
  }
});

app.use('/api/auth',      auth);
app.use('/api/products',  products);
app.use('/api/orders',    orders);
app.use('/api/reports',   reports);
app.use('/api/customers', customers);
app.use('/api/dashboard', dashboard);

app.use((req, res) => {
  if (req.path.startsWith('/api/')) return res.status(404).json({ error: 'Not found' });
  res.sendFile(path.join(__dirname, '..', 'frontend', 'admin', 'login.html'));
});

app.use((err, req, res, _next) => {
  console.error('[ERROR]', err.stack);
  res.status(500).json({ error: 'Internal Server Error' });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
