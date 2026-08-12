import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartItem {
  final int id;
  final String name;
  final double price;
  int quantity;

  CartItem({required this.id, required this.name, required this.price, this.quantity = 1});
}

class CartProvider with ChangeNotifier {
  final Map<int, CartItem> _items = {};
  double _discountPercent = 0.0;
  String? _promoCode;

  Map<int, CartItem> get items => {..._items};
  double get discountPercent => _discountPercent;
  String? get promoCode => _promoCode;

  double get subtotal {
    var total = 0.0;
    _items.forEach((key, item) {
      total += item.price * item.quantity;
    });
    return total;
  }

  double get discountAmount => subtotal * (_discountPercent / 100);
  double get totalAmount => subtotal - discountAmount;

  Future<void> applyPromoCode(String code) async {
    final response = await Supabase.instance.client
        .from('promos')
        .select('discount_percent')
        .eq('code', code)
        .eq('is_active', true)
        .maybeSingle();

    if (response != null) {
      _discountPercent = (response['discount_percent'] as num).toDouble();
      _promoCode = code;
      notifyListeners();
    } else {
      throw Exception('Code promo invalide ou expiré');
    }
  }

  void addItem(int productId, String name, double price) {
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (existing) => CartItem(
          id: existing.id,
          name: existing.name,
          price: existing.price,
          quantity: existing.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        productId,
        () => CartItem(id: productId, name: name, price: price),
      );
    }
    notifyListeners();
  }

  void removeItem(int productId) {
    _items.remove(productId);
    notifyListeners();
  }
}
