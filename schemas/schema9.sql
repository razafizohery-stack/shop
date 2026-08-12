-- Table des catégories
CREATE TABLE IF NOT EXISTS categories (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL
);

-- Activation de RLS
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Politiques de sécurité
CREATE POLICY "Categories are viewable by everyone" ON categories FOR SELECT USING (true);

CREATE POLICY "Vendeurs and Admins can insert categories" ON categories FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT id FROM profiles WHERE role IN ('vendeur', 'admin'))
);
