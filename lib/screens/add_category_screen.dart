import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || _slugController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('categories').insert({
        'name': _nameController.text,
        'slug': _slugController.text,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter une catégorie')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nom de la catégorie')),
            TextField(controller: _slugController, decoration: const InputDecoration(labelText: 'Slug (ex: mode-femme)')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _isLoading ? null : _submit, child: const Text('Ajouter')),
          ],
        ),
      ),
    );
  }
}
