class LocalInventory {
  final int? id;
  final String nameInventario;
  final String location;
  final double? totalStock;

  LocalInventory({
    this.id,
    required this.nameInventario,
    required this.location,
    this.totalStock,
  });

  factory LocalInventory.fromJson(Map<String, dynamic> json) {
    return LocalInventory(
      id: json['id'],
      nameInventario: json['name_inventario'] ?? '',
      location: json['location'] ?? '',
      totalStock: double.tryParse(json['total_stock']?.toString() ?? '0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_inventario': nameInventario,
      'location': location,
    };
  }
}
