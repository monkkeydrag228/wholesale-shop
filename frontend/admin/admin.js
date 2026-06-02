// admin.js — Admin Panel logic (Vanilla JS)
'use strict';

const API = '/api/products';

// ── DOM refs ──────────────────────────────────────────────────
const showFormBtn  = document.getElementById('showFormBtn');
const formSection  = document.getElementById('formSection');
const formTitle    = document.getElementById('formTitle');
const productForm  = document.getElementById('productForm');
const submitBtn    = document.getElementById('submitBtn');
const cancelBtn    = document.getElementById('cancelBtn');
const editIdInput  = document.getElementById('editId');

const tableBody    = document.getElementById('tableBody');
const tableEl      = document.getElementById('productsTable');
const tableCount   = document.getElementById('tableCount');
const tableLoading = document.getElementById('tableLoading');
const tableError   = document.getElementById('tableError');
const searchInput  = document.getElementById('searchInput');
const toast        = document.getElementById('toast');

let allProducts = [];   // local cache for search

// ── Toast helper ──────────────────────────────────────────────
function showToast(msg, type = 'success') {
  toast.textContent = msg;
  toast.className   = `toast show ${type}`;
  setTimeout(() => { toast.className = 'toast'; }, 3000);
}

// ── Load products ─────────────────────────────────────────────
async function loadProducts() {
  tableLoading.style.display = 'block';
  tableError.style.display   = 'none';
  tableEl.style.display      = 'none';

  try {
    const res = await fetch(API);
    if (!res.ok) throw new Error('Failed to fetch');
    allProducts = await res.json();
    renderTable(allProducts);
    tableLoading.style.display = 'none';
  } catch (err) {
    tableLoading.style.display = 'none';
    tableError.style.display   = 'block';
    console.error(err);
  }
}

function renderTable(products) {
  tableBody.innerHTML = '';
  tableCount.textContent = `${products.length} products`;

  if (!products.length) {
    tableBody.innerHTML = `<tr><td colspan="6" style="text-align:center;padding:2rem;color:#888">No products found.</td></tr>`;
  } else {
    products.forEach(p => tableBody.appendChild(createRow(p)));
  }
  tableEl.style.display = 'table';
}

function createRow(p) {
  const tr = document.createElement('tr');
  tr.innerHTML = `
    <td><img class="thumb"
         src="${p.image_url || 'https://via.placeholder.com/44x55?text=?'}"
         alt="${p.name}" /></td>
    <td>
      <div class="product-name-cell">${p.name}</div>
      <div class="product-desc-cell">${p.description || '—'}</div>
    </td>
    <td>${p.category}</td>
    <td>£${parseFloat(p.price).toFixed(2)}</td>
    <td>${p.stock}</td>
    <td class="actions-cell">
      <button class="btn-edit"   data-id="${p.id}">Edit</button>
      <button class="btn-delete" data-id="${p.id}">Delete</button>
    </td>
  `;
  tr.querySelector('.btn-edit').addEventListener('click', () => openEditForm(p));
  tr.querySelector('.btn-delete').addEventListener('click', () => deleteProduct(p.id, p.name));
  return tr;
}

// ── Form helpers ──────────────────────────────────────────────
function openAddForm() {
  formTitle.textContent     = 'Add New Product';
  submitBtn.textContent     = 'Add Product';
  editIdInput.value         = '';
  productForm.reset();
  formSection.style.display = 'block';
  formSection.scrollIntoView({ behavior: 'smooth' });
}

function openEditForm(p) {
  formTitle.textContent              = 'Edit Product';
  submitBtn.textContent              = 'Save Changes';
  editIdInput.value                  = p.id;
  document.getElementById('pName').value     = p.name;
  document.getElementById('pCategory').value = p.category;
  document.getElementById('pDesc').value     = p.description || '';
  document.getElementById('pPrice').value    = p.price;
  document.getElementById('pStock').value    = p.stock;
  document.getElementById('pImage').value    = p.image_url || '';
  formSection.style.display = 'block';
  formSection.scrollIntoView({ behavior: 'smooth' });
}

function closeForm() {
  formSection.style.display = 'none';
  productForm.reset();
  editIdInput.value = '';
}

// ── Form submit (create or update) ───────────────────────────
productForm.addEventListener('submit', async (e) => {
  e.preventDefault();
  const id = editIdInput.value;

  const payload = {
    name:        document.getElementById('pName').value.trim(),
    category:    document.getElementById('pCategory').value,
    description: document.getElementById('pDesc').value.trim(),
    price:       parseFloat(document.getElementById('pPrice').value),
    stock:       parseInt(document.getElementById('pStock').value),
    image_url:   document.getElementById('pImage').value.trim(),
  };

  try {
    const url    = id ? `${API}/${id}` : API;
    const method = id ? 'PUT' : 'POST';
    const res    = await fetch(url, {
      method,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    if (!res.ok) throw new Error('Request failed');

    showToast(id ? '✅ Product updated!' : '✅ Product added!');
    closeForm();
    loadProducts();
  } catch (err) {
    showToast('❌ Failed to save product', 'error');
  }
});

// ── Delete product ────────────────────────────────────────────
async function deleteProduct(id, name) {
  if (!confirm(`Delete "${name}"? This cannot be undone.`)) return;
  try {
    const res = await fetch(`${API}/${id}`, { method: 'DELETE' });
    if (!res.ok) throw new Error('Delete failed');
    showToast(`🗑 "${name}" deleted`);
    loadProducts();
  } catch (err) {
    showToast('❌ Could not delete product', 'error');
  }
}

// ── Search / filter ───────────────────────────────────────────
searchInput.addEventListener('input', () => {
  const q = searchInput.value.toLowerCase();
  const filtered = allProducts.filter(p =>
    p.name.toLowerCase().includes(q) || p.category.toLowerCase().includes(q)
  );
  renderTable(filtered);
});

// ── Event listeners ───────────────────────────────────────────
showFormBtn.addEventListener('click', openAddForm);
cancelBtn.addEventListener('click', closeForm);

// ── Init ──────────────────────────────────────────────────────
loadProducts();
