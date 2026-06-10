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

-- Customers table (B2B wholesale customers)
CREATE TABLE IF NOT EXISTS customers (
    id          SERIAL PRIMARY KEY,
    company_name    VARCHAR(200)    NOT NULL,
    contact_name    VARCHAR(100),
    phone           VARCHAR(30),
    email           VARCHAR(150),
    city            VARCHAR(100),
    type            VARCHAR(30)     DEFAULT 'retail',  -- 'retail' | 'corporate' | 'vip'
    status          VARCHAR(30)     DEFAULT 'active',  -- 'active' | 'inactive'
    notes           TEXT,
    created_at      TIMESTAMP       NOT NULL DEFAULT NOW()
);

-- Activity log table
CREATE TABLE IF NOT EXISTS activity_log (
    id          SERIAL PRIMARY KEY,
    user_name   VARCHAR(100),
    action      TEXT,
    entity_type VARCHAR(50),  -- 'order' | 'customer' | 'product'
    created_at  TIMESTAMP     NOT NULL DEFAULT NOW()
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

-- Customers sample data
INSERT INTO customers (company_name, contact_name, phone, email, city, type, status, notes) VALUES
    ('Style Market MChJ', 'Alisher Rakhimov', '+998 90 123 45 67', 'alisher@stylemarket.uz', 'Toshkent', 'corporate', 'active', 'VIP клиент, работает с нами с 2025г'),
    ('Fashion Plus LLC', 'Dilshod Karimov', '+998 91 234 56 78', 'dilshod@fashionplus.uz', 'Samarkand', 'retail', 'active', 'Малые заказы, регулярные покупки'),
    ('Global Garments', 'Svetlana Petrova', '+998 92 345 67 89', 'svetlana@global-garments.uz', 'Fergona', 'corporate', 'active', 'Оптовый партнер'),
    ('Urban Wear Co', 'Muhammad Yusupov', '+998 93 456 78 90', 'muhammad@urbanwear.uz', 'Bukhara', 'vip', 'active', 'Премиум клиент'),
    ('Casual Boutique', 'Natalya Volkova', '+998 94 567 89 01', 'natalya@casual.uz', 'Tashkent', 'retail', 'inactive', 'Неактивен с марта'),
    ('Textile Trading', 'Rustam Karimov', '+998 95 678 90 12', 'rustam@textile.uz', 'Toshkent', 'corporate', 'active', 'Оптовый поставщик'),
    ('Premium Collections', 'Yuliya Sokolova', '+998 96 789 01 23', 'yuliya@premium.uz', 'Samarkand', 'vip', 'active', 'Топ клиент по объему'),
    ('Fashion District', 'Karim Abdullayev', '+998 97 890 12 34', 'karim@fashiondistrict.uz', 'Tashkent', 'retail', 'active', 'Быстрые платежи'),
    ('Elite Boutique', 'Marina Volkova', '+998 98 901 23 45', 'marina@elite.uz', 'Bukhara', 'vip', 'active', 'VIP партнер'),
    ('Casual Street', 'Denis Petrov', '+998 90 111 22 33', 'denis@casual-street.uz', 'Fergona', 'retail', 'active', 'Молодой магазин'),
    ('Metropolitan', 'Gulnara Ismailova', '+998 91 222 33 44', 'gulnara@metro.uz', 'Toshkent', 'corporate', 'active', 'Крупная сеть'),
    ('Boutique Prestige', 'Olga Kuznetsova', '+998 92 333 44 55', 'olga@prestige.uz', 'Samarkand', 'vip', 'active', 'Премиум сегмент'),
    ('Urban Style', 'Anvar Mirkarimov', '+998 93 444 55 66', 'anvar@urbanstyle.uz', 'Tashkent', 'retail', 'active', 'Молодежный стиль'),
    ('Luxury Fashion', 'Tatiana Romanova', '+998 94 555 66 77', 'tatiana@luxury.uz', 'Bukhara', 'vip', 'active', 'Люкс сегмент'),
    ('Street Wear', 'Bekzod Shodmonov', '+998 95 666 77 88', 'bekzod@streetwear.uz', 'Fergona', 'retail', 'active', 'Спортивный стиль'),
    ('Fashion Hub', 'Lola Karimova', '+998 96 777 88 99', 'lola@fashionhub.uz', 'Toshkent', 'corporate', 'active', 'Торговый центр'),
    ('Trendy Clothes', 'Rashid Valiyev', '+998 97 888 99 00', 'rashid@trendy.uz', 'Samarkand', 'retail', 'active', 'Современный стиль'),
    ('Classic Wear', 'Svetlana Egorova', '+998 98 999 00 11', 'svetlana.e@classic.uz', 'Tashkent', 'corporate', 'active', 'Классический стиль'),
    ('Young Fashion', 'Malik Khasanov', '+998 90 000 11 22', 'malik@youngfashion.uz', 'Bukhara', 'retail', 'inactive', 'Требует активации'),
    ('Style Corner', 'Irina Sorokina', '+998 91 111 22 33', 'irina@stylecorner.uz', 'Fergona', 'retail', 'active', 'Небольшой магазин')
ON CONFLICT DO NOTHING;

-- Orders sample data - много заказов с разными статусами
INSERT INTO orders (customer_name, customer_phone, status, total_amount, shipping_addr, created_at) VALUES
    ('Style Market MChJ', '+998 90 123 45 67', 'delivered', 1599.85, 'Toshkent, Mirzo Ulugbek 45', NOW() - INTERVAL '180 days'),
    ('Style Market MChJ', '+998 90 123 45 67', 'delivered', 949.92, 'Toshkent, Mirzo Ulugbek 45', NOW() - INTERVAL '150 days'),
    ('Fashion Plus LLC', '+998 91 234 56 78', 'delivered', 599.88, 'Samarkand, Registan Street', NOW() - INTERVAL '140 days'),
    ('Global Garments', '+998 92 345 67 89', 'delivered', 1299.76, 'Fergona, Central Mall', NOW() - INTERVAL '130 days'),
    ('Urban Wear Co', '+998 93 456 78 90', 'delivered', 849.91, 'Bukhara, Fashion District', NOW() - INTERVAL '120 days'),
    ('Textile Trading', '+998 95 678 90 12', 'delivered', 2299.80, 'Toshkent, Commerce Center', NOW() - INTERVAL '110 days'),
    ('Premium Collections', '+998 96 789 01 23', 'delivered', 1749.85, 'Samarkand, Business Park', NOW() - INTERVAL '100 days'),
    ('Style Market MChJ', '+998 90 123 45 67', 'delivered', 1199.88, 'Toshkent, Mirzo Ulugbek 45', NOW() - INTERVAL '90 days'),
    ('Fashion District', '+998 97 890 12 34', 'delivered', 749.92, 'Tashkent, Fashion Mall', NOW() - INTERVAL '80 days'),
    ('Elite Boutique', '+998 98 901 23 45', 'delivered', 1399.80, 'Bukhara, Elite Center', NOW() - INTERVAL '70 days'),
    ('Casual Street', '+998 90 111 22 33', 'delivered', 599.85, 'Fergona, Street 5', NOW() - INTERVAL '60 days'),
    ('Metropolitan', '+998 91 222 33 44', 'delivered', 2599.92, 'Toshkent, Metro Plaza', NOW() - INTERVAL '50 days'),
    ('Boutique Prestige', '+998 92 333 44 55', 'delivered', 1899.90, 'Samarkand, Prestige', NOW() - INTERVAL '45 days'),
    ('Urban Style', '+998 93 444 55 66', 'delivered', 899.88, 'Tashkent, Urban Plaza', NOW() - INTERVAL '40 days'),
    ('Luxury Fashion', '+998 94 555 66 77', 'shipped', 1799.85, 'Bukhara, Luxury Mall', NOW() - INTERVAL '35 days'),
    ('Street Wear', '+998 95 666 77 88', 'shipped', 699.92, 'Fergona, Street Center', NOW() - INTERVAL '30 days'),
    ('Fashion Hub', '+998 96 777 88 99', 'shipped', 2099.80, 'Toshkent, Hub Center', NOW() - INTERVAL '25 days'),
    ('Style Market MChJ', '+998 90 123 45 67', 'processing', 1299.88, 'Toshkent, Mirzo Ulugbek 45', NOW() - INTERVAL '20 days'),
    ('Trendy Clothes', '+998 97 888 99 00', 'processing', 849.95, 'Samarkand, Trendy', NOW() - INTERVAL '15 days'),
    ('Classic Wear', '+998 98 999 00 11', 'processing', 1599.90, 'Tashkent, Classic', NOW() - INTERVAL '10 days'),
    ('Fashion Plus LLC', '+998 91 234 56 78', 'processing', 749.85, 'Samarkand, Registan Street', NOW() - INTERVAL '8 days'),
    ('Urban Wear Co', '+998 93 456 78 90', 'processing', 999.92, 'Bukhara, Fashion District', NOW() - INTERVAL '6 days'),
    ('Premium Collections', '+998 96 789 01 23', 'pending', 1899.88, 'Samarkand, Business Park', NOW() - INTERVAL '4 days'),
    ('Global Garments', '+998 92 345 67 89', 'pending', 1299.80, 'Fergona, Central Mall', NOW() - INTERVAL '3 days'),
    ('Style Corner', '+998 91 111 22 33', 'pending', 599.92, 'Fergona, Street', NOW() - INTERVAL '2 days'),
    ('Metropolitan', '+998 91 222 33 44', 'pending', 2199.85, 'Toshkent, Metro Plaza', NOW() - INTERVAL '1 day'),
    ('Elite Boutique', '+998 98 901 23 45', 'cancelled', 899.80, 'Bukhara, Elite Center', NOW() - INTERVAL '12 days'),
    ('Fashion District', '+998 97 890 12 34', 'delivered', 799.90, 'Tashkent, Fashion Mall', NOW() - INTERVAL '55 days'),
    ('Textile Trading', '+998 95 678 90 12', 'shipped', 1699.88, 'Toshkent, Commerce Center', NOW() - INTERVAL '22 days'),
    ('Boutique Prestige', '+998 92 333 44 55', 'pending', 1599.92, 'Samarkand, Prestige', NOW() - INTERVAL '5 days')
ON CONFLICT DO NOTHING;

-- Order items (line items) - связываем с заказами
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
    (1, 1, 50, 12.99),
    (1, 2, 25, 34.99),
    (1, 3, 10, 59.99),
    (2, 4, 15, 44.99),
    (2, 5, 8, 69.99),
    (3, 1, 30, 12.99),
    (3, 6, 20, 19.99),
    (4, 7, 8, 89.99),
    (4, 8, 20, 27.99),
    (5, 1, 40, 12.99),
    (5, 3, 12, 59.99),
    (6, 2, 35, 34.99),
    (6, 5, 15, 69.99),
    (7, 3, 18, 59.99),
    (7, 4, 12, 44.99),
    (8, 1, 60, 12.99),
    (8, 2, 18, 34.99),
    (9, 6, 25, 19.99),
    (9, 8, 15, 27.99),
    (10, 7, 10, 89.99),
    (10, 5, 8, 69.99),
    (11, 1, 35, 12.99),
    (11, 4, 10, 44.99),
    (12, 2, 40, 34.99),
    (12, 3, 15, 59.99),
    (13, 5, 12, 69.99),
    (13, 8, 20, 27.99),
    (14, 1, 45, 12.99),
    (14, 6, 15, 19.99),
    (15, 7, 12, 89.99),
    (15, 4, 8, 44.99),
    (16, 1, 38, 12.99),
    (16, 2, 10, 34.99),
    (17, 3, 20, 59.99),
    (17, 5, 10, 69.99),
    (18, 1, 55, 12.99),
    (18, 8, 18, 27.99),
    (19, 2, 25, 34.99),
    (19, 6, 12, 19.99),
    (20, 7, 15, 89.99),
    (20, 4, 12, 44.99),
    (21, 1, 42, 12.99),
    (21, 3, 8, 59.99),
    (22, 2, 20, 34.99),
    (22, 5, 12, 69.99),
    (23, 1, 48, 12.99),
    (23, 6, 18, 19.99),
    (24, 8, 22, 27.99),
    (24, 4, 10, 44.99),
    (25, 7, 14, 89.99),
    (25, 2, 15, 34.99),
    (26, 1, 38, 12.99),
    (26, 3, 12, 59.99),
    (27, 5, 10, 69.99),
    (28, 1, 50, 12.99),
    (28, 2, 20, 34.99),
    (29, 6, 22, 19.99),
    (29, 8, 18, 27.99),
    (30, 3, 18, 59.99),
    (30, 4, 12, 44.99)
ON CONFLICT DO NOTHING;

-- Activity log sample data - много записей
INSERT INTO activity_log (user_name, action, entity_type, created_at) VALUES
    ('Admin', 'Yangi mijoz qo''shildi: Style Market MChJ', 'customer', NOW() - INTERVAL '180 days'),
    ('Admin', 'Yangi buyurtma #1 yaratildi', 'order', NOW() - INTERVAL '180 days'),
    ('Admin', 'Buyurtma #1 yetkazildi', 'order', NOW() - INTERVAL '170 days'),
    ('Admin', 'Mahsulot "Classic White Tee" stoki 50 ta qisqartirildi', 'product', NOW() - INTERVAL '160 days'),
    ('Admin', 'Yangi mijoz qo''shildi: Fashion Plus LLC', 'customer', NOW() - INTERVAL '150 days'),
    ('Admin', 'Buyurtma #2 yetkazildi', 'order', NOW() - INTERVAL '140 days'),
    ('Admin', 'Yangi mijoz qo''shildi: Global Garments', 'customer', NOW() - INTERVAL '140 days'),
    ('Admin', 'Buyurtma #3 yetkazildi', 'order', NOW() - INTERVAL '130 days'),
    ('Admin', 'Buyurtma #4 yuborildi', 'order', NOW() - INTERVAL '125 days'),
    ('Admin', 'Yangi mijoz qo''shildi: Urban Wear Co', 'customer', NOW() - INTERVAL '120 days'),
    ('Admin', 'Buyurtma #5 jarayonda', 'order', NOW() - INTERVAL '110 days'),
    ('Admin', 'Mahsulot "Denim Jacket" qayta stok qo''shildi', 'product', NOW() - INTERVAL '100 days'),
    ('Admin', 'Yangi mijoz qo''shildi: Textile Trading', 'customer', NOW() - INTERVAL '110 days'),
    ('Admin', 'Buyurtma #6 yetkazildi', 'order', NOW() - INTERVAL '95 days'),
    ('Admin', 'Yangi mijoz qo''shildi: Premium Collections', 'customer', NOW() - INTERVAL '100 days'),
    ('Admin', 'Buyurtma #7 yetkazildi', 'order', NOW() - INTERVAL '90 days'),
    ('Admin', 'Buyurtma #8 yuborildi', 'order', NOW() - INTERVAL '85 days'),
    ('Admin', 'Yangi mijoz qo''shildi: Fashion District', 'customer', NOW() - INTERVAL '80 days'),
    ('Admin', 'Buyurtma #9 yetkazildi', 'order', NOW() - INTERVAL '75 days'),
    ('Admin', 'Yangi mijoz qo''shildi: Elite Boutique', 'customer', NOW() - INTERVAL '70 days'),
    ('Admin', 'Buyurtma #10 jarayonda', 'order', NOW() - INTERVAL '65 days'),
    ('Admin', 'Yangi mijoz qo''shildi: Casual Street', 'customer', NOW() - INTERVAL '60 days'),
    ('Admin', 'Buyurtma #11 yetkazildi', 'order', NOW() - INTERVAL '55 days'),
    ('Admin', 'Yangi mijoz qo''shildi: Metropolitan', 'customer', NOW() - INTERVAL '50 days'),
    ('Admin', 'Buyurtma #12 yetkazildi', 'order', NOW() - INTERVAL '45 days'),
    ('Admin', 'Yangi mijoz qo''shildi: Boutique Prestige', 'customer', NOW() - INTERVAL '45 days'),
    ('Admin', 'Buyurtma #13 yetkazildi', 'order', NOW() - INTERVAL '40 days'),
    ('Admin', 'Yangi mijoz qo''shildi: Urban Style', 'customer', NOW() - INTERVAL '40 days'),
    ('Admin', 'Buyurtma #14 jarayonda', 'order', NOW() - INTERVAL '38 days'),
    ('Admin', 'Yangi mijoz qo''shildi: Luxury Fashion', 'customer', NOW() - INTERVAL '35 days'),
    ('Admin', 'Buyurtma #15 yuborildi', 'order', NOW() - INTERVAL '30 days'),
    ('Admin', 'Yangi mijoz qo''shildi: Street Wear', 'customer', NOW() - INTERVAL '30 days'),
    ('Admin', 'Buyurtma #16 yuborildi', 'order', NOW() - INTERVAL '25 days'),
    ('Admin', 'Yangi mijoz qo''shildi: Fashion Hub', 'customer', NOW() - INTERVAL '25 days'),
    ('Admin', 'Buyurtma #17 jarayonda', 'order', NOW() - INTERVAL '20 days'),
    ('Admin', 'Yangi mijoz qo''shildi: Trendy Clothes', 'customer', NOW() - INTERVAL '15 days'),
    ('Admin', 'Buyurtma #18 jarayonda', 'order', NOW() - INTERVAL '15 days'),
    ('Admin', 'Yangi mijoz qo''shildi: Classic Wear', 'customer', NOW() - INTERVAL '10 days'),
    ('Admin', 'Buyurtma #19 kutilmoqda', 'order', NOW() - INTERVAL '8 days'),
    ('Admin', 'Buyurtma #20 kutilmoqda', 'order', NOW() - INTERVAL '6 days'),
    ('Admin', 'Mahsulot "Athletic Shorts" stoki 30 ta qisqartirildi', 'product', NOW() - INTERVAL '5 days'),
    ('Admin', 'Buyurtma #21 jarayonda', 'order', NOW() - INTERVAL '3 days'),
    ('Admin', 'Buyurtma #22 kutilmoqda', 'order', NOW() - INTERVAL '2 days'),
    ('Admin', 'Yangi buyurtma #23 yaratildi', 'order', NOW() - INTERVAL '1 day'),
    ('Admin', 'Buyurtma #24 kutilmoqda', 'order', NOW() - INTERVAL '1 day'),
    ('Admin', 'Mahsulot "Merino Wool Sweater" narx yangilandi', 'product', NOW() - INTERVAL '12 hours'),
    ('Admin', 'Yangi buyurtma #25 yaratildi', 'order', NOW() - INTERVAL '30 minutes'),
    ('Admin', 'Buyurtma #26 bekor qilindi', 'order', NOW() - INTERVAL '10 days')
ON CONFLICT DO NOTHING;
