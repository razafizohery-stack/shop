-- Ajout des colonnes pour les détails du payeur dans la table payments
ALTER TABLE payments ADD COLUMN IF NOT EXISTS payer_name TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS payer_phone TEXT;
