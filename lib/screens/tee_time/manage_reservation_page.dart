import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modern_golf_reservations/app_scaffold.dart';
import 'package:modern_golf_reservations/models/tee_time_model.dart';
import 'package:modern_golf_reservations/services/tee_time_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:modern_golf_reservations/services/invoice_repository.dart';
import 'package:modern_golf_reservations/router.dart' show AppRoute;
import 'package:modern_golf_reservations/config/fees.dart';

class ManageReservationPage extends StatefulWidget {
  const ManageReservationPage({super.key});

  @override
  State<ManageReservationPage> createState() => _ManageReservationPageState();
}

class _ManageReservationPageState extends State<ManageReservationPage> {
  final _repo = TeeTimeRepository();
  final InvoiceRepository _invoiceRepo = InvoiceRepository();
  List<TeeTimeModel> _items = [];
  bool _loading = true;
  DateTime? _filterDate;
  final TextEditingController _playerQueryCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _repo.init();
    await _invoiceRepo.init();
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final q = _playerQueryCtrl.text.trim().isEmpty ? null : _playerQueryCtrl.text.trim();
    final list = await _repo.search(date: _filterDate, playerQuery: q);
    setState(() {
      _items = list;
      _loading = false;
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
    if (res != null) {
      setState(() => _filterDate = res);
      await _load();
    }
  }

  void _clearFilters() async {
    setState(() {
      _filterDate = null;
      _playerQueryCtrl.clear();
    });
    await _load();
  }

  void _edit(TeeTimeModel m) async {
    final res = await context.push('/tee-time/create', extra: m);
    if (res == true) {
      await _load();
    }
  }

  Future<void> _createInvoice(TeeTimeModel m) async {
    final customer = (m.playerName == null || m.playerName!.isEmpty)
        ? 'Walk-in'
        : m.playerName!.trim();
    final qty = m.playerCount ?? 1;
    const double price = Fees.greenFeeDefault; // default GREEN FEE
    final items = [InvoiceItemInput(name: 'GREEN FEE', qty: qty, price: price)];
    await _invoiceRepo.createInvoice(customer: customer, items: items);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invoice dibuat untuk $customer')),
    );
    GoRouter.of(context).goNamed(AppRoute.invoice.name);
  }

  void _delete(TeeTimeModel m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reservation'),
        content: Text('Delete reservation for ${m.playerName ?? '-'} on ${DateFormat('yyyy-MM-dd').format(m.date)} at ${m.time}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _repo.deleteById(m.id!);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Manage Reservation',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner title
          Container(
            height: 54,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Manage Reservations',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Filters row
          Row(
            children: [
              // Date filter
              SizedBox(
                height: 40,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _filterDate == null
                        ? 'Filter Date'
                        : DateFormat('yyyy-MM-dd').format(_filterDate!),
                  ),
                  onPressed: _pickFilterDate,
                ),
              ),
              const SizedBox(width: 8),
              // Player filter
              Expanded(
                child: TextField(
                  controller: _playerQueryCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Filter by player name...',
                    prefixIcon: Icon(Icons.search, size: 18),
                  ),
                  onChanged: (_) => _load(),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _ReservationTable(
                    items: _items,
                    onEdit: _edit,
                    onDelete: _delete,
                    onCreateInvoice: _createInvoice,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReservationTable extends StatelessWidget {
  final List<TeeTimeModel> items;
  final ValueChanged<TeeTimeModel> onEdit;
  final ValueChanged<TeeTimeModel> onDelete;
  final ValueChanged<TeeTimeModel> onCreateInvoice;
  const _ReservationTable({
    required this.items,
    required this.onEdit,
    required this.onDelete,
    required this.onCreateInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final headers = const [
      'ID',
      'Player Name',
      'Date',
      'Time',
      'Status',
      'Actions',
    ];
    // Lebar kolom tetap agar tidak menggunakan Expanded di dalam area scroll horizontal
    const colId = 120.0;
    const colPlayer = 220.0;
    const colDate = 140.0;
    const colTime = 100.0;
    const colStatus = 140.0;
    const colActions = 280.0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final table = Table(
            columnWidths: const {
              0: FixedColumnWidth(colId),
              1: FixedColumnWidth(colPlayer),
              2: FixedColumnWidth(colDate),
              3: FixedColumnWidth(colTime),
              4: FixedColumnWidth(colStatus),
              5: FixedColumnWidth(colActions),
            },
            border: TableBorder.symmetric(
              inside: BorderSide(color: Theme.of(context).colorScheme.outline),
              outside: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            children: [
              // header
              TableRow(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                children: headers
                    .map((h) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Text(h, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ))
                    .toList(),
              ),
              // rows
              ...items.map((r) => TableRow(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text('${r.id ?? '-'}'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text(r.playerName ?? '-'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text(DateFormat('yyyy-MM-dd').format(r.date)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text(r.time),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _Badge(
                          label: r.status,
                          color: r.status == 'booked'
                              ? Theme.of(context).colorScheme.tertiary
                              : Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          SizedBox(
                            height: 28,
                            child: FilledButton.tonal(
                              onPressed: () => onEdit(r),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              ),
                              child: const Text('Edit'),
                            ),
                          ),
                          SizedBox(
                            height: 28,
                            child: FilledButton.tonal(
                              onPressed: () => onCreateInvoice(r),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                backgroundColor: Theme.of(context).colorScheme.secondary,
                                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                              ),
                              child: const Text('Create Invoice'),
                            ),
                          ),
                          SizedBox(
                            height: 28,
                            child: FilledButton.tonal(
                              onPressed: () => onDelete(r),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                backgroundColor: Theme.of(context).colorScheme.error,
                                foregroundColor: Theme.of(context).colorScheme.onError,
                              ),
                              child: const Text('Delete'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ])),
            ],
          );

          return Scrollbar(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: table,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: .6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: const Color(0xFF212529),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

// Keep the badge widget reused for statuses
