import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/cart_provider.dart';
import 'payment_screen.dart';
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
// ...

  final _promoController = TextEditingController();

  Future<void> _applyPromo(CartProvider cart) async {
    try {
      await cart.applyPromoCode(_promoController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promo appliquée !')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _placeOrder(BuildContext context, CartProvider cart) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;

    final orderResponse = await supabase.from('orders').insert({
      'user_id': user.id,
      'total_amount': cart.totalAmount,
      'status': 'pending',
    }).select().single();

    final orderId = orderResponse['id'];

    for (var item in cart.items.values) {
      await supabase.from('order_items').insert({
        'order_id': orderId,
        'product_id': item.id,
        'quantity': item.quantity,
        'price': item.price,
      });
    }

    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaymentScreen(orderId: orderId, totalAmount: cart.totalAmount),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mon Panier', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: cart.items.isEmpty
          ? const Center(child: Text('Votre panier est vide', style: TextStyle(fontSize: 18)))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items.values.toList()[index];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Text('Quantité: ${item.quantity} | Prix: ${(item.price * item.quantity).toStringAsFixed(0)} MGA', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => cart.removeItem(item.id),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      // Promo Input
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _promoController,
                              decoration: const InputDecoration(labelText: 'Code Promo', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(onPressed: () => _applyPromo(cart), child: const Text('Appliquer')),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Totals
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sous-total:'),
                          Text('${cart.subtotal.toStringAsFixed(0)} MGA'),
                        ],
                      ),
                      if (cart.discountPercent > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Réduction (${cart.discountPercent}%):'),
                            Text('-${cart.discountAmount.toStringAsFixed(0)} MGA', style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('${cart.totalAmount.toStringAsFixed(0)} MGA', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: cart.items.isEmpty ? null : () => _placeOrder(context, cart),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Commander', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
