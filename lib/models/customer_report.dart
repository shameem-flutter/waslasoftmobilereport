// To parse this JSON data, do
//
//     final customerReportModel = customerReportModelFromJson(jsonString);

import 'dart:convert';

CustomerReportModel customerReportModelFromJson(String str) =>
    CustomerReportModel.fromJson(json.decode(str));

class CustomerReportModel {
  final int id;
  final String name;
  final double openingBalance;
  final double currentBalance;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, dynamic> report;
  final BeforeDate beforeDate;
  final double differenceValue;

  CustomerReportModel({
    required this.id,
    required this.name,
    required this.openingBalance,
    required this.currentBalance,
    required this.startDate,
    required this.endDate,
    required this.report,
    required this.beforeDate,
    required this.differenceValue,
  });

  factory CustomerReportModel.fromJson(Map<String, dynamic> json) {
    return CustomerReportModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      openingBalance: (json['opening_balance'] ?? 0).toDouble(),
      currentBalance: (json['current_balance'] ?? 0).toDouble(),
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      report: Map<String, dynamic>.from(json['report'] ?? {}),
      beforeDate: BeforeDate.fromJson(json['before_date'] ?? {}),
      differenceValue: (json['difference_value'] ?? 0).toDouble(),
    );
  }
}

class BeforeDate {
  final Map<String, double> salesByMethod;
  final double salesReturns;
  final Map<String, double> paymentsByMethod;
  final Totals totals;

  BeforeDate({
    required this.salesByMethod,
    required this.salesReturns,
    required this.paymentsByMethod,
    required this.totals,
  });

  factory BeforeDate.fromJson(Map<String, dynamic> json) {
    return BeforeDate(
      salesByMethod: _parseDoubleMap(json['sales_by_method']),
      salesReturns: (json['sales_returns'] ?? 0).toDouble(),
      paymentsByMethod: _parseDoubleMap(json['payments_by_method']),
      totals: Totals.fromJson(json['totals'] ?? {}),
    );
  }

  static Map<String, double> _parseDoubleMap(dynamic value) {
    if (value == null || value is! Map) return {};
    return value.map<String, double>(
      (key, val) => MapEntry(key.toString(), (val ?? 0).toDouble()),
    );
  }
}

class Report {
  Report();

  factory Report.fromJson(Map<String, dynamic> json) => Report();

  Map<String, dynamic> toJson() => {};
}

class SalesByMethod {
  int creditPayment;

  SalesByMethod({required this.creditPayment});

  factory SalesByMethod.fromJson(Map<String, dynamic> json) =>
      SalesByMethod(creditPayment: json["Credit Payment"]);

  Map<String, dynamic> toJson() => {"Credit Payment": creditPayment};
}

class Totals {
  final double totalSales;
  final double totalReturns;
  final int totalPayments;

  Totals({
    required this.totalSales,
    required this.totalReturns,
    required this.totalPayments,
  });

  factory Totals.fromJson(Map<String, dynamic> json) {
    return Totals(
      totalSales: (json['total_sales'] ?? 0).toDouble(),
      totalReturns: (json['total_returns'] ?? 0).toDouble(),
      totalPayments: json['total_payments'] ?? 0,
    );
  }
}
