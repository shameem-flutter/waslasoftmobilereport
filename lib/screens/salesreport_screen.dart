import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:waslasoftreport/constants/colors.dart';
import 'package:waslasoftreport/utilities/gap_func.dart';
import 'package:waslasoftreport/utilities/pdf_utils.dart';

import '../models/sales_report.dart';
import '../services/salesreportservice.dart';

class SalesreportScreen extends StatefulWidget {
  const SalesreportScreen({super.key});

  @override
  State<SalesreportScreen> createState() => _SalesreportScreenState();
}

class _SalesreportScreenState extends State<SalesreportScreen> {
  final SalesReportService _service = SalesReportService();

  DateTime fromDate = DateTime.now().subtract(const Duration(days: 350));
  DateTime toDate = DateTime.now();

  bool isLoading = false;
  List<SalesreportModel> reportList = [];

  final DateFormat _apiFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _uiFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    // Data will only load when user clicks "View Report" button
  }

  Future<void> _loadReport() async {
    setState(() => isLoading = true);
    try {
      final data = await _service.fetchReport(
        _apiFormat.format(fromDate),
        _apiFormat.format(toDate),
      );

      // Sort data
      data.sort((a, b) {
        final dateCompare = a.saleDate.compareTo(b.saleDate);
        if (dateCompare != 0) return dateCompare;
        return a.posInvoiceNo.compareTo(b.posInvoiceNo);
      });

      if (mounted) {
        setState(() {
          reportList = data;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _pickDate(DateTime initial, Function(DateTime) onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) onPicked(picked);
  }

  Widget _buildDateField(
    String label,
    DateTime date,
    Function(DateTime) onChanged,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
          vertGap(6),
          InkWell(
            onTap: () => _pickDate(date, onChanged),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: primaryColor,
                  ),
                  horiGap(8),
                  Expanded(
                    child: Text(
                      _uiFormat.format(date),
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    double totalCash = reportList.fold(0.0, (sum, r) => sum + r.cashPaidAmount);
    double totalBank = reportList.fold(0.0, (sum, r) => sum + r.bankPayment);
    double totalCredit = reportList.fold(
      0.0,
      (sum, r) => sum + r.creditCardPaidAmount,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Summary',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              vertGap(16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Cash Payment',
                      totalCash,
                      Icons.money_rounded,
                      Colors.green,
                    ),
                  ),
                  horiGap(12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Bank Payment',
                      totalBank,
                      Icons.account_balance_rounded,
                      Colors.blue,
                    ),
                  ),
                  horiGap(12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Credit Payment',
                      totalCredit,
                      Icons.credit_card_rounded,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          vertGap(8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          vertGap(4),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Sales Report",
          style: GoogleFonts.poppins(
            color: primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildDateField(
                            'From Date',
                            fromDate,
                            (d) => setState(() => fromDate = d),
                          ),
                          horiGap(16),
                          _buildDateField(
                            'To Date',
                            toDate,
                            (d) => setState(() => toDate = d),
                          ),
                        ],
                      ),
                      vertGap(12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isLoading ? null : _loadReport,
                              icon: isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.search_rounded,
                                      size: 20,
                                      color: whiteColor,
                                    ),
                              label: Text(
                                isLoading ? 'Loading...' : 'View Report',
                                style: const TextStyle(
                                  color: whiteColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          horiGap(12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: reportList.isNotEmpty
                                  ? _printReport
                                  : null,
                              icon: const Icon(
                                Icons.print_rounded,
                                size: 20,
                                color: whiteColor,
                              ),
                              label: const Text(
                                'Print',
                                style: TextStyle(
                                  color: whiteColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Data Area
            isLoading && reportList.isEmpty
                ? Container(
                    height: 400,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  )
                : reportList.isEmpty
                ? Container(
                    height: 400,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        vertGap(12),
                        const Text(
                          'No data available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        vertGap(8),
                        Text(
                          'Select dates and click "View Report"',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      if (reportList.isNotEmpty && !isLoading)
                        _buildPaymentSummary(),
                      _buildGrandTotal(),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildDataTable(),
                            ),
                          ),
                        ),
                      ),

                      // Grand Total
                      vertGap(8),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    // Calculate column totals
    double totalDiscount = reportList.fold(
      0.0,
      (sum, r) => sum + r.discountAmountTotal,
    );
    double totalCash = reportList.fold(0.0, (sum, r) => sum + r.cashPaidAmount);
    double totalCard = reportList.fold(
      0.0,
      (sum, r) => sum + r.creditCardPaidAmount,
    );
    double totalBank = reportList.fold(0.0, (sum, r) => sum + r.bankPayment);
    double totalBeforeTax = reportList.fold(
      0.0,
      (sum, r) => sum + (r.subTotal - r.discountAmountTotal),
    );
    double totalTax = reportList.fold(0.0, (sum, r) => sum + r.taxAmountTotal);
    double grandTotal = reportList.fold(0.0, (sum, r) {
      final beforeTax = r.subTotal - r.discountAmountTotal;
      return sum + (beforeTax + r.taxAmountTotal);
    });

    return Table(
      border: TableBorder.all(color: Colors.grey.shade300, width: 1),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FixedColumnWidth(80), // Inv No
        1: FixedColumnWidth(110), // Date
        2: FixedColumnWidth(100), // Pay Mode
        3: FixedColumnWidth(100), // Discount
        4: FixedColumnWidth(100), // Cash
        5: FixedColumnWidth(100), // Card
        6: FixedColumnWidth(100), // Bank
        7: FixedColumnWidth(110), // Before Tax
        8: FixedColumnWidth(100), // Tax
        9: FixedColumnWidth(110), // Net Total
      },
      children: [
        _headerRow(),
        ...reportList.map(_dataRow),
        // Total Row
        TableRow(
          decoration: BoxDecoration(color: primaryColor.withOpacity(0.1)),
          children: [
            _buildTotalCell('TOTAL', isBold: true),
            _buildTotalCell(''),
            _buildTotalCell(''),
            _buildTotalCell(totalDiscount.toStringAsFixed(2), isBold: true),
            _buildTotalCell(totalCash.toStringAsFixed(2), isBold: true),
            _buildTotalCell(totalCard.toStringAsFixed(2), isBold: true),
            _buildTotalCell(totalBank.toStringAsFixed(2), isBold: true),
            _buildTotalCell(totalBeforeTax.toStringAsFixed(2), isBold: true),
            _buildTotalCell(totalTax.toStringAsFixed(2), isBold: true),
            _buildTotalCell(grandTotal.toStringAsFixed(2), isBold: true),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalCell(String text, {bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          fontSize: 13,
          color: primaryColor,
        ),
      ),
    );
  }

  TableRow _headerRow() {
    return TableRow(
      decoration: BoxDecoration(color: primaryColor),
      children: const [
        _Header('Inv'),
        _Header('Sale Date'),
        _Header('Pay Mode'),
        _Header('Discount'),
        _Header('Cash Paid'),
        _Header('Card Paid'),
        _Header('Bank Paid'),
        _Header('Before Tax'),
        _Header('Tax Amt'),
        _Header('Net Total'),
      ],
    );
  }

  TableRow _dataRow(SalesreportModel r) {
    final beforeTax = r.subTotal - r.discountAmountTotal;
    final net = beforeTax + r.taxAmountTotal;

    return TableRow(
      decoration: const BoxDecoration(color: Colors.white),
      children: [
        _Cell(r.posInvoiceNo, center: true),
        _Cell(_uiFormat.format(r.saleDate), center: true),
        _Cell(
          _formatPaymentMode(paymentModeValues.reverse[r.paymentMode]),
          center: true,
        ),
        _Cell(r.discountAmountTotal.toStringAsFixed(2), right: true),
        _Cell(r.cashPaidAmount.toStringAsFixed(2), right: true),
        _Cell(r.creditCardPaidAmount.toStringAsFixed(2), right: true),
        _Cell(r.bankPayment.toStringAsFixed(2), right: true),
        _Cell(beforeTax.toStringAsFixed(2), right: true),
        _Cell(r.taxAmountTotal.toStringAsFixed(2), right: true),
        _Cell(net.toStringAsFixed(2), right: true, bold: true),
      ],
    );
  }

  String _formatPaymentMode(String? mode) {
    if (mode == null) return 'N/A';
    if (mode == 'Cash Payment') return 'Cash';
    if (mode == 'Credit Payment') return 'Credit';
    if (mode == 'Bank') return 'Bank';
    return mode;
  }

  Future<void> _printReport() async {
    await PdfUtils.printSalesReport(
      reportList: reportList,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  Widget _buildGrandTotal() {
    double totalNet = reportList.fold(0.0, (sum, r) {
      final beforeTax = r.subTotal - r.discountAmountTotal;
      return sum + (beforeTax + r.taxAmountTotal);
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'GRAND TOTAL',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            '₹${totalNet.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final bool right;
  final bool center;
  final bool bold;

  const _Cell(
    this.text, {
    this.right = false,
    this.center = false,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Text(
        text,
        textAlign: center
            ? TextAlign.center
            : right
            ? TextAlign.right
            : TextAlign.left,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          fontSize: 13,
          color: Colors.black,
        ),
      ),
    );
  }
}
