import '../../data/repositories/customer_repository.dart';
import '../entities/customer.dart';

/// GetCustomersUseCase - Domain Layer
///
/// Business logic for fetching customers from Odoo API
class GetCustomersUseCase {
  final CustomerRepository _repository;

  GetCustomersUseCase({CustomerRepository? repository})
      : _repository = repository ?? CustomerRepository();

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
