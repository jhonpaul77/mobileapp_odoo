import '../../domain/entities/product.dart';
import '../datasources/product_remote_datasource.dart';

/// Product Repository Implementation
///
/// Implements business logic for product operations.
/// Acts as a bridge between data layer and domain layer.
class ProductRepositoryImpl {
  final ProductRemoteDataSource _remoteDataSource;

  ProductRepositoryImpl({ProductRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? ProductRemoteDataSource();

  /// Fetches all products and converts them to domain entities
  ///
  /// Returns `List<Product>` (Entity) for use in presentation layer.
  /// Handles errors and converts Models to Entities.
  Future<List<Product>> getProducts({
    required String db,
    required String apiKey,
  }) async {
    try {
      print('🔄 [PRODUCT_REPO] Getting products...');

      final productModels = await _remoteDataSource.getProducts(
        db: db,
        apiKey: apiKey,
      );

      print(
          '✅ [PRODUCT_REPO] Converting ${productModels.length} models to entities');

      final products = productModels.map((model) => model.toEntity()).toList();

      return products;
    } catch (e) {
      print('❌ [PRODUCT_REPO] Error: $e');
      rethrow;
    }
  }
}
