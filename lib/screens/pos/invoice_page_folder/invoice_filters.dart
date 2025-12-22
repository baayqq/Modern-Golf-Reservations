import 'package:flutter/material.dart';

class InvoiceFilters extends StatelessWidget {
  final DateTime? filterDate;
  final TextEditingController nameController;
  final VoidCallback onSearch;
  final VoidCallback onClear;
  final VoidCallback onPickDate;

  const InvoiceFilters({
    super.key,
    required this.filterDate,
    required this.nameController,
    required this.onSearch,
    required this.onClear,
    required this.onPickDate,
  });

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filter Tanggal'),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 42,
                    child: InkWell(
                      onTap: onPickDate,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          filterDate == null
                              ? 'dd/mm/yyyy'
                              : '${_two(filterDate!.day)}/${_two(filterDate!.month)}/${filterDate!.year}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nama Pemain'),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 42,
                    child: TextField(
                      controller: nameController,
                      decoration: const InputDecoration(hintText: 'Cari...'),
                      onSubmitted: (_) => onSearch(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 42,
              child: ElevatedButton(
                onPressed: onSearch,
                child: const Text('Cari'),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 42,
              child: ElevatedButton(
                onPressed: onClear,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
                child: const Text('Clear'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}