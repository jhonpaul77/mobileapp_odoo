import '../../data/repositories/product_repository_impl.dart';
import '../entities/product.dart';

/// Get Products UseCase
///
/// Business logic for retrieving products.
/// Called by presentation layer (Provider).
class GetProductsUseCase {
  final ProductRepositoryImpl _repository;

  GetProductsUseCase({ProductRepositoryImpl? repository})
      : _repository = repository ?? ProductRepositoryImpl();

  /// Executes the use case to get all products
  ///
  /// Returns `List<Product>` for display in UI.
  Future<List<Product>> call({
    required String db,
    required String apiKey,
  }) async {
    try {
      print('🔄 [GET_PRODUCTS_UC] Executing use case...');

      final products = await _repository.getProducts(
        db: db,
        apiKey: apiKey,
      );

      print(
          '✅ [GET_PRODUCTS_UC] Use case completed: ${products.length} products');

      return products;
    } catch (e) {
      print('❌ [GET_PRODUCTS_UC] Use case error: $e');
      rethrow;
    }
  }
}
