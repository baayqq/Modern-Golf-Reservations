import 'package:flutter/material.dart';
import 'day_header.dart';

class MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelect;

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
    final startWeekday = firstOfMonth.weekday % 7;

    const totalCells = 42;
    final startDate = firstOfMonth.subtract(Duration(days: startWeekday));
    final dates = List.generate(
      totalCells,
      (i) => startDate.add(Duration(days: i)),
    );

    return Column(
      children: [

        Padding(
          padding: EdgeInsets.symmetric(
            vertical: compact ? 0 : 2,
          ),
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

        LayoutBuilder(
          builder: (context, c) {
            final spacing = compact ? 0.0 : 3.0;
            final boxWidth = c.maxWidth;
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
                        bg = cs.primaryContainer;
                      } else if (isToday) {
                        bg = cs.surfaceContainerLowest;
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