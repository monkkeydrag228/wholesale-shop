'use strict';
const express = require('express');
const router  = express.Router();
const db      = require('../db');

// GET all customers
router.get('/', async (req, res) => {
  try {
    const { rows } = await db.query(`
      SELECT c.*,
        COUNT(o.id)               AS order_count,
        COALESCE(SUM(o.total_amount),0) AS total_spent
      FROM customers c
      LEFT JOIN orders o ON o.customer_id = c.id
      GROUP BY c.id
      ORDER BY c.created_at DESC
    `);
    res.json(rows);
  } catch (err) { console.error(err); res.status(500).json({ error: 'Server error' }); }
});

// POST create customer
router.post('/', async (req, res) => {
  const { company_name, contact_name, phone, email, city, type, status, notes } = req.body;
  if (!company_name) return res.status(400).json({ error: 'Company name required' });
  try {
    const { rows } = await db.query(
      `INSERT INTO customers (company_name,contact_name,phone,email,city,type,status,notes)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
      [company_name, contact_name||null, phone||null, email||null,
       city||null, type||'retail', status||'active', notes||null]
    );
    await db.query(`INSERT INTO activity_log(user_name,action,entity_type) VALUES($1,$2,'customer')`,
      ['Admin', `Yangi mijoz qo'shildi: ${company_name}`]);
    res.status(201).json(rows[0]);
  } catch (err) { console.error(err); res.status(500).json({ error: 'Server error' }); }
});

// PUT update customer
router.put('/:id', async (req, res) => {
  const { id } = req.params;
  const { company_name, contact_name, phone, email, city, type, status, notes } = req.body;
  try {
    const { rows } = await db.query(
      `UPDATE customers SET company_name=$1,contact_name=$2,phone=$3,email=$4,
       city=$5,type=$6,status=$7,notes=$8 WHERE id=$9 RETURNING *`,
      [company_name, contact_name||null, phone||null, email||null,
       city||null, type||'retail', status||'active', notes||null, id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Not found' });
    res.json(rows[0]);
  } catch (err) { console.error(err); res.status(500).json({ error: 'Server error' }); }
});

// DELETE customer
router.delete('/:id', async (req, res) => {
  try {
    await db.query('DELETE FROM customers WHERE id=$1', [req.params.id]);
    res.json({ success: true });
  } catch (err) { console.error(err); res.status(500).json({ error: 'Server error' }); }
});

module.exports = router;
