import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider pour gérer l'état du thème (Dark/Light mode)
final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<bool> {
  // true = Dark Mode, false = Light Mode
  // La valeur initiale est false (Light Mode par défaut)
  ThemeNotifier() : super(false);

  // Méthode pour basculer entre les deux thèmes
  void toggleTheme() {
    state = !state;
  }
}

