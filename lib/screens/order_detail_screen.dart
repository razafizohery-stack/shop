import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  List<dynamic> _drivers = [];
  String? _selectedDriverId;
  bool _isLoadingDrivers = true;
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
    _selectedDriverId = widget.order['delivery_person_id'];
    
    final payments = widget.order['payments'] as List;
    final payment = payments.isNotEmpty ? payments[0] : null;
    final status = payment != null ? payment['status'] : 'pending';
    
    if (status == 'verified') _currentStep = 1;
    if (widget.order['delivery_person_id'] != null) _currentStep = 2;

    if (payments.isNotEmpty) {
      _driverNameController.text = payments[0]['delivery_person_name'] ?? '';
      _driverPhoneController.text = payments[0]['delivery_person_phone'] ?? '';
    }
  }
Future<void> _updateDeliveryInfo(String paymentId) async {
  await Supabase.instance.client
      .from('payments')
      .update({
        'delivery_person_name': _driverNameController.text,
        'delivery_person_phone': _driverPhoneController.text,
      })
      .eq('id', paymentId);
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informations livreur mises à jour')));
}

Future<void> _loadDrivers() async {
  final response = await Supabase.instance.client
      .from('profiles')
      .select()
      .eq('role', 'livreur');
  setState(() {
    _drivers = response;
    _isLoadingDrivers = false;
  });
}

  @override
  void dispose() {
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    super.dispose();
  }

  Future<void> _assignDriver(String? driverId) async {
    if (driverId == null) return;
    await Supabase.instance.client
        .from('orders')
        .update({'delivery_person_id': driverId})
        .eq('id', widget.order['id']);
    setState(() {
      _selectedDriverId = driverId;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Livreur attribué')));
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final payments = widget.order['payments'] as List;
    final payment = payments.isNotEmpty ? payments[0] : null;
    final String status = payment != null ? (payment['status'] ?? 'pending') : 'pending';
    final items = widget.order['order_items'] as List;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail Commande', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Informations Paiement
            if (payment != null)
              Card(
                margin: const EdgeInsets.all(16),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.payment, color: Colors.blueGrey),
                          const SizedBox(width: 10),
                          Text('Détails du Paiement', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(thickness: 1, height: 20),
                      _buildDetailRow(Icons.account_balance_wallet, 'Méthode', payment['payment_method'] ?? 'N/A'),
                      _buildDetailRow(Icons.receipt_long, 'Référence', payment['reference'] ?? 'N/A'),
                      _buildDetailRow(Icons.person, 'Payeur', payment['payer_name'] ?? 'N/A'),
                      _buildDetailRow(Icons.phone, 'Téléphone', payment['payer_phone'] ?? 'N/A'),
                      _buildDetailRow(Icons.location_on, 'Lieu', payment['delivery_location'] ?? 'N/A'),
                      const Divider(height: 20),
                      _buildDetailRow(Icons.delivery_dining, 'Livreur', payment['delivery_person_name'] ?? 'Non attribué'),
                      _buildDetailRow(Icons.phone_android, 'Tél. Livreur', payment['delivery_person_phone'] ?? 'N/A'),
                      const Divider(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Montant: ${widget.order['total_amount']} MGA',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Liste des produits
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Articles commandés', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  ...items.map((item) {
                    final variant = item['product_variants'];
                    final product = variant != null ? variant['products'] : {};
                    final imageUrl = product['image_url'] ?? ''; 
                    return ListTile(
                      leading: imageUrl.isNotEmpty
                          ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover))
                          : const CircleAvatar(backgroundColor: Colors.blueGrey, child: Icon(Icons.shopping_bag, color: Colors.white)),
                      title: Text(product['name'] ?? 'Produit inconnu', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Var: ${variant?['color'] ?? ''} ${variant?['size'] ?? ''}'),
                      trailing: Text('x${item['quantity']}\n${item['price']} MGA', textAlign: TextAlign.right),
                    );
                  }),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(primary: Colors.blueGrey),
              ),
              child: SizedBox(
                height: 500, // Fixed height to satisfy Stepper layout
                child: Stepper(
                  type: StepperType.horizontal,
                  currentStep: _currentStep,
                  onStepContinue: () {
                    if (_currentStep < 2) {
                      setState(() => _currentStep += 1);
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) {
                      setState(() => _currentStep -= 1);
                    }
                  },
                  controlsBuilder: (BuildContext context, ControlsDetails details) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Row(
                        children: <Widget>[
                          ElevatedButton(
                            onPressed: details.onStepContinue,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                            child: Text(_currentStep == 2 ? 'Finaliser' : 'Continuer'),
                          ),
                          const SizedBox(width: 10),
                          TextButton(onPressed: details.onStepCancel, child: const Text('Annuler')),
                        ],
                      ),
                    );
                  },
                  steps: [
                    Step(
                      title: const Text('Commande'),
                      content: Text('Total: ${widget.order['total_amount']} MGA', style: const TextStyle(fontSize: 16)),
                      isActive: _currentStep >= 0,
                      state: _currentStep > 0 ? StepState.complete : StepState.editing,
                    ),
                    Step(
                      title: const Text('Déstockage'),
                      content: const Text('Article déstocké automatiquement après vérification.'),
                      isActive: _currentStep >= 1,
                      state: status == 'verified' ? StepState.complete : (_currentStep == 1 ? StepState.editing : StepState.disabled),
                    ),
                    Step(
                      title: const Text('Livreur'),
                      content: _isLoadingDrivers
                          ? const CircularProgressIndicator()
                          : (auth.isAdmin || auth.isSeller)
                              ? Column(
                                  children: [
                                    DropdownButtonFormField<String>(
                                      value: _selectedDriverId,
                                      items: _drivers.map((d) => DropdownMenuItem(value: d['id'] as String, child: Text(d['full_name'] ?? 'Livreur'))).toList(),
                                      onChanged: _assignDriver,
                                      decoration: const InputDecoration(labelText: 'Attribuer un livreur (profil)', border: OutlineInputBorder()),
                                    ),
                                    const SizedBox(height: 15),
                                    TextField(controller: _driverNameController, decoration: const InputDecoration(labelText: 'Nom du livreur', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline))),
                                    const SizedBox(height: 10),
                                    TextField(controller: _driverPhoneController, decoration: const InputDecoration(labelText: 'Numéro du livreur', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone_iphone)), keyboardType: TextInputType.phone),
                                    const SizedBox(height: 15),
                                    ElevatedButton.icon(
                                      onPressed: () => payment != null ? _updateDeliveryInfo(payment['id'].toString()) : null,
                                      icon: const Icon(Icons.save),
                                      label: const Text('Enregistrer livreur'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Nom: ${_drivers.firstWhere((d) => d['id'] == _selectedDriverId, orElse: () => {'full_name': 'Non attribué'})['full_name']}'),
                                    Text('Tél: ${_drivers.firstWhere((d) => d['id'] == _selectedDriverId, orElse: () => {'phone': 'N/A'})['phone'] ?? 'N/A'}'),
                                  ],
                                ),
                      isActive: true,
                      state: (_selectedDriverId != null || (_driverNameController.text.isNotEmpty)) 
                          ? StepState.complete 
                          : StepState.editing,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }
}
