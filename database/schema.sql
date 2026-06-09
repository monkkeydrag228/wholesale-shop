-- DRAPE CRM — Complete Database Schema

CREATE TABLE IF NOT EXISTS users (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(150) UNIQUE NOT NULL,
    password    VARCHAR(255) NOT NULL,
    role        VARCHAR(20) NOT NULL DEFAULT 'staff',
    created_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS customers (
    id           SERIAL PRIMARY KEY,
    company_name VARCHAR(200) NOT NULL,
    contact_name VARCHAR(150),
    phone        VARCHAR(50),
    email        VARCHAR(150),
    city         VARCHAR(100),
    type         VARCHAR(30) NOT NULL DEFAULT 'retail',
    status       VARCHAR(20) NOT NULL DEFAULT 'active',
    notes        TEXT,
    created_at   TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS products (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(200) NOT NULL,
    category    VARCHAR(100) NOT NULL,
    description TEXT,
    price       NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    stock       INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    image_url   TEXT,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS orders (
    id              SERIAL PRIMARY KEY,
    customer_id     INTEGER REFERENCES customers(id) ON DELETE SET NULL,
    customer_name   VARCHAR(150),
    customer_phone  VARCHAR(50),
    status          VARCHAR(30) NOT NULL DEFAULT 'pending',
    total_amount    NUMERIC(10,2) NOT NULL DEFAULT 0,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS order_items (
    id          SERIAL PRIMARY KEY,
    order_id    INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id  INTEGER REFERENCES products(id) ON DELETE SET NULL,
    quantity    INTEGER NOT NULL CHECK (quantity > 0),
    unit_price  NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0)
);

CREATE TABLE IF NOT EXISTS activity_log (
    id          SERIAL PRIMARY KEY,
    user_name   VARCHAR(150) NOT NULL DEFAULT 'Admin',
    action      TEXT NOT NULL,
    entity_type VARCHAR(50),
    created_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_orders_customer   ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status     ON orders(status);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_activity_created  ON activity_log(created_at DESC);

-- Admin user: admin777@gmail.com / bishbash
INSERT INTO users (name, email, password, role) VALUES
    ('Admin', 'admin777@gmail.com',
     '$2b$10$rnTcLKovVqb9cv8ATaBMl.McOVXIsyMhvLQ2ECYSQCeCfvzmOGuQ2', 'admin')
ON CONFLICT (email) DO NOTHING;

-- Products
INSERT INTO products (name, category, description, price, stock, image_url) VALUES
    ('Classic White Tee',    'T-Shirts',  'Premium 100% cotton t-shirt',              12.99, 480, 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400'),
    ('Slim Fit Chinos',      'Trousers',  'Modern slim-fit stretch chinos',           34.99, 185, 'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=400'),
    ('Denim Jacket',         'Jackets',   'Vintage-wash unisex denim jacket',         59.99, 108, 'https://images.unsplash.com/photo-1551537482-f2075a1d41f2?w=400'),
    ('Floral Summer Dress',  'Dresses',   'Lightweight floral print midi dress',      44.99,  72, 'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=400'),
    ('Merino Wool Sweater',  'Knitwear',  'Fine merino wool crew-neck sweater',       69.99, 138, 'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=400'),
    ('Athletic Shorts',      'Sportswear','Quick-dry athletic shorts with liner',     19.99, 285, 'https://images.unsplash.com/photo-1539185441755-769473a23570?w=400'),
    ('Linen Blazer',         'Jackets',   'Relaxed linen blazer for warm weather',    89.99,  54, 'https://images.unsplash.com/photo-1594938298603-c8148c4b984b?w=400'),
    ('Striped Polo Shirt',   'T-Shirts',  'Classic striped polo, pique cotton',       27.99, 237, 'https://images.unsplash.com/photo-1586790170083-2f9ceadc732d?w=400')
ON CONFLICT DO NOTHING;

-- Customers
INSERT INTO customers (company_name, contact_name, phone, email, city, type, status) VALUES
    ('Style Market MChJ',    'Aziz Karimov',    '+998 91 234 56 78', 'aziz@stylemarket.uz',   'Toshkent',   'corporate', 'active'),
    ('Fashion Plaza YaTT',   'Malika Yusupova', '+998 93 345 67 89', 'info@fashionplaza.uz',  'Samarqand',  'vip',       'active'),
    ('Premium Shop MChJ',    'Bobur Mirzayev',  '+998 90 456 78 90', 'premium@shop.uz',       'Buxoro',     'corporate', 'active'),
    ('City Store YaTT',      'Nargiza Rahimova','+998 94 567 89 01', 'city@store.uz',         'Namangan',   'retail',    'active'),
    ('Boutique Shop MChJ',   'Sherzod Toshev',  '+998 97 678 90 12', 'boutique@shop.uz',      'Fargona',    'retail',    'active'),
    ('Trend Clothes YaTT',   'Dilnoza Xasanova','+998 99 789 01 23', 'trend@clothes.uz',      'Toshkent',   'vip',       'active'),
    ('Moda Store MChJ',      'Jasur Ergashev',  '+998 91 890 12 34', 'moda@store.uz',         'Andijon',    'corporate', 'inactive'),
    ('Elite Fashion MChJ',   'Sarvar Nazarov',  '+998 93 901 23 45', 'elite@fashion.uz',      'Qarshi',     'retail',    'active')
ON CONFLICT DO NOTHING;

-- Seed orders
DO $$
DECLARE
  c1 INT; c2 INT; c3 INT; c4 INT; c5 INT; c6 INT;
  p1 INT; p2 INT; p3 INT; p4 INT; p5 INT; p6 INT; p7 INT; p8 INT;
  o  INT;
BEGIN
  SELECT id INTO c1 FROM customers WHERE company_name='Style Market MChJ'   LIMIT 1;
  SELECT id INTO c2 FROM customers WHERE company_name='Fashion Plaza YaTT'  LIMIT 1;
  SELECT id INTO c3 FROM customers WHERE company_name='Premium Shop MChJ'   LIMIT 1;
  SELECT id INTO c4 FROM customers WHERE company_name='City Store YaTT'     LIMIT 1;
  SELECT id INTO c5 FROM customers WHERE company_name='Boutique Shop MChJ'  LIMIT 1;
  SELECT id INTO c6 FROM customers WHERE company_name='Trend Clothes YaTT'  LIMIT 1;

  SELECT id INTO p1 FROM products WHERE name='Classic White Tee'   LIMIT 1;
  SELECT id INTO p2 FROM products WHERE name='Slim Fit Chinos'     LIMIT 1;
  SELECT id INTO p3 FROM products WHERE name='Denim Jacket'        LIMIT 1;
  SELECT id INTO p4 FROM products WHERE name='Floral Summer Dress' LIMIT 1;
  SELECT id INTO p5 FROM products WHERE name='Merino Wool Sweater' LIMIT 1;
  SELECT id INTO p6 FROM products WHERE name='Athletic Shorts'     LIMIT 1;
  SELECT id INTO p7 FROM products WHERE name='Linen Blazer'        LIMIT 1;
  SELECT id INTO p8 FROM products WHERE name='Striped Polo Shirt'  LIMIT 1;

  IF (SELECT COUNT(*) FROM orders) = 0 THEN
    -- Jan
    INSERT INTO orders(customer_id,customer_name,status,total_amount,created_at) VALUES(c1,'Style Market MChJ','delivered',389.85,NOW()-INTERVAL'150 days') RETURNING id INTO o;
    INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES(o,p1,10,12.99),(o,p2,5,34.99),(o,p3,2,59.99);
    INSERT INTO activity_log(action,entity_type,created_at) VALUES('Yangi buyurtma yaratildi #'||o,'order',NOW()-INTERVAL'150 days');

    INSERT INTO orders(customer_id,customer_name,status,total_amount,created_at) VALUES(c2,'Fashion Plaza YaTT','delivered',539.82,NOW()-INTERVAL'145 days') RETURNING id INTO o;
    INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES(o,p5,4,69.99),(o,p7,3,89.99),(o,p6,6,19.99);
    INSERT INTO activity_log(action,entity_type,created_at) VALUES('Yangi buyurtma yaratildi #'||o,'order',NOW()-INTERVAL'145 days');

    -- Feb
    INSERT INTO orders(customer_id,customer_name,status,total_amount,created_at) VALUES(c3,'Premium Shop MChJ','delivered',479.88,NOW()-INTERVAL'120 days') RETURNING id INTO o;
    INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES(o,p4,6,44.99),(o,p8,8,27.99);

    INSERT INTO orders(customer_id,customer_name,status,total_amount,created_at) VALUES(c4,'City Store YaTT','delivered',719.76,NOW()-INTERVAL'115 days') RETURNING id INTO o;
    INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES(o,p3,4,59.99),(o,p7,4,89.99),(o,p2,4,34.99);

    INSERT INTO orders(customer_id,customer_name,status,total_amount,created_at) VALUES(c5,'Boutique Shop MChJ','cancelled',129.90,NOW()-INTERVAL'110 days') RETURNING id INTO o;
    INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES(o,p1,10,12.99);

    -- Mar
    INSERT INTO orders(customer_id,customer_name,status,total_amount,created_at) VALUES(c6,'Trend Clothes YaTT','delivered',629.91,NOW()-INTERVAL'90 days') RETURNING id INTO o;
    INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES(o,p5,3,69.99),(o,p3,3,59.99),(o,p4,5,44.99),(o,p6,5,19.99);

    INSERT INTO orders(customer_id,customer_name,status,total_amount,created_at) VALUES(c1,'Style Market MChJ','delivered',359.88,NOW()-INTERVAL'85 days') RETURNING id INTO o;
    INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES(o,p8,6,27.99),(o,p2,4,34.99),(o,p1,4,12.99);

    -- Apr
    INSERT INTO orders(customer_id,customer_name,status,total_amount,created_at) VALUES(c2,'Fashion Plaza YaTT','shipped',889.74,NOW()-INTERVAL'60 days') RETURNING id INTO o;
    INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES(o,p7,5,89.99),(o,p5,5,69.99),(o,p3,3,59.99);

    INSERT INTO orders(customer_id,customer_name,status,total_amount,created_at) VALUES(c3,'Premium Shop MChJ','shipped',519.84,NOW()-INTERVAL'55 days') RETURNING id INTO o;
    INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES(o,p4,8,44.99),(o,p6,10,19.99),(o,p1,6,12.99);

    -- May
    INSERT INTO orders(customer_id,customer_name,status,total_amount,created_at) VALUES(c4,'City Store YaTT','processing',749.88,NOW()-INTERVAL'30 days') RETURNING id INTO o;
    INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES(o,p7,4,89.99),(o,p2,6,34.99),(o,p5,4,69.99);

    INSERT INTO orders(customer_id,customer_name,status,total_amount,created_at) VALUES(c5,'Boutique Shop MChJ','processing',419.85,NOW()-INTERVAL'25 days') RETURNING id INTO o;
    INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES(o,p3,3,59.99),(o,p8,5,27.99),(o,p6,8,19.99);

    -- Jun
    INSERT INTO orders(customer_id,customer_name,status,total_amount,created_at) VALUES(c6,'Trend Clothes YaTT','pending',979.83,NOW()-INTERVAL'10 days') RETURNING id INTO o;
    INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES(o,p7,6,89.99),(o,p5,5,69.99),(o,p3,3,59.99);

    INSERT INTO orders(customer_id,customer_name,status,total_amount,created_at) VALUES(c1,'Style Market MChJ','pending',329.88,NOW()-INTERVAL'5 days') RETURNING id INTO o;
    INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES(o,p4,4,44.99),(o,p1,8,12.99),(o,p8,4,27.99);

    INSERT INTO orders(customer_id,customer_name,status,total_amount,created_at) VALUES(c2,'Fashion Plaza YaTT','pending',214.92,NOW()-INTERVAL'2 days') RETURNING id INTO o;
    INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES(o,p2,3,34.99),(o,p6,6,19.99),(o,p1,3,12.99);

    -- Activity log
    INSERT INTO activity_log(user_name,action,entity_type,created_at) VALUES
      ('Admin','Tizimga kirdi','auth',NOW()-INTERVAL'2 hours'),
      ('Admin','Yangi mahsulot qo''shildi: Classic White Tee','product',NOW()-INTERVAL'1 day'),
      ('Admin','Buyurtma holati o''zgartirildi: delivered','order',NOW()-INTERVAL'1 day'),
      ('Admin','Yangi mijoz qo''shildi: Style Market MChJ','customer',NOW()-INTERVAL'2 days'),
      ('Admin','Buyurtma yaratildi','order',NOW()-INTERVAL'3 days');
  END IF;
END $$;
