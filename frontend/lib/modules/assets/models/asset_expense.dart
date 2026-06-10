class AssetExpense {
  final int id;
  final int assetId;
  final int? proyectoId;
  final String expenseType;
  final double amount;
  final String date;
  final String? description;
  final int? mileage;
  final double? gallons;
  final int? proveedorId;
  final String? paymentMethod;
  final int? bancoId;

  AssetExpense({
    required this.id,
    required this.assetId,
    this.proyectoId,
    required this.expenseType,
    required this.amount,
    required this.date,
    this.description,
    this.mileage,
    this.gallons,
    this.proveedorId,
    this.paymentMethod,
    this.bancoId,
  });

  factory AssetExpense.fromJson(Map<String, dynamic> json) {
    return AssetExpense(
      id: json['id'],
      assetId: json['asset_id'],
      proyectoId: json['proyecto_id'],
      expenseType: json['expense_type'],
      amount: double.parse((json['amount'] ?? 0).toString()),
      date: json['date'],
      description: json['description'],
      mileage: json['mileage'],
      gallons: json['gallons'] != null ? double.parse(json['gallons'].toString()) : null,
      proveedorId: json['proveedor_id'],
      paymentMethod: json['payment_method'],
      bancoId: json['banco_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'asset_id': assetId,
      'proyecto_id': proyectoId,
      'expense_type': expenseType,
      'amount': amount,
      'date': date,
      'description': description,
      'mileage': mileage,
      'gallons': gallons,
      'proveedor_id': proveedorId,
      'payment_method': paymentMethod,
      'banco_id': bancoId,
    };
  }
}
