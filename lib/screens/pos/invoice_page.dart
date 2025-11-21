import 'package:flutter/material.dart';
import '../../app_scaffold.dart';
import '../../services/invoice_repository.dart';
import 'package:modern_golf_reservations/utils/currency.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final InvoiceRepository _repo = InvoiceRepository();
  List<InvoiceItem> _invoices = [];
  InvoiceItem? _selectedInvoice;
  List<InvoiceLine> _selectedItems = [];
  DateTime? _filterDate;
  final TextEditingController _filterNameCtrl = TextEditingController();
  // Combined payment state
  final TextEditingController _payerCtrl = TextEditingController();
  final Set<int> _selectedInvoiceIds = <int>{};
  // Controllers untuk nominal bayar per invoice (partial/custom)
  final Map<int, TextEditingController> _amountCtrls = {};
  // Mode pembayaran: gabungan atau individu
  PaymentMode _paymentMode = PaymentMode.combined;
  // Metode pembayaran: cash, credit, debit, qris
  String _paymentMethod = 'cash';
  static const Map<String, String> _methodLabels = {
    'cash': 'Cash',
    'credit': 'Kartu Kredit',
    'debit': 'Debit',
    'qris': 'QRIS',
  };
  // Detail item untuk pilihan gabungan: invoiceId -> daftar item
  final Map<int, List<InvoiceLine>> _combinedSelectedItems = {};

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
    final rows = await _repo.getInvoices(
      date: _filterDate,
      customerQuery: _filterNameCtrl.text.trim().isEmpty
          ? null
          : _filterNameCtrl.text.trim(),
    );
    // Hitung outstanding (sisa tagihan) untuk setiap invoice
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
      // Permintaan: jika invoice sudah dibayar, jangan tampilkan di Invoice Page.
      // Logika yang lebih aman adalah menyembunyikan invoice dengan sisa tagihan 0
      // (baik status-nya 'paid' maupun secara perhitungan sudah lunas).
      if (outstanding <= 0.0) {
        continue; // skip invoice yang sudah lunas
      }
      items.add(
        InvoiceItem(
          id: idVal.toString(),
          customer: (e['customer'] as String?) ?? 'Walk-in',
          total: total,
          status: status,
          date: DateTime.tryParse((e['date'] as String?) ?? '') ?? DateTime.now(),
          outstanding: outstanding,
        ),
      );
    }
    setState(() {
      _invoices = items;
      // Inisialisasi controller nominal per invoice dengan default sisa tagihan
      for (final inv in _invoices) {
        final id = int.parse(inv.id);
        _amountCtrls.putIfAbsent(id, () => TextEditingController());
        final ctrl = _amountCtrls[id]!;
        final defaultText = inv.outstanding > 0 ? inv.outstanding.toStringAsFixed(0) : '';
        ctrl.text = defaultText;
      }
    });
  }

  Future<void> _viewDetails(InvoiceItem inv) async {
    setState(() {
      _selectedInvoice = inv;
      _selectedItems = [];
    });
    final rows = await _repo.getItemsForInvoice(int.parse(inv.id));
    setState(() {
      _selectedItems = rows.map((e) {
        final name = (e['name'] as String?) ?? '';
        final qty =
            (e['qty'] as int?) ??
            (e['qty'] is num ? (e['qty'] as num).toInt() : 0);
        final price = (e['price'] is num)
            ? (e['price'] as num).toDouble()
            : (e['price'] as double? ?? 0.0);
        return InvoiceLine(name: name, qty: qty, price: price);
      }).toList();
    });
  }

  void _exportPdf() {
    if (_selectedInvoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih invoice terlebih dahulu')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Exported invoice #${_selectedInvoice!.id} to PDF (dummy)',
        ),
      ),
    );
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
    // Muat detail untuk semua invoice yang dipilih (mode gabungan), paralel agar UI tidak macet
    final ids = _selectedInvoiceIds.toList();
    final futures = ids.map((id) => _repo.getItemsForInvoice(id)).toList();
    final results = await Future.wait(futures);
    final Map<int, List<InvoiceLine>> next = {};
    for (var i = 0; i < ids.length; i++) {
      final rows = results[i];
      next[ids[i]] = rows.map((e) {
        final name = (e['name'] as String?) ?? '';
        final qty = (e['qty'] as int?) ?? (e['qty'] is num ? (e['qty'] as num).toInt() : 0);
        final price = (e['price'] is num) ? (e['price'] as num).toDouble() : (e['price'] as double? ?? 0.0);
        return InvoiceLine(name: name, qty: qty, price: price);
      }).toList();
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
    _repo.close();
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
            // Gunakan scroll vertikal agar konten panjang tidak overflow.
            // Tabel invoice punya scroll internal sehingga aman.
            final tableHeight = (constraints.maxHeight * 0.5).clamp(320.0, 560.0);
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Invoice List',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _filters(),
                  const SizedBox(height: 16),
                  SizedBox(height: tableHeight, child: _invoiceTable()),
                  const SizedBox(height: 16),
                  if (_paymentMode == PaymentMode.combined && _selectedInvoiceIds.isNotEmpty)
                    _combinedDetailsSection(),
                  const SizedBox(height: 16),
                  _detailsSection(),
                  const SizedBox(height: 16),
                  _combinedPaymentBar(),
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

  Widget _combinedPaymentBar() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nama Pembayar (contoh: Pemain A)'),
            const SizedBox(height: 6),
            SizedBox(
              height: 42,
              child: TextField(
                controller: _payerCtrl,
                decoration: const InputDecoration(hintText: 'Masukkan nama pembayar...'),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Mode Pembayaran'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Gabungan'),
                  selected: _paymentMode == PaymentMode.combined,
                  onSelected: (sel) {
                    if (sel) {
                      setState(() {
                        _paymentMode = PaymentMode.combined;
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Individu'),
                  selected: _paymentMode == PaymentMode.individual,
                  onSelected: (sel) {
                    if (sel) {
                      setState(() {
                        _paymentMode = PaymentMode.individual;
                        _selectedInvoiceIds.clear();
                        _combinedSelectedItems.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Metode Pembayaran'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: const Text('Cash'),
                  selected: _paymentMethod == 'cash',
                  onSelected: (sel) {
                    if (sel) setState(() => _paymentMethod = 'cash');
                  },
                ),
                ChoiceChip(
                  label: const Text('Kartu Kredit'),
                  selected: _paymentMethod == 'credit',
                  onSelected: (sel) {
                    if (sel) setState(() => _paymentMethod = 'credit');
                  },
                ),
                ChoiceChip(
                  label: const Text('Debit'),
                  selected: _paymentMethod == 'debit',
                  onSelected: (sel) {
                    if (sel) setState(() => _paymentMethod = 'debit');
                  },
                ),
                ChoiceChip(
                  label: const Text('QRIS'),
                  selected: _paymentMethod == 'qris',
                  onSelected: (sel) {
                    if (sel) setState(() => _paymentMethod = 'qris');
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_paymentMode == PaymentMode.combined)
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: _handleCombinedPayment,
                  child: const Text('Terima Pembayaran Gabungan'),
                ),
              )
            else
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_selectedInvoice == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pilih invoice terlebih dahulu (klik ID/Nama/Tanggal)')),
                      );
                      return;
                    }
                    await _handleIndividualPayment(_selectedInvoice!);
                  },
                  child: const Text('Bayar Invoice Terpilih'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCombinedPayment() async {
    if (_selectedInvoiceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu invoice untuk dibayar')),
      );
      return;
    }
    // Ambil nominal per invoice dari input pengguna dan validasi terhadap sisa tagihan
    final allocations = <PaymentAllocationInput>[];
    final invalid = <String>[];
    for (final id in _selectedInvoiceIds) {
      final inv = _invoices.firstWhere(
        (e) => int.tryParse(e.id) == id,
        orElse: () => InvoiceItem(id: id.toString(), customer: '', total: 0.0, status: PaymentStatus.unpaid, date: DateTime.now(), outstanding: 0.0),
      );
      final ctrl = _amountCtrls[id];
      final raw = ctrl?.text.trim() ?? '';
      final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
      final amount = digits.isEmpty ? 0.0 : double.tryParse(digits) ?? 0.0;
      if (amount <= 0) {
        invalid.add('#${inv.id} (nominal kosong/tidak valid)');
        continue;
      }
      if (amount > inv.outstanding + 0.0001) {
        invalid.add('#${inv.id} (nominal melebihi sisa tagihan)');
        continue;
      }
      allocations.add(PaymentAllocationInput(invoiceId: id, amount: amount));
    }
    if (invalid.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Periksa nominal: ${invalid.join(', ')}')),
      );
      return;
    }
    if (allocations.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada nominal pembayaran yang valid')),
      );
      return;
    }
    final payer = _payerCtrl.text.trim().isEmpty ? 'Unknown Payer' : _payerCtrl.text.trim();
    await _repo.createCombinedPayment(payer: payer, allocations: allocations, method: _paymentMethod);
    if (!mounted) return;
    setState(() {
      _selectedInvoiceIds.clear();
    });
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pembayaran gabungan berhasil diproses')),
    );
  }
  Future<void> _handleIndividualPayment(InvoiceItem inv) async {
    if (_paymentMode != PaymentMode.individual) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aktifkan mode 'Individu' di bar atas untuk melakukan pembayaran individu")),
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
        SnackBar(content: Text('Nominal melebihi sisa tagihan untuk invoice #${inv.id}')),
      );
      return;
    }
    final payer = _payerCtrl.text.trim().isEmpty ? inv.customer : _payerCtrl.text.trim();

    final confirmed = await _confirmIndividualPayment(inv: inv, amount: amount, payer: payer);
    if (!confirmed) return;

    await _repo.createCombinedPayment(
      payer: payer,
      allocations: [PaymentAllocationInput(invoiceId: id, amount: amount)],
      method: _paymentMethod,
    );
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pembayaran individu berhasil untuk invoice #${inv.id}')),
    );
  }

  Widget _filters() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filter Tanggal'),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 42,
                    child: InkWell(
                      onTap: _pickFilterDate,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.outline),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _filterDate == null
                              ? 'dd/mm/yyyy'
                              : '${_two(_filterDate!.day)}/${_two(_filterDate!.month)}/${_filterDate!.year}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nama Pemain'),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 42,
                    child: TextField(
                      controller: _filterNameCtrl,
                      decoration: const InputDecoration(hintText: 'Cari...'),
                      onSubmitted: (_) => _load(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 42,
              child: ElevatedButton(
                onPressed: _load,
                // Gunakan warna dari tema agar konsisten
                child: const Text('Cari'),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 42,
              child: ElevatedButton(
                onPressed: _clearFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
                child: const Text('Clear'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _invoiceTable() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final table = Table(
            // Gunakan FlexColumnWidth agar tabel mengisi lebar kontainer tanpa perlu scroll horizontal
            columnWidths: const {
              0: FixedColumnWidth(56), // select
              1: FlexColumnWidth(1), // invoice id
              2: FlexColumnWidth(2), // customer name
              3: FlexColumnWidth(1.4), // total
              4: FlexColumnWidth(1.6), // bayar (input)
              5: FlexColumnWidth(1), // status
              6: FlexColumnWidth(1.2), // date
            },
            border: TableBorder.all(color: Theme.of(context).colorScheme.outline),
            children: [
             _headerRow([
               'Select',
               'Invoice ID',
               'Customer Name',
               'Total Amount',
               'Bayar (Rp)',
               'Payment Status',
               'Date',
             ]),
              ..._invoices.map(_dataRow),
            ],
          );

          // Hanya scroll vertikal; lebar tabel mengikuti lebar kontainer
          return Scrollbar(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: table,
              ),
            ),
          );
        },
      ),
    );
  }

  TableRow _headerRow(List<String> headers) {
    return TableRow(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest),
      children: headers
          .map(
            (h) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                h,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          )
          .toList(),
    );
  }

  TableRow _dataRow(InvoiceItem inv) {
    final idInt = int.parse(inv.id);
    final amountCtrl = _amountCtrls[idInt] ?? TextEditingController();
    _amountCtrls[idInt] = amountCtrl;
    return TableRow(
      children: [
        // Select checkbox
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Checkbox(
            value: _selectedInvoiceIds.contains(int.parse(inv.id)),
            onChanged: (val) async {
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
                // Mode individu: pilih satu invoice via checkbox
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
            },
          ),
        ),
        // Invoice ID (clickable)
        InkWell(
          onTap: () => _viewDetails(inv),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              inv.id,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        // Customer Name
        InkWell(
          onTap: () => _viewDetails(inv),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              inv.customer,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // Total Amount
        InkWell(
          onTap: () => _viewDetails(inv),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(Formatters.idr(inv.total)),
          ),
        ),
        // Bayar (Rp) - input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: SizedBox(
            height: 36,
            child: TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Sisa: ${Formatters.idr(inv.outstanding)}',
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onChanged: (v) {
                final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                if (digits != v) {
                  amountCtrl.value = TextEditingValue(
                    text: digits,
                    selection: TextSelection.collapsed(offset: digits.length),
                  );
                }
              },
              onTap: () => _viewDetails(inv),
            ),
          ),
        ),
        // Payment Status (badge)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: _statusBadge(inv.status),
        ),
        // Date
        InkWell(
          onTap: () => _viewDetails(inv),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              _formatDate(inv.date),
              softWrap: true,
            ),
          ),
        ),

      ],
    );
  }

  Widget _detailsSection() {
    if (_selectedInvoice == null) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Klik salah satu invoice untuk melihat detail item transaksi.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final inv = _selectedInvoice!;
    final total = _selectedItems.fold<double>(
      0.0,
      (s, e) => s + e.price * e.qty,
    );
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoice #${inv.id} - ${inv.customer}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('Tanggal: ${_formatDate(inv.date)}'),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final table = Table(
                  columnWidths: const {
                    // Pastikan kolom Item cukup lebar agar teks tidak memecah per huruf
                    0: FixedColumnWidth(220),
                    1: FixedColumnWidth(80),
                    2: FixedColumnWidth(160),
                    3: FixedColumnWidth(180),
                  },
                  border: TableBorder.all(color: Theme.of(context).colorScheme.outline),
                  children: [
                    _headerRow(['Item', 'Qty', 'Price', 'Subtotal']),
                    ..._selectedItems.map(
                      (it) => TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Text(it.name),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Text('${it.qty}'),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Text(Formatters.idr(it.price)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Text(Formatters.idr(it.price * it.qty)),
                          ),
                        ],
                      ),
                    ),
                    TableRow(
                      children: [
                        const SizedBox.shrink(),
                        const SizedBox.shrink(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: const Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Text(
                            Formatters.idr(total),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                );

                // Pastikan tabel minimal selebar area konten untuk mencegah kolom menyempit ekstrem
                return Scrollbar(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: table,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: _exportPdf,
                    child: const Text('Export to PDF'),
                  ),
                  ),
                ],
            ),
          ],
        ),
      ),
    );
  }

  // Menampilkan detail untuk semua invoice yang dipilih saat mode gabungan
  Widget _combinedDetailsSection() {
    final ids = _selectedInvoiceIds.toList();
    if (ids.isEmpty) return const SizedBox.shrink();

    Widget buildItemsTable(List<InvoiceLine> items) {
      final total = items.fold<double>(0.0, (s, e) => s + e.qty * e.price);
      return LayoutBuilder(
        builder: (context, constraints) {
          final table = Table(
            columnWidths: const {
              0: FixedColumnWidth(220),
              1: FixedColumnWidth(80),
              2: FixedColumnWidth(160),
              3: FixedColumnWidth(180),
            },
            border: TableBorder.all(color: Theme.of(context).colorScheme.outline),
            children: [
              _headerRow(['Item', 'Qty', 'Price', 'Subtotal']),
              ...items.map(
                (it) => TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text(it.name),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text('${it.qty}'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text(Formatters.idr(it.price)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text(Formatters.idr(it.price * it.qty)),
                    ),
                  ],
                ),
              ),
              TableRow(
                children: [
                  const SizedBox.shrink(),
                  const SizedBox.shrink(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text(
                      Formatters.idr(total),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          );
          return Scrollbar(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: table,
              ),
            ),
          );
        },
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Invoice (Gabungan)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...ids.map((id) {
              final inv = _invoices.firstWhere(
                (e) => int.tryParse(e.id) == id,
                orElse: () => _selectedInvoice ?? _invoices.first,
              );
              final items = _combinedSelectedItems[id] ?? const <InvoiceLine>[];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoice #${inv.id} - ${inv.customer}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text('Tanggal: ${_formatDate(inv.date)}'),
                    const SizedBox(height: 8),
                    buildItemsTable(items),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmIndividualPayment({required InvoiceItem inv, required double amount, required String payer}) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Konfirmasi Pembayaran Individu'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invoice: #${inv.id}'),
                  Text('Customer: ${inv.customer}'),
                  const SizedBox(height: 8),
                  Text('Nominal Bayar: ${Formatters.idr(amount)}'),
                  Text('Sisa Tagihan Setelah Bayar: ${Formatters.idr((inv.outstanding - amount).clamp(0.0, double.infinity))}'),
                  const SizedBox(height: 8),
                  Text('Pembayar: $payer'),
                  Text('Metode: ${_methodLabels[_paymentMethod] ?? _paymentMethod}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Bayar'),
                ),
              ],
            );
          },
        ) ?? false;
  }

  Widget _statusBadge(PaymentStatus status) {
    late final Color bg;
    late final Color fg;
    late final String label;
    switch (status) {
      case PaymentStatus.unpaid:
        bg = Theme.of(context).colorScheme.tertiaryContainer;
        fg = Theme.of(context).colorScheme.onTertiaryContainer;
        label = 'Unpaid';
        break;
      case PaymentStatus.paid:
        bg = Theme.of(context).colorScheme.secondaryContainer;
        fg = Theme.of(context).colorScheme.onSecondaryContainer;
        label = 'Paid';
        break;
      case PaymentStatus.partial:
        bg = Theme.of(context).colorScheme.primaryContainer;
        fg = Theme.of(context).colorScheme.onPrimaryContainer;
        label = 'Partial';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }

  

  String _formatDate(DateTime dt) {
    // 31/05/2025, 07:50 AM
    final d = _two(dt.day);
    final m = _two(dt.month);
    final y = dt.year;
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = _two(dt.minute);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$d/$m/$y, ${_two(h)}:$minute $ampm';
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}

enum PaymentStatus { unpaid, paid, partial }
enum PaymentMode { combined, individual }

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
