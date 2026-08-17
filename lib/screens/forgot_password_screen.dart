import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'verify_code_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendCode() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final email = _emailController.text.trim();
      
      // Générer code 6 chiffres
      final code = (100000 + Random().nextInt(900000)).toString();
      
      print('DEBUG: Searching for user with email: $email');
      final user = await supabase.from('profiles')
          .select('id')
          .eq('email', email)
          .single();

      print('DEBUG: Found user ID: ${user['id']}');

      final updateResponse = await supabase.from('profiles').update({
        'reset_token': code,
        'reset_token_expires': DateTime.now().add(const Duration(minutes: 15)).toIso8601String(),
      }).eq('id', user['id']).select();

      print('DEBUG: Update token response: $updateResponse');

      print("Code généré (simulé): $code");

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VerifyCodeScreen(email: email)),
        );
      }
    } catch (e) {
      print('DEBUG: Error in _sendCode: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _isLoading ? null : _sendCode, child: const Text('Envoyer le code')),
          ],
        ),
      ),
    );
  }
}
