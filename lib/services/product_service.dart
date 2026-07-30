import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../config/api_config.dart';
import 'api_service.dart';
import 'config_service.dart';
import 'secure_storage_service.dart';

/// Product Service
///
/// Service untuk mengambil data produk dari Odoo ERP.
///
/// API Endpoint: GET /get_product_sale
class ProductService {
  final _api = ApiService().dio;
  final logger = Logger();

  /// Get all products for sale
  ///
  /// Returns:
  /// ```dart
  /// {
  ///   'Success': true,
  ///   'Message': 'Success',
  ///   'Data': {
  ///     'items': [
  ///       {
  ///         'id': 123,
  ///         'name': 'Product Name',
  ///         'default_code': 'SKU001',
  ///         'list_price': 100000.0,
  ///         'qty_available': 50.0,
  ///         'uom_name': 'Unit',
  ///         'categ_id': [1, 'Category']
  ///       }
  ///     ],
  ///     'total': 100
  ///   }
  /// }
  /// ```
  Future<Map<String, dynamic>> getProductsForSale() async {
    try {
      logger.i('🛍️ Fetching products for sale');

      final response = await _api.get(
        ApiConfig.getProductSale,
        options: Options(
          headers: {
            'db': await ConfigService().getDatabase(),
            'api-key': await SecureStorageService().getAccessToken(),
          },
        ),
      );

      // API returns direct array
      final products = response.data as List;

      logger.i('✅ Loaded ${products.length} products');

      return {
        'Success': true,
        'Message': 'Products loaded successfully',
        'Data': {
          'items': products,
          'total': products.length,
        },
      };
    } on DioException catch (e) {
      logger.e('❌ Network error loading products', error: e);

      return {
        'Success': false,
        'Message': e.response?.data['Message'] ??
            e.response?.statusMessage ??
            'Network error',
        'Data': {
          'items': [],
          'total': 0,
        },
      };
    } on FormatException catch (e) {
      logger.e('❌ Parse error loading products', error: e);

      return {
        'Success': false,
        'Message': 'Invalid data format from server',
        'Data': {
          'items': [],
          'total': 0,
        },
      };
    } catch (e) {
      logger.e('❌ Unexpected error loading products', error: e);

      return {
        'Success': false,
        'Message': 'Unexpected error: $e',
        'Data': {
          'items': [],
          'total': 0,
        },
      };
    }
  }

  /// Get product by ID
  ///
  /// Parameters:
  /// - [id]: Product ID
  ///
  /// Returns:
  /// ```dart
  /// {
  ///   'Success': true,
  ///   'Message': 'Success',
  ///   'Data': {
  ///     'id': 123,
  ///     'name': 'Product Name',
  ///     'list_price': 100000.0,
  ///     ...
  ///   }
  /// }
  /// ```
  Future<Map<String, dynamic>> getProductById(int id) async {
    try {
      logger.i('🛍️ Fetching product ID: $id');

      // Get all products and filter by ID
      final result = await getProductsForSale();

      if (result['Success'] == true) {
        final products = result['Data']['items'] as List;
        final product = products.firstWhere(
          (p) => p['id'] == id,
          orElse: () => null,
        );

        if (product != null) {
          logger.i('✅ Product found: ${product['name']}');
          return {
            'Success': true,
            'Message': 'Product found',
            'Data': product,
          };
        } else {
          logger.w('⚠️ Product not found with ID: $id');
          return {
            'Success': false,
            'Message': 'Product not found',
          };
        }
      } else {
        return result;
      }
    } catch (e) {
      logger.e('❌ Error getting product by ID', error: e);

      return {
        'Success': false,
        'Message': 'Failed to get product: $e',
      };
    }
  }

  /// Search products by name or SKU
  ///
  /// Parameters:
  /// - [query]: Search query
  ///
  /// Returns filtered list of products
  Future<Map<String, dynamic>> searchProducts(String query) async {
    try {
      logger.i('🔍 Searching products: "$query"');

      final result = await getProductsForSale();

      if (result['Success'] == true) {
        final allProducts = result['Data']['items'] as List;
        final lowerQuery = query.toLowerCase();

        final filtered = allProducts.where((product) {
          final name = (product['name'] ?? '').toString().toLowerCase();
          final sku = (product['default_code'] ?? '').toString().toLowerCase();
          return name.contains(lowerQuery) || sku.contains(lowerQuery);
        }).toList();

        logger.i('✅ Found ${filtered.length} products matching "$query"');

        return {
          'Success': true,
          'Message': 'Search completed',
          'Data': {
            'items': filtered,
            'total': filtered.length,
            'query': query,
          },
        };
      } else {
        return result;
      }
    } catch (e) {
      logger.e('❌ Error searching products', error: e);

      return {
        'Success': false,
        'Message': 'Search failed: $e',
        'Data': {
          'items': [],
          'total': 0,
        },
      };
    }
  }

  /// Get products by category
  ///
  /// Parameters:
  /// - [categoryId]: Category ID
  ///
  /// Returns filtered list of products
  Future<Map<String, dynamic>> getProductsByCategory(int categoryId) async {
    try {
      logger.i('📂 Fetching products for category: $categoryId');

      final result = await getProductsForSale();

      if (result['Success'] == true) {
        final allProducts = result['Data']['items'] as List;

        final filtered = allProducts.where((product) {
          final categId = product['categ_id'];
          if (categId is List && categId.isNotEmpty) {
            return categId[0] == categoryId;
          }
          return false;
        }).toList();

        logger.i('✅ Found ${filtered.length} products in category');

        return {
          'Success': true,
          'Message': 'Products loaded',
          'Data': {
            'items': filtered,
            'total': filtered.length,
            'category_id': categoryId,
          },
        };
      } else {
        return result;
      }
    } catch (e) {
      logger.e('❌ Error getting products by category', error: e);

      return {
        'Success': false,
        'Message': 'Failed to get products: $e',
        'Data': {
          'items': [],
          'total': 0,
        },
      };
    }
  }
}
