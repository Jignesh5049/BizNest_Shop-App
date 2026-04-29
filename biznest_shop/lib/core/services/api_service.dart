import 'package:dio/dio.dart';

import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import 'package:image_picker/image_picker.dart';
import 'token_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  static const Duration _authRequestTimeout = Duration(seconds: 60);

  late final Dio _dio;
  final _tokenService = TokenService();

  static const String _baseUrl = 'https://biznest-app.onrender.com/api';

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final jwtToken = await _tokenService.getJwtToken();
          if (jwtToken != null) {
            options.headers['Authorization'] = 'Bearer $jwtToken';
            return handler.next(options);
          }

          try {
            final session = Supabase.instance.client.auth.currentSession;
            if (session != null) {
              options.headers['Authorization'] =
                  'Bearer ${session.accessToken}';
            }
          } catch (_) {
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            _tokenService.clearJwtToken();
            Supabase.instance.client.auth.signOut();
          }

          if (error.type == DioExceptionType.connectionTimeout) {
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                error:
                    'Connection timeout. Make sure the server is running and accessible.',
                type: error.type,
              ),
            );
          }

          if (error.type == DioExceptionType.receiveTimeout) {
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                error:
                    'Request timeout. Server took too long to respond. Check your network connection.',
                type: error.type,
              ),
            );
          }

          if (error.type == DioExceptionType.connectionError) {
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                error:
                    'Connection failed. Check if server at 192.168.6.14:5000 is reachable.',
                type: error.type,
              ),
            );
          }

          return handler.next(error);
        },
      ),
    );
  }

  void setBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }

  Future<Response> signup(Map<String, dynamic> data) =>
      _dio.post('/auth/signup', data: data);
  Future<Response> login(Map<String, dynamic> data) => _dio.post(
        '/auth/login',
        data: data,
        options: Options(
          connectTimeout: _authRequestTimeout,
          sendTimeout: _authRequestTimeout,
          receiveTimeout: _authRequestTimeout,
        ),
      );
  Future<Response> syncUser(Map<String, dynamic> data) =>
      _dio.post('/auth/sync', data: data);
  Future<Response> getMe() => _dio.get('/auth/me');
  Future<Response> updateMe(Map<String, dynamic> data) =>
      _dio.put('/auth/profile', data: data);

  Future<Response> getBusiness() => _dio.get('/business');
  Future<Response> createBusiness(Map<String, dynamic> data) =>
      _dio.post('/business', data: data);
  Future<Response> updateBusiness(Map<String, dynamic> data) =>
      _dio.put('/business', data: data);

  Future<Response> getProducts() => _dio.get('/products');
  Future<Response> getProduct(String id) => _dio.get('/products/$id');
  Future<Response> createProduct(Map<String, dynamic> data) =>
      _dio.post('/products', data: data);
  Future<Response> updateProduct(String id, Map<String, dynamic> data) =>
      _dio.put('/products/$id', data: data);
  Future<Response> deleteProduct(String id) => _dio.delete('/products/$id');
  Future<Response> updateStock(String id, Map<String, dynamic> data) =>
      _dio.patch('/products/$id/stock', data: data);

  Future<Response> getCustomers() => _dio.get('/customers');
  Future<Response> getCustomer(String id) => _dio.get('/customers/$id');
  Future<Response> createCustomer(Map<String, dynamic> data) =>
      _dio.post('/customers', data: data);
  Future<Response> updateCustomer(String id, Map<String, dynamic> data) =>
      _dio.put('/customers/$id', data: data);
  Future<Response> deleteCustomer(String id) => _dio.delete('/customers/$id');

  Future<Response> getOrders({Map<String, dynamic>? params}) =>
      _dio.get('/orders', queryParameters: params);
  Future<Response> getOrder(String id) => _dio.get('/orders/$id');
  Future<Response> createOrder(Map<String, dynamic> data) =>
      _dio.post('/orders', data: data);
  Future<Response> updateOrderStatus(String id, String status) =>
      _dio.put('/orders/$id/status', data: {'status': status});
  Future<Response> updateOrderPayment(String id, Map<String, dynamic> data) =>
      _dio.put('/orders/$id/payment', data: data);
  Future<Response> cancelOrder(String id) => _dio.delete('/orders/$id');

  Future<Response> getExpenses({Map<String, dynamic>? params}) =>
      _dio.get('/expenses', queryParameters: params);
  Future<Response> getExpensesSummary({Map<String, dynamic>? params}) =>
      _dio.get('/expenses/summary', queryParameters: params);
  Future<Response> createExpense(Map<String, dynamic> data) =>
      _dio.post('/expenses', data: data);
  Future<Response> updateExpense(String id, Map<String, dynamic> data) =>
      _dio.put('/expenses/$id', data: data);
  Future<Response> deleteExpense(String id) => _dio.delete('/expenses/$id');

  Future<Response> getDashboardStats({Map<String, dynamic>? params}) =>
      _dio.get('/analytics/dashboard', queryParameters: params);
  Future<Response> getRevenueChart({Map<String, dynamic>? params}) =>
      _dio.get('/analytics/revenue-chart', queryParameters: params);
  Future<Response> getTopProducts({Map<String, dynamic>? params}) =>
      _dio.get('/analytics/top-products', queryParameters: params);
  Future<Response> getHealthScore({Map<String, dynamic>? params}) =>
      _dio.get('/analytics/health-score', queryParameters: params);

  Future<Response> getBusinessReviews({Map<String, dynamic>? params}) =>
      _dio.get('/reviews', queryParameters: params);

  Future<Response> getSupportTickets({Map<String, dynamic>? params}) =>
      _dio.get('/support', queryParameters: params);
  Future<Response> replySupportTicket(String id, Map<String, dynamic> data) =>
      _dio.put('/support/$id/reply', data: data);
  Future<Response> updateSupportTicketStatus(String id, String status) =>
      _dio.put('/support/$id/status', data: {'status': status});

  Future<Response> uploadProductImage(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final multipartFile = MultipartFile.fromBytes(
      bytes,
      filename: imageFile.name.isNotEmpty ? imageFile.name : 'upload.jpg',
    );
    final formData = FormData.fromMap({'file': multipartFile});
    return _dio.post('/uploads', data: formData);
  }

  // ==================== CUSTOMER STORE API ====================
  Future<Response> getStoreBusinesses({Map<String, dynamic>? params}) =>
      _dio.get('/store/businesses', queryParameters: params);
  Future<Response> getStoreBusiness(String id) =>
      _dio.get('/store/businesses/$id');
  Future<Response> getStoreProduct(String id) =>
      _dio.get('/store/products/$id');
  Future<Response> getProductReviews(String id) =>
      _dio.get('/store/products/$id/reviews');
  Future<Response> getAllStoreProducts({Map<String, dynamic>? params}) =>
      _dio.get('/store/all-products', queryParameters: params);

  Future<Response> createStoreOrder(Map<String, dynamic> data) =>
      _dio.post('/store/orders', data: data);
  Future<Response> getStoreOrders({Map<String, dynamic>? params}) =>
      _dio.get('/store/orders', queryParameters: params);
  Future<Response> getStoreOrder(String id) => _dio.get('/store/orders/$id');
  Future<Response> cancelStoreOrder(String id) =>
      _dio.put('/store/orders/$id/cancel');
  Future<Response> reorder(String id) => _dio.post('/store/orders/$id/reorder');

  Future<Response> getReviewEligibility(String id) =>
      _dio.get('/store/products/$id/reviews/eligibility');
  Future<Response> createReview(String id, Map<String, dynamic> data) =>
      _dio.post('/store/products/$id/reviews', data: data);

  Future<Response> getFavorites() => _dio.get('/store/favorites');
  Future<Response> addFavorite(String productId) =>
      _dio.post('/store/favorites/$productId');
  Future<Response> removeFavorite(String productId) =>
      _dio.delete('/store/favorites/$productId');

  Future<Response> getAddresses() => _dio.get('/store/addresses');
  Future<Response> addAddress(Map<String, dynamic> data) =>
      _dio.post('/store/addresses', data: data);
  Future<Response> updateAddress(String id, Map<String, dynamic> data) =>
      _dio.put('/store/addresses/$id', data: data);
  Future<Response> deleteAddress(String id) =>
      _dio.delete('/store/addresses/$id');

  Future<Response> createSupportTicket(Map<String, dynamic> data) =>
      _dio.post('/store/support', data: data);
  Future<Response> getCustomerSupportTickets() => _dio.get('/store/support');

  Future<Response> getCustomerDashboard() => _dio.get('/store/dashboard');
}
