-- Migration pour gérer les prix par région/nation
CREATE TABLE product_prices (
  id SERIAL PRIMARY KEY,
  product_id INTEGER REFERENCES products(id) ON DELETE CASCADE NOT NULL,
  region TEXT NOT NULL, -- e.g., 'chine', 'mada'
  price DECIMAL NOT NULL,
  currency TEXT DEFAULT 'MGA', -- e.g., 'USD', 'MGA'
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Activation de RLS (Row Level Security)
ALTER TABLE product_prices ENABLE ROW LEVEL SECURITY;

-- Politique : Tout le monde peut voir les prix
CREATE POLICY "Public prices are viewable by everyone" ON product_prices FOR SELECT USING (true);
