class AssetCategory {
  final int id;
  final String name;
  final String? description;
  final int? defaultAssetAccountId;
  final int? defaultExpenseAccountId;

  AssetCategory({
    required this.id,
    required this.name,
    this.description,
    this.defaultAssetAccountId,
    this.defaultExpenseAccountId,
  });

  factory AssetCategory.fromJson(Map<String, dynamic> json) {
    return AssetCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      defaultAssetAccountId: json['default_asset_account_id'],
      defaultExpenseAccountId: json['default_expense_account_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'default_asset_account_id': defaultAssetAccountId,
      'default_expense_account_id': defaultExpenseAccountId,
    };
  }
}
