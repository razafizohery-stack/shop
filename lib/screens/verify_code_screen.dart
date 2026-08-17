import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'new_password_screen.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String email;
  const VerifyCodeScreen({super.key, required this.email});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyCode() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      
      final profile = await supabase
          .from('profiles')
          .select('id, reset_token, reset_token_expires')
          .eq('email', widget.email)
          .single();

      final dbCode = profile['reset_token']?.toString();
      final enteredCode = _codeController.text.trim();
      
      if (dbCode == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucun code généré pour cet email.')));
        return;
      }

      final expiresAt = DateTime.parse(profile['reset_token_expires']);
      final now = DateTime.now();

      print('DEBUG: Entered code: "$enteredCode"');
      print('DEBUG: DB code: "$dbCode"');
      print('DEBUG: Expires at: $expiresAt, Now: $now');
      print('DEBUG: Code match: ${dbCode == enteredCode}');
      print('DEBUG: Not expired: ${expiresAt.isAfter(now)}');

      if (dbCode == enteredCode && expiresAt.isAfter(now)) {
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => NewPasswordScreen(userId: profile['id'])),
          );
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code invalide ou expiré')));
      }
    } catch (e) {
      print('DEBUG: Verification error: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vérification')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: _codeController, decoration: const InputDecoration(labelText: 'Code à 6 chiffres'), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _isLoading ? null : _verifyCode, child: const Text('Vérifier')),
          ],
        ),
      ),
    );
  }
}
