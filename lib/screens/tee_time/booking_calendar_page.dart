import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modern_golf_reservations/app_scaffold.dart';

class BookingCalendarPage extends StatefulWidget {
  const BookingCalendarPage({super.key});

  @override
  State<BookingCalendarPage> createState() => _BookingCalendarPageState();
}

class _BookingCalendarPageState extends State<BookingCalendarPage> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDate;
  bool _selectMode = false;

  void _prevMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    });
  }

  void _toggleSelect(bool v) {
    setState(() {
      _selectMode = v;
      if (!v) _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthTitle = DateFormat('MMMM yyyy').format(_visibleMonth);
    return AppScaffold(
      title: 'Tee Time Reservation',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page title
          Text(
            'Tee Time Schedule Calendar',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          // Top actions row
          Row(
            children: [
              FilledButton.tonal(
                onPressed: _selectedDate == null ? null : () {},
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6EFD).withOpacity(.15),
                  foregroundColor: const Color(0xFF0D6EFD),
                ),
                child: const Text('Book Tee Time for Selected Date'),
              ),
              const Spacer(),
              if (_selectMode)
                FilledButton.tonal(
                  onPressed: () => _toggleSelect(false),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF8D7DA),
                    foregroundColor: const Color(0xFF842029),
                  ),
                  child: const Text('Cancel Selection'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Toolbar (prev/next, today, view switch)
          Row(
            children: [
              // prev/next
              SizedBox(
                height: 36,
                child: OutlinedButton(
                  onPressed: _prevMonth,
                  style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Icon(Icons.chevron_left),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: OutlinedButton(
                  onPressed: _nextMonth,
                  style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Icon(Icons.chevron_right),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonal(
                onPressed: () {
                  setState(() {
                    _visibleMonth = DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                    );
                  });
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6C757D),
                  foregroundColor: Colors.white,
                ),
                child: const Text('today'),
              ),
              const Spacer(),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'month', label: Text('month')),
                  ButtonSegment(value: 'week', label: Text('week')),
                ],
                selected: const {'month'},
                showSelectedIcon: false,
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                    const Color(0xFF212529),
                  ),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Month title centered
          Center(
            child: Text(
              monthTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 12),
          // Calendar grid
          Expanded(
            child: _MonthGrid(
              month: _visibleMonth,
              selected: _selectedDate,
              onSelect: (d) {
                if (!_selectMode) _toggleSelect(true);
                setState(() => _selectedDate = d);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelect;
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final startWeekday = firstOfMonth.weekday % 7; // make Sunday = 0
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    // build list of DateTimes displayed (previous month padding + current + next padding)
    final totalCells = 42; // 6 weeks x 7 days
    final startDate = firstOfMonth.subtract(Duration(days: startWeekday));
    final dates = List.generate(
      totalCells,
      (i) => startDate.add(Duration(days: i)),
    );

    final headerStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: const Color(0xFF0D6EFD),
    );

    return Column(
      children: [
        // Weekday headers
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDEE2E6)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: const [
              _DayHeader('Sun'),
              _DayHeader('Mon'),
              _DayHeader('Tue'),
              _DayHeader('Wed'),
              _DayHeader('Thu'),
              _DayHeader('Fri'),
              _DayHeader('Sat'),
            ],
          ),
        ),
        // Grid
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFDEE2E6)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
              ),
              itemCount: totalCells,
              itemBuilder: (context, index) {
                final date = dates[index];
                final isThisMonth = date.month == month.month;
                final isToday = _isSameDay(date, DateTime.now());
                final isSelected =
                    selected != null && _isSameDay(date, selected!);

                Color? bg;
                if (isSelected) {
                  bg = const Color(0xFFFFF3CD); // pale yellow like sample
                } else if (isToday) {
                  bg = const Color(0xFFE7F1FF);
                }

                return InkWell(
                  onTap: isThisMonth ? () => onSelect(date) : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: bg,
                      border: Border(
                        right: const BorderSide(color: Color(0xFFDEE2E6)),
                        bottom: const BorderSide(color: Color(0xFFDEE2E6)),
                      ),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: isThisMonth
                              ? const Color(0xFF0D6EFD)
                              : Colors.black.withOpacity(.35),
                          decoration: TextDecoration.underline,
                          decorationColor: const Color(0xFF0D6EFD),
                          decorationThickness: 1,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayHeader extends StatelessWidget {
  final String label;
  const _DayHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF0D6EFD),
            decoration: TextDecoration.underline,
            decorationColor: Color(0xFF0D6EFD),
            decorationThickness: 1,
          ),
        ),
      ),
    );
  }
}
