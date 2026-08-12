-- Politique pour permettre aux utilisateurs d'insérer des paiements liés à leurs propres commandes
CREATE POLICY "Users can insert payments for their own orders" ON payments 
FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM orders
    WHERE orders.id = payments.order_id
    AND orders.user_id = auth.uid()
  )
);

-- Politique pour permettre aux utilisateurs de voir leurs propres paiements
CREATE POLICY "Users can view their own payments" ON payments 
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM orders
    WHERE orders.id = payments.order_id
    AND orders.user_id = auth.uid()
  )
);
