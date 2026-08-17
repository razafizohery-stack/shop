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
  final _descriptionController = TextEditingController();
  
  List<Map<String, dynamic>> _variants = [];
  final List<String> _sizeTypes = ['Taille (XS/S/M/L/XL)', 'Pointure', 'Pouces', 'Standard'];

  int? _selectedCategoryId;
  List<dynamic> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _addVariant(); // Add one initial variant
  }

  void _addVariant() {
    setState(() {
      _variants.add({
        'color': null, // Store color value directly
        'sizeType': _sizeTypes.first,
        'sizeValueController': TextEditingController(),
        'quantityController': TextEditingController(),
        'imageUrlController': TextEditingController(),
      });
    });
  }

  void _removeVariant(int index) {
    setState(() {
      _variants[index]['sizeValueController'].dispose();
      _variants[index]['quantityController'].dispose();
      _variants[index]['imageUrlController'].dispose();
      _variants.removeAt(index);
    });
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
      
      final productResponse = await Supabase.instance.client.from('products').insert({
        'name': _nameController.text,
        'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
        'price': double.parse(_priceController.text),
        'category_id': _selectedCategoryId,
        'seller_id': user?.id,
      }).select().single();

      final productId = productResponse['id'];

      for (var variant in _variants) {
        await Supabase.instance.client.from('product_variants').insert({
          'product_id': productId,
          'color': variant['color'],
          'size': variant['sizeValueController'].text.isEmpty ? null : variant['sizeValueController'].text,
          'size_type': variant['sizeType'],
          'quantity': int.tryParse(variant['quantityController'].text) ?? 0,
          'image_url': variant['imageUrlController'].text.isEmpty ? null : variant['imageUrlController'].text,
        });
      }

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
    _descriptionController.dispose();
    for (var v in _variants) {
      v['sizeValueController'].dispose();
      v['quantityController'].dispose();
      v['imageUrlController'].dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Produit', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Informations Générales'),
            _buildTextField(_nameController, 'Nom du produit', Icons.title),
            _buildTextField(_priceController, 'Prix (€)', Icons.euro, keyboardType: TextInputType.number),
            _buildTextField(_descriptionController, 'Description', Icons.description, maxLines: 3),
            DropdownButtonFormField(
              decoration: const InputDecoration(labelText: 'Catégorie', prefixIcon: Icon(Icons.category), border: OutlineInputBorder()),
              items: _categories.map((c) => DropdownMenuItem(value: c['id'], child: Text(c['name']))).toList(),
              onChanged: (val) => setState(() => _selectedCategoryId = val as int),
            ),
            const SizedBox(height: 30),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('Variantes'),
                ElevatedButton.icon(
                  onPressed: _addVariant,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            ..._variants.asMap().entries.map((entry) => _buildVariantCard(entry.key, entry.value)).toList(),
            
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: _isLoading ? const CircularProgressIndicator() : const Text('Enregistrer le produit', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder()),
        keyboardType: keyboardType,
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildVariantCard(int index, Map<String, dynamic> v) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Variante ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeVariant(index)),
              ],
            ),
            const Text('Couleur'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                Colors.red, Colors.blue, Colors.green, Colors.black, Colors.white, Colors.yellow, Colors.grey,
              ].map((color) {
                bool isSelected = v['color'] == color.value.toString();
                return GestureDetector(
                  onTap: () => setState(() => v['color'] = color.value.toString()),
                  child: CircleAvatar(
                    backgroundColor: color == Colors.white ? Colors.grey[300] : color,
                    radius: 18,
                    child: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField(
              value: v['sizeType'],
              decoration: const InputDecoration(labelText: 'Type de taille', border: OutlineInputBorder()),
              items: _sizeTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) => setState(() => v['sizeType'] = val),
            ),
            const SizedBox(height: 15),
            TextField(controller: v['sizeValueController'], decoration: const InputDecoration(labelText: 'Valeur (ex: XL, 42)', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: v['imageUrlController'], decoration: const InputDecoration(labelText: 'URL Image', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: v['quantityController'], decoration: const InputDecoration(labelText: 'Quantité', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          ],
        ),
      ),
    );
  }
}
