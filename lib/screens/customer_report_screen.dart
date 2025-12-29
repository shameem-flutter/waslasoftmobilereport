import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waslasoftreport/constants/colors.dart';
import 'package:waslasoftreport/models/customer_report.dart';
import 'package:waslasoftreport/models/ledger.dart';
import 'package:waslasoftreport/services/customer_reportservice.dart';
import 'package:waslasoftreport/utilities/gap_func.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CustomerReportScreen extends StatefulWidget {
  const CustomerReportScreen({super.key});

  @override
  State<CustomerReportScreen> createState() => _CustomerReportScreenState();
}

class _CustomerReportScreenState extends State<CustomerReportScreen> {
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final CustomerReportservice _service = CustomerReportservice();

  DateTime? fromDate;
  DateTime? toDate;
  bool isLoading = false;
  CustomerReportModel? reportData;

  @override
  void initState() {
    super.initState();
    fromDate = DateTime.now().subtract(const Duration(days: 7));
    toDate = DateTime.now();
  }

  Future<void> _fetchReport() async {
    if (_customerNameController.text.isEmpty) {
      _showSnackBar('Please enter customer name');
      return;
    }

    setState(() {
      isLoading = true;
      reportData = null;
    });

    try {
      final customer = await _service.getCustomerByName(
        _customerNameController.text.trim(),
      );

      if (customer == null) {
        setState(() => isLoading = false);
        _showSnackBar('Customer not found');
        return;
      }

      final result = await _service.customerReportGet(
        DateFormat('yyyy-MM-dd').format(fromDate!),
        DateFormat('yyyy-MM-dd').format(toDate!),
        customer.id,
      );

      setState(() {
        reportData = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar('Error: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Customer Ledger Statement',
          style: TextStyle(
            color: primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Filter Section
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
                      _buildTextField('Customer Name', _customerNameController),
                      vertGap(12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              'From Date',
                              fromDate,
                              (d) => setState(() => fromDate = d),
                            ),
                          ),
                          horiGap(16),
                          Expanded(
                            child: _buildDateField(
                              'To Date',
                              toDate,
                              (d) => setState(() => toDate = d),
                            ),
                          ),
                        ],
                      ),
                      vertGap(12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isLoading ? null : _fetchReport,
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
                              onPressed: reportData != null
                                  ? _printLedger
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

            // Report Area - No Expanded, just direct content
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(48.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              _buildReportArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildReportArea() {
    if (reportData == null) {
      return _buildEmptyState();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildReportHeader(),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: _buildDataTable(
              _filterRows(_buildLedgerRows(reportData!)),
              _calculateTotalRow(_buildLedgerRows(reportData!)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
        vertGap(6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter customer name',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? date,
    Function(DateTime) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
        vertGap(6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) onChanged(picked);
          },
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
                    date != null
                        ? DateFormat('dd/MM/yyyy').format(date)
                        : 'Select date',
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Test Company LTD',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'CUSTOMER LEDGER STATEMENT',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Customer: ${reportData!.name}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            'Period: ${DateFormat('dd/MM/yyyy').format(reportData!.startDate)} - ${DateFormat('dd/MM/yyyy').format(reportData!.endDate)}',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<LedgerRow> rows, LedgerRow totalRow) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(primaryColor),
        headingRowHeight: 56,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 56,
        columnSpacing: 20,
        horizontalMargin: 16,
        dividerThickness: 1,
        border: TableBorder.all(color: Colors.grey.shade500, width: 1),
        columns:
            [
                  'Date',
                  'Credit Sales',
                  'Cash',
                  'Credit Card',
                  'Cheque',
                  'Discount',
                  'Sales Return',
                  'Narration',
                  'Balance',
                ]
                .map(
                  (label) => DataColumn(
                    label: Container(
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
                .toList(),
        rows: [
          // Opening Balance Row
          DataRow(
            color: WidgetStateProperty.all(Colors.blue[50]),
            cells: [
              const DataCell(Text('')),
              const DataCell(Text('')),
              const DataCell(Text('')),
              const DataCell(Text('')),
              const DataCell(Text('')),
              const DataCell(Text('')),
              const DataCell(Text('')),
              const DataCell(
                Text(
                  'Opening Balance',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(
                Text(
                  reportData!.openingBalance.toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          // Transaction Rows
          ...rows
              .skip(1)
              .map(
                (row) => DataRow(
                  cells: [
                    DataCell(Text(row.date)),
                    DataCell(
                      Text(
                        row.creditSales == 0
                            ? ''
                            : row.creditSales.toStringAsFixed(2),
                      ),
                    ),
                    DataCell(
                      Text(row.cash == 0 ? '' : row.cash.toStringAsFixed(2)),
                    ),
                    DataCell(
                      Text(
                        row.creditCard == 0
                            ? ''
                            : row.creditCard.toStringAsFixed(2),
                      ),
                    ),
                    DataCell(
                      Text(
                        row.cheque == 0 ? '' : row.cheque.toStringAsFixed(2),
                      ),
                    ),
                    DataCell(
                      Text(
                        row.discount == 0
                            ? ''
                            : row.discount.toStringAsFixed(2),
                      ),
                    ),
                    DataCell(
                      Text(
                        row.salesReturn == 0
                            ? ''
                            : row.salesReturn.toStringAsFixed(2),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 200,
                        child: Text(
                          row.narration,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        row.balance.toStringAsFixed(2),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: row.balance < 0 ? Colors.red : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          // Total Row
          DataRow(
            color: WidgetStateProperty.all(Colors.grey[200]),
            cells: [
              const DataCell(
                Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataCell(
                Text(
                  totalRow.creditSales.toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(
                Text(
                  totalRow.cash.toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(
                Text(
                  totalRow.creditCard.toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(
                Text(
                  totalRow.cheque.toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(
                Text(
                  totalRow.discount.toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(
                Text(
                  totalRow.salesReturn.toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const DataCell(Text('')),
              DataCell(
                Text(
                  totalRow.balance.toStringAsFixed(2),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: totalRow.balance < 0 ? Colors.red : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Data Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter customer name and select dates to view report',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  List<LedgerRow> _filterRows(List<LedgerRow> rows) {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return rows;

    return rows
        .where((row) => row.narration.toLowerCase().contains(query))
        .toList();
  }

  List<LedgerRow> _buildLedgerRows(CustomerReportModel r) {
    double runningBalance = r.openingBalance;
    final List<LedgerRow> rows = [
      LedgerRow(
        date: '',
        creditSales: 0,
        cash: 0,
        creditCard: 0,
        cheque: 0,
        discount: 0,
        salesReturn: 0,
        narration: 'Opening Balance',
        balance: runningBalance,
      ),
    ];

    final sortedDates = r.report.keys.toList()
      ..sort(
        (a, b) => DateFormat(
          'dd/MM/yyyy',
        ).parse(a).compareTo(DateFormat('dd/MM/yyyy').parse(b)),
      );

    for (final date in sortedDates) {
      final day = r.report[date] as Map<String, dynamic>;

      for (final sale in List<Map<String, dynamic>>.from(day['sales'] ?? [])) {
        final amount = (sale['grand_total'] ?? 0).toDouble();
        runningBalance += amount;

        rows.add(
          LedgerRow(
            date: date,
            creditSales: sale['payment_mode'] == 'Credit Payment' ? amount : 0,
            cash: sale['payment_mode'] == 'Cash Payment' ? amount : 0,
            creditCard: sale['payment_mode'] == 'Credit Card' ? amount : 0,
            cheque: sale['payment_mode'] == 'Cheque' ? amount : 0,
            discount: 0,
            salesReturn: 0,
            narration: '${sale['transaction_no']} (${sale['payment_mode']})',
            balance: runningBalance,
          ),
        );
      }

      for (final ret in List<Map<String, dynamic>>.from(
        day['sales_return'] ?? [],
      )) {
        final amount = (ret['amount'] ?? 0).toDouble();
        runningBalance -= amount;

        rows.add(
          LedgerRow(
            date: date,
            creditSales: 0,
            cash: 0,
            creditCard: 0,
            cheque: 0,
            discount: 0,
            salesReturn: amount,
            narration: '${ret['transaction_no']} - Return',
            balance: runningBalance,
          ),
        );
      }

      for (final pay in List<Map<String, dynamic>>.from(
        day['customer_payments'] ?? [],
      )) {
        final amount = (pay['amount'] ?? 0).toDouble();
        runningBalance -= amount;

        rows.add(
          LedgerRow(
            date: date,
            creditSales: 0,
            cash: pay['payment_mode'] == 'Cash' ? amount : 0,
            creditCard: pay['payment_mode'] == 'Card' ? amount : 0,
            cheque: pay['payment_mode'] == 'Cheque' ? amount : 0,
            discount: 0,
            salesReturn: 0,
            narration: 'Payment',
            balance: runningBalance,
          ),
        );
      }
    }

    return rows;
  }

  LedgerRow _calculateTotalRow(List<LedgerRow> rows) {
    double creditSales = 0, cash = 0, creditCard = 0;
    double cheque = 0, discount = 0, salesReturn = 0;

    for (final r in rows) {
      creditSales += r.creditSales;
      cash += r.cash;
      creditCard += r.creditCard;
      cheque += r.cheque;
      discount += r.discount;
      salesReturn += r.salesReturn;
    }

    return LedgerRow(
      date: 'Total',
      creditSales: creditSales,
      cash: cash,
      creditCard: creditCard,
      cheque: cheque,
      discount: discount,
      salesReturn: salesReturn,
      narration: '',
      balance: rows.isNotEmpty ? rows.last.balance : 0,
    );
  }

  Future<void> _printLedger() async {
    final doc = await _generatePdf(reportData!);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Customer_Ledger_${reportData!.id}',
    );
  }

  Future<pw.Document> _generatePdf(CustomerReportModel report) async {
    final pdf = pw.Document();
    final rows = _buildLedgerRows(report);
    final totalRow = _calculateTotalRow(rows);
    final filteredRows = _filterRows(rows);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
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
                pw.SizedBox(height: 10),
              ],
            ),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.2),
                1: const pw.FlexColumnWidth(1.3),
                2: const pw.FlexColumnWidth(1.0),
                3: const pw.FlexColumnWidth(1.2),
                4: const pw.FlexColumnWidth(1.0),
                5: const pw.FlexColumnWidth(1.0),
                6: const pw.FlexColumnWidth(1.2),
                7: const pw.FlexColumnWidth(2.0),
                8: const pw.FlexColumnWidth(1.2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue900),
                  children: [
                    _pdfCell('Date', isHeader: true),
                    _pdfCell('Credit Sales', isHeader: true),
                    _pdfCell('Cash', isHeader: true),
                    _pdfCell('Credit Card', isHeader: true),
                    _pdfCell('Cheque', isHeader: true),
                    _pdfCell('Discount', isHeader: true),
                    _pdfCell('Sales Return', isHeader: true),
                    _pdfCell('Narration', isHeader: true),
                    _pdfCell('Balance', isHeader: true),
                  ],
                ),
                ...filteredRows.map((row) {
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: filteredRows.indexOf(row) % 2 == 0
                          ? PdfColors.grey100
                          : PdfColors.white,
                    ),
                    children: [
                      _pdfCell(row.date, align: pw.Alignment.centerLeft),
                      _pdfCell(
                        row.creditSales == 0
                            ? ''
                            : row.creditSales.toStringAsFixed(2),
                        align: pw.Alignment.centerRight,
                      ),
                      _pdfCell(
                        row.cash == 0 ? '' : row.cash.toStringAsFixed(2),
                        align: pw.Alignment.centerRight,
                      ),
                      _pdfCell(
                        row.creditCard == 0
                            ? ''
                            : row.creditCard.toStringAsFixed(2),
                        align: pw.Alignment.centerRight,
                      ),
                      _pdfCell(
                        row.cheque == 0 ? '' : row.cheque.toStringAsFixed(2),
                        align: pw.Alignment.centerRight,
                      ),
                      _pdfCell(
                        row.discount == 0
                            ? ''
                            : row.discount.toStringAsFixed(2),
                        align: pw.Alignment.centerRight,
                      ),
                      _pdfCell(
                        row.salesReturn == 0
                            ? ''
                            : row.salesReturn.toStringAsFixed(2),
                        align: pw.Alignment.centerRight,
                      ),
                      _pdfCell(row.narration, align: pw.Alignment.centerLeft),
                      _pdfCell(
                        row.balance.toStringAsFixed(2),
                        align: pw.Alignment.centerRight,
                        isBold: true,
                      ),
                    ],
                  );
                }),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                  children: [
                    _pdfCell(
                      'Total',
                      isBold: true,
                      align: pw.Alignment.centerLeft,
                    ),
                    _pdfCell(
                      totalRow.creditSales.toStringAsFixed(2),
                      isBold: true,
                      align: pw.Alignment.centerRight,
                    ),
                    _pdfCell(
                      totalRow.cash.toStringAsFixed(2),
                      isBold: true,
                      align: pw.Alignment.centerRight,
                    ),
                    _pdfCell(
                      totalRow.creditCard.toStringAsFixed(2),
                      isBold: true,
                      align: pw.Alignment.centerRight,
                    ),
                    _pdfCell(
                      totalRow.cheque.toStringAsFixed(2),
                      isBold: true,
                      align: pw.Alignment.centerRight,
                    ),
                    _pdfCell(
                      totalRow.discount.toStringAsFixed(2),
                      isBold: true,
                      align: pw.Alignment.centerRight,
                    ),
                    _pdfCell(
                      totalRow.salesReturn.toStringAsFixed(2),
                      isBold: true,
                      align: pw.Alignment.centerRight,
                    ),
                    _pdfCell(''),
                    _pdfCell(
                      totalRow.balance.toStringAsFixed(2),
                      isBold: true,
                      align: pw.Alignment.centerRight,
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _pdfCell(
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

  @override
  void dispose() {
    _customerNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
