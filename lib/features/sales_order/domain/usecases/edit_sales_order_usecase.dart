import '../../data/repositories/sales_order_repository.dart';
import '../entities/sales_order.dart';

/// EditSalesOrderUseCase - Domain Layer
///
/// Business logic for editing a sales order
class EditSalesOrderUseCase {
  final SalesOrderRepository _repository;

  EditSalesOrderUseCase({SalesOrderRepository? repository})
      : _repository = repository ?? SalesOrderRepository();

  /// Execute usecase to edit a sales order
  Future<bool> call({
    required String db,
    required String apiKey,
    required SalesOrder order,
  }) async {
    return await _repository.editSalesOrder(
      db: db,
      apiKey: apiKey,
      order: order,
    );
  }
}
