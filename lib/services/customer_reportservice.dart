import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:waslasoftreport/constants/api_client.dart';
import 'package:waslasoftreport/constants/api_endpoints.dart';
import 'package:waslasoftreport/models/customer.dart';
import 'package:waslasoftreport/models/customer_report.dart';

class CustomerReportservice {
  final Dio dio = ApiClient.dio;

  Future<List<Customer>> fetchCustomers() async {
    final res = await dio.get(ApiEndpoints.customerName);
    return (res.data as List).map((e) => Customer.fromJson(e)).toList();
  }

  Future<Customer?> getCustomerByName(String name) async {
    final customers = await fetchCustomers();

    try {
      return customers.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<CustomerReportModel?> customerReportGet(
    String fromDate,
    String toDate,
    int customerId,
  ) async {
    debugPrint('🟡 SERVICE CALL');
    debugPrint('Query params → from: $fromDate, to: $toDate, id: $customerId');

    final response = await dio.get(
      ApiEndpoints.customerReport,
      queryParameters: {
        'start_date': fromDate,
        'end_date': toDate,
        'customer_id': customerId,
      },
    );

    debugPrint('🟡 RAW RESPONSE TYPE: ${response.data.runtimeType}');
    debugPrint('🟡 RAW RESPONSE DATA: ${response.data}');

    // ✅ CASE 1: Backend returned empty list
    if (response.data is List) {
      debugPrint('⚠️ EMPTY LEDGER LIST RETURNED');
      return null;
    }

    // ✅ CASE 2: Backend returned ledger object
    if (response.data is Map<String, dynamic>) {
      debugPrint('🟢 LEDGER OBJECT FOUND');
      return CustomerReportModel.fromJson(response.data);
    }

    // ❌ Unexpected response
    throw Exception('Unexpected response format');
  }
}
