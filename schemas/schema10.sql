-- RLS pour la table 'products'

-- S'assurer que RLS est activé
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- 1. Lecture : tout le monde peut voir les produits
DROP POLICY IF EXISTS "Products are viewable by everyone" ON products;
CREATE POLICY "Products are viewable by everyone" ON products FOR SELECT USING (true);

-- 2. Insertion : seuls les vendeurs et admins peuvent ajouter des produits
DROP POLICY IF EXISTS "Vendeurs and Admins can insert products" ON products;
CREATE POLICY "Vendeurs and Admins can insert products" ON products FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT id FROM profiles WHERE role IN ('vendeur', 'admin'))
);

-- 3. Mise à jour : seuls les vendeurs et admins peuvent modifier les produits
DROP POLICY IF EXISTS "Vendeurs and Admins can update products" ON products;
CREATE POLICY "Vendeurs and Admins can update products" ON products FOR UPDATE USING (
  auth.uid() IN (SELECT id FROM profiles WHERE role IN ('vendeur', 'admin'))
);

-- 4. Suppression : seuls les vendeurs et admins peuvent supprimer les produits
DROP POLICY IF EXISTS "Vendeurs and Admins can delete products" ON products;
CREATE POLICY "Vendeurs and Admins can delete products" ON products FOR DELETE USING (
  auth.uid() IN (SELECT id FROM profiles WHERE role IN ('vendeur', 'admin'))
);
