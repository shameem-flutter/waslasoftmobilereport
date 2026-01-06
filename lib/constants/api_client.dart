import 'package:dio/dio.dart';
import 'package:waslasoftreport/constants/api_endpoints.dart';
import 'package:waslasoftreport/services/auth_interseptor.dart';

class ApiClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(AuthInterceptor());

  static Dio get dio {
    _dio.options.baseUrl = ApiEndpoints.baseUrl;
    return _dio;
  }
}
