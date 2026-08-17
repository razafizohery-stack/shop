import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _variants = [];
  List<dynamic> _comments = [];
  final _commentController = TextEditingController();
  bool _isLoading = true;
  dynamic _selectedVariant;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadVariants(), _loadComments()]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadVariants() async {
    final variants = await _supabase
        .from('product_variants')
        .select()
        .eq('product_id', widget.product['id']);
    
    setState(() {
      _variants = variants;
      if (_variants.isNotEmpty) {
        _selectedVariant = _variants.first;
      }
    });
  }

  Future<void> _loadComments() async {
    final comments = await _supabase
        .from('comments')
        .select('*, profiles(username)')
        .eq('product_id', widget.product['id'])
        .order('created_at', ascending: false);
    
    setState(() {
      _comments = comments;
    });
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) return;
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez vous connecter')));
      return;
    }
    
    await _supabase.from('comments').insert({
      'product_id': widget.product['id'],
      'user_id': user.id, // Explicitly include user_id
      'content': _commentController.text,
    });
    
    _commentController.clear();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _showEditDialog(BuildContext context) {
    final nameController = TextEditingController(text: widget.product['name']);
    final priceController = TextEditingController(text: widget.product['price'].toString());
    final Map<int, TextEditingController> variantControllers = {};
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier le produit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nom du produit')),
                TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prix')),
                const SizedBox(height: 20),
                const Text('Variantes (Quantité)', style: TextStyle(fontWeight: FontWeight.bold)),
                ..._variants.map((v) {
                  final controller = TextEditingController(text: v['quantity'].toString());
                  variantControllers[v['id']] = controller;
                  return ListTile(
                    title: Text('${v['color'] != null ? 'Variante: ' : ''}${v['size_type']}: ${v['size']}'),
                    subtitle: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantité'),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Mettre à jour le nom et le prix
                  print('DEBUG: Updating product ${widget.product['id']}');
                  final updateResponse = await _supabase.from('products').update({
                    'name': nameController.text,
                    'price': double.tryParse(priceController.text) ?? widget.product['price'],
                  }).eq('id', widget.product['id']).select();

                  print('DEBUG: Product update response: $updateResponse');

                  // Mettre à jour les quantités des variantes
                  for (var v in _variants) {
                    final val = variantControllers[v['id']]?.text;
                    if (val != null) {
                      await _supabase
                          .from('product_variants')
                          .update({'quantity': int.tryParse(val) ?? 0})
                          .eq('id', v['id']);
                    }
                  }
                  
                  // Rafraîchir les données
                  _loadVariants();
                  // Mettre à jour localement pour refléter dans l'UI
                  if (updateResponse.isNotEmpty) {
                    setState(() {
                      widget.product['name'] = updateResponse[0]['name'];
                      widget.product['price'] = updateResponse[0]['price'];
                    });
                  }
                  
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  print('DEBUG: Error updating product: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                  }
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final canEdit = auth.isAdmin || auth.isSeller;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditDialog(context),
            ),
          Consumer<CartProvider>(
            builder: (context, cart, child) => Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  ),
                ),
                if (cart.items.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text('${cart.totalQuantity}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  Container(
                    height: 350,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: _selectedVariant != null && _selectedVariant['image_url'] != null
                        ? Image.network(_selectedVariant['image_url'], fit: BoxFit.cover)
                        : const Icon(Icons.image, size: 100, color: Colors.grey),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.product['name'], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('${widget.product['price']} MGA', style: const TextStyle(fontSize: 22, color: Colors.green, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        if (widget.product['description'] != null)
                          Text(widget.product['description'], style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                        const SizedBox(height: 24),
                        
                        const Text('Sélectionner une variante', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        
                        ..._variants.map((v) {
                          bool isSelected = _selectedVariant == v;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedVariant = v),
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: isSelected ? Colors.blue[50] : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: isSelected ? Colors.blue : Colors.transparent),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    if (v['color'] != null)
                                      CircleAvatar(backgroundColor: Color(int.parse(v['color'])), radius: 15),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${v['size_type'] ?? ''}: ${v['size'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Text('Stock: ${v['quantity']}', style: TextStyle(color: v['quantity'] > 0 ? Colors.green : Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        const Divider(height: 40, thickness: 1),
                        const Text('Commentaires', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        
                        // Input field
                        TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Partagez votre avis...',
                            filled: true,
                            fillColor: Colors.grey[100],
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.send, color: Colors.blueAccent),
                              onPressed: _addComment,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Comments list
                        if (_comments.isEmpty)
                          const Text('Aucun commentaire pour le moment.', style: TextStyle(color: Colors.grey)),
                        ..._comments.map((c) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          color: Colors.grey[50],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(child: Text(c['profiles']?['username']?.toString().substring(0, 1).toUpperCase() ?? '?')),
                            title: Text(c['profiles']?['username'] ?? 'Anonyme', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(c['content']),
                            ),
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
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                Provider.of<CartProvider>(context, listen: false).addItem(
                  widget.product['id'],
                  _selectedVariant['id'],
                  '${widget.product['name']} (${_selectedVariant['size'] ?? ''})',
                  widget.product['price'].toDouble(),
                  _selectedVariant['quantity'] as int,
                );
                },
                child: const Text('AJOUTER AU PANIER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
    );
  }
}
