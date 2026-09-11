import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FoodItem {
  final String id;
  final String name;
  final String category; // 'Frigo', 'Placard', 'Congélateur'
  final double quantity;
  final String unit; // 'L', 'ml', 'kg', 'g', 'pièces'
  final DateTime? expirationDate;

  FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    this.expirationDate,
  });

  factory FoodItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodItem(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? 'Frigo',
      quantity: (data['quantity'] ?? 1).toDouble(),
      unit: data['unit'] ?? 'pièces',
      expirationDate: data['expirationDate'] != null 
          ? (data['expirationDate'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'expirationDate': expirationDate != null ? Timestamp.fromDate(expirationDate!) : null,
    };
  }
}

class UtensilItem {
  final String id;
  final String name;

  UtensilItem({required this.id, required this.name});

  factory UtensilItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UtensilItem(
      id: doc.id,
      name: data['name'] ?? '',
    );
  }
}

class RecipeHistoryItem {
  final String id;
  final String title;
  final DateTime date;

  RecipeHistoryItem({required this.id, required this.title, required this.date});

  factory RecipeHistoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecipeHistoryItem(
      id: doc.id,
      title: data['title'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
    );
  }
}

// Provider de flux qui écoute Firestore en temps réel pour l'utilisateur connecté
final stockStreamProvider = StreamProvider<List<FoodItem>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);
  
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('stock')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => FoodItem.fromFirestore(doc)).toList());
});

final utensilsStreamProvider = StreamProvider<List<UtensilItem>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);
  
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('utensils')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => UtensilItem.fromFirestore(doc)).toList());
});

final recipeHistoryStreamProvider = StreamProvider<List<RecipeHistoryItem>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);
  
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('recipeHistory')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => RecipeHistoryItem.fromFirestore(doc)).toList());
});

// Classe utilitaire pour manipuler le stock dans Firestore
class StockService {
  final _db = FirebaseFirestore.instance;
  
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference? get _stockCollection {
    if (_uid == null) return null;
    return _db.collection('users').doc(_uid!).collection('stock');
  }

  CollectionReference? get _utensilsCollection {
    if (_uid == null) return null;
    return _db.collection('users').doc(_uid!).collection('utensils');
  }

  CollectionReference? get _recipeHistoryCollection {
    if (_uid == null) return null;
    return _db.collection('users').doc(_uid!).collection('recipeHistory');
  }

  Future<void> addFood({
    required String name,
    required String category,
    required double quantity,
    required String unit,
    DateTime? expirationDate,
  }) async {
    await _stockCollection?.add({
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'expirationDate': expirationDate != null ? Timestamp.fromDate(expirationDate) : null,
    });
  }

  Future<void> updateFood(FoodItem item) async {
    await _stockCollection?.doc(item.id).update(item.toMap());
  }

  Future<void> removeFood(String id) async {
    await _stockCollection?.doc(id).delete();
  }

  Future<void> updateFoodQuantity(String id, double newQuantity) async {
    if (newQuantity <= 0) {
      await removeFood(id);
    } else {
      await _stockCollection?.doc(id).update({'quantity': newQuantity});
    }
  }

  Future<void> addUtensil(String name) async {
    await _utensilsCollection?.add({'name': name});
  }

  Future<void> removeUtensil(String id) async {
    await _utensilsCollection?.doc(id).delete();
  }

  Future<void> addRecipeHistory(String title) async {
    await _recipeHistoryCollection?.add({
      'title': title,
      'date': FieldValue.serverTimestamp(),
    });
  }
}

// Provider global pour accéder au service sans context
final stockServiceProvider = Provider<StockService>((ref) {
  return StockService();
});

