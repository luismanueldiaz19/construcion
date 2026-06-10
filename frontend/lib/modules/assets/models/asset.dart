import 'asset_category.dart';

class Asset {
  final int id;
  final int categoryId;
  final String name;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final String? purchaseDate;
  final double initialCost;
  final String status;
  final String? notes;
  final AssetCategory? category;
  final double? tco;

  Asset({
    required this.id,
    required this.categoryId,
    required this.name,
    this.brand,
    this.model,
    this.serialNumber,
    this.purchaseDate,
    required this.initialCost,
    required this.status,
    this.notes,
    this.category,
    this.tco,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'],
      brand: json['brand'],
      model: json['model'],
      serialNumber: json['serial_number'],
      purchaseDate: json['purchase_date'],
      initialCost: double.parse((json['initial_cost'] ?? 0).toString()),
      status: json['status'] ?? 'Activo',
      notes: json['notes'],
      tco: json['tco'] != null ? double.parse(json['tco'].toString()) : null,
      category: json['category'] != null ? AssetCategory.fromJson(json['category']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'name': name,
      'brand': brand,
      'model': model,
      'serial_number': serialNumber,
      'purchase_date': purchaseDate,
      'initial_cost': initialCost,
      'status': status,
      'notes': notes,
    };
  }
}
