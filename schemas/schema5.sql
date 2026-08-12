-- Migration pour ajouter la colonne 'role' à la table 'profiles'
ALTER TABLE profiles 
ADD COLUMN role TEXT DEFAULT 'client' CHECK (role IN ('client', 'vendeur', 'admin'));
