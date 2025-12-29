import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:waslasoftreport/models/customer_report.dart';
import 'package:waslasoftreport/models/ledger.dart';
import 'package:waslasoftreport/models/sales_report.dart';

class PdfUtils {
  // Sales Report PDF Generation
  static Future<void> printSalesReport({
    required List<SalesreportModel> reportList,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final doc = await _generateSalesReportPdf(
      reportList: reportList,
      fromDate: fromDate,
      toDate: toDate,
    );

    final apiFormat = DateFormat('yyyy-MM-dd');
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name:
          'Sales_Report_${apiFormat.format(fromDate)}_to_${apiFormat.format(toDate)}',
    );
  }

  static Future<pw.Document> _generateSalesReportPdf({
    required List<SalesreportModel> reportList,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final pdf = pw.Document();
    final uiFormat = DateFormat('dd/MM/yyyy');

    // Calculate totals
    double totalCash = reportList.fold(0.0, (sum, r) => sum + r.cashPaidAmount);
    double totalBank = reportList.fold(0.0, (sum, r) => sum + r.bankPayment);
    double totalCredit = reportList.fold(
      0.0,
      (sum, r) => sum + r.creditCardPaidAmount,
    );
    double totalDiscount = reportList.fold(
      0.0,
      (sum, r) => sum + r.discountAmountTotal,
    );
    double totalTax = reportList.fold(0.0, (sum, r) => sum + r.taxAmountTotal);
    double grandTotal = reportList.fold(0.0, (sum, r) {
      final beforeTax = r.subTotal - r.discountAmountTotal;
      return sum + (beforeTax + r.taxAmountTotal);
    });

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Test Company LTD',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'SALES REPORT',
                    style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Period: ${uiFormat.format(fromDate)} - ${uiFormat.format(toDate)}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.Divider(),
                  pw.SizedBox(height: 10),
                ],
              ),

