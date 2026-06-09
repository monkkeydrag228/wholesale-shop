// routes/auth.js — Login endpoint
'use strict';

const express  = require('express');
const router   = express.Router();
const bcrypt   = require('bcryptjs');
const jwt      = require('jsonwebtoken');
const db       = require('../db');

const JWT_SECRET  = process.env.JWT_SECRET || 'drape-secret-key-2026';
const JWT_EXPIRES = '8h';

// ── POST /api/auth/login ──────────────────────────────────────
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }

  try {
    const { rows } = await db.query(
      "SELECT * FROM users WHERE email = $1 AND role = 'admin'",
      [email.toLowerCase().trim()]
    );

    if (!rows.length) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const user = rows[0];
    const valid = await bcrypt.compare(password, user.password);

    if (!valid) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES }
    );

    res.json({ token, name: user.name, email: user.email });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Login failed' });
  }
});

module.exports = router;
