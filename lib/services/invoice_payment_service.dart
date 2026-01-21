import 'package:modern_golf_reservations/models/invoice_models.dart';
import 'invoice_repository.dart';

class InvoicePaymentService {
  final InvoiceRepository _repo;
  InvoicePaymentService({InvoiceRepository? repository})
    : _repo = repository ?? InvoiceRepository();

  Future<void> init() => _repo.init();
  Future<void> close() => _repo.close();

  Future<List<InvoiceItem>> loadInvoices({
    DateTime? date,
    String? customerQuery,
  }) async {
    final rows = await _repo.getInvoices(
      date: date,
      customerQuery: customerQuery,
    );
    final items = <InvoiceItem>[];
    for (final e in rows) {
      final idVal = e['id'] as int? ?? (e['id'] as num).toInt();
      final statusStr = (e['status'] as String?) ?? 'unpaid';
      final status = switch (statusStr) {
        'paid' => PaymentStatus.paid,
        'partial' => PaymentStatus.partial,
        _ => PaymentStatus.unpaid,
      };
      final total = (e['total'] is num)
          ? (e['total'] as num).toDouble()
          : (e['total'] as double? ?? 0.0);
      final paid = await _repo.getPaidAmountForInvoice(idVal);
      final outstanding = (total - paid).clamp(0.0, double.infinity);
      if (outstanding <= 0.0) {
        continue;
      }
      items.add(
        InvoiceItem(
          id: idVal.toString(),
          customer: (e['customer'] as String?) ?? 'Walk-in',
          phoneNumber: e['phoneNumber'] as String?,
          total: total,
          status: status,
          date:
              DateTime.tryParse((e['date'] as String?) ?? '') ?? DateTime.now(),
          outstanding: outstanding,
        ),
      );
    }
    return items;
  }

  Future<List<InvoiceLine>> getInvoiceLines(int invoiceId) async {
    final rows = await _repo.getItemsForInvoice(invoiceId);
    return rows.map((e) {
      final name = (e['name'] as String?) ?? '';
      final qty =
          (e['qty'] as int?) ??
          (e['qty'] is num ? (e['qty'] as num).toInt() : 0);
      final price = (e['price'] is num)
          ? (e['price'] as num).toDouble()
          : (e['price'] as double? ?? 0.0);
      return InvoiceLine(name: name, qty: qty, price: price);
    }).toList();
  }

  CombinedReceiptData? validateCombinedAllocations({
    required List<InvoiceItem> invoices,
    required Map<int, double> amountsByInvoiceId,
    required String payer,
    required String methodLabel,
  }) {
    final allocations = <PaymentAllocationData>[];
    final invalid = <String>[];
    num totalAmount = 0;

    for (final entry in amountsByInvoiceId.entries) {
      final id = entry.key;
      final amount = entry.value;
      final inv = invoices.firstWhere(
        (e) => int.tryParse(e.id) == id,
        orElse: () => InvoiceItem(
          id: id.toString(),
          customer: '-',
          total: 0,
          status: PaymentStatus.unpaid,
          date: DateTime.now(),
          outstanding: 0,
        ),
      );
      if (amount <= 0) {
        invalid.add('#${inv.id} (nominal kosong/tidak valid)');
        continue;
      }
      if (amount > inv.outstanding + 0.0001) {
        invalid.add('#${inv.id} (nominal melebihi sisa tagihan)');
        continue;
      }
      totalAmount += amount;
      final statusAfter = amount >= inv.outstanding - 0.0001
          ? 'paid'
          : 'partial';
      allocations.add(
        PaymentAllocationData(
          invoiceId: int.parse(inv.id),
          customer: inv.customer,
          phoneNumber: inv.phoneNumber,
          amount: amount,
          invoiceTotal: inv.total,
          status: statusAfter,
        ),
      );
    }

    if (invalid.isNotEmpty || allocations.isEmpty) {
      return null;
    }

    return CombinedReceiptData(
      payer: payer.isEmpty ? 'Unknown Payer' : payer,
      methodLabel: methodLabel,
      totalAmount: totalAmount,
      allocations: allocations,
    );
  }

  Future<int> processCombinedPayment({
    required String payer,
    required Map<int, double> amountsByInvoiceId,
    required String method,
  }) async {
    final inputs = amountsByInvoiceId.entries
        .map((e) => PaymentAllocationInput(invoiceId: e.key, amount: e.value))
        .toList();
    final paymentId = await _repo.createCombinedPayment(
      payer: payer.isEmpty ? 'Unknown Payer' : payer,
      allocations: inputs,
      method: method,
    );
    return paymentId;
  }

  Future<void> processIndividualPayment({
    required int invoiceId,
    required double amount,
    required String payer,
    required String method,
  }) async {
    await _repo.createCombinedPayment(
      payer: payer.isEmpty ? 'Unknown Payer' : payer,
      allocations: [
        PaymentAllocationInput(invoiceId: invoiceId, amount: amount),
      ],
      method: method,
    );
  }
}
