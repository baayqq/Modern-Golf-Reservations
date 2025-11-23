// SlotsPanel
// Panel ringkas yang menampilkan daftar slot tee time untuk tanggal terpilih.
// Menggunakan SlotRow untuk layout lebar, dan mendukung tap untuk melihat detail.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modern_golf_reservations/models/tee_time_model.dart';
import 'package:modern_golf_reservations/services/tee_time_repository.dart';
import 'slot_row.dart';

class SlotsPanel extends StatelessWidget {
  final DateTime date;
  final List<TeeTimeModel> slots;
  final bool loading;
  final ValueChanged<TeeTimeModel> onTapSlot;
  const SlotsPanel({
    super.key,
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
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (scrollable)
                SizedBox(
                  height: 260,
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: slotTimes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (ctx, i) {
                      final t = slotTimes[i];
                      final reserved = isReserved(t, teeBox);
                      final cs = Theme.of(context).colorScheme;
                      final bg = reserved ? cs.errorContainer : cs.secondaryContainer;
                      final fg = reserved ? cs.onErrorContainer : cs.onSecondaryContainer;
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
                      SlotRow(
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
                    child: buildBox('Tee Box 10 (Holes 10–18)', 10, scrollable: false),
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