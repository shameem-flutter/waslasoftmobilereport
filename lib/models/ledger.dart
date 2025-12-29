class LedgerRow {
  final String date;
  final double creditSales;
  final double cash;
  final double creditCard;
  final double cheque;
  final double discount;
  final double salesReturn;
  final String narration;
  final double balance;

  LedgerRow({
    required this.date,
    required this.creditSales,
    required this.cash,
    required this.creditCard,
    required this.cheque,
    required this.discount,
    required this.salesReturn,
    required this.narration,
    required this.balance,
  });
}
