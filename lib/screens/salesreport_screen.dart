import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:waslasoftreport/constants/colors.dart';
import 'package:waslasoftreport/utilities/gap_func.dart';
import 'package:waslasoftreport/utilities/pdf_utils.dart';
import 'package:waslasoftreport/widgets/ip_config_button.dart';

import '../models/sales_report.dart';
import '../services/salesreportservice.dart';

class SalesreportScreen extends StatefulWidget {
  const SalesreportScreen({super.key});

  @override
  State<SalesreportScreen> createState() => _SalesreportScreenState();
}

class _SalesreportScreenState extends State<SalesreportScreen> {
  final SalesReportService _service = SalesReportService();
  final ScrollController _horizontalScrollController = ScrollController();

  DateTime fromDate = DateTime.now().subtract(const Duration(days: 350));
  DateTime toDate = DateTime.now();

  bool isLoading = false;
  List<SalesreportModel> reportList = [];

  final DateFormat _apiFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _uiFormat = DateFormat('dd/MM/yyyy');

  // Column Widths
  final double wInv = 80;
  final double wDate = 110;
  final double wMode = 100;
  final double wDisc = 100;
  final double wCash = 100;
  final double wCard = 100;
  final double wBank = 100;
  final double wPreTax = 110;
  final double wTax = 100;
  final double wNet = 110;

  double get totalTableWidth =>
      wInv +
      wDate +
      wMode +
      wDisc +
      wCash +
      wCard +
      wBank +
      wPreTax +
      wTax +
      wNet;

  @override
  void initState() {
    super.initState();
    // Data will only load when user clicks "View Report" button
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
    setState(() => isLoading = true);
    // Give UI a moment to show loader before blocking work starts
    await Future.delayed(Duration.zero);

    try {
      final data = await _service.fetchReport(
        _apiFormat.format(fromDate),
        _apiFormat.format(toDate),
      );

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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '₹${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
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
        actions: const [
          IpConfigButton(),
          SizedBox(width: 8),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Container(
                color: Colors.grey[100],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                                        isLoading
                                            ? 'Loading...'
                                            : 'View Report',
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
                                          borderRadius: BorderRadius
                                              .circular(10),
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
                                          borderRadius: BorderRadius
                                              .circular(10),
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
                    if (!isLoading && reportList.isNotEmpty)
                      _buildPaymentSummary(),
                  ],
                ),
              ),
            ),
          ];
        },
        body: isLoading && reportList.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : reportList.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
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
                ),
              )
            : Column(
                children: [
                  // Data Table Area
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Fix: Ensure standard width constraint for ListView
                        final double contentWidth =
                            totalTableWidth > constraints.maxWidth
                                ? totalTableWidth
                                : constraints.maxWidth;

                        return Scrollbar(
                          controller: _horizontalScrollController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            controller: _horizontalScrollController,
                            child: Container(
                              width: contentWidth,
                              height: constraints.maxHeight,
                              child: Column(
                                children: [
                                  _buildTableHeader(),
                                  Expanded(
                                    child: ListView.builder(
                                      // Virtualization enabled
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      itemCount: reportList.length,
                                      itemBuilder: (context, index) {
                                        return _buildDataRow(
                                          reportList[index],
                                          index,
                                        );
                                      },
                                    ),
                                  ),
                                  _buildTableFooter(),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _buildGrandTotal(),
                ],
              ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: primaryColor,
      height: 50,
      child: Row(
        children: [
          _HeaderCell('Inv', wInv),
          _HeaderCell('Sale Date', wDate),
          _HeaderCell('Pay Mode', wMode),
          _HeaderCell('Discount', wDisc),
          _HeaderCell('Cash Paid', wCash),
          _HeaderCell('Card Paid', wCard),
          _HeaderCell('Bank Paid', wBank),
          _HeaderCell('Before Tax', wPreTax),
          _HeaderCell('Tax Amt', wTax),
          _HeaderCell('Net Total', wNet),
        ],
      ),
    );
  }

  Widget _buildDataRow(SalesreportModel r, int index) {
    final beforeTax = r.subTotal - r.discountAmountTotal;
    final net = beforeTax + r.taxAmountTotal;
    final isEven = index % 2 == 0;

    return Container(
      color: isEven ? Colors.white : Colors.grey[50], // Striped rows
      height: 45, // Fixed height optimization hint
      child: Row(
        children: [
          _DataCell(r.posInvoiceNo, wInv, center: true),
          _DataCell(_uiFormat.format(r.saleDate), wDate, center: true),
          _DataCell(
            _formatPaymentMode(paymentModeValues.reverse[r.paymentMode]),
            wMode,
            center: true,
          ),
          _DataCell(
            r.discountAmountTotal.toStringAsFixed(2),
            wDisc,
            right: true,
          ),
          _DataCell(r.cashPaidAmount.toStringAsFixed(2), wCash, right: true),
          _DataCell(
            r.creditCardPaidAmount.toStringAsFixed(2),
            wCard,
            right: true,
          ),
          _DataCell(r.bankPayment.toStringAsFixed(2), wBank, right: true),
          _DataCell(beforeTax.toStringAsFixed(2), wPreTax, right: true),
          _DataCell(r.taxAmountTotal.toStringAsFixed(2), wTax, right: true),
          _DataCell(net.toStringAsFixed(2), wNet, right: true, bold: true),
        ],
      ),
    );
  }

  Widget _buildTableFooter() {
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

    return Container(
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      height: 50,
      child: Row(
        children: [
          _FooterCell('TOTAL', wInv + wDate + wMode, center: true, bold: true),
          _FooterCell(
            totalDiscount.toStringAsFixed(2),
            wDisc,
            right: true,
            bold: true,
          ),
          _FooterCell(
            totalCash.toStringAsFixed(2),
            wCash,
            right: true,
            bold: true,
          ),
          _FooterCell(
            totalCard.toStringAsFixed(2),
            wCard,
            right: true,
            bold: true,
          ),
          _FooterCell(
            totalBank.toStringAsFixed(2),
            wBank,
            right: true,
            bold: true,
          ),
          _FooterCell(
            totalBeforeTax.toStringAsFixed(2),
            wPreTax,
            right: true,
            bold: true,
          ),
          _FooterCell(
            totalTax.toStringAsFixed(2),
            wTax,
            right: true,
            bold: true,
          ),
          _FooterCell(
            grandTotal.toStringAsFixed(2),
            wNet,
            right: true,
            bold: true,
          ),
        ],
      ),
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
          colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
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

class _HeaderCell extends StatelessWidget {
  final String text;
  final double width;

  const _HeaderCell(this.text, this.width);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final double width;
  final bool right;
  final bool center;
  final bool bold;

  const _DataCell(
    this.text,
    this.width, {
    this.right = false,
    this.center = false,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        alignment: center
            ? Alignment.center
            : right
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _FooterCell extends StatelessWidget {
  final String text;
  final double width;
  final bool right;
  final bool center;
  final bool bold;

  const _FooterCell(
    this.text,
    this.width, {
    this.right = false,
    this.center = false,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        alignment: center
            ? Alignment.center
            : right
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
            color: primaryColor,
          ),
        ),
      ),
    );
  }
}
