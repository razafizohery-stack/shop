-- Migration pour ajouter 'is_active' aux promos produits
ALTER TABLE product_promos ADD COLUMN is_active BOOLEAN DEFAULT true;
