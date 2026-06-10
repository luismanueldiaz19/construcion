import '../../../services/http_service.dart';
import '../models/asset.dart';
import '../models/asset_category.dart';
import '../models/asset_expense.dart';

class AssetService {
  final HttpService _httpService = HttpService();

  Future<List<Asset>> getAssets() async {
    final response = await _httpService.get('assets');
    return (response as List).map((json) => Asset.fromJson(json)).toList();
  }

  Future<Asset> createAsset(Asset asset) async {
    final response = await _httpService.post('assets', asset.toJson());
    return Asset.fromJson(response);
  }

  Future<Asset> getAsset(int id) async {
    final response = await _httpService.get('assets/$id');
    return Asset.fromJson(response);
  }

  Future<List<AssetCategory>> getCategories() async {
    final response = await _httpService.get('asset-categories');
    return (response as List).map((json) => AssetCategory.fromJson(json)).toList();
  }

  Future<AssetCategory> createCategory(String name, [String? description]) async {
    final response = await _httpService.post('asset-categories', {
      'name': name,
      'description': description,
    });
    return AssetCategory.fromJson(response);
  }

  Future<void> deleteCategory(int id) async {
    await _httpService.delete('asset-categories/$id');
  }

  Future<AssetExpense> createExpense(AssetExpense expense) async {
    final response = await _httpService.post('asset-expenses', expense.toJson());
    return AssetExpense.fromJson(response);
  }
}
