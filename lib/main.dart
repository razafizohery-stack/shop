import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'screens/auth_screen.dart';
import 'providers/cart_provider.dart';
import 'providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://gswbojtgecieahfphlxx.supabase.co',
    anonKey: 'sb_publishable_FxM5wCpLxxYjnVoUyXA97A_3OVbHA7w',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Vente App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          scaffoldBackgroundColor: Colors.white,
          useMaterial3: true,
        ),

        home: const AuthScreen(),
      ),
    );
  }
}
