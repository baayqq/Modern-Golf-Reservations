import 'package:flutter/material.dart';

class PrintActionBar extends StatelessWidget {
  final bool canPrintSingle;
  final VoidCallback? onPrint;
  final VoidCallback? onDownload;

  const PrintActionBar({
    super.key,
    required this.canPrintSingle,
    this.onPrint,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    if (!canPrintSingle) {
      return Row(
        children: [
          SizedBox(
            height: 42,
            child: ElevatedButton(
              onPressed: null,
              child: const Text('Print Invoice Terpilih'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 42,
            child: OutlinedButton(
              onPressed: null,
              child: const Text('Download PDF'),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Pilih tepat satu invoice untuk mencetak PDF',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        SizedBox(
          height: 42,
          child: ElevatedButton(
            onPressed: onPrint,
            child: const Text('Print Invoice Terpilih'),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 42,
          child: OutlinedButton(
            onPressed: onDownload,
            child: const Text('Download PDF'),
          ),
        ),
      ],
    );
  }
}