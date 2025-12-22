import 'package:flutter/material.dart';
import '../../app_scaffold.dart';
import '../../services/invoice_payment_service.dart';
import 'package:modern_golf_reservations/utils/currency.dart';
import 'package:printing/printing.dart';
import '../../services/invoice_pdf.dart' as pdfsvc;

import 'package:modern_golf_reservations/models/invoice_models.dart';
import 'invoice_page_folder/invoice_filters.dart';
import 'invoice_page_folder/invoice_table.dart';
import 'invoice_page_folder/print_action_bar.dart';
import 'invoice_page_folder/combined_payment_bar.dart';
import 'invoice_page_folder/details_section.dart';
import 'invoice_page_folder/combined_details_section.dart';
import 'invoice_page_folder/combined_receipt_bar.dart';
import '../../services/payment_pdf.dart' as paypdf;
import 'package:modern_golf_reservations/utils/date_formatters.dart';
import 'package:modern_golf_reservations/widgets/pos/invoice/confirm_combined_payment_dialog.dart';
import 'package:modern_golf_reservations/widgets/pos/invoice/confirm_individual_payment_dialog.dart';
import 'package:modern_golf_reservations/widgets/pos/invoice/print_saved_combined_payment_dialog.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final InvoicePaymentService _service = InvoicePaymentService();
  List<InvoiceItem> _invoices = [];
  InvoiceItem? _selectedInvoice;
  List<InvoiceLine> _selectedItems = [];
  DateTime? _filterDate;
  final TextEditingController _filterNameCtrl = TextEditingController();

  final TextEditingController _payerCtrl = TextEditingController();
  final Set<int> _selectedInvoiceIds = <int>{};

  final Map<int, TextEditingController> _amountCtrls = {};

  PaymentMode _paymentMode = PaymentMode.combined;

  String _paymentMethod = 'cash';
  static const Map<String, String> _methodLabels = {
    'cash': 'Cash',
    'credit': 'Kartu Kredit',
    'debit': 'Debit',
    'qris': 'QRIS',
  };

  final Map<int, List<InvoiceLine>> _combinedSelectedItems = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _service.init();
    await _load();
  }

  Future<void> _load() async {
    final items = await _service.loadInvoices(
      date: _filterDate,
      customerQuery: _filterNameCtrl.text.trim().isEmpty
          ? null
          : _filterNameCtrl.text.trim(),
    );
    setState(() {
      _invoices = items;
      for (final inv in _invoices) {
        final id = int.parse(inv.id);
        _amountCtrls.putIfAbsent(id, () => TextEditingController());
        final ctrl = _amountCtrls[id]!;
        final defaultText = inv.outstanding > 0
            ? inv.outstanding.toStringAsFixed(0)
            : '';
        ctrl.text = defaultText;
      }
    });
  }

  Future<void> _viewDetails(InvoiceItem inv) async {
    setState(() {
      _selectedInvoice = inv;
      _selectedItems = [];
    });
    final items = await _service.getInvoiceLines(int.parse(inv.id));
    setState(() {
      _selectedItems = items;
    });
  }

  Future<void> _exportPdf() async {
    InvoiceItem? targetInv = _selectedInvoice;
    if (targetInv == null && _selectedInvoiceIds.length == 1) {
      final id = _selectedInvoiceIds.first;
      final matches = _invoices.where((e) => int.tryParse(e.id) == id);
      targetInv = matches.isNotEmpty ? matches.first : null;
    }

    if (targetInv == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tepat satu invoice terlebih dahulu'),
        ),
      );
      return;
    }

    List<InvoiceLine> items = _selectedItems;
    if (_selectedInvoice == null || _selectedInvoice!.id != targetInv!.id) {
      items = await _service.getInvoiceLines(int.parse(targetInv!.id));
    }

    final pdfItems = items
        .map(
          (it) => pdfsvc.InvoiceItem(
            productName: it.name,
            quantity: it.qty,
            unitPrice: it.price,
          ),
        )
        .toList();

    try {
      await Printing.sharePdf(
        bytes: await pdfsvc.generateInvoicePdf(
          invoiceDate: targetInv!.date,
          customerName: targetInv!.customer,
          items: pdfItems,
        ),
        filename: 'invoice_${targetInv!.id}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal print invoice: $e')));
      return;
    }

    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _downloadPdf() async {
    InvoiceItem? targetInv = _selectedInvoice;
    if (targetInv == null && _selectedInvoiceIds.length == 1) {
      final id = _selectedInvoiceIds.first;
      final matches = _invoices.where((e) => int.tryParse(e.id) == id);
      targetInv = matches.isNotEmpty ? matches.first : null;
    }

    if (targetInv == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tepat satu invoice terlebih dahulu'),
        ),
      );
      return;
    }

    List<InvoiceLine> items = _selectedItems;
    if (_selectedInvoice == null || _selectedInvoice!.id != targetInv.id) {
      items = await _service.getInvoiceLines(int.parse(targetInv.id));
    }

    final pdfItems = items
        .map(
          (it) => pdfsvc.InvoiceItem(
            productName: it.name,
            quantity: it.qty,
            unitPrice: it.price,
          ),
        )
        .toList();

    try {
      final bytes = await pdfsvc.generateInvoicePdf(
        invoiceDate: targetInv.date,
        customerName: targetInv.customer,
        items: pdfItems,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'invoice_${targetInv.id}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengunduh PDF: $e')));
      return;
    }

    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    if (mounted) {
      setState(() {});
    }
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
      _filterNameCtrl.clear();
    });
    _load();
  }

  Future<void> _loadCombinedDetails() async {
    final ids = _selectedInvoiceIds.toList();
    final futures = ids.map((id) => _service.getInvoiceLines(id)).toList();
    final results = await Future.wait(futures);
    final Map<int, List<InvoiceLine>> next = {};
    for (var i = 0; i < ids.length; i++) {
      next[ids[i]] = results[i];
    }
    if (!mounted) return;
    setState(() {
      _combinedSelectedItems
        ..clear()
        ..addAll(next);
    });
  }

  @override
  void dispose() {
    _filterNameCtrl.dispose();
    _payerCtrl.dispose();
    for (final c in _amountCtrls.values) {
      c.dispose();
    }
    _service.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Invoices',
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tableHeight = (constraints.maxHeight * 0.5).clamp(
              320.0,
              560.0,
            );
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Invoice List',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  InvoiceFilters(
                    filterDate: _filterDate,
                    nameController: _filterNameCtrl,
                    onSearch: _load,
                    onClear: _clearFilters,
                    onPickDate: _pickFilterDate,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: tableHeight,
                    child: InvoiceTable(
                      invoices: _invoices,
                      selectedInvoiceIds: _selectedInvoiceIds,
                      paymentMode: _paymentMode,
                      amountControllers: _amountCtrls,
                      onCheckboxChanged: _onCheckboxChanged,
                      onTapDetails: _viewDetails,
                      formatDate: _formatDate,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_paymentMode == PaymentMode.individual)
                    PrintActionBar(
                      canPrintSingle:
                          _selectedInvoice != null ||
                          _selectedInvoiceIds.length == 1,
                      onPrint: _exportPdf,
                      onDownload: _downloadPdf,
                    ),
                  const SizedBox(height: 16),
                  if (_paymentMode == PaymentMode.combined &&
                      _selectedInvoiceIds.isNotEmpty)
                    CombinedDetailsSection(
                      selectedInvoiceIds: _selectedInvoiceIds,
                      invoices: _invoices,
                      combinedSelectedItems: _combinedSelectedItems,
                      formatDate: _formatDate,
                    ),
                  if (_paymentMode == PaymentMode.combined)
                    CombinedReceiptBar(
                      selectedCount: _selectedInvoiceIds.length,
                      onPrintCombined: _printCombinedDetails,
                      onDownloadCombined: _downloadCombinedDetails,
                    ),
                  const SizedBox(height: 16),
                  InvoiceDetailsSection(
                    selectedInvoice: _selectedInvoice,
                    selectedItems: _selectedItems,
                    formatDate: _formatDate,
                  ),
                  const SizedBox(height: 16),
                  CombinedPaymentBar(
                    payerController: _payerCtrl,
                    paymentMode: _paymentMode,
                    onChangePaymentMode: (mode) {
                      setState(() {
                        _paymentMode = mode;
                        if (mode == PaymentMode.individual) {
                          _selectedInvoiceIds.clear();
                          _combinedSelectedItems.clear();
                        }
                      });
                    },
                    paymentMethod: _paymentMethod,
                    onChangePaymentMethod: (method) =>
                        setState(() => _paymentMethod = method),
                    onCombinedPay: _handleCombinedPayment,
                    onIndividualPay: () async {
                      if (_selectedInvoice == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Pilih invoice terlebih dahulu (klik ID/Nama/Tanggal)',
                            ),
                          ),
                        );
                        return;
                      }
                      await _handleIndividualPayment(_selectedInvoice!);
                    },
                    selectedCount: _selectedInvoiceIds.length,
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
            );
          },
        ),
      ),
    );
  }

  Future<void> _onCheckboxChanged(InvoiceItem inv, bool? val) async {
    final id = int.parse(inv.id);
    if (_paymentMode == PaymentMode.combined) {
      setState(() {
        if (val == true) {
          _selectedInvoiceIds.add(id);
        } else {
          _selectedInvoiceIds.remove(id);
          _combinedSelectedItems.remove(id);
        }
      });
      await _loadCombinedDetails();
    } else {
      setState(() {
        if (val == true) {
          _selectedInvoiceIds
            ..clear()
            ..add(id);
        } else {
          _selectedInvoiceIds.remove(id);
        }
      });
      if (val == true) {
        await _viewDetails(inv);
      }
    }
  }

  Future<void> _printCombinedDetails() async {
    final data = _buildCombinedReceiptData();
    if (data == null) return;
    try {
      final allocations = data.allocations
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
      await Printing.sharePdf(
        bytes: await paypdf.generatePaymentPdf(
          paymentId: 0,
          date: DateTime.now(),
          payer: data.payer,
          method: data.methodLabel,
          amount: data.totalAmount,
          allocations: allocations,
        ),
        filename:
            'payment_combined_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal print payment: $e')));
      return;
    }

    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _downloadCombinedDetails() async {
    final data = _buildCombinedReceiptData();
    if (data == null) return;
    try {
      final allocations = data.allocations
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
      final bytes = await paypdf.generatePaymentPdf(
        paymentId: 0,
        date: DateTime.now(),
        payer: data.payer,
        method: data.methodLabel,
        amount: data.totalAmount,
        allocations: allocations,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'combined_payment_preview.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengunduh PDF: $e')));
      return;
    }

    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    if (mounted) {
      setState(() {});
    }
  }

  CombinedReceiptData? _buildCombinedReceiptData() {
    if (_selectedInvoiceIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal dua invoice untuk pembayaran gabungan'),
        ),
      );
      return null;
    }
    final amountsById = <int, double>{};
    for (final id in _selectedInvoiceIds) {
      final ctrl = _amountCtrls[id];
      final raw = ctrl?.text.trim() ?? '';
      final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
      final amount = digits.isEmpty ? 0.0 : double.tryParse(digits) ?? 0.0;
      amountsById[id] = amount;
    }
    final payer = _payerCtrl.text.trim();
    final methodLabel = _methodLabels[_paymentMethod] ?? _paymentMethod;
    final res = _service.validateCombinedAllocations(
      invoices: _invoices,
      amountsByInvoiceId: amountsById,
      payer: payer,
      methodLabel: methodLabel,
    );
    if (res == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Periksa nominal alokasi pembayaran')),
      );
    }
    return res;
  }

  Future<void> _handleCombinedPayment() async {
    final data = _buildCombinedReceiptData();
    if (data == null) return;
    final confirmed = await ConfirmCombinedPaymentDialog.show(
      context,
      payer: data.payer,
      methodLabel: data.methodLabel,
      allocations: data.allocations,
    );
    if (!confirmed) return;

    final amountsById = <int, double>{
      for (final a in data.allocations) a.invoiceId: a.amount,
    };
    final paymentId = await _service.processCombinedPayment(
      payer: data.payer,
      amountsByInvoiceId: amountsById,
      method: _paymentMethod,
    );
    if (!mounted) return;
    setState(() {
      _selectedInvoiceIds.clear();
    });
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pembayaran gabungan berhasil diproses')),
    );
    await PrintSavedCombinedPaymentDialog.show(
      context,
      paymentId: paymentId,
      payer: data.payer,
      methodLabel: data.methodLabel,
      total: data.totalAmount,
      allocations: data.allocations,
    );
  }

  Future<void> _handleIndividualPayment(InvoiceItem inv) async {
    if (_paymentMode != PaymentMode.individual) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Aktifkan mode 'Individu' di bar atas untuk melakukan pembayaran individu",
          ),
        ),
      );
      return;
    }
    final id = int.parse(inv.id);
    final ctrl = _amountCtrls[id];
    final raw = ctrl?.text.trim() ?? '';
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = digits.isEmpty ? 0.0 : double.tryParse(digits) ?? 0.0;
    if (amount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nominal tidak valid untuk invoice #${inv.id}')),
      );
      return;
    }
    if (amount > inv.outstanding + 0.0001) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nominal melebihi sisa tagihan untuk invoice #${inv.id}',
          ),
        ),
      );
      return;
    }
    final payer = _payerCtrl.text.trim().isEmpty
        ? inv.customer
        : _payerCtrl.text.trim();

    final confirmed = await ConfirmIndividualPaymentDialog.show(
      context,
      invoice: inv,
      amount: amount,
      payer: payer,
      methodLabel: _methodLabels[_paymentMethod] ?? _paymentMethod,
    );
    if (!confirmed) return;
    await _service.processIndividualPayment(
      invoiceId: id,
      amount: amount,
      payer: payer,
      method: _paymentMethod,
    );
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pembayaran individu berhasil untuk invoice #${inv.id}'),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return DateFormatters.compactDateTime12h(dt);
  }
}
