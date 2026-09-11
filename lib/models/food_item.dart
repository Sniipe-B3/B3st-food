class FoodItem {
  final String id;
  final String name;
  final double quantity;
  final String unit; // ex: kg, g, L, ml, pièces
  final String category; // ex: Frigo, Placard, Congélateur
  final DateTime expiryDate;

  FoodItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    required this.expiryDate,
  });

  // Méthode pour copier l'objet en modifiant certaines propriétés
  FoodItem copyWith({
    String? id,
    String? name,
    double? quantity,
    String? unit,
    String? category,
    DateTime? expiryDate,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }

  // Convertir un FoodItem en Map (utile pour Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'expiryDate': expiryDate.toIso8601String(),
    };
  }

  // Créer un FoodItem depuis un Map (utile pour Firestore)
  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      quantity: map['quantity']?.toDouble() ?? 0.0,
      unit: map['unit'] ?? '',
      category: map['category'] ?? '',
      expiryDate: DateTime.parse(map['expiryDate']),
    );
  }
}

