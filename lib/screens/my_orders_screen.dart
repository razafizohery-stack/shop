import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import 'order_detail_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  List<dynamic> _orders = [];
  List<dynamic> _filteredOrders = [];
  bool _isLoading = true;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _tabs = ['pending', 'verified', 'rejected'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_filterOrders);
    _loadOrders();
    _searchController.addListener(_filterOrders);
  }

  Future<void> _loadOrders() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = _supabase.auth.currentUser!.id;
    
    // Utilisation explicite des relations pour lever l'ambiguïté PGRST201
    var query = _supabase
        .from('orders')
        .select('''
          *, 
          payments(*), 
          client:profiles!orders_user_id_fkey(full_name), 
          livreur:profiles!orders_delivery_person_id_fkey(full_name),
          order_items(*, product_variants(*, products(*)))
        ''');
    
    if (!auth.isAdmin && !auth.isSeller) {
      query = query.eq('user_id', userId);
    }
    
    final response = await query.order('created_at', ascending: false);
    
    setState(() {
      _orders = response;
      _filterOrders();
      _isLoading = false;
    });
  }

  void _filterOrders() {
    final status = _tabs[_tabController.index];
    final searchQuery = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredOrders = _orders.where((order) {
        final payments = order['payments'] as List;
        
        // Priorité au statut du paiement, fallback vers le statut de la commande
        final orderStatus = payments.isNotEmpty ? payments[0]['status'] : (order['status'] ?? 'pending');
        final clientName = (order['profiles']?['full_name'] ?? '').toLowerCase();
        
        return orderStatus == status && 
               (clientName.contains(searchQuery) || order['id'].toString().contains(searchQuery));
      }).toList();
    });
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      print('DEBUG: Sync updating order $orderId and payments to $newStatus');
      
      // 1. Mettre à jour la table 'orders'
      final orderResponse = await _supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId)
          .select(); // .select() permet de voir les lignes affectées
          
      print('DEBUG: Orders update response: $orderResponse');
          
      // 2. Mettre à jour la table 'payments'
      final paymentResponse = await _supabase
          .from('payments')
          .update({'status': newStatus})
          .eq('order_id', orderId)
          .select();
          
      print('DEBUG: Payments update response: $paymentResponse');
            
      print('DEBUG: Update attempted');
      _loadOrders(); // Recharger pour synchroniser
    } catch (e) {
      print('Error updating order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commandes'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrders),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((s) => Tab(text: s.toUpperCase())).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(labelText: 'Rechercher (Client/ID)', prefixIcon: Icon(Icons.search)),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = _filteredOrders[index];
                      final payments = order['payments'] as List;
                      final payment = payments.isNotEmpty ? payments[0] : null;
                      
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text('Commande du ${DateTime.parse(order['created_at']).toLocal().toString().split('.')[0]}'),
                          subtitle: Text(
                            'Client: ${payment != null ? payment['payer_name'] : 'N/A'}\n'
                            'Tél: ${payment != null ? payment['payer_phone'] : 'N/A'}\n'
                            'Total: ${order['total_amount']} MGA'
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
                            );
                            _loadOrders();
                          },
                          trailing: (auth.isAdmin || auth.isSeller)
                              ? PopupMenuButton<String>(
                                  onSelected: (status) => _updateOrderStatus(order['id'].toString(), status),
                                  itemBuilder: (context) => ['pending', 'verified', 'rejected']
                                      .map((s) => PopupMenuItem(value: s, child: Text(s)))
                                      .toList(),
                                  child: const Icon(Icons.more_vert),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
