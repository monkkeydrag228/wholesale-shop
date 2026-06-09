// routes/orders.js — create and list orders
'use strict';

const express = require('express');
const router  = express.Router();
const db      = require('../db');

// ── GET /api/orders  — list all orders (admin use) ───────────
router.get('/', async (req, res) => {
  try {
    const { rows } = await db.query(`
      SELECT o.*,
             COALESCE(o.customer_name, u.name, 'Guest') AS customer_name,
             COALESCE(o.customer_phone, '')              AS customer_phone,
             u.email AS customer_email
        FROM orders o
   LEFT JOIN users u ON u.id = o.user_id
    ORDER BY o.created_at DESC
    `);
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: 'Could not fetch orders' });
  }
});

// ── POST /api/orders  — place new order ──────────────────────
router.post('/', async (req, res) => {
  const { user_id, items, shipping_addr, customer_name, customer_phone } = req.body;
  // items: [{ product_id, quantity }, ...]

  if (!items || !items.length) {
    return res.status(400).json({ error: 'Order must contain at least one item' });
  }

  const client = await db.connect();   // use transaction
  try {
    await client.query('BEGIN');

    // 1. Calculate total & verify stock
    let total = 0;
    const lineItems = [];
    for (const item of items) {
      const { rows } = await client.query(
        'SELECT id, price, stock FROM products WHERE id = $1 FOR UPDATE',
        [item.product_id]
      );
      if (!rows.length) throw new Error(`Product ${item.product_id} not found`);
      const product = rows[0];
      if (product.stock < item.quantity) {
        throw new Error(`Insufficient stock for product ${item.product_id}`);
      }
      total += product.price * item.quantity;
      lineItems.push({ ...item, unit_price: product.price });
    }

    // 2. Create order
    const { rows: [order] } = await client.query(
      `INSERT INTO orders (user_id, total_amount, shipping_addr, customer_name, customer_phone)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [user_id || null, total.toFixed(2), shipping_addr || '', customer_name || '', customer_phone || '']
    );

    // 3. Insert order items & decrement stock
    for (const li of lineItems) {
      await client.query(
        `INSERT INTO order_items (order_id, product_id, quantity, unit_price)
         VALUES ($1, $2, $3, $4)`,
        [order.id, li.product_id, li.quantity, li.unit_price]
      );
      await client.query(
        'UPDATE products SET stock = stock - $1 WHERE id = $2',
        [li.quantity, li.product_id]
      );
    }

    await client.query('COMMIT');
    res.status(201).json({ order, items: lineItems });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    res.status(400).json({ error: err.message });
  } finally {
    client.release();
  }
});

// ── PATCH /api/orders/:id/status  — update order status ──────
router.patch('/:id/status', async (req, res) => {
  const { status } = req.body;
  const allowed = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];
  if (!allowed.includes(status)) {
    return res.status(400).json({ error: 'Invalid status' });
  }
  try {
    const { rows } = await db.query(
      `UPDATE orders SET status = $1, updated_at = NOW() WHERE id = $2 RETURNING *`,
      [status, req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Order not found' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Could not update status' });
  }
});

module.exports = router;
