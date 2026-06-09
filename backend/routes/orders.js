'use strict';
const express = require('express');
const router  = express.Router();
const db      = require('../db');

// GET all orders with items count
router.get('/', async (req, res) => {
  try {
    const { rows } = await db.query(`
      SELECT o.*,
        COUNT(oi.id) AS items_count
      FROM orders o
      LEFT JOIN order_items oi ON oi.order_id = o.id
      GROUP BY o.id
      ORDER BY o.created_at DESC
    `);
    res.json(rows);
  } catch (err) { console.error(err); res.status(500).json({ error: 'Server error' }); }
});

// GET single order with items
router.get('/:id', async (req, res) => {
  try {
    const { rows } = await db.query('SELECT * FROM orders WHERE id=$1', [req.params.id]);
    if (!rows.length) return res.status(404).json({ error: 'Not found' });
    const { rows: items } = await db.query(
      `SELECT oi.*, p.name AS product_name FROM order_items oi
       LEFT JOIN products p ON p.id = oi.product_id WHERE oi.order_id=$1`, [req.params.id]);
    res.json({ ...rows[0], items });
  } catch (err) { console.error(err); res.status(500).json({ error: 'Server error' }); }
});

// POST create order
router.post('/', async (req, res) => {
  const { customer_id, customer_name, customer_phone, items } = req.body;
  if (!items || !items.length) return res.status(400).json({ error: 'Items required' });
  try {
    const total = items.reduce((s, i) => s + i.quantity * i.unit_price, 0);
    const { rows } = await db.query(
      `INSERT INTO orders(customer_id,customer_name,customer_phone,total_amount)
       VALUES($1,$2,$3,$4) RETURNING *`,
      [customer_id||null, customer_name||null, customer_phone||null, total]
    );
    const orderId = rows[0].id;
    for (const item of items) {
      await db.query(
        'INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES($1,$2,$3,$4)',
        [orderId, item.product_id, item.quantity, item.unit_price]
      );
    }
    res.status(201).json(rows[0]);
  } catch (err) { console.error(err); res.status(500).json({ error: 'Server error' }); }
});

// PATCH update status
router.patch('/:id/status', async (req, res) => {
  const { status } = req.body;
  const valid = ['pending','processing','shipped','delivered','cancelled'];
  if (!valid.includes(status)) return res.status(400).json({ error: 'Invalid status' });
  try {
    const { rows } = await db.query(
      'UPDATE orders SET status=$1, updated_at=NOW() WHERE id=$2 RETURNING *',
      [status, req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Not found' });
    res.json(rows[0]);
  } catch (err) { console.error(err); res.status(500).json({ error: 'Server error' }); }
});

// DELETE order
router.delete('/:id', async (req, res) => {
  try {
    await db.query('DELETE FROM orders WHERE id=$1', [req.params.id]);
    res.json({ success: true });
  } catch (err) { console.error(err); res.status(500).json({ error: 'Server error' }); }
});

module.exports = router;
