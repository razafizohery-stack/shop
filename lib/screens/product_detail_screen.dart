import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _variants = [];
  bool _isLoading = true;
  dynamic _selectedVariant;

  @override
  void initState() {
    super.initState();
    _loadVariants();
  }

  Future<void> _loadVariants() async {
    final variants = await _supabase
        .from('product_variants')
        .select()
        .eq('product_id', widget.product['id']);
    
    setState(() {
      _variants = variants;
      _isLoading = false;
      if (_variants.isNotEmpty) {
        _selectedVariant = _variants.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  if (widget.product['image_url'] != null)
                    Container(
                      height: 300,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(widget.product['image_url']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  
                  // Détails
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.product['name'], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('${widget.product['price']} MGA', style: const TextStyle(fontSize: 22, color: Colors.green, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 24),
                        
                        const Text('Variantes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        
                        if (_variants.isEmpty)
                          const Text('Aucune variante disponible', style: TextStyle(color: Colors.grey)),
                        
                        ..._variants.map((v) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: RadioListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            title: Text('${v['color'] ?? 'N/A'} | ${v['size'] ?? ''} ${v['shoe_size'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: Text('Stock: ${v['quantity']}', style: TextStyle(color: v['quantity'] > 0 ? Colors.green : Colors.red)),
                            value: v,
                            groupValue: _selectedVariant,
                            onChanged: v['quantity'] > 0 ? (val) => setState(() => _selectedVariant = val) : null,
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _selectedVariant == null || _selectedVariant['quantity'] == 0
          ? null
          : Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Provider.of<CartProvider>(context, listen: false).addItem(
                    widget.product['id'],
                    '${widget.product['name']} (${_selectedVariant['color'] ?? ''} ${_selectedVariant['size'] ?? ''})',
                    widget.product['price'].toDouble(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajouté au panier !')));
                },
                child: const Text('AJOUTER AU PANIER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
    );
  }
}
