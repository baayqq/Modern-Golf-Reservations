import 'package:flutter/material.dart';

enum PaymentStatus {
  unpaid,
  paid,
  partial,
}

enum PaymentMode {
  combined,
  individual,
}

class InvoiceItem {
  final String id;
  final String customer;
  final double total;
  final PaymentStatus status;
  final DateTime date;
  final double outstanding;

  InvoiceItem({
    required this.id,
    required this.customer,
    required this.total,
    required this.status,
    required this.date,
    required this.outstanding,
  });
}

class InvoiceLine {
  final String name;
  final int qty;
  final double price;

  InvoiceLine({required this.name, required this.qty, required this.price});
}

class PaymentAllocationData {
  final int invoiceId;
  final String customer;
  final double amount;
  final double invoiceTotal;
  final String status;

  const PaymentAllocationData({
    required this.invoiceId,
    required this.customer,
    required this.amount,
    required this.invoiceTotal,
    required this.status,
  });
}

class CombinedReceiptData {
  final String payer;
  final String methodLabel;
  final num totalAmount;
  final List<PaymentAllocationData> allocations;

  const CombinedReceiptData({
    required this.payer,
    required this.methodLabel,
    required this.totalAmount,
    required this.allocations,
  });
}