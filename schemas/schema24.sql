-- Ajout de la colonne pour le lieu de livraison dans la table payments
ALTER TABLE payments ADD COLUMN IF NOT EXISTS delivery_location TEXT;
