-- ============================================================
-- WHOLESALE CLOTHING SHOP — Database Schema
-- BTEC Unit 6: Networking in the Cloud
-- ============================================================

-- Users table (customers + admins)
CREATE TABLE IF NOT EXISTS users (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100)        NOT NULL,
    email       VARCHAR(150) UNIQUE NOT NULL,
    password    VARCHAR(255)        NOT NULL,   -- bcrypt hash
    role        VARCHAR(20)         NOT NULL DEFAULT 'customer', -- 'customer' | 'admin'
    created_at  TIMESTAMP           NOT NULL DEFAULT NOW()
);

-- Products table
CREATE TABLE IF NOT EXISTS products (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(200)    NOT NULL,
    category    VARCHAR(100)    NOT NULL,       -- e.g. 'T-Shirts', 'Jackets'
    description TEXT,
    price       NUMERIC(10,2)   NOT NULL CHECK (price >= 0),
    stock       INTEGER         NOT NULL DEFAULT 0 CHECK (stock >= 0),
    image_url   TEXT,
    created_at  TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP       NOT NULL DEFAULT NOW()
);

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
    id              SERIAL PRIMARY KEY,
    user_id         INTEGER         REFERENCES users(id) ON DELETE SET NULL,
    customer_name   VARCHAR(100),
    customer_phone  VARCHAR(30),
    status          VARCHAR(30)     NOT NULL DEFAULT 'pending',  -- pending|processing|shipped|delivered|cancelled
    total_amount    NUMERIC(10,2)   NOT NULL CHECK (total_amount >= 0),
    shipping_addr   TEXT,
    created_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP       NOT NULL DEFAULT NOW()
);

-- Order items (line items)
CREATE TABLE IF NOT EXISTS order_items (
    id          SERIAL PRIMARY KEY,
    order_id    INTEGER         NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id  INTEGER         REFERENCES products(id) ON DELETE SET NULL,
    quantity    INTEGER         NOT NULL CHECK (quantity > 0),
    unit_price  NUMERIC(10,2)   NOT NULL CHECK (unit_price >= 0)
);

-- ── Indexes ─────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_products_category  ON products(category);
CREATE INDEX IF NOT EXISTS idx_orders_user        ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order  ON order_items(order_id);

-- ── Seed data ────────────────────────────────────────────────
INSERT INTO users (name, email, password, role) VALUES
    ('Admin User',  'admin@wholesale.com', '$2b$10$examplehashedpassword1', 'admin'),
    ('Jane Smith',  'jane@example.com',    '$2b$10$examplehashedpassword2', 'customer')
ON CONFLICT (email) DO NOTHING;

INSERT INTO products (name, category, description, price, stock, image_url) VALUES
    ('Classic White Tee',     'T-Shirts', 'Premium 100% cotton unisex t-shirt.',          12.99, 500, 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400'),
    ('Slim Fit Chinos',       'Trousers', 'Modern slim-fit chinos, stretch fabric.',       34.99, 200, 'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=400'),
    ('Denim Jacket',          'Jackets',  'Vintage-wash denim jacket, unisex cut.',        59.99, 120, 'https://images.unsplash.com/photo-1551537482-f2075a1d41f2?w=400'),
    ('Floral Summer Dress',   'Dresses',  'Lightweight floral print midi dress.',          44.99,  80, 'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=400'),
    ('Merino Wool Sweater',   'Knitwear', 'Fine merino wool crew-neck sweater.',           69.99, 150, 'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=400'),
    ('Athletic Shorts',       'Sportswear','Quick-dry athletic shorts with liner.',        19.99, 300, 'https://images.unsplash.com/photo-1539185441755-769473a23570?w=400'),
    ('Linen Blazer',          'Jackets',  'Relaxed linen blazer for warm weather.',        89.99,  60, 'https://images.unsplash.com/photo-1594938298603-c8148c4b984b?w=400'),
    ('Striped Polo Shirt',    'T-Shirts', 'Classic striped polo, pique cotton.',           27.99, 250, 'https://images.unsplash.com/photo-1586790170083-2f9ceadc732d?w=400')
ON CONFLICT DO NOTHING;
