import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class PromoScreen extends StatefulWidget {
  const PromoScreen({super.key});

  @override
  State<PromoScreen> createState() => _PromoScreenState();
}

class _PromoScreenState extends State<PromoScreen> {
  Future<List<Map<String, dynamic>>> _fetchProductsWithPromos() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];
    final products = await Supabase.instance.client
        .from('products')
        .select('id, name, price')
        .eq('seller_id', user.id);

    final promos = await Supabase.instance.client
        .from('product_promos')
        .select('id, product_id, discount_percent, is_active');

    return (products as List).map((product) {
      final promo = promos.firstWhere(
        (p) => p['product_id'] == product['id'],
        orElse: () => {},
      );
      return {...product as Map<String, dynamic>, 'promo': promo.isNotEmpty ? promo : null};
    }).toList().cast<Map<String, dynamic>>();
  }

  Future<void> _deactivatePromo(int promoId) async {
    await Supabase.instance.client
        .from('product_promos')
        .update({'is_active': false})
        .eq('id', promoId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promotion désactivée')));
      setState(() {}); // Rafraîchir l'écran
    }
  }

  // ... (dans l'itemBuilder de la liste)
  // Mise à jour de l'affichage et du bouton :
  /*
  subtitle: Text(promo != null && promo['is_active'] == true
    ? 'Promo active: ${promo['discount_percent']}%' 
    : 'Aucune promo active'),
  trailing: promo != null && promo['is_active'] == true
    ? IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => _deactivatePromo(promo['id']),
      )
  */

  void _showAddPromoDialog(int productId) {
    final discountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une promotion'),
        content: TextField(
          controller: discountController,
          decoration: const InputDecoration(labelText: 'Pourcentage de réduction (%)'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final discount = double.tryParse(discountController.text);
              if (discount != null) {
                await Supabase.instance.client.from('product_promos').insert({
                  'product_id': productId,
                  'discount_percent': discount,
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promotion appliquée')));
                  setState(() {}); // Rafraîchir l'écran
                }
              }
            },
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes Promotions')),
      body: FutureBuilder(
        future: _fetchProductsWithPromos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final products = snapshot.data as List<Map<String, dynamic>>;
          if (products.isEmpty) return const Center(child: Text('Aucun produit pour le moment'));

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final promo = product['promo'];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(promo != null && promo['is_active'] == true
                    ? 'Promo active: ${promo['discount_percent']}%' 
                    : 'Aucune promo active'),
                  trailing: promo != null && promo['is_active'] == true
                    ? IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deactivatePromo(promo['id']),
                      )
                    : IconButton(
                        icon: const Icon(Icons.local_offer),
                        onPressed: () => _showAddPromoDialog(product['id']),
                      ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
