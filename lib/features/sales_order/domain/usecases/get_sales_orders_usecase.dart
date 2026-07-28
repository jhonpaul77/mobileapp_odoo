import '../../data/repositories/sales_order_repository.dart';
import '../entities/sales_order.dart';

/// GetSalesOrdersUseCase - Domain Layer
///
/// Business logic for fetching sales orders from Odoo API
class GetSalesOrdersUseCase {
  final SalesOrderRepository _repository;

  GetSalesOrdersUseCase({SalesOrderRepository? repository})
      : _repository = repository ?? SalesOrderRepository();

  /// Execute usecase to get sales orders
  Future<List<SalesOrder>> call({
    required String db,
    required String apiKey,
  }) async {
    return await _repository.getSalesOrders(
      db: db,
      apiKey: apiKey,
    );
  }
}
