-- Activer RLS pour order_items
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Politique pour permettre aux utilisateurs d'insérer des articles dans les commandes qu'ils possèdent
CREATE POLICY "Users can insert items into their own orders" ON order_items 
FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM orders
    WHERE orders.id = order_items.order_id
    AND orders.user_id = auth.uid()
  )
);

-- Politique pour permettre aux utilisateurs de voir leurs propres articles de commande
CREATE POLICY "Users can view their own order items" ON order_items 
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM orders
    WHERE orders.id = order_items.order_id
    AND orders.user_id = auth.uid()
  )
);
