import 'package:flutter/material.dart';

class SlotRow extends StatelessWidget {
  final String time;
  final bool reserved;
  final void Function(String time, bool reserved) onTap;
  const SlotRow({
    super.key,
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