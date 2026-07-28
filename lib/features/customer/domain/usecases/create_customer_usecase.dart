import '../../data/repositories/customer_repository.dart';
import '../entities/customer.dart';

/// CreateCustomerUseCase - Domain Layer
///
/// Business logic for creating a new customer
class CreateCustomerUseCase {
  final CustomerRepository _repository;

  CreateCustomerUseCase({CustomerRepository? repository})
      : _repository = repository ?? CustomerRepository();

  /// Execute create customer
  ///
  /// Parameters:
  /// - db: Database name
  /// - apiKey: API authentication key
  /// - data: Customer data (name, phone, email, address, etc.)
  Future<Customer> call({
    required String db,
    required String apiKey,
    required Map<String, dynamic> data,
  }) async {
    // Validate required fields
    if (data['name'] == null || data['name'].toString().trim().isEmpty) {
      throw Exception('Nama customer wajib diisi');
    }

    if (data['name'].toString().trim().length < 3) {
      throw Exception('Nama customer minimal 3 karakter');
    }

    // Validate email if provided
    if (data['email'] != null && data['email'].toString().isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(data['email'])) {
        throw Exception('Format email tidak valid');
      }
    }

    // Call repository
    return await _repository.createCustomer(
      db: db,
      apiKey: apiKey,
      data: data,
    );
  }
}
