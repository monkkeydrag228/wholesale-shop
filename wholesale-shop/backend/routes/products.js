// routes/products.js — CRUD for products
'use strict';

const express = require('express');
const router  = express.Router();
const db      = require('../db');

// ── GET /api/products  — list all products (optionally filter by category) ──
router.get('/', async (req, res) => {
  try {
    const { category } = req.query;
    let sql    = 'SELECT * FROM products ORDER BY created_at DESC';
    let params = [];

    if (category) {
      sql    = 'SELECT * FROM products WHERE category = $1 ORDER BY created_at DESC';
      params = [category];
    }

    const { rows } = await db.query(sql, params);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Could not fetch products' });
  }
});

// ── GET /api/products/:id  — single product ──────────────────
router.get('/:id', async (req, res) => {
  try {
    const { rows } = await db.query(
      'SELECT * FROM products WHERE id = $1',
      [req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Product not found' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Could not fetch product' });
  }
});

// ── POST /api/products  — create product ─────────────────────
router.post('/', async (req, res) => {
  const { name, category, description, price, stock, image_url } = req.body;

  if (!name || !category || price == null) {
    return res.status(400).json({ error: 'name, category and price are required' });
  }

  try {
    const { rows } = await db.query(
      `INSERT INTO products (name, category, description, price, stock, image_url)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [name, category, description || '', price, stock || 0, image_url || '']
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Could not create product' });
  }
});

// ── PUT /api/products/:id  — update product ───────────────────
router.put('/:id', async (req, res) => {
  const { name, category, description, price, stock, image_url } = req.body;
  try {
    const { rows } = await db.query(
      `UPDATE products
          SET name = COALESCE($1, name),
              category = COALESCE($2, category),
              description = COALESCE($3, description),
              price = COALESCE($4, price),
              stock = COALESCE($5, stock),
              image_url = COALESCE($6, image_url),
              updated_at = NOW()
        WHERE id = $7
        RETURNING *`,
      [name, category, description, price, stock, image_url, req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Product not found' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Could not update product' });
  }
});

// ── DELETE /api/products/:id  — delete product ────────────────
router.delete('/:id', async (req, res) => {
  try {
    const { rowCount } = await db.query(
      'DELETE FROM products WHERE id = $1',
      [req.params.id]
    );
    if (!rowCount) return res.status(404).json({ error: 'Product not found' });
    res.json({ message: 'Product deleted' });
  } catch (err) {
    res.status(500).json({ error: 'Could not delete product' });
  }
});

module.exports = router;
