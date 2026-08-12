import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';

class PaymentScreen extends StatefulWidget {  final String orderId;
  final double totalAmount;

  const PaymentScreen({super.key, required this.orderId, required this.totalAmount});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _refController = TextEditingController();
  final _nameController = TextEditingController();
  String? _selectedMethod;
  bool _isLoading = false;

  final Map<String, String> _numbers = {
    'Mvola': '034 00 000 01',
    'Orange Money': '032 00 000 02',
    'Airtel Money': '033 00 000 03',
  };

  final Map<String, String> _logos = {
    'Mvola': 'assets/mvl.png',
    'Orange Money': 'assets/org.png',
    'Airtel Money': 'assets/art.png',
  };

  Future<void> _submitPayment() async {
    if (_refController.text.isEmpty || _nameController.text.isEmpty || _selectedMethod == null) return;
    setState(() => _isLoading = true);

    await Supabase.instance.client.from('payments').insert({
      'order_id': widget.orderId,
      'payment_method': _selectedMethod,
      'reference': 'Nom: ${_nameController.text} | Ref: ${_refController.text}',
      'status': 'pending',
    });

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paiement soumis, en attente de vérification.')),
      );
    }
  }

  Future<void> _triggerUSSD() async {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez choisir une méthode')));
      return;
    }
    // Nettoyer le numéro : supprimer les espaces
    final String rawNumber = _numbers[_selectedMethod]!;
    final String cleanNumber = rawNumber.replaceAll(' ', '');
    
    // Construction du code USSD
    final String code = '*144*1*$cleanNumber*${widget.totalAmount.toInt()}#';
    
    if (Platform.isAndroid) {
      final AndroidIntent intent = AndroidIntent(
        action: 'android.intent.action.DIAL',
        data: 'tel:${Uri.encodeComponent(code)}',
      );
      await intent.launch();
    } else {
      final Uri url = Uri(scheme: 'tel', path: code);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Ajouter des listeners pour réévaluer le bouton de validation
    _refController.addListener(_updateUI);
    _nameController.addListener(_updateUI);
  }

  void _updateUI() {
    setState(() {}); // Force la reconstruction pour mettre à jour l'état du bouton
  }

  @override
  void dispose() {
    _refController.removeListener(_updateUI);
    _nameController.removeListener(_updateUI);
    _refController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Montant: ${widget.totalAmount.toStringAsFixed(0)} MGA', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // 1. Choix de méthode
            const Text('1. Choisissez la méthode :'),
            ..._numbers.entries.map((entry) => RadioListTile(
                  secondary: Image.asset(_logos[entry.key]!, width: 40, height: 40),
                  title: Text(entry.key),
                  subtitle: Text('Numéro: ${entry.value}'),
                  value: entry.key,
                  groupValue: _selectedMethod,
                  onChanged: (val) => setState(() => _selectedMethod = val),
                )),
            const SizedBox(height: 20),

            // 2. Action USSD
            const Text('2. Effectuez le transfert :'),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedMethod == null ? null : _triggerUSSD,
                icon: const Icon(Icons.phone_android),
                label: const Text('Lancer le paiement USSD'),
              ),
            ),
            const SizedBox(height: 20),

            // 3. Confirmation
            const Text('3. Confirmez ici après le transfert :'),
            const SizedBox(height: 10),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Votre Nom', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _refController, decoration: const InputDecoration(labelText: 'ID de transaction (Reçu par SMS)', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading || _selectedMethod == null || _refController.text.isEmpty ? null : _submitPayment,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Valider mon paiement'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
