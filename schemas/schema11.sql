-- Migration pour la gestion des promotions
CREATE TABLE promos (
  id SERIAL PRIMARY KEY,
  code TEXT UNIQUE NOT NULL,
  discount_percent DECIMAL NOT NULL,
  expiry_date TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT true
);

-- Activation RLS
ALTER TABLE promos ENABLE ROW LEVEL SECURITY;

-- Politique : Tout le monde peut lire les promos actives
CREATE POLICY "Active promos are viewable by everyone" ON promos FOR SELECT USING (is_active = true);
