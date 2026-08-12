-- Migration pour améliorer la structure des produits et catégories
-- (Pas de changement requis sur les tables existantes, mais ajout d'un index pour la performance)
CREATE INDEX idx_products_category_id ON products(category_id);
