// ============================================================
//  server.js  —  Wholesale Clothing Shop API
//  BTEC Unit 6: Networking in the Cloud
// ============================================================
'use strict';

const express = require('express');
const cors    = require('cors');
const path    = require('path');
require('dotenv').config();

const db       = require('./db');          // PostgreSQL pool
const products = require('./routes/products');
const orders   = require('./routes/orders');

const app  = express();
const PORT = process.env.PORT || 3000;

// ── Middleware ────────────────────────────────────────────────
app.use(cors());                              // allow cross-origin requests
app.use(express.json());                      // parse JSON bodies
app.use(express.urlencoded({ extended: true }));

// Serve static frontend files
app.use(express.static(path.join(__dirname, '..', 'frontend', 'public')));
app.use('/admin', express.static(path.join(__dirname, '..', 'frontend', 'admin')));

// ── Health check (used by Load Balancer target group) ─────────
app.get('/health', async (req, res) => {
  try {
    await db.query('SELECT 1');              // verify DB connectivity
    res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
  } catch (err) {
    res.status(503).json({ status: 'error', message: 'Database unreachable' });
  }
});

// ── API Routes ────────────────────────────────────────────────
app.use('/api/products', products);
app.use('/api/orders',   orders);

// ── SPA fallback: serve index.html for any unknown GET route ──
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '..', 'frontend', 'public', 'index.html'));
});

// ── Global error handler ──────────────────────────────────────
app.use((err, req, res, _next) => {
  console.error('[ERROR]', err.stack);
  res.status(500).json({ error: 'Internal Server Error' });
});

// ── Start server ──────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`✅  Server running on port ${PORT}`);
  console.log(`   Shop:  http://localhost:${PORT}`);
  console.log(`   Admin: http://localhost:${PORT}/admin`);
  console.log(`   API:   http://localhost:${PORT}/api/products`);
});
