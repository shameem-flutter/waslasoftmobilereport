import 'package:shared_preferences/shared_preferences.dart';

class ApiEndpoints {
  static String baseUrl = 'https://127.0.0.1:8000/';

  static const String _baseUrlKey = 'api_base_url';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_baseUrlKey);
    if (savedUrl != null) {
      baseUrl = savedUrl;
    }
  }

  static Future<void> updateBaseUrl(String protocol, String host) async {
    final newUrl = '$protocol$host/';
    baseUrl = newUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, newUrl);
  }

  static const String login = 'api/v1/accounts/login/';
  static const String items = '/api/v2/license/item/';
  static const String salesReport = "api/v1/integration/sale-report/";
  static const String customerReport = "api/v1/integration/customer-ledger/";
  static const String customerName = "api/v1/integration/customer/";
}
