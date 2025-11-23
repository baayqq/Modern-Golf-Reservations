// Model: Invoice domain models used by InvoicePage and related widgets.
// Menyimpan struktur data untuk invoice dan itemnya, serta enum status dan mode pembayaran.
// Dipisahkan ke folder models agar UI tetap bersih dan mudah diuji.
import 'package:flutter/material.dart';

/// Status pembayaran untuk sebuah invoice.
enum PaymentStatus {
  unpaid,
  paid,
  partial,
}

/// Mode pembayaran yang didukung di UI Invoice Page.
enum PaymentMode {
  combined,
  individual,
}

/// Data ringkas sebuah invoice yang ditampilkan di tabel.
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

/// Baris item di dalam sebuah invoice.
class InvoiceLine {
  final String name;
  final int qty;
  final double price;

  InvoiceLine({required this.name, required this.qty, required this.price});
}

/// Data alokasi pembayaran (agnostik terhadap PDF service),
/// diproduksi oleh service dan dikonsumsi oleh UI.
class PaymentAllocationData {
  final int invoiceId;
  final String customer;
  final double amount;
  final double invoiceTotal;
  final String status; // 'paid' atau 'partial'

  const PaymentAllocationData({
    required this.invoiceId,
    required this.customer,
    required this.amount,
    required this.invoiceTotal,
    required this.status,
  });
}

/// Himpunan data untuk preview/print kwitansi gabungan.
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