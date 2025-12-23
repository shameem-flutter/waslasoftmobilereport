import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:waslasoftreport/constants/colors.dart';
import 'package:waslasoftreport/utilities/gap_func.dart';

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

  static const int _rowsPerPage = 10;
  int _currentPage = 0;

  final DateFormat _apiFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _uiFormat = DateFormat('dd/MM/yyyy');

  int get _totalPages => (reportList.length / _rowsPerPage).ceil();

  List<SalesreportModel> get _paginatedReports {
    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, reportList.length);
    return start >= reportList.length ? [] : reportList.sublist(start, end);
  }

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => isLoading = true);
    try {
      final data = await _service.fetchReport(
        _apiFormat.format(fromDate),
        _apiFormat.format(toDate),
      );

      // Sort data before pagination
      data.sort((a, b) {
        final dateCompare = a.saleDate.compareTo(b.saleDate);
        if (dateCompare != 0) return dateCompare;
        return a.posInvoiceNo.compareTo(b.posInvoiceNo);
      });

      if (mounted) {
        setState(() {
          reportList = data;
          _currentPage = 0;
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
      body: Column(
        children: [
          // Filter Card
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
                    SizedBox(
                      width: double.infinity,
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Table Area
          Expanded(
            child: isLoading && reportList.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : reportList.isEmpty
                ? Center(
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
                          'No data found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildReportTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTable() {
    double totalNet = reportList.fold(0.0, (sum, r) {
      final beforeTax = r.subTotal - r.discountAmountTotal;
      return sum + (beforeTax + r.taxAmountTotal);
    });

    return Column(
      children: [
        // Table with scrolling
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            physics: const BouncingScrollPhysics(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
          ),
        ),

        // Pagination Controls
        _buildPaginationControls(),

        // Grand Total
        Container(
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
        ),

        vertGap(4),
      ],
    );
  }

  Widget _buildDataTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300, width: 1),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FixedColumnWidth(65), // Inv No
        1: FixedColumnWidth(90), // Date
        2: FixedColumnWidth(110), // Pay Mode
        3: FixedColumnWidth(85), // Discount
        4: FixedColumnWidth(85), // Cash
        5: FixedColumnWidth(85), // Card
        6: FixedColumnWidth(85), // Bank
        7: FixedColumnWidth(95), // Before Tax
        8: FixedColumnWidth(80), // Tax
        9: FixedColumnWidth(95), // Net Total
      },
      children: [_headerRow(), ..._paginatedReports.map(_dataRow)],
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

  Widget _buildPaginationControls() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 0
                ? () => setState(() => _currentPage--)
                : null,
            icon: Icon(
              Icons.chevron_left_rounded,
              color: _currentPage > 0 ? primaryColor : Colors.grey,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          horiGap(12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'Page ${_currentPage + 1} / $_totalPages',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          horiGap(12),
          IconButton(
            onPressed: _currentPage < _totalPages - 1
                ? () => setState(() => _currentPage++)
                : null,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: _currentPage < _totalPages - 1
                  ? primaryColor
                  : Colors.grey,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12.5,
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        textAlign: center
            ? TextAlign.center
            : right
            ? TextAlign.right
            : TextAlign.left,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          fontSize: 12.5,
          color: Colors.black87,
        ),
      ),
    );
  }
}
