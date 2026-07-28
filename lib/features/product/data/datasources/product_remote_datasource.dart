import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../config/api_config.dart';
import '../../../../services/api_service.dart';
import '../models/product_model.dart';

/// Product Remote DataSource
///
/// Handles all API calls related to products.
/// Communicates with Odoo ERP API.
class ProductRemoteDataSource {
  final Dio _dio;

  ProductRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiService().dio;

  /// Fetches all products for sale from Odoo API
  ///
  /// Returns list of ProductModel from API response.
  /// API Response format: Direct array of product objects
  /// Example: [{"id": 1, "name": "Product", ...}, ...]
  Future<List<ProductModel>> getProducts({
    required String db,
    required String apiKey,
  }) async {
    try {
      print('🔄 [PRODUCT_DS] Fetching products...');
      print('   DB: $db');
      print('   API Key: ${apiKey.substring(0, 8)}...');

      final response = await _dio.get(
        ApiConfig.getProductSale,
        options: Options(
          headers: ApiConfig.odooApiHeaders(
            db: db,
            apiKey: apiKey,
          ),
        ),
      );

      print('✅ [PRODUCT_DS] Response received: ${response.statusCode}');
      print('📦 [PRODUCT_DS] Response type: ${response.data.runtimeType}');

      // Handle both String and List responses
      List<dynamic> jsonList;

      if (response.data is String) {
        // Response is a JSON string, parse it
        print('🔄 [PRODUCT_DS] Parsing JSON string...');
        final parsed = json.decode(response.data);

        if (parsed is! List) {
          throw Exception(
              'Invalid response format after parsing: expected List, got ${parsed.runtimeType}');
        }
        jsonList = parsed;
      } else if (response.data is List) {
        // Response is already a List
        jsonList = response.data as List<dynamic>;
      } else {
        throw Exception(
            'Invalid response format: expected List or String, got ${response.data.runtimeType}');
      }

      print('✅ [PRODUCT_DS] Products count: ${jsonList.length}');

      final products = jsonList
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return products;
    } on DioException catch (e) {
      print('❌ [PRODUCT_DS] Dio error: ${e.message}');
      print('   Response: ${e.response?.data}');
      throw Exception(
          'Failed to fetch products: ${e.response?.data ?? e.message}');
    } catch (e) {
      print('❌ [PRODUCT_DS] Unexpected error: $e');
      throw Exception('Unexpected error while fetching products: $e');
    }
  }
}
