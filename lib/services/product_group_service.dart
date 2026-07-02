import 'package:dio/dio.dart';
import 'package:pintarx/models/product/product_group/product_group.dart';
import 'package:pintarx/models/product/product_group/product_group_response.dart';
import 'api_service.dart';
import '../config/api_config.dart';

class ProductGroupService {
  final _api = ApiService().dio;

  // ✅ FETCH - Get all product groups with pagination
  Future<ProductGroupResponse> fetchProductGroups({
    int length = 10,
    int start = 0,
  }) async {
    try {
      print('📦 [PRODUCT_GROUP] Fetching product groups...');
      print('📦 [PRODUCT_GROUP] URL: ${ApiConfig.baseUrl}${ApiConfig.productGroupFetch}');
      print('📦 [PRODUCT_GROUP] Params: length=$length, start=$start');
      
      final response = await _api.get(
        ApiConfig.productGroupFetch,
        queryParameters: {
          'length': length,
          'start': start,
        },
      );

      print('📦 [PRODUCT_GROUP] Response status: ${response.statusCode}');
      print('📦 [PRODUCT_GROUP] Response data: ${response.data}');

      final productGroupResponse = ProductGroupResponse.fromJsonList(response.data);
      
      if (productGroupResponse.success) {
        print('✅ [PRODUCT_GROUP] Fetched ${productGroupResponse.data?.length ?? 0} groups');
      } else {
        print('⚠️ [PRODUCT_GROUP] Fetch warning: ${productGroupResponse.message}');
      }

      return productGroupResponse;
    } on DioException catch (e) {
      print('❌ [PRODUCT_GROUP] Fetch error: ${e.message}');
      print('❌ [PRODUCT_GROUP] Status: ${e.response?.statusCode}');
      print('❌ [PRODUCT_GROUP] Response: ${e.response?.data}');
      return ProductGroupResponse(
        success: false,
        message: e.response?.data['Message'] ?? 'Failed to fetch product groups: ${e.message}',
      );
    } catch (e) {
      print('❌ [PRODUCT_GROUP] Unexpected error: $e');
      return ProductGroupResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  // ✅ GET - Get single product group by ID
  Future<ProductGroupResponse> getProductGroupDetail(String groupId) async {
    try {
      print('📦 [PRODUCT_GROUP] Getting detail for: $groupId');
      
      final response = await _api.get(
        '${ApiConfig.productGroupGet}/$groupId',
      );

      final productGroupResponse = ProductGroupResponse.fromJsonSingle(response.data);
      
      if (productGroupResponse.success) {
        print('✅ [PRODUCT_GROUP] Detail loaded: ${productGroupResponse.singleData?.nama}');
      }

      return productGroupResponse;
    } on DioException catch (e) {
      print('❌ [PRODUCT_GROUP] Detail error: ${e.message}');
      return ProductGroupResponse(
        success: false,
        message: e.response?.data['Message'] ?? 'Failed to get product group detail',
      );
    }
  }

  // ✅ CREATE - Add new product group
  Future<ProductGroupResponse> createProductGroup({
    required String nama,
    required String keterangan,
    required String catatan,
  }) async {
    try {
      print('📦 [PRODUCT_GROUP] Creating product group: $nama');
      print('📦 [PRODUCT_GROUP] URL: ${ApiConfig.baseUrl}${ApiConfig.productGroupCreate}');
      print('📦 [PRODUCT_GROUP] Data: nama=$nama, keterangan=$keterangan');
      
      final response = await _api.post(
        ApiConfig.productGroupCreate,
        data: {
          'nama': nama,
          'keterangan': keterangan,
          'catatan': catatan,
        },
      );

      print('📦 [PRODUCT_GROUP] Create response: ${response.data}');

      final productGroupResponse = ProductGroupResponse.fromJsonSingle(response.data);
      
      if (productGroupResponse.success) {
        print('✅ [PRODUCT_GROUP] Created successfully');
      } else {
        print('⚠️ [PRODUCT_GROUP] Create warning: ${productGroupResponse.message}');
      }

      return productGroupResponse;
    } on DioException catch (e) {
      print('❌ [PRODUCT_GROUP] Create error: ${e.message}');
      print('❌ [PRODUCT_GROUP] Status: ${e.response?.statusCode}');
      print('❌ [PRODUCT_GROUP] Response: ${e.response?.data}');
      
      if (e.response?.statusCode == 500) {
        final data = e.response?.data;
        if (data != null && data is Map) {
          return ProductGroupResponse(
            success: false,
            message: data['Message'] ?? 'Gagal menambah grup produk',
          );
        }
      }
      
      return ProductGroupResponse(
        success: false,
        message: e.response?.data['Message'] ?? 'Failed to create product group: ${e.message}',
      );
    } catch (e) {
      print('❌ [PRODUCT_GROUP] Unexpected error: $e');
      return ProductGroupResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  // ✅ UPDATE - Edit existing product group
  Future<ProductGroupResponse> updateProductGroup({
    required String id,
    required String nama,
    required String keterangan,
    required String catatan,
  }) async {
    try {
      print('📦 [PRODUCT_GROUP] Updating product group: $id');
      print('📦 [PRODUCT_GROUP] URL: ${ApiConfig.baseUrl}${ApiConfig.productGroupUpdate}');
      print('📦 [PRODUCT_GROUP] Data: id=$id, nama=$nama');

      final response = await _api.put(
        ApiConfig.productGroupUpdate,
        data: {
          'id': id,
          'nama': nama,
          'keterangan': keterangan,
          'catatan': catatan,
        },
      );

      print('📦 [PRODUCT_GROUP] Update response: ${response.data}');

      final productGroupResponse = ProductGroupResponse.fromJsonSingle(response.data);

      if (productGroupResponse.success) {
        print('✅ [PRODUCT_GROUP] Updated successfully');
      } else {
        print('⚠️ [PRODUCT_GROUP] Update warning: ${productGroupResponse.message}');
      }

      return productGroupResponse;
    } on DioException catch (e) {
      print('❌ [PRODUCT_GROUP] Update error: ${e.message}');
      print('❌ [PRODUCT_GROUP] Status: ${e.response?.statusCode}');
      print('❌ [PRODUCT_GROUP] Response: ${e.response?.data}');

      if (e.response?.statusCode == 500) {
        final data = e.response?.data;
        if (data != null && data is Map) {
          final message = data['Message'] ?? 'Gagal update grup produk';
          if (message.contains('no rows')) {
            return ProductGroupResponse(
              success: false,
              message: 'Grup produk tidak ditemukan atau sudah dihapus',
            );
          }
          return ProductGroupResponse(
            success: false,
            message: message,
          );
        }
      }

      return ProductGroupResponse(
        success: false,
        message: e.response?.data['Message'] ?? 'Failed to update product group: ${e.message}',
      );
    } catch (e) {
      print('❌ [PRODUCT_GROUP] Unexpected error: $e');
      return ProductGroupResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  // ✅ DELETE - Remove product group
  Future<ProductGroupResponse> deleteProductGroup(String groupId) async {
    try {
      print('📦 [PRODUCT_GROUP] Deleting product group: $groupId');
      print('📦 [PRODUCT_GROUP] URL: ${ApiConfig.baseUrl}${ApiConfig.productGroupUpdate}/$groupId');
      
      final response = await _api.delete(
        '${ApiConfig.productGroupUpdate}/$groupId',
      );

      print('📦 [PRODUCT_GROUP] Delete response: ${response.data}');

      final productGroupResponse = ProductGroupResponse.fromJsonNoData(response.data);
      
      if (productGroupResponse.success) {
        print('✅ [PRODUCT_GROUP] Deleted successfully');
      } else {
        print('⚠️ [PRODUCT_GROUP] Delete warning: ${productGroupResponse.message}');
      }

      return productGroupResponse;
    } on DioException catch (e) {
      print('❌ [PRODUCT_GROUP] Delete error: ${e.message}');
      print('❌ [PRODUCT_GROUP] Status: ${e.response?.statusCode}');
      print('❌ [PRODUCT_GROUP] Response: ${e.response?.data}');
      
      if (e.response?.statusCode == 500) {
        final data = e.response?.data;
        if (data != null && data is Map) {
          final message = data['Message'] ?? 'Gagal hapus grup produk';
          
          if (message.contains('no rows')) {
            return ProductGroupResponse(
              success: false,
              message: 'Grup produk tidak ditemukan atau sudah dihapus',
            );
          }
          
          return ProductGroupResponse(
            success: false,
            message: message,
          );
        }
      }
      
      return ProductGroupResponse(
        success: false,
        message: e.response?.data['Message'] ?? 'Failed to delete product group: ${e.message}',
      );
    } catch (e) {
      print('❌ [PRODUCT_GROUP] Unexpected error: $e');
      return ProductGroupResponse(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }
}