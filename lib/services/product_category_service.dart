import 'package:dio/dio.dart';
import 'package:pintarx/models/product/product_category/product_category_response.dart';
import 'api_service.dart';
import '../config/api_config.dart';

class ProductCategoryService {
  final _api = ApiService().dio;

  // GET - Fetch all categories
  Future<ProductCategoryResponse> fetchCategories({
    int length = 50,
    int start = 0,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.productCategoryFetch}';
      print('📦 [CATEGORY] Fetching categories...');
      print('📦 [CATEGORY] URL: $url');
      print('📦 [CATEGORY] Params: length=$length, start=$start');

      final response = await _api.get(
        ApiConfig.productCategoryFetch,
        queryParameters: {
          'length': length,
          'start': start,
        },
      );

      print('📦 [CATEGORY] Response status: ${response.statusCode}');
      print('📦 [CATEGORY] Response data: ${response.data}');

      final categoryResponse =
          ProductCategoryResponse.fromJsonList(response.data);

      if (categoryResponse.success) {
        print(
            '✅ [CATEGORY] Fetched ${categoryResponse.data?.length ?? 0} categories');
      } else {
        print('⚠️ [CATEGORY] Fetch warning: ${categoryResponse.message}');
      }

      return categoryResponse;
    } on DioException catch (e) {
      final message = (e.response?.data is Map)
          ? e.response?.data['Message']
          : e.response?.data?.toString();

      print('❌ [CATEGORY] Fetch error: ${e.message}');
      print('❌ [CATEGORY] Status: ${e.response?.statusCode}');
      print('❌ [CATEGORY] Response: $message');

      return ProductCategoryResponse(
        success: false,
        message: message ?? 'Gagal memuat kategori: ${e.message}',
      );
    } catch (e) {
      print('❌ [CATEGORY] Unexpected error: $e');
      return ProductCategoryResponse(
        success: false,
        message: 'Terjadi kesalahan: $e',
      );
    }
  }

  // GET - Get single category by ID
  Future<ProductCategoryResponse> getCategoryDetail(String categoryId) async {
    try {
      final url =
          '${ApiConfig.baseUrl}${ApiConfig.productCategoryGet}/$categoryId';
      print('📦 [CATEGORY] Getting detail for: $categoryId');
      print('📦 [CATEGORY] URL: $url');

      final response =
          await _api.get('${ApiConfig.productCategoryGet}/$categoryId');

      final categoryResponse =
          ProductCategoryResponse.fromJsonSingle(response.data);

      if (categoryResponse.success) {
        print(
            '✅ [CATEGORY] Detail loaded: ${categoryResponse.singleData?.nama}');
      }

      return categoryResponse;
    } on DioException catch (e) {
      final message = (e.response?.data is Map)
          ? e.response?.data['Message']
          : e.response?.data?.toString();

      print('❌ [CATEGORY] Detail error: ${e.message}');
      return ProductCategoryResponse(
        success: false,
        message: message ?? 'Gagal memuat detail kategori',
      );
    }
  }

  // POST - Create new category
  Future<ProductCategoryResponse> createCategory({
    required String nama,
    required String keterangan,
    required String catatan,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.productCategoryCreate}';
      print('📦 [CATEGORY] Creating category: $nama');
      print('📦 [CATEGORY] URL: $url');

      final response = await _api.post(
        ApiConfig.productCategoryCreate,
        data: {
          'nama': nama,
          'keterangan': keterangan,
          'catatan': catatan,
        },
      );

      print('📦 [CATEGORY] Create response: ${response.data}');

      final categoryResponse =
          ProductCategoryResponse.fromJsonSingle(response.data);

      if (categoryResponse.success) {
        print('✅ [CATEGORY] Created successfully');
      } else {
        print('⚠️ [CATEGORY] Create warning: ${categoryResponse.message}');
      }

      return categoryResponse;
    } on DioException catch (e) {
      final message = (e.response?.data is Map)
          ? e.response?.data['Message']
          : e.response?.data?.toString();

      print('❌ [CATEGORY] Create error: ${e.message}');
      print('❌ [CATEGORY] Status: ${e.response?.statusCode}');
      print('❌ [CATEGORY] Response: $message');

      return ProductCategoryResponse(
        success: false,
        message: message ?? 'Gagal menambah kategori: ${e.message}',
      );
    } catch (e) {
      print('❌ [CATEGORY] Unexpected error: $e');
      return ProductCategoryResponse(
        success: false,
        message: 'Terjadi kesalahan: $e',
      );
    }
  }

  // PUT - Update existing category
  Future<ProductCategoryResponse> updateCategory({
    required String id,
    required String nama,
    required String keterangan,
    required String catatan,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.productCategoryUpdate}';
      print('📦 [CATEGORY] Updating category: $id');
      print('📦 [CATEGORY] URL: $url');

      final response = await _api.put(
        ApiConfig.productCategoryUpdate,
        data: {
          'id': id,
          'nama': nama,
          'keterangan': keterangan,
          'catatan': catatan,
        },
      );

      print('📦 [CATEGORY] Update response: ${response.data}');

      final categoryResponse =
          ProductCategoryResponse.fromJsonSingle(response.data);

      if (categoryResponse.success) {
        print('✅ [CATEGORY] Updated successfully');
      } else {
        print('⚠️ [CATEGORY] Update warning: ${categoryResponse.message}');
      }

      return categoryResponse;
    } on DioException catch (e) {
      final message = (e.response?.data is Map)
          ? e.response?.data['Message']
          : e.response?.data?.toString();

      print('❌ [CATEGORY] Update error: ${e.message}');
      print('❌ [CATEGORY] Status: ${e.response?.statusCode}');
      print('❌ [CATEGORY] Response: $message');

      return ProductCategoryResponse(
        success: false,
        message: message ?? 'Gagal update kategori: ${e.message}',
      );
    } catch (e) {
      print('❌ [CATEGORY] Unexpected error: $e');
      return ProductCategoryResponse(
        success: false,
        message: 'Terjadi kesalahan: $e',
      );
    }
  }
}
