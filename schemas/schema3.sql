-- Insérer les produits fictifs dans la table products de Supabase
-- Assurez-vous que la table categories existe et contient au moins une catégorie,
-- ou modifiez cette requête si vous n'avez pas encore configuré les catégories.

INSERT INTO public.products (id, name, price, image_url)
VALUES 
  (1, 'Robe d''été', 29.99, 'https://picsum.photos/200/300?random=1'),
  (2, 'Chemise Blanche', 19.99, 'https://picsum.photos/200/300?random=2'),
  (3, 'Jean Slim', 39.99, 'https://picsum.photos/200/300?random=3'),
  (4, 'Basket Urban', 49.99, 'https://picsum.photos/200/300?random=4')
ON CONFLICT (id) DO NOTHING;
