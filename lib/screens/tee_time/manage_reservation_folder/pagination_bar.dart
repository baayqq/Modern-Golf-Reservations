// PaginationBar
// Komponen bar kontrol pagination: info jumlah data, dropdown page size, tombol prev/next.
// Reusable untuk daftar/tabel dengan pagination sederhana.
import 'package:flutter/material.dart';

class PaginationBar extends StatelessWidget {
  final int total;
  final int pageSize;
  final int currentPage;
  final ValueChanged<int> onPageSizeChanged;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  const PaginationBar({
    super.key,
    required this.total,
    required this.pageSize,
    required this.currentPage,
    required this.onPageSizeChanged,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final start = total == 0 ? 0 : (currentPage * pageSize) + 1;
    final end = (start == 0) ? 0 : ((currentPage + 1) * pageSize).clamp(0, total);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Menampilkan $start-$end dari $total'),
          const SizedBox(width: 12),
          DropdownButton<int>(
            value: pageSize,
            items: const [10, 20, 50, 100]
                .map((v) => DropdownMenuItem(value: v, child: Text('$v / halaman')))
                .toList(),
            onChanged: (v) {
              if (v != null) onPageSizeChanged(v);
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Sebelumnya',
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Berikutnya',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}