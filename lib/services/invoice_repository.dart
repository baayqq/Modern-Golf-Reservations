import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class InvoiceRepository {
  static Database? _sharedDb;
  static bool _tablesInitialized = false;

  Database? _db;

  Future<void> init() async {
    if (_sharedDb == null || !_sharedDb!.isOpen) {
      final factory = databaseFactoryFfiWeb;
      _sharedDb = await factory.openDatabase('pos.db');
    }
    _db = _sharedDb;

    if (!_tablesInitialized) {
      await _createTables();
      await _seedIfEmpty();
      _tablesInitialized = true;
    }
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

  Future<void> _seedIfEmpty() async {}

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

  Future<List<Map<String, Object?>>> getInvoices({
    DateTime? date,
    String? customerQuery,
    String? status,
  }) async {
    final whereParts = <String>[];
    final args = <Object?>[];
    if (status != null && status.isNotEmpty) {
      whereParts.add('status = ?');
      args.add(status);
    }
    if (date != null) {
      final isoDay = DateTime(
        date.year,
        date.month,
        date.day,
      ).toIso8601String().split('T').first;
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

  Future<double> getPaidAmountForInvoice(int invoiceId) async {
    final rows = await _db!.rawQuery(
      'SELECT SUM(amount) AS paid FROM payment_allocations WHERE invoiceId = ?',
      [invoiceId],
    );
    final paid = (rows.first['paid'] as num?)?.toDouble() ?? 0.0;
    return paid;
  }

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

  Future<List<Map<String, Object?>>> getPayments({
    DateTime? date,
    String? payerQuery,
    String? method,
  }) async {
    final whereParts = <String>[];
    final args = <Object?>[];
    if (date != null) {
      final isoDay = DateTime(
        date.year,
        date.month,
        date.day,
      ).toIso8601String().split('T').first;
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

  Future<List<Map<String, Object?>>> getAllocationsForPayment(
    int paymentId,
  ) async {
    return _db!.rawQuery(
      'SELECT pa.id, pa.invoiceId, pa.amount, i.customer, i.total, i.status FROM payment_allocations pa JOIN invoices i ON i.id = pa.invoiceId WHERE pa.paymentId = ? ORDER BY pa.id ASC',
      [paymentId],
    );
  }

  Future<Set<String>> getCustomersWithInvoices() async {
    final rows = await _db!.rawQuery(
      'SELECT DISTINCT LOWER(customer) as customer FROM invoices WHERE customer IS NOT NULL',
    );
    return rows
        .map((row) => (row['customer'] as String?) ?? '')
        .where((c) => c.trim().isNotEmpty)
        .toSet();
  }

  Future<void> recalculateAllInvoiceStatuses() async {
    final invoices = await _db!.query('invoices');
    for (final invoice in invoices) {
      final invoiceId = invoice['id'] as int;
      final total = (invoice['total'] as num).toDouble();
      final paid = await getPaidAmountForInvoice(invoiceId);
      final status = paid >= total
          ? 'paid'
          : (paid > 0.0 ? 'partial' : 'unpaid');
      await _db!.update(
        'invoices',
        {'status': status},
        where: 'id = ?',
        whereArgs: [invoiceId],
      );
    }
  }

  Future<void> close() async {
    if (kIsWeb) {
      _db = null;
      return;
    }
    await _db?.close();
    _db = null;
  }
}

class InvoiceItemInput {
  final String name;
  final int qty;
  final double price;

  const InvoiceItemInput({
    required this.name,
    required this.qty,
    required this.price,
  });
}

class PaymentAllocationInput {
  final int invoiceId;
  final double amount;
  const PaymentAllocationInput({required this.invoiceId, required this.amount});
}
