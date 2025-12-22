import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modern_golf_reservations/models/tee_time_model.dart';
import 'status_badge.dart';

class ReservationTable extends StatelessWidget {
  final List<TeeTimeModel> items;
  final ValueChanged<TeeTimeModel> onEdit;
  final ValueChanged<TeeTimeModel> onDelete;
  final ValueChanged<TeeTimeModel> onCreateInvoice;
  const ReservationTable({
    super.key,
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
                        child: StatusBadge(
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