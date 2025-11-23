// TimeList Widget
// Tujuan: Menampilkan daftar pilihan jam dalam dialog pemilihan waktu.
// Dapat dilabeli Tee Box untuk membedakan pilihan box 1 dan 10.
import 'package:flutter/material.dart';

class TimeList extends StatelessWidget {
  final String boxLabel;
  final List<TimeOfDay> times;
  final ValueChanged<TimeOfDay> onPick;

  const TimeList({
    super.key,
    required this.boxLabel,
    required this.times,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: times.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final tod = times[i];
        return InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => onPick(tod),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}',
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Tee Box $boxLabel',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}