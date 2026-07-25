
/*
# Food Hub – Add order source, courier company, call history tracking

## Summary
Adds columns to track who placed an order (admin/staff/customer), which courier company was used, and a dedicated call history table for customer profiles.

## Modified Tables

### orders
- created_by_name: text — name of the person who created the order
- created_by_source: text — 'admin', 'staff', or 'customer'
- courier_company: text — e.g. Steadfast, RedX, Sundarban

### customers
- (no new columns, but updated_at triggers for real-time)

## New Tables

### customer_call_history
Tracks every status change and call event on a customer profile with timestamp.
- id, customer_id, customer_name, old_status, new_status, note, changed_by, changed_at
*/

-- Add columns to orders
ALTER TABLE orders ADD COLUMN IF NOT EXISTS created_by_name text DEFAULT '';
ALTER TABLE orders ADD COLUMN IF NOT EXISTS created_by_source text DEFAULT 'staff' CHECK (created_by_source IN ('admin','staff','customer'));
ALTER TABLE orders ADD COLUMN IF NOT EXISTS courier_company text DEFAULT '';

-- Add index for courier company queries
CREATE INDEX IF NOT EXISTS orders_courier_company_idx ON orders(courier_company);

-- Customer call history table
CREATE TABLE IF NOT EXISTS customer_call_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id uuid REFERENCES customers(id) ON DELETE CASCADE,
  customer_name text NOT NULL,
  old_status text,
  new_status text NOT NULL,
  note text DEFAULT '',
  changed_by text DEFAULT '',
  changed_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS customer_call_history_customer_idx ON customer_call_history(customer_id);
CREATE INDEX IF NOT EXISTS customer_call_history_changed_at_idx ON customer_call_history(changed_at);

ALTER TABLE customer_call_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "customer_call_history_select" ON customer_call_history;
CREATE POLICY "customer_call_history_select" ON customer_call_history FOR SELECT
TO authenticated USING (true);

DROP POLICY IF EXISTS "customer_call_history_insert" ON customer_call_history;
CREATE POLICY "customer_call_history_insert" ON customer_call_history FOR INSERT
TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "customer_call_history_update" ON customer_call_history;
CREATE POLICY "customer_call_history_update" ON customer_call_history FOR UPDATE
TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "customer_call_history_delete" ON customer_call_history;
CREATE POLICY "customer_call_history_delete" ON customer_call_history FOR DELETE
TO authenticated USING (true);
