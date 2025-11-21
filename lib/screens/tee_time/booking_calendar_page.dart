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
        // Default: TIDAK memilih tanggal apa pun.
        // Tampilkan hanya kalender sampai user memilih tanggal.
        final now = DateTime.now();
        setState(() {
          _visibleMonth = DateTime(now.year, now.month);
          _selectedDate = null;
        });
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
    final monthTitle = DateFormat('MMMM yyyy').format(_visibleMonth);
    const double contentMaxWidth =
        1120.0; // lebar konten standar agar konsisten dengan bagian lain (dibuat lebih lebar)

    // Pastikan AppScaffold SELALU digunakan agar background konsisten
    // untuk menghindari flicker layar putih saat transisi atau loading.
    Widget pageBody;
    if (_loading) {
      pageBody = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      pageBody = Center(child: Text('Error: $_error'));
    } else {
      pageBody = SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        child: Column(
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
            const SizedBox(height: 8),
            // Month title centered with consistent content width
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: contentMaxWidth),
                child: Text(
                  monthTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Calendar grid
            // Remove fixed height wrapper so the month can render all 6 weeks
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: contentMaxWidth),
                child: _MonthGrid(
                  month: _visibleMonth,
                  selected: _selectedDate,
                  compact:
                      _selectedDate !=
                      null, // jika user sudah memilih tanggal, tampilkan versi compact
                  onSelect: (d) {
                    // Toggle selection: klik tanggal yang sama dua kali untuk batal memilih
                    if (_selectedDate != null &&
                        _isSameDay(d, _selectedDate!)) {
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
              ),
            ),
            const SizedBox(height: 6),
            // Inline slots panel (summary) for the selected day
            if (_selectedDate != null)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: contentMaxWidth),
                  child: _SlotsPanel(
                    date: _selectedDate!,
                    slots: _slots,
                    loading: _loadingSlots,
                    onTapSlot: _onSlotTap,
                  ), // tanpa fixed height: panel menyesuaikan konten agar seluruh jadwal tampak
                ),
              ),
          ],
        ),
      );
    }

    return AppScaffold(title: 'Tee Time Reservation', body: pageBody);
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.error,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    const Text('Status: Reserved'),
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
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 16,
                    ),
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
  // compact = true bila user sudah memilih tanggal (kalender dibuat lebih pendek)
  final bool compact;
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.compact,
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
          padding: EdgeInsets.symmetric(
            vertical: compact ? 0 : 2,
          ), // header adaptif (rapat saat compact)
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
        // Buat grid mengikuti lebar container dan pangkas tinggi total
        LayoutBuilder(
          builder: (context, c) {
            final spacing = compact ? 0.0 : 3.0; // jarak antar sel adaptif
            final boxWidth =
                c.maxWidth; // isi penuh lebar kontainer agar sejajar garis biru
            return Center(
              child: SizedBox(
                width: boxWidth,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      childAspectRatio: compact
                          ? 3.0
                          : 1.35, // tinggi sel adaptif (lebih pendek saat compact)
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
                        bg = cs
                            .surfaceContainerLowest; // subtle background for today
                      }

                      return InkWell(
                        onTap: isThisMonth ? () => onSelect(date) : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color: bg,
                            border: Border(
                              right: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
                              bottom: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                          padding: EdgeInsets.all(
                            compact ? 0 : 3,
                          ), // padding adaptif
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: compact
                                    ? 9
                                    : 12, // ukuran angka adaptif
                                color: isThisMonth
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context).colorScheme.onSurface
                                          .withValues(alpha: .35),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
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

    // Gunakan jam standar dari repository agar konsisten dengan Create Tee Time
    final slotTimes = TeeTimeRepository.standardSlotTimes();

    bool isReserved(String time, int teeBox) =>
        slots.any((s) => s.time == time && s.teeBox == teeBox && s.status == 'booked');

    Widget buildBox(String title, int teeBox, {required bool scrollable}) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(
            12,
          ), // padding sedikit diperbesar agar konten lebih lega
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (scrollable)
                SizedBox(
                  height:
                      260, // tinggi scroll untuk mobile/layar sempit (tetap scroll)
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: slotTimes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (ctx, i) {
                      final t = slotTimes[i];
                      final reserved = isReserved(t, teeBox);
                      final cs = Theme.of(context).colorScheme;
                      final bg = reserved
                          ? cs.errorContainer
                          : cs.secondaryContainer;
                      final fg = reserved
                          ? cs.onErrorContainer
                          : cs.onSecondaryContainer;
                      return InkWell(
                        onTap: () => onTapSlot(
                          TeeTimeModel(
                            date: date,
                            time: t,
                            teeBox: teeBox,
                            status: reserved ? 'booked' : 'available',
                          ),
                        ),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: fg.withValues(alpha: .25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                reserved
                                    ? Icons.event_busy
                                    : Icons.event_available,
                                size: 18,
                                color: fg,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$t  ${reserved ? '• Reserved' : '• Available'}',
                                  style: TextStyle(color: fg, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Column(
                  children: [
                    for (var i = 0; i < slotTimes.length; i++) ...[
                      _SlotRow(
                        time: slotTimes[i],
                        reserved: isReserved(slotTimes[i], teeBox),
                        onTap: (t, reserved) => onTapSlot(
                          TeeTimeModel(
                            date: date,
                            time: t,
                            teeBox: teeBox,
                            status: reserved ? 'booked' : 'available',
                          ),
                        ),
                      ),
                      if (i != slotTimes.length - 1) const SizedBox(height: 6),
                    ],
                  ],
                ),
            ],
          ),
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
        LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth >= 800;
            if (isWide) {
              return Row(
                children: [
                  Expanded(
                    child: buildBox('Tee Box 1 (Holes 1–9)', 1, scrollable: false),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: buildBox(
                      'Tee Box 10 (Holes 10–18)',
                      10,
                      scrollable: false,
                    ),
                  ),
                ],
              );
            }
            // Mobile / sempit: susun vertikal
            return Column(
              children: [
                buildBox('Tee Box 1 (Holes 1–9)', 1, scrollable: false),
                const SizedBox(height: 8),
                buildBox('Tee Box 10 (Holes 10–18)', 10, scrollable: false),
              ],
            );
          },
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

// Widget baris slot tee time tunggal (digunakan pada layout lebar tanpa scroll)
// Menampilkan waktu dan status (Reserved/Available) dengan warna yang konsisten,
// serta mendukung tap callback untuk interaksi.
class _SlotRow extends StatelessWidget {
  final String time;
  final bool reserved;
  final void Function(String time, bool reserved) onTap;
  const _SlotRow({
    required this.time,
    required this.reserved,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = reserved ? cs.errorContainer : cs.secondaryContainer;
    final fg = reserved ? cs.onErrorContainer : cs.onSecondaryContainer;

    return InkWell(
      onTap: () => onTap(time, reserved),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: fg.withValues(alpha: .25)),
        ),
        child: Row(
          children: [
            Icon(
              reserved ? Icons.event_busy : Icons.event_available,
              size: 18,
              color: fg,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$time  ${reserved ? '• Reserved' : '• Available'}',
                style: TextStyle(color: fg, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
