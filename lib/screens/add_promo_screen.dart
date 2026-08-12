import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddPromoScreen extends StatefulWidget {
  const AddPromoScreen({super.key});

  @override
  State<AddPromoScreen> createState() => _AddPromoScreenState();
}

class _AddPromoScreenState extends State<AddPromoScreen> {
  final _codeController = TextEditingController();
  final _discountController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_codeController.text.isEmpty || _discountController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('promos').insert({
        'code': _codeController.text.toUpperCase(),
        'discount_percent': double.parse(_discountController.text),
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
      appBar: AppBar(title: const Text('Ajouter une Promo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _codeController, decoration: const InputDecoration(labelText: 'Code (ex: SAVE10)')),
            TextField(controller: _discountController, decoration: const InputDecoration(labelText: 'Pourcentage (%)'), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _isLoading ? null : _submit, child: const Text('Créer')),
          ],
        ),
      ),
    );
  }
}
