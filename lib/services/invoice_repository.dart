import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Simple repository for POS invoices and invoice items using SQLite (WASM on web).
class InvoiceRepository {
  Database? _db;

  Future<void> init() async {
    final factory = databaseFactoryFfiWeb;
    _db = await factory.openDatabase('pos.db');
    await _createTables();
    await _seedIfEmpty();
  }

  Future<void> _createTables() async {
    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer TEXT,
        total REAL NOT NULL,
        status TEXT NOT NULL,
        date TEXT NOT NULL
      );
    ''');
    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceId INTEGER NOT NULL,
        name TEXT NOT NULL,
        qty INTEGER NOT NULL,
        price REAL NOT NULL
      );
    ''');
    await _db!.execute(
      'CREATE INDEX IF NOT EXISTS idx_invoices_date ON invoices(date);',
    );
    await _db!.execute(
      'CREATE INDEX IF NOT EXISTS idx_invoice_items_invoice ON invoice_items(invoiceId);',
    );
    // Payments: support combined payments across multiple invoices
    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        payer TEXT NOT NULL,
        amount REAL NOT NULL,
        method TEXT,
        date TEXT NOT NULL
      );
    ''');
    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS payment_allocations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        paymentId INTEGER NOT NULL,
        invoiceId INTEGER NOT NULL,
        amount REAL NOT NULL
      );
    ''');
    await _db!.execute(
      'CREATE INDEX IF NOT EXISTS idx_payment_allocations_invoice ON payment_allocations(invoiceId);',
    );
  }

  Future<void> _seedIfEmpty() async {
    final count = Sqflite.firstIntValue(
      await _db!.rawQuery('SELECT COUNT(*) FROM invoices'),
    );
    if ((count ?? 0) == 0) {
      // Create one sample unpaid invoice for demo
      final now = DateTime.now();
      final id = await _db!.insert('invoices', {
        'customer': 'Alexander Dippo',
        'total': 24272000.0,
        'status': 'unpaid',
        'date': now.toIso8601String(),
      });
      await _db!.insert('invoice_items', {
        'invoiceId': id,
        'name': 'GREEN FEE',
        'qty': 1,
        'price': 24272000.0,
      });
    }
  }

  Future<int> createInvoice({
    required String customer,
    required List<InvoiceItemInput> items,
    String status = 'unpaid',
    DateTime? date,
  }) async {
    final dt = date ?? DateTime.now();
    final total = items.fold<double>(0.0, (s, e) => s + e.price * e.qty);
    final invoiceId = await _db!.insert('invoices', {
      'customer': customer,
      'total': total,
      'status': status,
      'date': dt.toIso8601String(),
    });
    for (final item in items) {
      await _db!.insert('invoice_items', {
        'invoiceId': invoiceId,
        'name': item.name,
        'qty': item.qty,
        'price': item.price,
      });
    }
    return invoiceId;
  }

  Future<List<Map<String, Object?>>> getUnpaidInvoices() async {
    return _db!.query(
      'invoices',
      where: 'status = ?',
      whereArgs: const ['unpaid'],
      orderBy: 'date DESC',
    );
  }

  Future<List<Map<String, Object?>>> getInvoices({DateTime? date, String? customerQuery, String? status}) async {
    final whereParts = <String>[];
    final args = <Object?>[];
    if (status != null && status.isNotEmpty) {
      whereParts.add('status = ?');
      args.add(status);
    }
    if (date != null) {
      final isoDay = DateTime(date.year, date.month, date.day)
          .toIso8601String()
          .split('T')
          .first; // e.g., 2025-10-15
      whereParts.add("date LIKE ?");
      args.add('$isoDay%');
    }
    if (customerQuery != null && customerQuery.trim().isNotEmpty) {
      whereParts.add('customer LIKE ?');
      args.add('%${customerQuery.trim()}%');
    }
    final whereClause = whereParts.isEmpty ? null : whereParts.join(' AND ');
    return _db!.query(
      'invoices',
      where: whereClause,
      whereArgs: whereClause == null ? null : args,
      orderBy: 'date DESC',
    );
  }

  Future<List<Map<String, Object?>>> getItemsForInvoice(int invoiceId) async {
    return _db!.query(
      'invoice_items',
      where: 'invoiceId = ?',
      whereArgs: [invoiceId],
      orderBy: 'id ASC',
    );
  }
  // Total paid amount against an invoice (sum of allocations)
  Future<double> getPaidAmountForInvoice(int invoiceId) async {
    final rows = await _db!.rawQuery(
      'SELECT SUM(amount) AS paid FROM payment_allocations WHERE invoiceId = ?',
      [invoiceId],
    );
    final paid = (rows.first['paid'] as num?)?.toDouble() ?? 0.0;
    return paid;
  }

  /// Create a combined payment that allocates amounts to multiple invoices.
  /// This allows one payer to settle invoices for multiple customers or bookings.
  Future<int> createCombinedPayment({
    required String payer,
    required List<PaymentAllocationInput> allocations,
    String? method,
    DateTime? date,
  }) async {
    final dt = date ?? DateTime.now();
    final totalAmount = allocations.fold<double>(0.0, (s, e) => s + e.amount);
    final paymentId = await _db!.insert('payments', {
      'payer': payer,
      'amount': totalAmount,
      'method': method,
      'date': dt.toIso8601String(),
    });
    for (final alloc in allocations) {
      await _db!.insert('payment_allocations', {
        'paymentId': paymentId,
        'invoiceId': alloc.invoiceId,
        'amount': alloc.amount,
      });
      // Update invoice status based on total paid so far
      final invRow = await _db!.query(
        'invoices',
        where: 'id = ?',
        whereArgs: [alloc.invoiceId],
        limit: 1,
      );
      if (invRow.isNotEmpty) {
        final total = (invRow.first['total'] as num).toDouble();
        final paid = await getPaidAmountForInvoice(alloc.invoiceId);
        final status = paid >= total
            ? 'paid'
            : (paid > 0.0 ? 'partial' : 'unpaid');
        await _db!.update(
          'invoices',
          {'status': status},
          where: 'id = ?',
          whereArgs: [alloc.invoiceId],
        );
      }
    }
    return paymentId;
  }

  // --- NEW: Query payments and allocations ---
  Future<List<Map<String, Object?>>> getPayments({DateTime? date, String? payerQuery, String? method}) async {
    final whereParts = <String>[];
    final args = <Object?>[];
    if (date != null) {
      final isoDay = DateTime(date.year, date.month, date.day)
          .toIso8601String()
          .split('T')
          .first;
      whereParts.add('date LIKE ?');
      args.add('$isoDay%');
    }
    if (payerQuery != null && payerQuery.trim().isNotEmpty) {
      whereParts.add('payer LIKE ?');
      args.add('%${payerQuery.trim()}%');
    }
    if (method != null && method.trim().isNotEmpty) {
      whereParts.add('method = ?');
      args.add(method.trim());
    }
    final whereClause = whereParts.isEmpty ? null : whereParts.join(' AND ');
    return _db!.query(
      'payments',
      where: whereClause,
      whereArgs: whereClause == null ? null : args,
      orderBy: 'date DESC',
    );
  }

  Future<List<Map<String, Object?>>> getAllocationsForPayment(int paymentId) async {
    return _db!.rawQuery(
      'SELECT pa.id, pa.invoiceId, pa.amount, i.customer, i.total, i.status FROM payment_allocations pa JOIN invoices i ON i.id = pa.invoiceId WHERE pa.paymentId = ? ORDER BY pa.id ASC',
      [paymentId],
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

class InvoiceItemInput {
  final String name;
  final int qty;
  final double price;

  const InvoiceItemInput({required this.name, required this.qty, required this.price});
}
class PaymentAllocationInput {
  final int invoiceId;
  final double amount;
  const PaymentAllocationInput({required this.invoiceId, required this.amount});
}