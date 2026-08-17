import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartItem {
  final int id;
  final int variantId;
  final String name;
  final double price;
  int quantity;
  final int availableStock;

  CartItem({
    required this.id, 
    required this.variantId, 
    required this.name, 
    required this.price, 
    this.quantity = 1,
    required this.availableStock,
  });
}

class CartProvider with ChangeNotifier {
  final Map<int, CartItem> _items = {};
  
  // Stocke les infos de la promo active: {percent, productId, code}
  Map<String, dynamic>? _activePromo; 

  Map<int, CartItem> get items => {..._items};
  String? get promoCode => _activePromo?['code'];
  double get discountPercent => _activePromo != null ? (_activePromo!['percent'] as num).toDouble() : 0.0;

  int get totalQuantity {
    var count = 0;
    _items.forEach((key, item) {
      count += item.quantity;
    });
    return count;
  }

  double get subtotal {
    var total = 0.0;
    _items.forEach((key, item) {
      total += item.price * item.quantity;
    });
    return total;
  }

  double get discountAmount {
    if (_activePromo == null) return 0.0;
    
    double percent = (_activePromo!['percent'] as num).toDouble();
    int? productId = _activePromo!['productId'];

    if (productId != null) {
      // Réduction par produit
      if (_items.containsKey(productId)) {
        CartItem item = _items[productId]!;
        return (item.price * item.quantity) * (percent / 100);
      }
      return 0.0; // Produit non présent dans le panier
    } else {
      // Réduction globale
      return subtotal * (percent / 100);
    }
  }

  double get totalAmount => subtotal - discountAmount;

  Future<void> applyPromoCode(String code) async {
    final now = DateTime.now().toIso8601String();

    final response = await Supabase.instance.client
        .from('promos')
        .select('discount_percent, start_date, expiry_date, product_id')
        .eq('code', code)
        .eq('is_active', true)
        .lte('start_date', now)
        .gte('expiry_date', now)
        .maybeSingle();

    if (response != null) {
      _activePromo = {
        'code': code,
        'percent': response['discount_percent'],
        'productId': response['product_id'], // Peut être null
      };
      notifyListeners();
    } else {
      _activePromo = null;
      notifyListeners();
      throw Exception('Code promo invalide, expiré ou pas encore actif');
    }
  }

  bool addItem(int productId, int variantId, String name, double price, int availableStock) {
    if (_items.containsKey(productId)) {
      if (_items[productId]!.quantity < availableStock) {
        _items.update(
          productId,
          (existing) => CartItem(
            id: existing.id,
            variantId: variantId,
            name: existing.name,
            price: existing.price,
            quantity: existing.quantity + 1,
            availableStock: availableStock,
          ),
        );
        notifyListeners();
        return true;
      }
      return false; // Stock atteint
    } else {
      if (availableStock > 0) {
        _items.putIfAbsent(
          productId,
          () => CartItem(id: productId, variantId: variantId, name: name, price: price, availableStock: availableStock),
        );
        notifyListeners();
        return true;
      }
      return false; // Stock insuffisant
    }
  }

  void removeItem(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void decrementItem(int productId) {
    if (!_items.containsKey(productId)) return;
    
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existing) => CartItem(
          id: existing.id,
          variantId: existing.variantId,
          name: existing.name,
          price: existing.price,
          quantity: existing.quantity - 1,
          availableStock: existing.availableStock,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }
}
