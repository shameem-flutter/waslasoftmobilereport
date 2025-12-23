import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waslasoftreport/constants/api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.path.contains(ApiEndpoints.login)) {
      return handler.next(options);
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access_token");
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'token $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      // UI redirection handled elsewhere
    }
    super.onError(err, handler);
  }
}
