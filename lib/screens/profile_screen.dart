import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io' show Platform;
import '../providers/auth_provider.dart';
import 'auth_screen.dart';
import 'my_orders_screen.dart';
import 'add_product_screen.dart';
import 'add_category_screen.dart';
import 'add_promo_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _launchUSSD() async {
    if (Platform.isAndroid) {
      // Pour Android, utiliser l'intent pour le dialer
      final String ussdCode = '#144*3*3#'.replaceAll('#', Uri.encodeComponent('#'));
      final AndroidIntent intent = AndroidIntent(
        action: 'android.intent.action.DIAL',
        data: 'tel:$ussdCode',
      );
      await intent.launch();
    } else {
      // Fallback pour iOS (url_launcher n'est plus importé, donc on ne peut pas utiliser launchUrl ici sans lui)
      debugPrint('USSD non supporté nativement sur cette plateforme');
    }
  }
  Future<void> _signOut(BuildContext context) async {
// ...

    if (context.mounted) {
      Provider.of<AuthProvider>(context, listen: false).clearProfile();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  Widget _buildProfileCard(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, Color? color}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: color ?? Colors.green),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAuthorizedToSell = authProvider.isAdmin || authProvider.isSeller;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          _buildProfileCard(
            context,
            icon: Icons.shopping_bag_outlined,
            title: 'Mes commandes',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyOrdersScreen())),
          ),
          _buildProfileCard(
            context,
            icon: Icons.lock_outline,
            title: 'Gestion de mot de passe',
            onTap: () {}, // TODO: Implémenter
          ),
          if (isAuthorizedToSell)
            Column(
              children: [
                _buildProfileCard(
                  context,
                  icon: Icons.add_circle_outline,
                  title: 'Ajout de nouveaux produits',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddProductScreen())),
                ),
                _buildProfileCard(
                  context,
                  icon: Icons.category_outlined,
                  title: 'Ajouter une catégorie',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddCategoryScreen())),
                ),
                _buildProfileCard(
                  context,
                  icon: Icons.local_offer_outlined,
                  title: 'Ajouter une Promo',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddPromoScreen())),
                ),
              ],
            ),
          _buildProfileCard(
            context,
            icon: Icons.phone_android,
            title: 'Test USSD (#144*3*3#)',
            onTap: _launchUSSD,
          ),
          _buildProfileCard(
            context,
            icon: Icons.logout,
            title: 'Déconnexion',
            color: Colors.red,
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }
}
