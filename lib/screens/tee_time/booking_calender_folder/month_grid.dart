// MonthGrid
// Kalender bulanan 6-minggu (42 sel) dengan pilihan tanggal.
// Fitur: highlight hari ini, highlight tanggal terpilih, dan header hari.
// Digunakan di BookingCalendarPage.
import 'package:flutter/material.dart';
import 'day_header.dart';

class MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelect;
  // compact = true bila user sudah memilih tanggal (kalender dibuat lebih pendek)
  final bool compact;
  const MonthGrid({
    super.key,
    required this.month,
    required this.selected,
    required this.compact,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final startWeekday = firstOfMonth.weekday % 7; // make Sunday = 0

    // build list of DateTimes displayed (previous month padding + current + next padding)
    const totalCells = 42; // 6 weeks x 7 days
    final startDate = firstOfMonth.subtract(Duration(days: startWeekday));
    final dates = List.generate(
      totalCells,
      (i) => startDate.add(Duration(days: i)),
    );

    return Column(
      children: [
        // Weekday headers
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: compact ? 0 : 2,
          ), // header adaptif (rapat saat compact)
          child: const Row(
            children: [
              DayHeader('Sun'),
              DayHeader('Mon'),
              DayHeader('Tue'),
              DayHeader('Wed'),
              DayHeader('Thu'),
              DayHeader('Fri'),
              DayHeader('Sat'),
            ],
          ),
        ),
        // Grid
        LayoutBuilder(
          builder: (context, c) {
            final spacing = compact ? 0.0 : 3.0; // jarak antar sel adaptif
            final boxWidth = c.maxWidth; // isi penuh lebar kontainer
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
                      childAspectRatio: compact ? 3.0 : 1.35,
                    ),
                    itemCount: totalCells,
                    itemBuilder: (context, index) {
                      final date = dates[index];
                      final isThisMonth = date.month == month.month;
                      final isToday = _isSameDay(date, DateTime.now());
                      final isSelected = selected != null && _isSameDay(date, selected!);

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
                              right: BorderSide(
                                color: Theme.of(context).colorScheme.outlineVariant,
                              ),
                              bottom: BorderSide(
                                color: Theme.of(context).colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                          padding: EdgeInsets.all(compact ? 0 : 3),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: compact ? 9 : 12,
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