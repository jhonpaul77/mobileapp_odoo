// services/sales_service.dart
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/sales/sales.dart';
import '../models/sales/sales_response.dart';
import 'api_service.dart';

class SalesService {
  final _api = ApiService().dio;

  Future<SalesResponse> createSales(Sales data) async {
    try {
      final response = await _api.post(
        ApiConfig.sales,
        data: data.toJson(),
      );

      return SalesResponse.fromJson(response.data);
    } on DioException catch (e) {
      return SalesResponse(
        success: false,
        message: e.response?.data['Message'] ?? e.message ?? 'Error',
      );
    } catch (e) {
      return SalesResponse(success: false, message: e.toString());
    }
  }
}
