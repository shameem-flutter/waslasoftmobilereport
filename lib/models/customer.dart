class Customer {
  final int id;
  final String name;
  final String? mobile;
  final double balance;

  Customer({
    required this.id,
    required this.name,
    this.mobile,
    required this.balance,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: (json['CustomerID'] as num).toInt(),
      name: (json['CustomerName'] ?? '').toString(),
      mobile: json['Mobile']?.toString(),
      balance: (json['Balance'] ?? 0).toDouble(),
    );
  }
}
