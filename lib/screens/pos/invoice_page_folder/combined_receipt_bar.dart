import 'package:flutter/material.dart';

class CombinedReceiptBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onPrintCombined;
  final VoidCallback onDownloadCombined;

  const CombinedReceiptBar({
    super.key,
    required this.selectedCount,
    required this.onPrintCombined,
    required this.onDownloadCombined,
  });

  @override
  Widget build(BuildContext context) {
    final canPrint = selectedCount >= 2;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 640;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detail Pembayaran Gabungan',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  canPrint
                      ? 'Siap mencetak/unduh rincian pembayaran gabungan untuk $selectedCount invoice'
                      : 'Pilih minimal 2 invoice untuk mencetak/unduh rincian gabungan',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment:
                      isNarrow ? WrapAlignment.start : WrapAlignment.end,
                  children: [
                    SizedBox(
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: canPrint ? onPrintCombined : null,
                        icon: const Icon(Icons.print),
                        label: const Text('Print Detail'),
                      ),
                    ),
                    SizedBox(
                      height: 42,
                      child: OutlinedButton.icon(
                        onPressed: canPrint ? onDownloadCombined : null,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Download Detail'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}