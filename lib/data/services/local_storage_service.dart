
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';

class LocalStorageService {
  static const String _cacheKey = 'cached_products';
  static const String _localIdsKey = 'local_product_ids';
  static const String _deletedIdsKey = 'deleted_product_ids';
  static const String _editedIdsKey = 'edited_product_ids';

  Future<void> saveProducts(List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();

    final data = products.map((p) => p.toJson()).toList();

    await prefs.setString(_cacheKey, jsonEncode(data));
  }

  Future<List<Product>> getProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_cacheKey);

    if (data == null) return [];

    final List<dynamic> decoded = jsonDecode(data);

    return decoded
        .map((item) => Product.fromJson(item))
        .toList();
  }

  Future<List<int>> getIds(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(key) ?? [];

    return values.map((value) => int.tryParse(value) ?? 0).toList();
  }

  Future<void> saveIds(String key, List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      key,
      ids.map((id) => id.toString()).toList(),
    );
  }

  Future<List<int>> getLocalIds() => getIds(_localIdsKey);

  Future<void> saveLocalIds(List<int> ids) =>
      saveIds(_localIdsKey, ids);

  Future<List<int>> getDeletedIds() => getIds(_deletedIdsKey);

  Future<void> saveDeletedIds(List<int> ids) =>
      saveIds(_deletedIdsKey, ids);

  Future<List<int>> getEditedIds() => getIds(_editedIdsKey);

  Future<void> saveEditedIds(List<int> ids) =>
      saveIds(_editedIdsKey, ids);

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_cacheKey);
    await prefs.remove(_localIdsKey);
    await prefs.remove(_deletedIdsKey);
    await prefs.remove(_editedIdsKey);
  }
}
