'use strict';
const express = require('express');
const router  = express.Router();
const db      = require('../db');

router.get('/summary', async (req, res) => {
  try {
    const [totals, statusBreakdown, monthly, topCustomers, recentOrders, recentActivity] = await Promise.all([
      db.query(`SELECT
        COUNT(*)                                    AS total_orders,
        COALESCE(SUM(total_amount),0)               AS total_revenue,
        COALESCE(AVG(total_amount),0)               AS avg_order,
        COUNT(*) FILTER(WHERE status='pending')     AS pending_orders,
        COUNT(*) FILTER(WHERE status='delivered')   AS delivered_orders
        FROM orders`),
      db.query(`SELECT status, COUNT(*) AS count FROM orders GROUP BY status ORDER BY count DESC`),
      db.query(`SELECT
        TO_CHAR(DATE_TRUNC('month',created_at),'Mon') AS month,
        DATE_TRUNC('month',created_at) AS month_date,
        COALESCE(SUM(total_amount),0) AS revenue,
        COUNT(*) AS orders
        FROM orders
        WHERE created_at >= NOW()-INTERVAL'6 months'
        GROUP BY DATE_TRUNC('month',created_at)
        ORDER BY month_date ASC`),
      db.query(`SELECT c.company_name, COUNT(o.id) AS orders, COALESCE(SUM(o.total_amount),0) AS spent
        FROM customers c LEFT JOIN orders o ON o.customer_id=c.id
        GROUP BY c.id,c.company_name ORDER BY spent DESC LIMIT 5`),
      db.query(`SELECT o.id,o.customer_name,o.status,o.total_amount,o.created_at
        FROM orders o ORDER BY o.created_at DESC LIMIT 5`),
      db.query(`SELECT * FROM activity_log ORDER BY created_at DESC LIMIT 8`)
    ]);
    const customerCount = await db.query(`SELECT COUNT(*) AS c FROM customers WHERE status='active'`);
    const productCount  = await db.query(`SELECT COUNT(*) AS c FROM products`);
    res.json({
      totals:          { ...totals.rows[0], customers: customerCount.rows[0].c, products: productCount.rows[0].c },
      statusBreakdown: statusBreakdown.rows,
      monthly:         monthly.rows,
      topCustomers:    topCustomers.rows,
      recentOrders:    recentOrders.rows,
      recentActivity:  recentActivity.rows
    });
  } catch (err) { console.error(err); res.status(500).json({ error: 'Server error' }); }
});

module.exports = router;
