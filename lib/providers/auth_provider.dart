import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;

  Map<String, dynamic>? get profile => _profile;
  String? get role => _profile?['role'];
  bool get isAdmin => role == 'admin';
  bool get isSeller => role == 'vendeur';
  bool get isClient => role == 'client';

  Future<void> loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      
      _profile = response;
      notifyListeners();
    }
  }

  void clearProfile() {
    _profile = null;
    notifyListeners();
  }
}
