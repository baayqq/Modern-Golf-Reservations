import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modern_golf_reservations/app_scaffold.dart';
import 'package:modern_golf_reservations/services/tee_time_repository.dart';
import 'package:modern_golf_reservations/models/tee_time_model.dart';
import 'package:modern_golf_reservations/screens/tee_time/booking_calender_folder/month_grid.dart';
import 'package:modern_golf_reservations/screens/tee_time/booking_calender_folder/slots_panel.dart';

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
                child: MonthGrid(
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
                  child: SlotsPanel(
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
