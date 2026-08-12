import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _colorController = TextEditingController();
  final _sizeController = TextEditingController();
  final _shoeSizeController = TextEditingController();
  final _quantityController = TextEditingController();
  int? _selectedCategoryId;
  List<dynamic> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final response = await Supabase.instance.client.from('categories').select();
    setState(() {
      _categories = response;
    });
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty || _selectedCategoryId == null) return;

    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      
      // 1. Insérer le produit
      final productResponse = await Supabase.instance.client.from('products').insert({
        'name': _nameController.text,
        'price': double.parse(_priceController.text),
        'image_url': _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
        'category_id': _selectedCategoryId,
        'seller_id': user?.id,
      }).select().single();

      final productId = productResponse['id'];

      // 2. Insérer la variante
      await Supabase.instance.client.from('product_variants').insert({
        'product_id': productId,
        'color': _colorController.text.isEmpty ? null : _colorController.text,
        'size': _sizeController.text.isEmpty ? null : _sizeController.text,
        'shoe_size': _shoeSizeController.text.isEmpty ? null : _shoeSizeController.text,
        'quantity': int.tryParse(_quantityController.text) ?? 0,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _colorController.dispose();
    _sizeController.dispose();
    _shoeSizeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un produit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nom')),
            TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Prix'), keyboardType: TextInputType.number),
            TextField(controller: _imageUrlController, decoration: const InputDecoration(labelText: 'URL Image')),
            DropdownButtonFormField(
              items: _categories.map((c) => DropdownMenuItem(value: c['id'], child: Text(c['name']))).toList(),
              onChanged: (val) => setState(() => _selectedCategoryId = val as int),
              decoration: const InputDecoration(labelText: 'Catégorie'),
            ),
            const Divider(),
            const Text('Variantes', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _colorController, decoration: const InputDecoration(labelText: 'Couleur')),
            TextField(controller: _sizeController, decoration: const InputDecoration(labelText: 'Taille (ex: XL, L)')),
            TextField(controller: _shoeSizeController, decoration: const InputDecoration(labelText: 'Pointure (si chaussure)')),
            TextField(controller: _quantityController, decoration: const InputDecoration(labelText: 'Quantité'), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _isLoading ? null : _submit, child: const Text('Ajouter')),
          ],
        ),
      ),
    );
  }
}
