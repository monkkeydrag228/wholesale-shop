// app.js — Shop frontend logic (Vanilla JS, no frameworks)
'use strict';

const API = '/api/products';

// ── State ─────────────────────────────────────────────────────
let cart = [];   // [{ product, quantity }]

// ── DOM references ────────────────────────────────────────────
const grid        = document.getElementById('productGrid');
const loadingEl   = document.getElementById('loadingState');
const errorEl     = document.getElementById('errorState');
const countBadge  = document.getElementById('productCount');
const cartDrawer  = document.getElementById('cartDrawer');
const overlay     = document.getElementById('overlay');
const cartItemsEl = document.getElementById('cartItems');
const cartTotal   = document.getElementById('cartTotal');
const cartCount   = document.getElementById('cartCount');

// ── Fetch & render products ───────────────────────────────────
async function loadProducts(category = '') {
  loadingEl.style.display = 'block';
  errorEl.style.display   = 'none';
  grid.innerHTML           = '';

  try {
    const url = category ? `${API}?category=${encodeURIComponent(category)}` : API;
    const res  = await fetch(url);
    if (!res.ok) throw new Error('Network response was not ok');
    const products = await res.json();

    loadingEl.style.display = 'none';
    countBadge.textContent  = `${products.length} items`;

    if (!products.length) {
      grid.innerHTML = '<p class="state-msg">No products in this category.</p>';
      return;
    }

    products.forEach(p => grid.appendChild(createCard(p)));
  } catch (err) {
    loadingEl.style.display = 'none';
    errorEl.style.display   = 'block';
    console.error('Failed to load products:', err);
  }
}

function createCard(p) {
  const card = document.createElement('article');
  card.className = 'product-card';
  card.innerHTML = `
    <img class="product-img"
         src="${p.image_url || 'https://via.placeholder.com/400x530?text=No+Image'}"
         alt="${p.name}" loading="lazy" />
    <div class="product-info">
      <span class="product-cat">${p.category}</span>
      <h3 class="product-name">${p.name}</h3>
      <p class="product-desc">${p.description || ''}</p>
      <div class="product-footer">
        <div>
          <div class="product-price">£${parseFloat(p.price).toFixed(2)}</div>
          <div class="product-stock">Stock: ${p.stock}</div>
        </div>
        <button class="add-btn" data-id="${p.id}">Add</button>
      </div>
    </div>
  `;
  card.querySelector('.add-btn').addEventListener('click', () => addToCart(p));
  return card;
}

// ── Cart logic ────────────────────────────────────────────────
function addToCart(product) {
  const existing = cart.find(i => i.product.id === product.id);
  if (existing) {
    existing.quantity += 1;
  } else {
    cart.push({ product, quantity: 1 });
  }
  renderCart();
  openCart();
}

function removeFromCart(productId) {
  cart = cart.filter(i => i.product.id !== productId);
  renderCart();
}

function renderCart() {
  cartItemsEl.innerHTML = '';
  let total = 0;

  cart.forEach(({ product, quantity }) => {
    const subtotal = product.price * quantity;
    total += subtotal;

    const li = document.createElement('li');
    li.className = 'cart-item';
    li.innerHTML = `
      <div>
        <div class="cart-item-name">${product.name}</div>
        <div class="cart-item-qty">Qty: ${quantity} × £${parseFloat(product.price).toFixed(2)}</div>
      </div>
      <div style="display:flex;align-items:center;gap:.5rem">
        <span class="cart-item-price">£${subtotal.toFixed(2)}</span>
        <button class="remove-btn" data-id="${product.id}" title="Remove">✕</button>
      </div>
    `;
    li.querySelector('.remove-btn').addEventListener('click', () => removeFromCart(product.id));
    cartItemsEl.appendChild(li);
  });

  cartTotal.textContent = `£${total.toFixed(2)}`;
  cartCount.textContent  = cart.reduce((n, i) => n + i.quantity, 0);
}

function openCart() {
  cartDrawer.classList.add('open');
  overlay.classList.add('open');
  document.body.style.overflow = 'hidden';
}
function closeCart() {
  cartDrawer.classList.remove('open');
  overlay.classList.remove('open');
  document.body.style.overflow = '';
}

// ── Checkout ──────────────────────────────────────────────────
document.getElementById('checkoutBtn').addEventListener('click', async () => {
  if (!cart.length) return alert('Your cart is empty.');

  const name  = document.getElementById('customerName').value.trim();
  const phone = document.getElementById('customerPhone').value.trim();
  if (!name)  return alert('Please enter your name.');
  if (!phone) return alert('Please enter your phone number.');

  const items = cart.map(i => ({ product_id: i.product.id, quantity: i.quantity }));
  try {
    const res = await fetch('/api/orders', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ items, shipping_addr: 'TBD', customer_name: name, customer_phone: phone })
    });
    if (!res.ok) {
      const err = await res.json();
      throw new Error(err.error || 'Order failed');
    }
    const data = await res.json();
    alert(`✅ Order #${data.order.id} placed!\nTotal: £${parseFloat(data.order.total_amount).toFixed(2)}`);
    cart = [];
    document.getElementById('customerName').value  = '';
    document.getElementById('customerPhone').value = '';
    renderCart();
    closeCart();
    loadProducts();
  } catch (err) {
    alert(`❌ Error: ${err.message}`);
  }
});

// ── Category filter buttons ───────────────────────────────────
document.querySelectorAll('.nav-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    loadProducts(btn.dataset.cat);
  });
});

// ── Open / close cart ─────────────────────────────────────────
document.getElementById('cartBtn').addEventListener('click', openCart);
document.getElementById('closeCart').addEventListener('click', closeCart);
overlay.addEventListener('click', closeCart);

// ── Init ──────────────────────────────────────────────────────
loadProducts();
