import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase
        .from('orders')
        .select('*, payments(status)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    setState(() {
      _orders = response;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes Commandes')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text('Aucune commande trouvée.'))
              : ListView.builder(
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final paymentStatus = order['payments'] != null && (order['payments'] as List).isNotEmpty
                        ? order['payments'][0]['status']
                        : 'En attente';
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text('Commande du ${DateTime.parse(order['created_at']).toLocal().toString().split('.')[0]}'),
                        subtitle: Text('Total: ${order['total_amount']} MGA\nStatut Paiement: $paymentStatus'),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}
