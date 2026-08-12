-- Migration pour ajouter le seller_id à la table 'products'
ALTER TABLE products 
ADD COLUMN seller_id UUID REFERENCES profiles(id);

-- Index pour accélérer la recherche des produits par vendeur
CREATE INDEX idx_products_seller_id ON products(seller_id);
