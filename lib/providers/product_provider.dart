
import 'package:flutter/material.dart';

import '../data/models/product_model.dart';
import '../data/services/api_service.dart';
import '../data/services/local_storage_service.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LocalStorageService _storage = LocalStorageService();

  List<Product> _products = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  String _searchQuery = '';

  int _skip = 0;
  final int _limit = 10;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  // Apply local changes to API products.
  Future<List<Product>> _mergeLocalChanges(
      List<Product> remoteProducts,
      ) async {
    final cached = await _storage.getProducts();
    final localIds = await _storage.getLocalIds();
    final deletedIds = await _storage.getDeletedIds();
    final editedIds = await _storage.getEditedIds();

    final Map<int, Product> cachedMap = {
      for (final product in cached) product.id: product,
    };

    final result = <Product>[];

    for (final remote in remoteProducts) {
      if (deletedIds.contains(remote.id)) continue;

      if (editedIds.contains(remote.id) &&
          cachedMap.containsKey(remote.id)) {
        result.add(cachedMap[remote.id]!);
      } else {
        result.add(remote);
      }
    }

    for (final id in localIds) {
      if (deletedIds.contains(id)) continue;

      final localProduct = cachedMap[id];

      if (localProduct != null &&
          !result.any((p) => p.id == id)) {
        result.add(localProduct);
      }
    }

    return result;
  }

  Future<void> initializeProducts() async {
    try {
      final cached = await _storage.getProducts();

      if (cached.isNotEmpty) {
        _products = cached;
        _skip = 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Cache error: $e');
    }

    await fetchProducts();
  }

  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = null;
    _skip = 0;
    _hasMore = true;
    notifyListeners();

    try {
      final remote = await _apiService.fetchProducts(
        limit: _limit,
        skip: 0,
      );

      _products = await _mergeLocalChanges(remote);
      _skip = remote.length;
      _hasMore = remote.length == _limit;

      await _storage.saveProducts(_products);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final remote = await _apiService.fetchProducts(
        limit: _limit,
        skip: _skip,
      );

      final merged = await _mergeLocalChanges(remote);

      for (final product in merged) {
        if (!_products.any((p) => p.id == product.id)) {
          _products.add(product);
        }
      }

      _skip += remote.length;
      _hasMore = remote.length == _limit;

      await _storage.saveProducts(_products);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> searchProducts(String query) async {
    _searchQuery = query.trim();

    if (_searchQuery.isEmpty) {
      await refreshProducts();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final remote = await _apiService.searchProducts(_searchQuery);
      final allCached = await _storage.getProducts();
      final deletedIds = await _storage.getDeletedIds();

      final cachedMatches = allCached.where((p) {
        return p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.category.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();

      final results = <Product>[];

      for (final product in remote) {
        if (!deletedIds.contains(product.id)) {
          results.add(product);
        }
      }

      for (final product in cachedMatches) {
        if (!deletedIds.contains(product.id) &&
            !results.any((p) => p.id == product.id)) {
          results.add(product);
        }
      }

      _products = results;
      _hasMore = false;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProducts() async {
    _searchQuery = '';
    await fetchProducts();
  }

  // CREATE
  Future<void> addProduct(Product product) async {
    final localIds = await _storage.getLocalIds();

    _products.insert(0, product);
    localIds.add(product.id);

    await _storage.saveLocalIds(localIds);
    await _storage.saveProducts(_products);

    notifyListeners();
  }

  // UPDATE
  Future<void> updateProduct(Product updatedProduct) async {
    final index = _products.indexWhere(
          (p) => p.id == updatedProduct.id,
    );

    if (index == -1) return;

    final editedIds = await _storage.getEditedIds();

    _products[index] = updatedProduct;

    if (!editedIds.contains(updatedProduct.id)) {
      editedIds.add(updatedProduct.id);
    }

    await _storage.saveEditedIds(editedIds);
    await _storage.saveProducts(_products);

    notifyListeners();
  }

  // DELETE
  Future<void> deleteProduct(int id) async {
    final localIds = await _storage.getLocalIds();
    final deletedIds = await _storage.getDeletedIds();
    final editedIds = await _storage.getEditedIds();

    _products.removeWhere((p) => p.id == id);

    localIds.remove(id);

    if (!deletedIds.contains(id)) {
      deletedIds.add(id);
    }

    editedIds.remove(id);

    await _storage.saveLocalIds(localIds);
    await _storage.saveDeletedIds(deletedIds);
    await _storage.saveEditedIds(editedIds);
    await _storage.saveProducts(_products);

    notifyListeners();
  }
  int generateProductId() {
    int highestId = 1000000;

    for (final product in _products) {
      if (product.id > highestId) {
        highestId = product.id;
      }
    }

    return highestId + 1;
  }

}
