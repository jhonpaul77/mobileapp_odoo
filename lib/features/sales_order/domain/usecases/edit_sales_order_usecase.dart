import '../../../../services/sales_service.dart';

/// EditSalesOrderUseCase - Domain Layer
///
/// Business logic for editing a sales order
///
/// NOTE: Using Service pattern instead of Repository for compatibility
class EditSalesOrderUseCase {
  final SalesService _service;

  EditSalesOrderUseCase({SalesService? service})
      : _service = service ?? SalesService();

  /// Execute usecase to edit a sales order
  Future<Map<String, dynamic>> call({
    required int id,
    required int partnerId,
    required String partnerPhone,
    required String partnerDistrict,
    required String partnerCity,
    required String partnerState,
    required String dateOrder,
    required int warehouseId,
    int? kurirId,
    String? awb,
    required String state,
    String? notes,
    required List<Map<String, dynamic>> orderLines,
  }) async {
    return await _service.editSaleOrder(
      id: id,
      partnerId: partnerId,
      partnerPhone: partnerPhone,
      partnerDistrict: partnerDistrict,
      partnerCity: partnerCity,
      partnerState: partnerState,
      dateOrder: dateOrder,
      warehouseId: warehouseId,
      kurirId: kurirId,
      awb: awb,
      state: state,
      notes: notes,
      orderLines: orderLines,
    );
  }
}
