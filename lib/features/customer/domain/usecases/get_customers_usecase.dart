import '../../data/repositories/customer_repository_impl.dart';
import '../entities/customer.dart';

/// GetCustomersUseCase - Domain Layer
///
/// Business logic for fetching customers from Odoo API
class GetCustomersUseCase {
  final CustomerRepositoryImpl _repository;

  GetCustomersUseCase({CustomerRepositoryImpl? repository})
      : _repository = repository ?? CustomerRepositoryImpl();

  /// Execute usecase to get customers
  ///
  /// Parameters:
  /// - db: Database name from config
  /// - apiKey: API key from secure storage
  Future<List<Customer>> call({
    required String db,
    required String apiKey,
  }) async {
    return await _repository.getCustomers(
      db: db,
      apiKey: apiKey,
    );
  }
}
