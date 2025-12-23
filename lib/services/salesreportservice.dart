import 'package:dio/dio.dart';
import 'package:waslasoftreport/constants/api_client.dart';
import 'package:waslasoftreport/constants/api_endpoints.dart';
import 'package:waslasoftreport/models/sales_report.dart';

class SalesReportService {
  final Dio dio = ApiClient.dio;

  Future<List<SalesreportModel>> fetchReport(
    String fromDate,
    String toDate,
  ) async {
    final response = await dio.get(
      ApiEndpoints.salesReport,
      queryParameters: {'start_date': fromDate, 'end_date': toDate},
    );

    return (response.data as List)
        .map((e) => SalesreportModel.fromJson(e))
        .toList();
  }
}
