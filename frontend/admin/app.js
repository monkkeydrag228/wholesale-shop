// ── DRAPE CRM — Shared utilities ─────────────────────────
'use strict';

// ── Auth ──────────────────────────────────────────────────
function getToken() { return localStorage.getItem('drape_token'); }
function getName()  { return localStorage.getItem('drape_name') || 'Admin'; }
function requireAuth() {
  if (!getToken()) { window.location.href = '/admin/login.html'; return false; }
  return true;
}
function authHeaders() {
  return { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + getToken() };
}

// ── Toast ─────────────────────────────────────────────────
let toastWrap;
function toast(msg, type = 'success') {
  if (!toastWrap) {
    toastWrap = document.createElement('div');
    toastWrap.className = 'toast-wrap';
    document.body.appendChild(toastWrap);
  }
  const t = document.createElement('div');
  t.className = 'toast ' + type;
  t.innerHTML = (type === 'success' ? '✓' : '✕') + ' ' + msg;
  toastWrap.appendChild(t);
  setTimeout(() => t.remove(), 3000);
}

// ── API helper ────────────────────────────────────────────
async function api(url, options = {}) {
  const res = await fetch(url, {
    headers: authHeaders(),
    ...options
  });
  if (res.status === 401 || res.status === 403) {
    localStorage.removeItem('drape_token');
    window.location.href = '/admin/login.html';
    return null;
  }
  return res;
}

// ── Topbar & Sidebar setup ────────────────────────────────
function setupLayout(activePage) {
  // Set user info
  const name = getName();
  const initials = name.split(' ').map(w => w[0]).join('').toUpperCase().slice(0, 2);
  document.querySelectorAll('.js-uname').forEach(el => el.textContent = name);
  document.querySelectorAll('.js-avatar').forEach(el => el.textContent = initials);

  // Active nav
  document.querySelectorAll('.nav-link[data-page]').forEach(link => {
    if (link.dataset.page === activePage) link.classList.add('active');
  });

  // Logout
  document.querySelectorAll('.js-logout').forEach(btn => {
    btn.addEventListener('click', () => {
      localStorage.removeItem('drape_token');
      localStorage.removeItem('drape_name');
      window.location.href = '/admin/login.html';
    });
  });
}

// ── Modal helpers ─────────────────────────────────────────
function openModal(id) {
  document.getElementById(id).classList.add('open');
}
function closeModal(id) {
  document.getElementById(id).classList.remove('open');
}
function setupModals() {
  document.querySelectorAll('[data-modal-close]').forEach(btn => {
    btn.addEventListener('click', () => {
      btn.closest('.modal-overlay').classList.remove('open');
    });
  });
  document.querySelectorAll('.modal-overlay').forEach(overlay => {
    overlay.addEventListener('click', e => {
      if (e.target === overlay) overlay.classList.remove('open');
    });
  });
}

// ── Format helpers ────────────────────────────────────────
function fmtMoney(v) {
  return parseFloat(v || 0).toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',') + ' so\'m';
}
function fmtDate(d) {
  if (!d) return '—';
  return new Date(d).toLocaleDateString('uz-UZ', { day: '2-digit', month: 'short', year: 'numeric' });
}

// ── Status badge ──────────────────────────────────────────
const STATUS_MAP = {
  pending:    ['badge-amber',  'Kutilmoqda'],
  processing: ['badge-blue',   'Jarayonda'],
  shipped:    ['badge-purple', 'Yuborildi'],
  delivered:  ['badge-green',  'Yetkazildi'],
  cancelled:  ['badge-red',    'Bekor qilindi'],
  active:     ['badge-green',  'Faol'],
  inactive:   ['badge-gray',   'Nofaol'],
};
function statusBadge(status) {
  const [cls, label] = STATUS_MAP[status] || ['badge-gray', status];
  return `<span class="badge ${cls}">${label}</span>`;
}
