
/*
# Food Hub – Core Schema

## Summary
Full schema for the Food Hub business management app.

## New Tables

### user_profiles
Stores role info for Supabase Auth users.
- id: references auth.users
- role: 'admin' or 'staff'
- name: display name
- created_at

### product_categories
- id, name, created_at

### products
- id, name, category_id, cost_price, sell_price, unit (kg/pcs/etc)
- total_stock: running total stock quantity
- created_at, updated_at

### stock_history
- id, product_id, quantity_added, note, created_at

### customers
- id, name, phone, address, status (all/call_me/not_now/pending/unreachable/ordered)
- last_order_date, last_order_amount, last_order_weight, last_order_product
- notes, created_at, updated_at

### orders
- id, customer_id, status (pending/confirmed/delivered/returned/cancelled)
- total_amount, total_weight, delivery_charge, discount, comment
- created_at, updated_at, confirmed_at, delivered_at
- courier_tracking_id, courier_name

### order_items
- id, order_id, product_id, product_name (snapshot), quantity, unit_price, total_price

### call_reports
- id, customer_id, customer_name (snapshot), phone (snapshot)
- status (unreachable/pending/not_now/ordered), note
- called_at

### monthly_targets
- id, year, month, target_kg, target_amount

### returned_parcels
- id, order_id, customer_id, customer_name, phone, product_name, quantity, reason
- returned_at

## Security
- RLS enabled on all tables
- Admin and authenticated users have full access
- Anon role gets NO access (login is required)
*/

-- User Profiles
CREATE TABLE IF NOT EXISTS user_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL DEFAULT '',
  role text NOT NULL DEFAULT 'staff' CHECK (role IN ('admin', 'staff')),
  created_at timestamptz DEFAULT now()
);

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "user_profiles_select" ON user_profiles;
CREATE POLICY "user_profiles_select" ON user_profiles FOR SELECT
TO authenticated USING (true);

DROP POLICY IF EXISTS "user_profiles_insert" ON user_profiles;
CREATE POLICY "user_profiles_insert" ON user_profiles FOR INSERT
TO authenticated WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "user_profiles_update" ON user_profiles;
CREATE POLICY "user_profiles_update" ON user_profiles FOR UPDATE
TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "user_profiles_delete" ON user_profiles;
CREATE POLICY "user_profiles_delete" ON user_profiles FOR DELETE
TO authenticated USING (auth.uid() = id);

-- Product Categories
CREATE TABLE IF NOT EXISTS product_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE product_categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "product_categories_select" ON product_categories;
CREATE POLICY "product_categories_select" ON product_categories FOR SELECT
TO authenticated USING (true);

DROP POLICY IF EXISTS "product_categories_insert" ON product_categories;
CREATE POLICY "product_categories_insert" ON product_categories FOR INSERT
TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "product_categories_update" ON product_categories;
CREATE POLICY "product_categories_update" ON product_categories FOR UPDATE
TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "product_categories_delete" ON product_categories;
CREATE POLICY "product_categories_delete" ON product_categories FOR DELETE
TO authenticated USING (true);

-- Products
CREATE TABLE IF NOT EXISTS products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  category_id uuid REFERENCES product_categories(id) ON DELETE SET NULL,
  cost_price numeric(12,2) NOT NULL DEFAULT 0,
  sell_price numeric(12,2) NOT NULL DEFAULT 0,
  unit text NOT NULL DEFAULT 'kg',
  total_stock numeric(12,3) NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "products_select" ON products;
CREATE POLICY "products_select" ON products FOR SELECT
TO authenticated USING (true);

DROP POLICY IF EXISTS "products_insert" ON products;
CREATE POLICY "products_insert" ON products FOR INSERT
TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "products_update" ON products;
CREATE POLICY "products_update" ON products FOR UPDATE
TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "products_delete" ON products;
CREATE POLICY "products_delete" ON products FOR DELETE
TO authenticated USING (true);

-- Stock History
CREATE TABLE IF NOT EXISTS stock_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  quantity_added numeric(12,3) NOT NULL DEFAULT 0,
  note text,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE stock_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "stock_history_select" ON stock_history;
CREATE POLICY "stock_history_select" ON stock_history FOR SELECT
TO authenticated USING (true);

DROP POLICY IF EXISTS "stock_history_insert" ON stock_history;
CREATE POLICY "stock_history_insert" ON stock_history FOR INSERT
TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "stock_history_update" ON stock_history;
CREATE POLICY "stock_history_update" ON stock_history FOR UPDATE
TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "stock_history_delete" ON stock_history;
CREATE POLICY "stock_history_delete" ON stock_history FOR DELETE
TO authenticated USING (true);

-- Customers
CREATE TABLE IF NOT EXISTS customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  phone text NOT NULL,
  address text NOT NULL DEFAULT '',
  status text NOT NULL DEFAULT 'call_me' CHECK (status IN ('call_me','not_now','pending','unreachable','ordered')),
  last_order_date date,
  last_order_amount numeric(12,2),
  last_order_weight numeric(12,3),
  last_order_product text,
  notes text DEFAULT '',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS customers_phone_idx ON customers(phone);
CREATE INDEX IF NOT EXISTS customers_status_idx ON customers(status);
CREATE INDEX IF NOT EXISTS customers_name_idx ON customers(name);

ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "customers_select" ON customers;
CREATE POLICY "customers_select" ON customers FOR SELECT
TO authenticated USING (true);

DROP POLICY IF EXISTS "customers_insert" ON customers;
CREATE POLICY "customers_insert" ON customers FOR INSERT
TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "customers_update" ON customers;
CREATE POLICY "customers_update" ON customers FOR UPDATE
TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "customers_delete" ON customers;
CREATE POLICY "customers_delete" ON customers FOR DELETE
TO authenticated USING (true);

