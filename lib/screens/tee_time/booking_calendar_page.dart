import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modern_golf_reservations/app_scaffold.dart';
import 'package:modern_golf_reservations/services/tee_time_repository.dart';
import 'package:modern_golf_reservations/models/tee_time_model.dart';


class BookingCalendarPage extends StatefulWidget {
  const BookingCalendarPage({super.key, this.initialSelectedDate});
  final DateTime? initialSelectedDate;

  @override
  State<BookingCalendarPage> createState() => _BookingCalendarPageState();
}

class _BookingCalendarPageState extends State<BookingCalendarPage> {
  final TeeTimeRepository _repo = TeeTimeRepository();
  DateTime _visibleMonth = DateTime.now();
  DateTime? _selectedDate;
  List<TeeTimeModel> _slots = [];
  bool _loadingSlots = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  Future<void> _initDb() async {
    try {
      await _repo.init();
      // Jika ada initialSelectedDate, pilih otomatis
      final initial = widget.initialSelectedDate;
      if (initial != null) {
        setState(() {
          _visibleMonth = DateTime(initial.year, initial.month);
          _selectedDate = initial;
        });
        await _openSlots(initial);
      } else {
        // Default: pilih tanggal hari ini dan tampilkan slotnya
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        setState(() {
          _visibleMonth = DateTime(now.year, now.month);
          _selectedDate = today;
        });
        await _openSlots(today);
      }
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



  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    final monthTitle = DateFormat('MMMM yyyy').format(_visibleMonth);
    return AppScaffold(
      title: 'Tee Time Reservation',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Page title
          Text(
            'Tee Time Schedule Calendar',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w600),
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
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  setState(() {
                    _visibleMonth = DateTime(now.year, now.month);
                    _selectedDate = today;
                  });
                  _openSlots(today);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
                child: const Text('today'),
              ),
              const Spacer(),
              // SegmentedButton view switch removed for cleaner UI
              SizedBox.shrink(),
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
          // Remove fixed height wrapper so the month can render all 6 weeks
          _MonthGrid(
            month: _visibleMonth,
            selected: _selectedDate,
            onSelect: (d) {
              // Toggle selection: klik tanggal yang sama dua kali untuk batal memilih
              if (_selectedDate != null && _isSameDay(d, _selectedDate!)) {
                setState(() {
                  _selectedDate = null;
                  _slots = [];
                });
                return;
              }
              setState(() => _selectedDate = d);
              _openSlots(d);
            },
          ),
          const SizedBox(height: 12),
          // Inline slots panel (summary) for the selected day
          if (_selectedDate != null)
            SizedBox(
              height: 240,
              child: _SlotsPanel(
                date: _selectedDate!,
                slots: _slots,
                loading: _loadingSlots,
                onTapSlot: _onSlotTap,
              ),
            ),

        ],
        ),
      ),
    );
  }


  Future<void> _openSlots(DateTime d) async {
    setState(() {
      _loadingSlots = true;
    });
    final list = await _repo.getSlotsForDate(d);
    setState(() {
      _slots = list;
      _loadingSlots = false;
    });
  }

  void _onSlotTap(TeeTimeModel slot) async {
    if (slot.status == 'booked') {
      await showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Booking Detail'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: ${DateFormat('yyyy-MM-dd').format(slot.date)}'),
                Text('Time: ${slot.time}'),
                Text('Player: ${slot.playerName ?? '-'}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Theme.of(context).colorScheme.error, size: 16),
                    const SizedBox(width: 6),
                    const Text('Status: Booked'),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } else {
      // Jangan tampilkan form booking. Hanya tampilkan informasi slot tersedia.
      await showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Tee Time Slot'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: ${DateFormat('yyyy-MM-dd').format(slot.date)}'),
                Text('Time: ${slot.time}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Theme.of(context).colorScheme.secondary, size: 16),
                    const SizedBox(width: 6),
                    const Text('Status: Available'),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    }
  }
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
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
    // Removed unused: daysInMonth
    // final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    // build list of DateTimes displayed (previous month padding + current + next padding)
    final totalCells = 42; // 6 weeks x 7 days
    final startDate = firstOfMonth.subtract(Duration(days: startWeekday));
    final dates = List.generate(
      totalCells,
      (i) => startDate.add(Duration(days: i)),
    );

    // Simplified header style is handled inside _DayHeader; local headerStyle removed

    return Column(
      children: [
        // Weekday headers
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
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
        // Use shrinkWrap GridView so it calculates its full height inside a scroll view
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(6),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 2.4, // make cells shorter so grid becomes more compact
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              final date = dates[index];
              final isThisMonth = date.month == month.month;
              final isToday = _isSameDay(date, DateTime.now());
              final isSelected =
                  selected != null && _isSameDay(date, selected!);

              Color? bg;
              final cs = Theme.of(context).colorScheme;
              if (isSelected) {
                bg = cs.primaryContainer; // selection highlight
              } else if (isToday) {
                bg = cs.surfaceContainerLowest; // subtle background for today
              }

              return InkWell(
                onTap: isThisMonth ? () => onSelect(date) : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: bg,
                    border: Border(
                      right: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                      bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isThisMonth
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: .35),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _SlotsPanel extends StatelessWidget {
  final DateTime date;
  final List<TeeTimeModel> slots;
  final bool loading;
  final ValueChanged<TeeTimeModel> onTapSlot;
  const _SlotsPanel({
    required this.date,
    required this.slots,
    required this.loading,
    required this.onTapSlot,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (slots.isEmpty) {
      return Center(
        child: Text(
          'No slots for ${DateFormat('yyyy-MM-dd').format(date)}',
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tee Times for ${DateFormat('EEE, dd MMM yyyy').format(date)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3.8,
            ),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final s = slots[index];
              final isBooked = s.status == 'booked';
              final cs = Theme.of(context).colorScheme;
              final bg = isBooked ? cs.errorContainer : cs.secondaryContainer;
              final fg = isBooked ? cs.onErrorContainer : cs.onSecondaryContainer;
              return InkWell(
                onTap: () => onTapSlot(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: fg.withValues(alpha: .25)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isBooked ? Icons.event_busy : Icons.event_available,
                        size: 18,
                        color: fg,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${s.time}  ${isBooked ? '• ${s.playerName}' : '• Available'}',
                          style: TextStyle(color: fg),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
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
