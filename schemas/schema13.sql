-- Migration pour lier les promotions aux produits
CREATE TABLE product_promos (
  id SERIAL PRIMARY KEY,
  product_id INTEGER REFERENCES products(id) ON DELETE CASCADE NOT NULL,
  discount_percent DECIMAL NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

ALTER TABLE product_promos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public product promos are viewable by everyone" ON product_promos FOR SELECT USING (true);
CREATE POLICY "Vendeurs and Admins can insert their product promos" ON product_promos FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT seller_id FROM products WHERE id = product_id)
);