-- Orders
CREATE TABLE IF NOT EXISTS orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id uuid NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','confirmed','delivered','returned','cancelled')),
  total_amount numeric(12,2) NOT NULL DEFAULT 0,
  total_weight numeric(12,3) NOT NULL DEFAULT 0,
  delivery_charge numeric(12,2) NOT NULL DEFAULT 0,
  discount numeric(12,2) NOT NULL DEFAULT 0,
  comment text DEFAULT '',
  courier_tracking_id text DEFAULT '',
  courier_name text DEFAULT '',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  confirmed_at timestamptz,
  delivered_at timestamptz
);

CREATE INDEX IF NOT EXISTS orders_customer_idx ON orders(customer_id);
CREATE INDEX IF NOT EXISTS orders_status_idx ON orders(status);
CREATE INDEX IF NOT EXISTS orders_created_at_idx ON orders(created_at);

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "orders_select" ON orders;
CREATE POLICY "orders_select" ON orders FOR SELECT
TO authenticated USING (true);

DROP POLICY IF EXISTS "orders_insert" ON orders;
CREATE POLICY "orders_insert" ON orders FOR INSERT
TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "orders_update" ON orders;
CREATE POLICY "orders_update" ON orders FOR UPDATE
TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "orders_delete" ON orders;
CREATE POLICY "orders_delete" ON orders FOR DELETE
TO authenticated USING (true);

-- Order Items
CREATE TABLE IF NOT EXISTS order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id uuid REFERENCES products(id) ON DELETE SET NULL,
  product_name text NOT NULL,
  quantity numeric(12,3) NOT NULL DEFAULT 1,
  unit text NOT NULL DEFAULT 'kg',
  unit_price numeric(12,2) NOT NULL DEFAULT 0,
  total_price numeric(12,2) NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS order_items_order_idx ON order_items(order_id);

ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "order_items_select" ON order_items;
CREATE POLICY "order_items_select" ON order_items FOR SELECT
TO authenticated USING (true);

DROP POLICY IF EXISTS "order_items_insert" ON order_items;
CREATE POLICY "order_items_insert" ON order_items FOR INSERT
TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "order_items_update" ON order_items;
CREATE POLICY "order_items_update" ON order_items FOR UPDATE
TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "order_items_delete" ON order_items;
CREATE POLICY "order_items_delete" ON order_items FOR DELETE
TO authenticated USING (true);

-- Call Reports
CREATE TABLE IF NOT EXISTS call_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id uuid REFERENCES customers(id) ON DELETE SET NULL,
  customer_name text NOT NULL,
  phone text NOT NULL,
  status text NOT NULL CHECK (status IN ('unreachable','pending','not_now','ordered')),
  note text DEFAULT '',
  called_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS call_reports_called_at_idx ON call_reports(called_at);

ALTER TABLE call_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "call_reports_select" ON call_reports;
CREATE POLICY "call_reports_select" ON call_reports FOR SELECT
TO authenticated USING (true);

DROP POLICY IF EXISTS "call_reports_insert" ON call_reports;
CREATE POLICY "call_reports_insert" ON call_reports FOR INSERT
TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "call_reports_update" ON call_reports;
CREATE POLICY "call_reports_update" ON call_reports FOR UPDATE
TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "call_reports_delete" ON call_reports;
CREATE POLICY "call_reports_delete" ON call_reports FOR DELETE
TO authenticated USING (true);

-- Monthly Targets
CREATE TABLE IF NOT EXISTS monthly_targets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  year int NOT NULL,
  month int NOT NULL CHECK (month BETWEEN 1 AND 12),
  target_kg numeric(12,3) NOT NULL DEFAULT 0,
  target_amount numeric(12,2) NOT NULL DEFAULT 0,
  UNIQUE(year, month)
);

ALTER TABLE monthly_targets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "monthly_targets_select" ON monthly_targets;
CREATE POLICY "monthly_targets_select" ON monthly_targets FOR SELECT
TO authenticated USING (true);

DROP POLICY IF EXISTS "monthly_targets_insert" ON monthly_targets;
CREATE POLICY "monthly_targets_insert" ON monthly_targets FOR INSERT
TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "monthly_targets_update" ON monthly_targets;
CREATE POLICY "monthly_targets_update" ON monthly_targets FOR UPDATE
TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "monthly_targets_delete" ON monthly_targets;
CREATE POLICY "monthly_targets_delete" ON monthly_targets FOR DELETE
TO authenticated USING (true);

-- Returned Parcels
CREATE TABLE IF NOT EXISTS returned_parcels (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid REFERENCES orders(id) ON DELETE SET NULL,
  customer_id uuid REFERENCES customers(id) ON DELETE SET NULL,
  customer_name text NOT NULL,
  phone text NOT NULL,
  product_name text NOT NULL,
  quantity numeric(12,3) NOT NULL DEFAULT 1,
  amount numeric(12,2) NOT NULL DEFAULT 0,
  reason text DEFAULT '',
  returned_at timestamptz DEFAULT now()
);

ALTER TABLE returned_parcels ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "returned_parcels_select" ON returned_parcels;
CREATE POLICY "returned_parcels_select" ON returned_parcels FOR SELECT
TO authenticated USING (true);

DROP POLICY IF EXISTS "returned_parcels_insert" ON returned_parcels;
CREATE POLICY "returned_parcels_insert" ON returned_parcels FOR INSERT
TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "returned_parcels_update" ON returned_parcels;
CREATE POLICY "returned_parcels_update" ON returned_parcels FOR UPDATE
TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "returned_parcels_delete" ON returned_parcels;
CREATE POLICY "returned_parcels_delete" ON returned_parcels FOR DELETE
TO authenticated USING (true);
