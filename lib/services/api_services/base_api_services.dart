import 'package:dio/dio.dart';
import 'package:waslasoftreport/constants/api_client.dart';

class BaseApiServices {
  final Dio dio;

  BaseApiServices({Dio? dio}) : dio = dio ?? ApiClient.dio;

  Future<Response?> get({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await dio.get(endpoint, queryParameters: queryParameters);
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<Response?> post({
    required String endpoint,
    required dynamic data,
  }) async {
    try {
      return await dio.post(endpoint, data: data);
    } on DioException catch (e) {
      return e.response;
    }
  }
}
