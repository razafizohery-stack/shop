-- --- Ajouts pour la gestion du stock ---
-- 1. Ajouter la référence à la variante dans les articles de commande
ALTER TABLE order_items ADD COLUMN IF NOT EXISTS variant_id INTEGER REFERENCES product_variants(id);

-- 2. Fonction pour décrémenter le stock
CREATE OR REPLACE FUNCTION decrement_stock_on_payment()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'verified' AND (OLD.status IS NULL OR OLD.status != 'verified') THEN
    UPDATE product_variants
    SET quantity = product_variants.quantity - items.quantity
    FROM (SELECT variant_id, quantity FROM order_items WHERE order_id = NEW.order_id) AS items
    WHERE product_variants.id = items.variant_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Trigger pour appeler la fonction
DROP TRIGGER IF EXISTS trg_decrement_stock ON payments;
CREATE TRIGGER trg_decrement_stock
AFTER UPDATE ON payments
FOR EACH ROW
EXECUTE FUNCTION decrement_stock_on_payment();
