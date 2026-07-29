import '../../domain/entities/customer.dart';
import '../datasources/customer_remote_datasource.dart';

/// Customer Repository Implementation
///
/// Implements business logic for customer operations.
/// Acts as a bridge between data layer and domain layer.
class CustomerRepositoryImpl {
  final CustomerRemoteDataSource _remoteDataSource;

  CustomerRepositoryImpl({CustomerRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? CustomerRemoteDataSource();

  /// Fetches all customers and converts them to domain entities
  ///
  /// Returns `List<Customer>` (Entity) for use in presentation layer.
  /// Handles errors and converts Models to Entities.
  Future<List<Customer>> getCustomers({
    required String db,
    required String apiKey,
  }) async {
    try {
      print('🔄 [CUSTOMER_REPO] Getting customers...');

      final customerModels = await _remoteDataSource.getCustomers(
        db: db,
        apiKey: apiKey,
      );

      print(
          '✅ [CUSTOMER_REPO] Converting ${customerModels.length} models to entities');

      final customers =
          customerModels.map((model) => model.toEntity()).toList();

      return customers;
    } catch (e) {
      print('❌ [CUSTOMER_REPO] Error: $e');
      rethrow;
    }
  }

  /// Creates a new customer and returns the created entity
  ///
  /// Returns `Customer` (Entity) for use in presentation layer.
  Future<Customer> createCustomer({
    required String db,
    required String apiKey,
    required Map<String, dynamic> data,
  }) async {
    try {
      print('🔄 [CUSTOMER_REPO] Creating customer...');

      final customerModel = await _remoteDataSource.createCustomer(
        db: db,
        apiKey: apiKey,
        data: data,
      );

      print('✅ [CUSTOMER_REPO] Customer created, converting to entity');

      return customerModel.toEntity();
    } catch (e) {
      print('❌ [CUSTOMER_REPO] Error: $e');
      rethrow;
    }
  }

  /// Updates an existing customer and returns the updated entity
  ///
  /// Returns `Customer` (Entity) for use in presentation layer.
  Future<Customer> editCustomer({
    required String db,
    required String apiKey,
    required int id,
    required Map<String, dynamic> data,
  }) async {
    try {
      print('🔄 [CUSTOMER_REPO] Editing customer $id...');

      final customerModel = await _remoteDataSource.editCustomer(
        db: db,
        apiKey: apiKey,
        id: id,
        data: data,
      );

      print('✅ [CUSTOMER_REPO] Customer updated, converting to entity');

      return customerModel.toEntity();
    } catch (e) {
      print('❌ [CUSTOMER_REPO] Error: $e');
      rethrow;
    }
  }
}