              // Table
              pw.Expanded(
                child: pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.2),
                    1: const pw.FlexColumnWidth(1.5),
                    2: const pw.FlexColumnWidth(1.3),
                    3: const pw.FlexColumnWidth(1.2),
                    4: const pw.FlexColumnWidth(1.2),
                    5: const pw.FlexColumnWidth(1.2),
                    6: const pw.FlexColumnWidth(1.2),
                    7: const pw.FlexColumnWidth(1.4),
                    8: const pw.FlexColumnWidth(1.2),
                    9: const pw.FlexColumnWidth(1.4),
                  },
                  children: [
                    // Header Row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blue900,
                      ),
                      children: [
                        _pdfCell('Inv', isHeader: true),
                        _pdfCell('Date', isHeader: true),
                        _pdfCell('Pay Mode', isHeader: true),
                        _pdfCell('Discount', isHeader: true),
                        _pdfCell('Cash', isHeader: true),
                        _pdfCell('Card', isHeader: true),
                        _pdfCell('Bank', isHeader: true),
                        _pdfCell('Before Tax', isHeader: true),
                        _pdfCell('Tax', isHeader: true),
                        _pdfCell('Net Total', isHeader: true),
                      ],
                    ),

                    // Data Rows
                    ...reportList.asMap().entries.map((entry) {
                      final index = entry.key;
                      final r = entry.value;
                      final beforeTax = r.subTotal - r.discountAmountTotal;
                      final net = beforeTax + r.taxAmountTotal;
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: index % 2 == 0
                              ? PdfColors.grey100
                              : PdfColors.white,
                        ),
                        children: [
                          _pdfCell(
                            r.posInvoiceNo,
                            align: pw.Alignment.centerLeft,
                          ),
                          _pdfCell(uiFormat.format(r.saleDate)),
                          _pdfCell(
                            _formatPaymentMode(
                              paymentModeValues.reverse[r.paymentMode],
                            ),
                          ),
                          _pdfCell(
                            r.discountAmountTotal.toStringAsFixed(2),
                            align: pw.Alignment.centerRight,
                          ),
                          _pdfCell(
                            r.cashPaidAmount.toStringAsFixed(2),
                            align: pw.Alignment.centerRight,
                          ),
                          _pdfCell(
                            r.creditCardPaidAmount.toStringAsFixed(2),
                            align: pw.Alignment.centerRight,
                          ),
                          _pdfCell(
                            r.bankPayment.toStringAsFixed(2),
                            align: pw.Alignment.centerRight,
                          ),
                          _pdfCell(
                            beforeTax.toStringAsFixed(2),
                            align: pw.Alignment.centerRight,
                          ),
                          _pdfCell(
                            r.taxAmountTotal.toStringAsFixed(2),
                            align: pw.Alignment.centerRight,
                          ),
                          _pdfCell(
                            net.toStringAsFixed(2),
                            align: pw.Alignment.centerRight,
                            isBold: true,
                          ),
                        ],
                      );
                    }),

                    // Total Row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blue50,
                      ),
                      children: [
                        _pdfCell(
                          'TOTAL',
                          isBold: true,
                          align: pw.Alignment.centerLeft,
                        ),
                        _pdfCell(''),
                        _pdfCell(''),
                        _pdfCell(
                          totalDiscount.toStringAsFixed(2),
                          isBold: true,
                          align: pw.Alignment.centerRight,
                        ),
                        _pdfCell(
                          totalCash.toStringAsFixed(2),
                          isBold: true,
                          align: pw.Alignment.centerRight,
                        ),
                        _pdfCell(
                          totalCredit.toStringAsFixed(2),
                          isBold: true,
                          align: pw.Alignment.centerRight,
                        ),
                        _pdfCell(
                          totalBank.toStringAsFixed(2),
                          isBold: true,
                          align: pw.Alignment.centerRight,
                        ),
                        _pdfCell(''),
                        _pdfCell(
                          totalTax.toStringAsFixed(2),
                          isBold: true,
                          align: pw.Alignment.centerRight,
                        ),
                        _pdfCell(
                          grandTotal.toStringAsFixed(2),
                          isBold: true,
                          align: pw.Alignment.centerRight,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Grand Total Section
              pw.SizedBox(height: 15),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue900,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'GRAND TOTAL',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    pw.Text(
                      grandTotal.toStringAsFixed(2),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // Customer Ledger PDF Generation
  static Future<void> printCustomerLedger({
    required CustomerReportModel report,
    required List<LedgerRow> filteredRows,
    required LedgerRow totalRow,
  }) async {
    final doc = await _generateCustomerLedgerPdf(
      report: report,
      filteredRows: filteredRows,
      totalRow: totalRow,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Customer_Ledger_${report.id}',
    );
  }

  static Future<pw.Document> _generateCustomerLedgerPdf({
    required CustomerReportModel report,
    required List<LedgerRow> filteredRows,
    required LedgerRow totalRow,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Test Company LTD',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'CUSTOMER LEDGER STATEMENT',
                    style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Customer: ${report.name}'),
                      pw.Text(
                        'Period: ${DateFormat('dd/MM/yyyy').format(report.startDate)} - ${DateFormat('dd/MM/yyyy').format(report.endDate)}',
                      ),
                    ],
                  ),
                  pw.Divider(),
                ],
              ),
            ),
            pw.TableHelper.fromTextArray(
              headers: [
                'Date',
                'Credit Sales',
                'Cash',
                'Credit Card',
                'Cheque',
                'Discount',
                'Sales Return',
                'Narration',
                'Balance',
              ],
              data: [
                ...filteredRows.map(
                  (row) => [
                    row.date,
                    row.creditSales == 0
                        ? ''
                        : row.creditSales.toStringAsFixed(2),
                    row.cash == 0 ? '' : row.cash.toStringAsFixed(2),
                    row.creditCard == 0
                        ? ''
                        : row.creditCard.toStringAsFixed(2),
                    row.cheque == 0 ? '' : row.cheque.toStringAsFixed(2),
                    row.discount == 0 ? '' : row.discount.toStringAsFixed(2),
                    row.salesReturn == 0
                        ? ''
                        : row.salesReturn.toStringAsFixed(2),
                    row.narration,
                    row.balance.toStringAsFixed(2),
                  ],
                ),
                [
                  'Total',
                  totalRow.creditSales.toStringAsFixed(2),
                  totalRow.cash.toStringAsFixed(2),
                  totalRow.creditCard.toStringAsFixed(2),
                  totalRow.cheque.toStringAsFixed(2),
                  totalRow.discount.toStringAsFixed(2),
                  totalRow.salesReturn.toStringAsFixed(2),
                  '',
                  totalRow.balance.toStringAsFixed(2),
                ],
              ],
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue900,
              ),
              cellAlignment: pw.Alignment.centerRight,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                7: pw.Alignment.centerLeft,
              },
              border: pw.TableBorder.all(color: PdfColors.grey400),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  // Helper methods
  static pw.Widget _pdfCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    pw.Alignment? align,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: align == pw.Alignment.centerRight
            ? pw.TextAlign.right
            : align == pw.Alignment.centerLeft
            ? pw.TextAlign.left
            : pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: (isHeader || isBold)
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
      ),
    );
  }

  static String _formatPaymentMode(String? mode) {
    if (mode == null) return 'N/A';
    if (mode == 'Cash Payment') return 'Cash';
    if (mode == 'Credit Payment') return 'Credit';
    if (mode == 'Bank') return 'Bank';
    return mode;
  }
}
