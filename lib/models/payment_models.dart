class PaymentRecord {
  final int id;
  final String payer;
  final double amount;
  final String? method;
  final DateTime date;
  const PaymentRecord({
    required this.id,
    required this.payer,
    required this.amount,
    required this.method,
    required this.date,
  });
}

class AllocationRecord {
  final int id;
  final int invoiceId;
  final double amount;
  final String customer;
  final double invoiceTotal;
  final String status;
  const AllocationRecord({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.customer,
    required this.invoiceTotal,
    required this.status,
  });
}