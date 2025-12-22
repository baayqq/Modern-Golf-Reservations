import 'package:flutter/material.dart';
import '../../app_scaffold.dart';
import '../../services/invoice_repository.dart';
import 'package:printing/printing.dart';
import '../../services/payment_pdf.dart' as paypdf;
import 'package:modern_golf_reservations/utils/currency.dart';
import '../../models/payment_models.dart';
import 'payment_history_folder/filters_widget.dart';
import 'payment_history_folder/payment_table.dart';
import 'payment_history_folder/allocations_section.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  final InvoiceRepository _repo = InvoiceRepository();
  final TextEditingController _payerCtrl = TextEditingController();
  DateTime? _filterDate;
  String? _methodFilter;

  List<PaymentRecord> _payments = [];
  PaymentRecord? _selectedPayment;
  List<AllocationRecord> _allocations = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _repo.init();
    await _load();
  }

  Future<void> _load() async {
    final rows = await _repo.getPayments(
      date: _filterDate,
      payerQuery: _payerCtrl.text.trim().isEmpty
          ? null
          : _payerCtrl.text.trim(),
      method: _methodFilter,
    );
    final items = rows.map((e) {
      final id = (e['id'] as int?) ?? (e['id'] as num).toInt();
      final payer = (e['payer'] as String?) ?? 'Unknown';
      final amount = (e['amount'] is num)
          ? (e['amount'] as num).toDouble()
          : (e['amount'] as double? ?? 0.0);
      final method = e['method'] as String?;
      final date =
          DateTime.tryParse((e['date'] as String?) ?? '') ?? DateTime.now();
      return PaymentRecord(
        id: id,
        payer: payer,
        amount: amount,
        method: method,
        date: date,
      );
    }).toList();
    setState(() {
      _payments = items;
      _selectedPayment = null;
      _allocations = [];
    });
  }

  Future<void> _viewAllocations(PaymentRecord p) async {
    setState(() {
      _selectedPayment = p;
      _allocations = [];
    });
    final rows = await _repo.getAllocationsForPayment(p.id);
    setState(() {
      _allocations = rows.map((e) {
        final id = (e['id'] as int?) ?? (e['id'] as num).toInt();
        final invoiceId =
            (e['invoiceId'] as int?) ?? (e['invoiceId'] as num).toInt();
        final amount = (e['amount'] is num)
            ? (e['amount'] as num).toDouble()
            : (e['amount'] as double? ?? 0.0);
        final customer = (e['customer'] as String?) ?? 'Walk-in';
        final total = (e['total'] is num)
            ? (e['total'] as num).toDouble()
            : (e['total'] as double? ?? 0.0);
        final status = (e['status'] as String?) ?? 'unpaid';
        return AllocationRecord(
          id: id,
          invoiceId: invoiceId,
          amount: amount,
          customer: customer,
          invoiceTotal: total,
          status: status,
        );
      }).toList();
    });
  }

  Future<void> _pickFilterDate() async {
    final now = DateTime.now();
    final res = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDate: _filterDate ?? now,
    );
    if (res != null) setState(() => _filterDate = res);
  }

  void _clearFilters() {
    setState(() {
      _filterDate = null;
      _payerCtrl.clear();
      _methodFilter = null;
    });
    _load();
  }

  @override
  void dispose() {
    _repo.close();
    _payerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Payment History',
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Payment History',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            PaymentHistoryFilters(
              filterDate: _filterDate,
              payerController: _payerCtrl,
              methodFilter: _methodFilter,
              onSearch: _load,
              onClear: _clearFilters,
              onPickDate: _pickFilterDate,
              onChangeMethod: (v) => setState(() => _methodFilter = v),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PaymentTable(
                payments: _payments,
                onView: _viewAllocations,
                onPrint: _printPayment,
                onDownload: _downloadPayment,
                formatDate: (d) => '${_two(d.day)}/${_two(d.month)}/${d.year}',
              ),
            ),
            const SizedBox(height: 16),
            PaymentAllocationsSection(
              selectedPayment: _selectedPayment,
              allocations: _allocations,
              onPrint: _selectedPayment == null
                  ? null
                  : () => _printPayment(_selectedPayment!),
              onDownload: _selectedPayment == null
                  ? null
                  : () => _downloadPayment(_selectedPayment!),
              formatDate: (d) => '${_two(d.day)}/${_two(d.month)}/${d.year}',
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '© 2025 | Fitri Dwi Astuti.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<void> _printPayment(PaymentRecord p) async {
    List<AllocationRecord> allocs = _allocations;
    if (_selectedPayment == null || _selectedPayment!.id != p.id) {
      final rows = await _repo.getAllocationsForPayment(p.id);
      allocs = rows.map((e) {
        final id = (e['id'] as int?) ?? (e['id'] as num).toInt();
        final invoiceId =
            (e['invoiceId'] as int?) ?? (e['invoiceId'] as num).toInt();
        final amount = (e['amount'] is num)
            ? (e['amount'] as num).toDouble()
            : (e['amount'] as double? ?? 0.0);
        final customer = (e['customer'] as String?) ?? 'Walk-in';
        final total = (e['total'] is num)
            ? (e['total'] as num).toDouble()
            : (e['total'] as double? ?? 0.0);
        final status = (e['status'] as String?) ?? 'unpaid';
        return AllocationRecord(
          id: id,
          invoiceId: invoiceId,
          amount: amount,
          customer: customer,
          invoiceTotal: total,
          status: status,
        );
      }).toList();
    }

    final pdfAllocations = allocs
        .map(
          (a) => paypdf.PaymentAllocation(
            invoiceId: a.invoiceId,
            customer: a.customer,
            amount: a.amount,
            invoiceTotal: a.invoiceTotal,
            status: a.status,
          ),
        )
        .toList();

    try {
      await Printing.sharePdf(
        bytes: await paypdf.generatePaymentPdf(
          paymentId: p.id,
          date: p.date,
          payer: p.payer,
          method: p.method ?? '-',
          amount: p.amount,
          allocations: pdfAllocations,
        ),
        filename: 'payment_${p.id}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuka dialog print: $e')));
      return;
    }

    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {});
  }

  Future<void> _downloadPayment(PaymentRecord p) async {
    List<AllocationRecord> allocs = _allocations;
    if (_selectedPayment == null || _selectedPayment!.id != p.id) {
      final rows = await _repo.getAllocationsForPayment(p.id);
      allocs = rows.map((e) {
        final id = (e['id'] as int?) ?? (e['id'] as num).toInt();
        final invoiceId =
            (e['invoiceId'] as int?) ?? (e['invoiceId'] as num).toInt();
        final amount = (e['amount'] is num)
            ? (e['amount'] as num).toDouble()
            : (e['amount'] as double? ?? 0.0);
        final customer = (e['customer'] as String?) ?? 'Walk-in';
        final total = (e['total'] is num)
            ? (e['total'] as num).toDouble()
            : (e['total'] as double? ?? 0.0);
        final status = (e['status'] as String?) ?? 'unpaid';
        return AllocationRecord(
          id: id,
          invoiceId: invoiceId,
          amount: amount,
          customer: customer,
          invoiceTotal: total,
          status: status,
        );
      }).toList();
    }

    final pdfAllocations = allocs
        .map(
          (a) => paypdf.PaymentAllocation(
            invoiceId: a.invoiceId,
            customer: a.customer,
            amount: a.amount,
            invoiceTotal: a.invoiceTotal,
            status: a.status,
          ),
        )
        .toList();

    try {
      final bytes = await paypdf.generatePaymentPdf(
        paymentId: p.id,
        date: p.date,
        payer: p.payer,
        method: p.method ?? '-',
        amount: p.amount,
        allocations: pdfAllocations,
      );
      await Printing.sharePdf(bytes: bytes, filename: 'payment_${p.id}.pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengunduh PDF: $e')));
      return;
    }

    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {});
  }
}
