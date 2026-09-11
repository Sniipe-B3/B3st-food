import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme_provider.dart';
import '../providers/stock_provider.dart';
import '../services/ai_service.dart';

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
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: const AddFoodForm(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
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

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stockStream = ref.watch(stockStreamProvider);
    final utensilsStream = ref.watch(utensilsStreamProvider);

    return stockStream.when(
      data: (stock) {
        final frigoItems = stock.where((item) => item.category == 'Frigo').toList();
        final placardItems = stock.where((item) => item.category == 'Placard').toList();
        final congeItems = stock.where((item) => item.category == 'Congélateur').toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mon Stock'),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Frigo'),
                Tab(text: 'Placard'),
                Tab(text: 'Congél.'),
                Tab(text: 'Ustensiles'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildList(frigoItems, ref, context),
              _buildList(placardItems, ref, context),
              _buildList(congeItems, ref, context),
              _buildUtensilsList(utensilsStream, ref, context),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              final index = _tabController.index;
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: index == 3 ? const AddUtensilForm() : const AddFoodForm(),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur : $e'))),
    );
  }

  Widget _buildList(List<FoodItem> items, WidgetRef ref, BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Aucun aliment'));
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        bool isExpiringSoon = false;
        if (item.expirationDate != null) {
          final daysLeft = item.expirationDate!.difference(DateTime.now()).inDays;
          isExpiringSoon = daysLeft <= 3;
        }

        return ListTile(
          title: Text(item.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${item.quantity} ${item.unit}'),
              if (item.expirationDate != null)
                Text(
                  'Expire le : ${item.expirationDate!.day}/${item.expirationDate!.month}/${item.expirationDate!.year}',
                  style: TextStyle(
                    color: isExpiringSoon ? Colors.red : Colors.grey,
                    fontWeight: isExpiringSoon ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
            ],
          ),
          leading: const Icon(Icons.fastfood),
          trailing: Wrap(
            spacing: 0,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: AddFoodForm(itemToEdit: item),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  ref.read(stockServiceProvider).removeFood(item.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUtensilsList(AsyncValue<List<UtensilItem>> utensilsStream, WidgetRef ref, BuildContext context) {
    return utensilsStream.when(
      data: (utensils) {
        if (utensils.isEmpty) {
          return const Center(child: Text('Aucun ustensile'));
        }
        return ListView.builder(
          itemCount: utensils.length,
          itemBuilder: (context, index) {
            final item = utensils[index];
            return ListTile(
              title: Text(item.name),
              leading: const Icon(Icons.kitchen),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  ref.read(stockServiceProvider).removeUtensil(item.id);
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur : $e')),
    );
  }
}

class RecipeScreen extends ConsumerStatefulWidget {
  const RecipeScreen({super.key});

  @override
  ConsumerState<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends ConsumerState<RecipeScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _recipe;
  int _guestCount = 2;
  Set<String> _selectedIds = {}; // Set of IDs of selected ingredients. Empty means none.

  Future<void> _generateRecipe() async {
    setState(() {
      _isLoading = true;
      _recipe = null;
    });

    try {
      final stockValue = ref.read(stockStreamProvider).value;
      if (stockValue == null || stockValue.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ajoutez des aliments à votre stock d\'abord !')),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      final selectedItems = _selectedIds.isEmpty ? stockValue : stockValue.where((e) => _selectedIds.contains(e.id)).toList();
      if (selectedItems.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun aliment sélectionné !')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final ingredients = selectedItems.map((e) => e.name).toList();
      final utensilsValue = ref.read(utensilsStreamProvider).value ?? [];
      final utensils = utensilsValue.map((e) => e.name).toList();

      final aiService = AiService();
      final recipe = await aiService.generateRecipe(ingredients, _guestCount, utensils);
      
      setState(() {
        _recipe = recipe;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la génération.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _validateRecipe() {
    if (_recipe == null) return;
    
    final title = _recipe!['title'] as String? ?? 'Recette IA';
    final used = _recipe!['usedIngredients'] as List?;
    
    final stockService = ref.read(stockServiceProvider);
    final stockValue = ref.read(stockStreamProvider).value;

    if (used != null && stockValue != null) {
      for (var u in used) {
        if (u['name'] == null || u['quantityUsed'] == null) continue;
        final name = u['name'].toString().toLowerCase().trim();
        final qty = (u['quantityUsed'] as num).toDouble();

        final item = stockValue.where((e) => e.name.toLowerCase().trim() == name).firstOrNull;
        if (item != null) {
          stockService.updateFoodQuantity(item.id, item.quantity - qty);
        }
      }
    }

    stockService.addRecipeHistory(title);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stock mis à jour avec succès !')),
    );

    setState(() {
      _recipe = null;
      _selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recettes IA'),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Création de la recette...'),
                ],
              ),
            )
          : _recipe == null
              ? _buildConfigForm()
              : _buildRecipeView(),
    );
  }

  Widget _buildConfigForm() {
    final stockValue = ref.watch(stockStreamProvider).value ?? [];
    
    final categories = ['Frigo', 'Placard', 'Congélateur'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Pour combien de personnes ?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _guestCount.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: _guestCount.toString(),
                  onChanged: (val) {
                    setState(() {
                      _guestCount = val.toInt();
                    });
                  },
                ),
              ),
              Text('$_guestCount pers.', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Sélectionnez les ingrédients à utiliser :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Text('(Laissez vide pour tout utiliser)', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          
          ...categories.map((cat) {
            final itemsInCat = stockValue.where((item) => item.category == cat).toList();
            if (itemsInCat.isEmpty) return const SizedBox.shrink();

            return ExpansionTile(
              title: Text(cat),
              children: itemsInCat.map((item) {
                return CheckboxListTile(
                  title: Text(item.name),
                  subtitle: Text('${item.quantity} ${item.unit}'),
                  value: _selectedIds.contains(item.id),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedIds.add(item.id);
                      } else {
                        _selectedIds.remove(item.id);
                      }
                    });
                  },
                );
              }).toList(),
            );
          }),

          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _generateRecipe,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Générer la recette'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          _recipe!['title'] ?? 'Recette',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('Temps : ${_recipe!['prepTime'] ?? '?'} - Pour $_guestCount personne(s)'),
        const Divider(),
        const Text('Ingrédients :', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (_recipe!['ingredients'] is List)
          ...(_recipe!['ingredients'] as List).map((i) => Text('- $i')),
        const SizedBox(height: 16),
        const Text('Préparation :', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (_recipe!['steps'] is List)
          ...(_recipe!['steps'] as List).map((s) => Text('- $s')),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _validateRecipe,
          icon: const Icon(Icons.check),
          label: const Text('J\'ai cuisiné ça ! (Mettre à jour le stock)'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _recipe = null;
            });
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Générer une autre recette'),
        ),
      ],
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
          ListTile(
            title: const Text('Historique des recettes cuisinées'),
            subtitle: const Text('Voir toutes vos créations IA validées'),
            leading: const Icon(Icons.restaurant_menu),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RecipeHistoryScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('Se déconnecter'),
            subtitle: const Text('Fermer votre session'),
            leading: const Icon(Icons.logout, color: Colors.red),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
          ListTile(
            title: const Text('B3st-Food V1.0.8'),
            subtitle: const Text('Voir l\'historique des modifications'),
            leading: const Icon(Icons.history),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Historique B3st-Food'),
                  content: const SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• V1.0.8 : Correctif de l\'ajout d\'ustensiles et ajout de l\'unité Centilitres (cl).'),
                        SizedBox(height: 8),
                        Text('• V1.0.7 : Liste déroulante des ingrédients, historique des recettes cuisinées et correctifs de l\'ajout d\'ustensiles.'),
                        SizedBox(height: 8),
                        Text('• V1.0.6 : Ajout des ustensiles, sélection d\'ingrédients pour l\'IA et déduction automatique du stock.'),
                        SizedBox(height: 8),
                        Text('• V1.0.5 : Authentification obligatoire, sauvegarde Cloud (Firestore), modification d\'ingrédient et choix des portions.'),
                        SizedBox(height: 8),
                        Text('• V1.0.4 : Génération de recettes IA avec Gemini depuis l\'onglet dédié.'),
                        SizedBox(height: 8),
                        Text('• V1.0.3 : Ajout de quantité, unité, date de péremption, et onglet Congélateur.'),
                        SizedBox(height: 8),
                        Text('• V1.0.2 : Sauvegarde du Dark Mode et ajout fonctionnel d\'un aliment.'),
                        SizedBox(height: 8),
                        Text('• V1.0.1 : Déplacement du bouton d\'ajout en bas à droite et ajout de l\'historique.'),
                        SizedBox(height: 8),
                        Text('• V1.0.0 : Initialisation de l\'application avec les onglets Stock, Recettes et Paramètres.'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fermer'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class RecipeHistoryScreen extends ConsumerWidget {
  const RecipeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyStream = ref.watch(recipeHistoryStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recettes cuisinées'),
      ),
      body: historyStream.when(
        data: (history) {
          if (history.isEmpty) {
            return const Center(child: Text('Aucune recette cuisinée pour le moment.'));
          }
          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return ListTile(
                title: Text(item.title),
                subtitle: Text('Le ${item.date.day}/${item.date.month}/${item.date.year} à ${item.date.hour}:${item.date.minute.toString().padLeft(2, '0')}'),
                leading: const Icon(Icons.check_circle, color: Colors.green),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
      ),
    );
  }
}

class AddFoodForm extends ConsumerStatefulWidget {
  final FoodItem? itemToEdit;

  const AddFoodForm({super.key, this.itemToEdit});

  @override
  ConsumerState<AddFoodForm> createState() => _AddFoodFormState();
}

class _AddFoodFormState extends ConsumerState<AddFoodForm> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  String _selectedCategory = 'Frigo';
  String _selectedUnit = 'pièces';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.itemToEdit != null) {
      _nameController.text = widget.itemToEdit!.name;
      _quantityController.text = widget.itemToEdit!.quantity.toString();
      _selectedCategory = widget.itemToEdit!.category;
      _selectedUnit = widget.itemToEdit!.unit;
      _selectedDate = widget.itemToEdit!.expirationDate;
    } else {
      _quantityController.text = '1';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    
    final quantity = double.tryParse(_quantityController.text.trim()) ?? 1.0;

    final service = ref.read(stockServiceProvider);

    if (widget.itemToEdit == null) {
      service.addFood(
        name: name,
        category: _selectedCategory,
        quantity: quantity,
        unit: _selectedUnit,
        expirationDate: _selectedDate,
      );
    } else {
      final updatedItem = FoodItem(
        id: widget.itemToEdit!.id,
        name: name,
        category: _selectedCategory,
        quantity: quantity,
        unit: _selectedUnit,
        expirationDate: _selectedDate,
      );
      service.updateFood(updatedItem);
    }
    
    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.itemToEdit == null ? 'Ajouter un aliment' : 'Modifier un aliment',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom de l\'aliment',
              border: OutlineInputBorder(),
            ),
            autofocus: widget.itemToEdit == null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantité',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  value: _selectedUnit,
                  items: const [
                    DropdownMenuItem(value: 'L', child: Text('Litres (L)')),
                    DropdownMenuItem(value: 'cl', child: Text('Centilitres (cl)')),
                    DropdownMenuItem(value: 'ml', child: Text('Millilitres (ml)')),
                    DropdownMenuItem(value: 'kg', child: Text('Kilogrammes (kg)')),
                    DropdownMenuItem(value: 'g', child: Text('Grammes (g)')),
                    DropdownMenuItem(value: 'pièces', child: Text('Pièces')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedUnit = value);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Unité',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            items: const [
              DropdownMenuItem(value: 'Frigo', child: Text('Frigo')),
              DropdownMenuItem(value: 'Placard', child: Text('Placard')),
              DropdownMenuItem(value: 'Congélateur', child: Text('Congélateur')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _selectedCategory = value);
            },
            decoration: const InputDecoration(
              labelText: 'Catégorie',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text(_selectedDate == null 
              ? 'Aucune date de péremption' 
              : 'Expire le : ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
            trailing: const Icon(Icons.calendar_today),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: Text(widget.itemToEdit == null ? 'Ajouter' : 'Modifier'),
          ),
        ],
      ),
    );
  }
}

class AddUtensilForm extends ConsumerStatefulWidget {
  const AddUtensilForm({super.key});

  @override
  ConsumerState<AddUtensilForm> createState() => _AddUtensilFormState();
}

class _AddUtensilFormState extends ConsumerState<AddUtensilForm> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    ref.read(stockServiceProvider).addUtensil(name);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Ajouter un ustensile',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom (ex: Four, Cookeo...)',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}

