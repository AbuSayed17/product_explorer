
import 'package:dio/dio.dart';
import '../models/product_model.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://dummyjson.com',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  Future<List<Product>> fetchProducts({
    int limit = 10,
    int skip = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/products',
        queryParameters: {
          'limit': limit,
          'skip': skip,
        },
      );

      final List<dynamic> data = response.data['products'];

      return data.map((item) => Product.fromJson(item)).toList();
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to load products');
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await _dio.get(
        '/products/search',
        queryParameters: {'q': query},
      );

      final List<dynamic> data = response.data['products'];

      return data.map((item) => Product.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Product search failed: $e');
    }
  }

  Future<Product> fetchProductById(int id) async {
    try {
      final response = await _dio.get('/products/$id');
      return Product.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load product: $e');
    }
  }
}
