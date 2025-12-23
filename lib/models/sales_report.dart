import 'dart:convert';

List<SalesreportModel> salesreportModelFromJson(String str) =>
    List<SalesreportModel>.from(
      json.decode(str).map((x) => SalesreportModel.fromJson(x)),
    );

String salesreportModelToJson(List<SalesreportModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class SalesreportModel {
  String posInvoiceNo;
  DateTime saleDate;
  PaymentMode paymentMode;
  double subTotal; // Changed to double
  double taxAmountTotal;
  double discountAmountTotal;
  double cashPaidAmount; // Changed to double
  double creditCardPaidAmount; // Changed to double
  double bankPayment; // Changed to double

  SalesreportModel({
    required this.posInvoiceNo,
    required this.saleDate,
    required this.paymentMode,
    required this.subTotal,
    required this.taxAmountTotal,
    required this.discountAmountTotal,
    required this.cashPaidAmount,
    required this.creditCardPaidAmount,
    required this.bankPayment,
  });

  factory SalesreportModel.fromJson(Map<String, dynamic> json) =>
      SalesreportModel(
        posInvoiceNo: json["pos_invoice_no"] ?? '',
        saleDate: DateTime.parse(json["sale_date"]),
        paymentMode:
            paymentModeValues.map[json["payment_mode"]] ??
            PaymentMode.CASH_PAYMENT, // Default fallback
        subTotal: (json["sub_total"] ?? 0).toDouble(), // Safe conversion
        taxAmountTotal: (json["tax_amount_total"] ?? 0).toDouble(),
        discountAmountTotal: (json["discount_amount_total"] ?? 0).toDouble(),
        cashPaidAmount: (json["cash_paid_amount"] ?? 0).toDouble(),
        creditCardPaidAmount: (json["credit_card_paid_amount"] ?? 0).toDouble(),
        bankPayment: (json["bank_payment"] ?? 0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
    "pos_invoice_no": posInvoiceNo,
    "sale_date": saleDate.toIso8601String(),
    "payment_mode": paymentModeValues.reverse[paymentMode],
    "sub_total": subTotal,
    "tax_amount_total": taxAmountTotal,
    "discount_amount_total": discountAmountTotal,
    "cash_paid_amount": cashPaidAmount,
    "credit_card_paid_amount": creditCardPaidAmount,
    "bank_payment": bankPayment,
  };
}

enum PaymentMode { BANK, CASH_PAYMENT, CREDIT_PAYMENT }

final paymentModeValues = EnumValues({
  "Bank": PaymentMode.BANK,
  "Cash Payment": PaymentMode.CASH_PAYMENT,
  "Credit Payment": PaymentMode.CREDIT_PAYMENT,
});

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
