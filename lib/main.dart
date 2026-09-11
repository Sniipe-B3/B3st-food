import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'firebase_options.dart'; // Fichier généré par FlutterFire CLI

// Provider pour écouter l'état de connexion de l'utilisateur
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

void main() async {
  // S'assurer que les bindings Flutter sont initialisés avant les appels asynchrones
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation de Firebase avec try-catch pour éviter les crashs (ex: navigation privée)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Erreur lors de l'initialisation de Firebase: $e");
  }
  
  // Chargement des variables d'environnement (ex: clé API de l'IA)
  // Décommenter une fois le package flutter_dotenv installé et le fichier .env créé
  /*
  await dotenv.load(fileName: ".env");
  */

  runApp(
    // ProviderScope est nécessaire pour utiliser Riverpod
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Écoute des changements de thème via le Provider
    final isDarkMode = ref.watch(themeProvider);
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'B3st Food Inventory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green, 
          brightness: Brightness.dark,
        ),
      ),
      // Applique le mode selon l'état du ThemeProvider
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: authState.when(
        data: (user) {
          if (user != null) {
            return const HomeScreen();
          }
          return const AuthScreen();
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, __) => const Scaffold(body: Center(child: Text('Erreur d\'authentification'))),
      ),
    );
  }
}
