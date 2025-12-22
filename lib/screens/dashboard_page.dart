import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modern_golf_reservations/app_scaffold.dart';
import 'package:modern_golf_reservations/services/tee_time_repository.dart';
import 'package:modern_golf_reservations/models/tee_time_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TextEditingController _dateController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  final TeeTimeRepository _repo = TeeTimeRepository();

  bool _loading = true;
  String? _error;
  int _todayCount = 0;
  int _weekCount = 0;
  int _monthCount = 0;
  List<TeeTimeModel> _bookingsForSelectedDate = const [];

  String get _formattedSelectedDate =>
      DateFormat('MMMM dd, yyyy').format(_selectedDate);

  @override
  void initState() {
    super.initState();
    _dateController.text = _formattedSelectedDate;
    _initData();
  }

  Future<void> _initData() async {
    try {
      await _repo.init();
      await _refreshCounts();
      await _refreshBookingsForSelectedDate();
      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refreshCounts() async {
    final today = await _repo.countPlayersToday();
    final week = await _repo.countPlayersThisWeek();
    final month = await _repo.countPlayersThisMonth();
    setState(() {
      _todayCount = today;
      _weekCount = week;
      _monthCount = month;
    });
  }

  Future<void> _refreshBookingsForSelectedDate() async {
    final list = await _repo.getBookedForDate(_selectedDate);
    setState(() {
      _bookingsForSelectedDate = list;
    });
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year - 5);
    final DateTime lastDate = DateTime(now.year + 5);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDatePickerMode: DatePickerMode.day,
      selectableDayPredicate: (day) => true,
      builder: (context, child) {

        return Theme(
          data: Theme.of(context),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formattedSelectedDate;
      });

      await _refreshBookingsForSelectedDate();
    }
  }

  @override
  Widget build(BuildContext context) {

    return AppScaffold(
      title: 'Dashboard',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Tee Sheet for $_formattedSelectedDate',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(
                              text: DateFormat(
                                'dd/MM/yyyy',
                              ).format(_selectedDate),
                            ),
                            readOnly: true,
                            decoration: const InputDecoration(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 40,
                          width: 46,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: _pickDate,
                            child: const Icon(Icons.calendar_today, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _StatsRow(
                  todayCount: _todayCount,
                  weekCount: _weekCount,
                  monthCount: _monthCount,
                ),
                const SizedBox(height: 16),
                Expanded(child: _TeeTable(bookings: _bookingsForSelectedDate)),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '© 2025 Fitri Dwi Astuti',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }
}

class _StatsRow extends StatelessWidget {
  final int todayCount;
  final int weekCount;
  final int monthCount;
  const _StatsRow({
    required this.todayCount,
    required this.weekCount,
    required this.monthCount,
  });
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    final cs = Theme.of(context).colorScheme;
    final cards = [
      _StatCard(title: 'Players Today', color: cs.primary, count: todayCount),
      _StatCard(
        title: 'Players This Week',
        color: cs.secondary,
        count: weekCount,
      ),
      _StatCard(
        title: 'Players This Month',
        color: cs.tertiary,
        count: monthCount,
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards
            .map(
              (c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: c,
              ),
            )
            .toList(),
      );
    }

    return Row(
      children: cards
          .map(
            (c) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: c,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final Color color;
  final int count;
  const _StatCard({
    required this.title,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeeTable extends StatelessWidget {
  final List<TeeTimeModel> bookings;
  const _TeeTable({required this.bookings});
  @override
  Widget build(BuildContext context) {
    final headers = [
      'Tee Time',
      'Player 1',
      'Player 2',
      'Player 3',
      'Player 4',
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [

          Table(
            border: TableBorder(
              top: BorderSide(color: Colors.grey.shade300),
              left: BorderSide(color: Colors.grey.shade300),
              right: BorderSide(color: Colors.grey.shade300),
              bottom: BorderSide(color: Colors.grey.shade300),
              horizontalInside: BorderSide(color: Colors.grey.shade300),
              verticalInside: BorderSide(color: Colors.grey.shade300),
            ),
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                children: headers
                    .map(
                      (h) => Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                        child: Text(
                          h,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),

          if (bookings.isEmpty)
            SizedBox(
              height: 60,
              child: Center(
                child: Text(
                  'No reservations found for this day.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Table(
                  border: TableBorder(
                    top: BorderSide(color: Colors.grey.shade300),
                    left: BorderSide(color: Colors.grey.shade300),
                    right: BorderSide(color: Colors.grey.shade300),
                    bottom: BorderSide(color: Colors.grey.shade300),
                    horizontalInside: BorderSide(color: Colors.grey.shade300),
                    verticalInside: BorderSide(color: Colors.grey.shade300),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1),
                    4: FlexColumnWidth(1),
                  },
                  children: [
                    for (final b in bookings)
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            child: Text(
                              b.time,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            child: Text(b.playerName ?? '-'),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            child: Text(b.player2Name ?? '-'),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            child: Text(b.player3Name ?? '-'),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            child: Text(b.player4Name ?? '-'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}