import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../models/asset_category.dart';
import '../models/asset_expense.dart';
import '../services/asset_service.dart';

class AssetsProvider extends ChangeNotifier {
  final AssetService _assetService = AssetService();

  List<Asset> _assets = [];
  List<AssetCategory> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Asset> get assets => _assets;
  List<AssetCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAssets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _assets = await _assetService.getAssets();
      _categories = await _assetService.getCategories();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createCategory(String name) async {
    try {
      final newCat = await _assetService.createCategory(name);
      _categories.add(newCat);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _assetService.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createAsset(Asset asset) async {
    try {
      final newAsset = await _assetService.createAsset(asset);
      _assets.add(newAsset);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> registerExpense(AssetExpense expense) async {
    try {
      await _assetService.createExpense(expense);
      await fetchAssets();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
