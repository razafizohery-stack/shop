-- Table des variantes de produits
CREATE TABLE product_variants (
  id SERIAL PRIMARY KEY,
  product_id INTEGER REFERENCES products(id) ON DELETE CASCADE NOT NULL,
  size TEXT, -- Pour XL, XXL, etc.
  color TEXT,
  shoe_size TEXT, -- Pour pointure
  quantity INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Activation de RLS
ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;

-- Politique de sécurité
CREATE POLICY "Public variants are viewable by everyone" ON product_variants FOR SELECT USING (true);
CREATE POLICY "Sellers can manage their variants" ON product_variants FOR ALL USING (auth.uid() IN (SELECT seller_id FROM products WHERE id = product_id));
