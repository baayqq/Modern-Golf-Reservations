import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modern_golf_reservations/app_scaffold.dart';
import 'package:modern_golf_reservations/models/tee_time_model.dart';
import 'package:modern_golf_reservations/services/tee_time_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:modern_golf_reservations/router.dart' show AppRoute;
import 'package:modern_golf_reservations/screens/tee_time/manage_reservation_folder/reservation_table.dart';
import 'package:modern_golf_reservations/screens/tee_time/manage_reservation_folder/pagination_bar.dart';

class ManageReservationPage extends StatefulWidget {
  const ManageReservationPage({super.key});

  @override
  State<ManageReservationPage> createState() => _ManageReservationPageState();
}

class _ManageReservationPageState extends State<ManageReservationPage> {
  final _repo = TeeTimeRepository();
  List<TeeTimeModel> _items = [];
  bool _loading = true;
  DateTime? _filterDate;
  final TextEditingController _playerQueryCtrl = TextEditingController();

  int _pageSize = 20;
  int _currentPage = 0;

  List<TeeTimeModel> get _pagedItems {
    final start = _currentPage * _pageSize;
    if (start >= _items.length) return const [];
    final end = (start + _pageSize).clamp(0, _items.length);
    return _items.sublist(start, end);
  }

  int get _totalPages => (_items.length + _pageSize - 1) ~/ _pageSize;

  void _goToPage(int p) {
    setState(() {
      _currentPage = p.clamp(0, _totalPages == 0 ? 0 : _totalPages - 1);
    });
  }

  void _setPageSize(int size) {
    setState(() {
      _pageSize = size;
      _currentPage = 0;
    });
  }

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
    setState(() => _loading = true);
    final q = _playerQueryCtrl.text.trim().isEmpty ? null : _playerQueryCtrl.text.trim();
    final list = await _repo.search(date: _filterDate, playerQuery: q);
    setState(() {
      _items = list;
      _loading = false;
      _currentPage = 0;
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

  void _createInvoice(TeeTimeModel m) {
    final customer = (m.playerName == null || m.playerName!.isEmpty)
        ? 'Walk-in'
        : m.playerName!.trim();
    final qty = (m.playerCount ?? 1).toString();
    final qp = {
      'from': 'teeManage',
      'customer': customer,
      'qty': qty,
    };
    GoRouter.of(context).goNamed(AppRoute.pos.name, queryParameters: qp);
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

          Row(
            children: [

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
                : Column(
                    children: [
                      Expanded(
                        child: ReservationTable(
                          items: _pagedItems,
                          onEdit: _edit,
                          onDelete: _delete,
                          onCreateInvoice: _createInvoice,
                        ),
                      ),
                      const SizedBox(height: 8),
                      PaginationBar(
                        total: _items.length,
                        pageSize: _pageSize,
                        currentPage: _currentPage,
                        onPageSizeChanged: _setPageSize,
                        onPrev: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
                        onNext: (_currentPage + 1) < _totalPages ? () => _goToPage(_currentPage + 1) : null,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}