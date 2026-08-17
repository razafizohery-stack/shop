-- Ajout de la colonne pour l'ID du livreur dans la table orders
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_person_id UUID REFERENCES profiles(id);
