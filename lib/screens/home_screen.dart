import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Liste des écrans pour chaque onglet
  final List<Widget> _screens = const [
    StockScreen(),
    RecipeScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      // Bouton central (+) affiché uniquement sur l'onglet "Mon Stock" (index 0)
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                // TODO: Ouvrir une page (AddItemScreen) ou un modal avec un formulaire
                // -------------------------------------------------------------
                // Futures intégrations possibles à commenter ici :
                // - Scan de code-barres : utiliser un package comme `mobile_scanner` 
                //   ou `barcode_scan2` pour remplir automatiquement le formulaire.
                // - Saisie vocale : utiliser `speech_to_text` pour dicter les produits.
                // -------------------------------------------------------------
                showModalBottomSheet(
                  context: context,
                  builder: (context) => const Center(
                    child: Text("Formulaire d'ajout manuel (à implémenter)"),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Mon Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Recettes IA',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// Squelettes des vues (Onglets)
// (À séparer dans leurs propres fichiers idéalement)
// ==========================================

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 2 onglets: Frigo, Placard
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mon Stock'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Frigo'),
              Tab(text: 'Placard'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Center(child: Text('Contenu du Frigo')),
            Center(child: Text('Contenu du Placard')),
          ],
        ),
      ),
    );
  }
}

class RecipeScreen extends StatelessWidget {
  const RecipeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recettes IA'),
      ),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () {
            // TODO: Appel au service mocké d'IA (AIService)
            // Pour le moment, on affiche juste un message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Génération de recette en cours...')),
            );
          },
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Générer une recette'),
        ),
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Basculer entre le thème clair et sombre'),
            value: isDarkMode,
            onChanged: (value) {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
    );
  }
}

