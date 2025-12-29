import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waslasoftreport/constants/api_client.dart';
import 'package:waslasoftreport/constants/api_endpoints.dart';

class AuthService {
  final Dio _dio = ApiClient.dio;

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: {'username': username, 'password': password},
    );

    if (response.statusCode == 200) {
      final token = response.data['token'];
      if (token == null) return false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return token != null && token.isNotEmpty;
  }
}
