import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  int? _selectedCategoryId;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterBySearch);
  }

  void _filterBySearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((p) => p['name'].toString().toLowerCase().contains(query)).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharger seulement si _products est vide
    if (_products.isEmpty) _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final categories = await _supabase.from('categories').select();
    final products = await _supabase.from('products').select();
    // Ne récupérer que les promos actives
    final promos = await _supabase.from('product_promos').select().eq('is_active', true);
    
    // Associer les promos aux produits
    final productsWithPromos = (products as List).map((product) {
      final promo = promos.firstWhere(
        (p) => p['product_id'] == product['id'],
        orElse: () => {},
      );
      return {...product as Map<String, dynamic>, 'promo': promo.isNotEmpty ? promo : null};
    }).toList();

    setState(() {
      _categories = categories;
      _products = productsWithPromos;
      _filteredProducts = productsWithPromos;
      _isLoading = false;
    });
  }

  // ... (keeping _filterProducts and _loadProductsFiltered as they were)
  void _filterProducts(int? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _searchController.clear(); // Effacer la recherche lors du changement de catégorie
    });
    _loadProductsFiltered(categoryId);
  }

  Future<void> _loadProductsFiltered(int? categoryId) async {
    setState(() => _isLoading = true);
    var query = _supabase.from('products').select();
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    final products = await query;
    // (Note: Should also handle promo association here, simplified for brevity)
    setState(() {
      _products = products;
      _filteredProducts = products;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Découvrir', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Rechercher un produit...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(25))),
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => _filterProducts(null),
                      child: Text('Tous', style: TextStyle(color: _selectedCategoryId == null ? Colors.green : Colors.grey)),
                    ),
                    ..._categories.map((c) => TextButton(
                      onPressed: () => _filterProducts(c['id']),
                      child: Text(c['name'], style: TextStyle(color: _selectedCategoryId == c['id'] ? Colors.green : Colors.grey)),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) => Badge(
              label: Text('${cart.items.length}'),
              isLabelVisible: cart.items.isNotEmpty,
              child: IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _filteredProducts.length,
            itemBuilder: (context, index) {
              final product = _filteredProducts[index];
              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(product: product),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: product['image_url'] != null 
                                ? Image.network(product['image_url'], fit: BoxFit.cover, width: double.infinity)
                                : const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
                            ),
                            if (product['promo'] != null)
                              Positioned(
                                top: 20,
                                left: -15,
                                child: Transform.rotate(
                                  angle: -0.785398, // -45 degrees in radians
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    color: Colors.red,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.local_offer, color: Colors.white, size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          'PROMO ${product['promo']['discount_percent'].toInt()}%',
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('${product['price']} MGA', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ProductDetailScreen(product: product),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}
