// routes/reports.js — Analytics & Reports API
'use strict';
const express = require('express');
const router  = express.Router();
const db      = require('../db');

// GET /api/reports/summary — all analytics in one call
router.get('/summary', async (req, res) => {
  try {
    const [
      totals,
      statusBreakdown,
      monthlyRevenue,
      topProducts,
      recentOrders,
      categoryRevenue,
    ] = await Promise.all([

      // KPI totals
      db.query(`
        SELECT
          COUNT(*)                                       AS total_orders,
          COALESCE(SUM(total_amount), 0)                 AS total_revenue,
          COUNT(DISTINCT COALESCE(customer_name, 'Guest')) AS total_customers,
          COALESCE(AVG(total_amount), 0)                 AS avg_order_value,
          COUNT(*) FILTER (WHERE status = 'pending')     AS pending_orders,
          COUNT(*) FILTER (WHERE status = 'delivered')   AS delivered_orders
        FROM orders
      `),

      // Orders by status
      db.query(`
        SELECT status, COUNT(*) AS count, COALESCE(SUM(total_amount),0) AS revenue
        FROM orders
        GROUP BY status
        ORDER BY count DESC
      `),

      // Monthly revenue — last 6 months
      db.query(`
        SELECT
          TO_CHAR(DATE_TRUNC('month', created_at), 'Mon YYYY') AS month,
          DATE_TRUNC('month', created_at)                       AS month_date,
          COALESCE(SUM(total_amount), 0)                        AS revenue,
          COUNT(*)                                              AS orders
        FROM orders
        WHERE created_at >= NOW() - INTERVAL '6 months'
        GROUP BY DATE_TRUNC('month', created_at)
        ORDER BY month_date ASC
      `),

      // Top 5 products by revenue
      db.query(`
        SELECT
          p.name,
          p.category,
          SUM(oi.quantity)               AS total_sold,
          SUM(oi.quantity * oi.unit_price) AS revenue
        FROM order_items oi
        JOIN products p ON p.id = oi.product_id
        GROUP BY p.id, p.name, p.category
        ORDER BY revenue DESC
        LIMIT 5
      `),

      // Recent 5 orders
      db.query(`
        SELECT
          id,
          customer_name,
          customer_phone,
          status,
          total_amount,
          created_at
        FROM orders
        ORDER BY created_at DESC
        LIMIT 5
      `),

      // Revenue by category
      db.query(`
        SELECT
          p.category,
          SUM(oi.quantity * oi.unit_price) AS revenue,
          SUM(oi.quantity)                  AS units_sold
        FROM order_items oi
        JOIN products p ON p.id = oi.product_id
        GROUP BY p.category
        ORDER BY revenue DESC
      `),
    ]);

    res.json({
      totals:          totals.rows[0],
      statusBreakdown: statusBreakdown.rows,
      monthlyRevenue:  monthlyRevenue.rows,
      topProducts:     topProducts.rows,
      recentOrders:    recentOrders.rows,
      categoryRevenue: categoryRevenue.rows,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Could not load reports data' });
  }
});

module.exports = router;
