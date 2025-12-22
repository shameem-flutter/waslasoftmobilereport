import 'package:dio/dio.dart';
import 'package:waslasoftreport/constants/api_endpoints.dart';
import 'package:waslasoftreport/services/auth_interseptor.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(AuthInterceptor());
}
