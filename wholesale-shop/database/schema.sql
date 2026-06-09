-- DRAPE Wholesale — Database Schema

CREATE TABLE IF NOT EXISTS users (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100)        NOT NULL,
    email       VARCHAR(150) UNIQUE NOT NULL,
    password    VARCHAR(255)        NOT NULL,
    role        VARCHAR(20)         NOT NULL DEFAULT 'customer',
    created_at  TIMESTAMP           NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS products (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(200)    NOT NULL,
    category    VARCHAR(100)    NOT NULL,
    description TEXT,
    price       NUMERIC(10,2)   NOT NULL CHECK (price >= 0),
    stock       INTEGER         NOT NULL DEFAULT 0 CHECK (stock >= 0),
    image_url   TEXT,
    created_at  TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP       NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS orders (
    id              SERIAL PRIMARY KEY,
    user_id         INTEGER         REFERENCES users(id) ON DELETE SET NULL,
    customer_name   VARCHAR(150),
    customer_phone  VARCHAR(50),
    status          VARCHAR(30)     NOT NULL DEFAULT 'pending',
    total_amount    NUMERIC(10,2)   NOT NULL CHECK (total_amount >= 0),
    shipping_addr   TEXT,
    created_at      TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP       NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS order_items (
    id          SERIAL PRIMARY KEY,
    order_id    INTEGER         NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id  INTEGER         REFERENCES products(id) ON DELETE SET NULL,
    quantity    INTEGER         NOT NULL CHECK (quantity > 0),
    unit_price  NUMERIC(10,2)   NOT NULL CHECK (unit_price >= 0)
);

CREATE INDEX IF NOT EXISTS idx_products_category  ON products(category);
CREATE INDEX IF NOT EXISTS idx_orders_user        ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order  ON order_items(order_id);

-- ── Admin user: admin777@gmail.com / bishbash ─────────────────
INSERT INTO users (name, email, password, role) VALUES
    ('Admin', 'admin777@gmail.com',
     '$2b$10$rnTcLKovVqb9cv8ATaBMl.McOVXIsyMhvLQ2ECYSQCeCfvzmOGuQ2', 'admin')
ON CONFLICT (email) DO NOTHING;

-- ── Products ──────────────────────────────────────────────────
INSERT INTO products (name, category, description, price, stock, image_url) VALUES
    ('Classic White Tee',   'T-Shirts',  'Premium 100% cotton unisex t-shirt.',     12.99, 480, 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400'),
    ('Slim Fit Chinos',     'Trousers',  'Modern slim-fit chinos, stretch fabric.',  34.99, 185, 'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=400'),
    ('Denim Jacket',        'Jackets',   'Vintage-wash denim jacket, unisex cut.',   59.99, 108, 'https://images.unsplash.com/photo-1551537482-f2075a1d41f2?w=400'),
    ('Floral Summer Dress', 'Dresses',   'Lightweight floral print midi dress.',     44.99,  72, 'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=400'),
    ('Merino Wool Sweater', 'Knitwear',  'Fine merino wool crew-neck sweater.',      69.99, 138, 'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=400'),
    ('Athletic Shorts',     'Sportswear','Quick-dry athletic shorts with liner.',    19.99, 285, 'https://images.unsplash.com/photo-1539185441755-769473a23570?w=400'),
    ('Linen Blazer',        'Jackets',   'Relaxed linen blazer for warm weather.',   89.99,  54, 'https://images.unsplash.com/photo-1594938298603-c8148c4b984b?w=400'),
    ('Striped Polo Shirt',  'T-Shirts',  'Classic striped polo, pique cotton.',      27.99, 237, 'https://images.unsplash.com/photo-1586790170083-2f9ceadc732d?w=400')
ON CONFLICT DO NOTHING;

-- ── Seed orders (6 months of data for reports) ────────────────
DO $$
DECLARE
  p1 INT; p2 INT; p3 INT; p4 INT; p5 INT; p6 INT; p7 INT; p8 INT;
  o  INT;
BEGIN
  SELECT id INTO p1 FROM products WHERE name='Classic White Tee'   LIMIT 1;
  SELECT id INTO p2 FROM products WHERE name='Slim Fit Chinos'     LIMIT 1;
  SELECT id INTO p3 FROM products WHERE name='Denim Jacket'        LIMIT 1;
  SELECT id INTO p4 FROM products WHERE name='Floral Summer Dress' LIMIT 1;
  SELECT id INTO p5 FROM products WHERE name='Merino Wool Sweater' LIMIT 1;
  SELECT id INTO p6 FROM products WHERE name='Athletic Shorts'     LIMIT 1;
  SELECT id INTO p7 FROM products WHERE name='Linen Blazer'        LIMIT 1;
  SELECT id INTO p8 FROM products WHERE name='Striped Polo Shirt'  LIMIT 1;

  IF (SELECT COUNT(*) FROM orders) = 0 THEN

    -- January
    INSERT INTO orders(customer_name,customer_phone,status,total_amount,created_at) VALUES('Sarah Mitchell','+44 7700 900142','delivered',389.85,NOW()-INTERVAL'150 days') RETURNING id INTO o;
    INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES(o,p1,10,12.99),(o,p2,5,34.99),(o,p3,2,59.99);

    INSERT INTO orders(customer_name,customer_phone,status,total_amount,created_at) VALUES('James Thornton','+44 7911 123456','delivered',539.82,NOW()-INTERVAL'145 days') RETURNING id INTO o;
    INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES(o,p5,4,69.99),(o,p7,3,89.99),(o,p6,6,19.99);

    -- February
    INSERT INTO orders(customer_name,customer_phone,status,total_amount,created_at) VALUES('Aisha Patel','+44 7800 654321','delivered',479.88,NOW()-INTERVAL'120 days') RETURNING id INTO o;
    INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES(o,p4,6,44.99),(o,p8,8,27.99);

    INSERT INTO orders(customer_name,customer_phone,status,total_amount,created_at) VALUES('Luke Davidson','+44 7555 112233','delivered',719.76,NOW()-INTERVAL'115 days') RETURNING id INTO o;
    INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES(o,p3,4,59.99),(o,p7,4,89.99),(o,p2,4,34.99);

    INSERT INTO orders(customer_name,customer_phone,status,total_amount,created_at) VALUES('Mei Zhang','+44 7444 998877','cancelled',129.90,NOW()-INTERVAL'110 days') RETURNING id INTO o;
    INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES(o,p1,10,12.99);

    -- March
    INSERT INTO orders(customer_name,customer_phone,status,total_amount,created_at) VALUES('Fatima Al-Hassan','+44 7333 776655','delivered',629.91,NOW()-INTERVAL'90 days') RETURNING id INTO o;
    INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES(o,p5,3,69.99),(o,p3,3,59.99),(o,p4,5,44.99),(o,p6,5,19.99);

    INSERT INTO orders(customer_name,customer_phone,status,total_amount,created_at) VALUES('Oliver Barnes','+44 7222 334455','delivered',359.88,NOW()-INTERVAL'85 days') RETURNING id INTO o;
    INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES(o,p8,6,27.99),(o,p2,4,34.99),(o,p1,4,12.99);

    -- April
    INSERT INTO orders(customer_name,customer_phone,status,total_amount,created_at) VALUES('Priya Singh','+44 7666 221100','shipped',889.74,NOW()-INTERVAL'60 days') RETURNING id INTO o;
    INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES(o,p7,5,89.99),(o,p5,5,69.99),(o,p3,3,59.99);

    INSERT INTO orders(customer_name,customer_phone,status,total_amount,created_at) VALUES('Daniel Kozlov','+44 7777 445566','shipped',519.84,NOW()-INTERVAL'55 days') RETURNING id INTO o;
    INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES(o,p4,8,44.99),(o,p6,10,19.99),(o,p1,6,12.99);

    -- May
    INSERT INTO orders(customer_name,customer_phone,status,total_amount,created_at) VALUES('Emily Watson','+44 7888 667788','processing',749.88,NOW()-INTERVAL'30 days') RETURNING id INTO o;
    INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES(o,p7,4,89.99),(o,p2,6,34.99),(o,p5,4,69.99);

    INSERT INTO orders(customer_name,customer_phone,status,total_amount,created_at) VALUES('Arjun Mehta','+44 7999 554433','processing',419.85,NOW()-INTERVAL'25 days') RETURNING id INTO o;
    INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES(o,p3,3,59.99),(o,p8,5,27.99),(o,p6,8,19.99);

    -- June (recent)
    INSERT INTO orders(customer_name,customer_phone,status,total_amount,created_at) VALUES('Sophie Turner','+44 7100 223344','pending',979.83,NOW()-INTERVAL'10 days') RETURNING id INTO o;
    INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES(o,p7,6,89.99),(o,p5,5,69.99),(o,p3,3,59.99);

    INSERT INTO orders(customer_name,customer_phone,status,total_amount,created_at) VALUES('Liam Okafor','+44 7200 112233','pending',329.88,NOW()-INTERVAL'5 days') RETURNING id INTO o;
    INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES(o,p4,4,44.99),(o,p1,8,12.99),(o,p8,4,27.99);

    INSERT INTO orders(customer_name,customer_phone,status,total_amount,created_at) VALUES('Chloe Bennett','+44 7300 998800','pending',214.92,NOW()-INTERVAL'2 days') RETURNING id INTO o;
    INSERT INTO order_items(order_id,product_id,quantity,unit_price) VALUES(o,p2,3,34.99),(o,p6,6,19.99),(o,p1,3,12.99);

  END IF;
END $$;
