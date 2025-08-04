import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modern_golf_reservations/app_scaffold.dart';

class ManageReservationPage extends StatelessWidget {
  const ManageReservationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final date = DateTime(2025, 6, 13);
    final teeGroups = [
      _TeeGroup(
        timeLabel: '07:10 AM',
        rows: const [
          _RowData('Buulolo', '8463', 'Pending'),
          _RowData('Arif Djoko', '8464', 'Pending'),
          _RowData('Danang', '8465', 'Pending'),
          _RowData('Suyasa', '8466', 'Pending'),
        ],
      ),
      _TeeGroup(
        timeLabel: '07:20 AM',
        rows: const [
          _RowData('Mujib', '8467', 'Pending'),
          _RowData('Miko', '8468', 'Pending'),
          _RowData('Pandu', '8469', 'Pending'),
        ],
      ),
    ];

    return AppScaffold(
      title: 'Manage Reservation',
      body: ListView(
        children: [
          // Banner title
          Container(
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF0D6EFD),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Text(
              'Pending Reservations',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Date header
          Text(
            'Date: ${DateFormat('MMMM dd, yyyy').format(date)}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text('Tee Time: 07:10 AM'),
          const SizedBox(height: 16),

          // Groups
          for (final g in teeGroups) ...[
            _GroupTable(group: g),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

class _GroupTable extends StatelessWidget {
  final _TeeGroup group;
  const _GroupTable({required this.group});

  @override
  Widget build(BuildContext context) {
    final headers = const [
      'Player Name',
      'Reservation ID',
      'Status',
      'Actions',
    ];
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Group title above the table
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tee Time: ${group.timeLabel}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
          // Table header
          Container(
            color: const Color(0xFFF1F3F5),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              children: headers
                  .map(
                    (h) => Expanded(
                      child: Text(
                        h,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const Divider(height: 0),
          // Table rows
          ...group.rows.map(
            (r) => Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFDEE2E6))),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(r.player)),
                  Expanded(child: Text(r.reservationId)),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _Badge(
                        label: r.status,
                        color: const Color(0xFFFFC107),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: const [
                        _ActionBtn(label: 'Confirm', color: Color(0xFF198754)),
                        _ActionBtn(label: 'Cancel', color: Color(0xFFDC3545)),
                      ],
                    ),
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

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(.6)),
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

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  const _ActionBtn({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: FilledButton.tonal(
        onPressed: () {},
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
        child: Text(label),
      ),
    );
  }
}

class _TeeGroup {
  final String timeLabel;
  final List<_RowData> rows;
  _TeeGroup({required this.timeLabel, required this.rows});
}

class _RowData {
  final String player;
  final String reservationId;
  final String status;
  const _RowData(this.player, this.reservationId, this.status);
}
