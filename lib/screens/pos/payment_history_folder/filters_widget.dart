import 'package:flutter/material.dart';

class PaymentHistoryFilters extends StatelessWidget {
  final DateTime? filterDate;
  final TextEditingController payerController;
  final String? methodFilter;
  final VoidCallback onSearch;
  final VoidCallback onClear;
  final VoidCallback onPickDate;
  final ValueChanged<String?> onChangeMethod;

  const PaymentHistoryFilters({
    super.key,
    required this.filterDate,
    required this.payerController,
    required this.methodFilter,
    required this.onSearch,
    required this.onClear,
    required this.onPickDate,
    required this.onChangeMethod,
  });

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 900;
            final fields = [
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
                    const Text('Nama Pembayar'),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 42,
                      child: TextField(
                        controller: payerController,
                        decoration: const InputDecoration(hintText: 'Cari...'),
                        onSubmitted: (_) => onSearch(),
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
                    const Text('Metode'),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 42,
                      child: DropdownButtonFormField<String>(
                        value: methodFilter,
                        items: const [
                          DropdownMenuItem(value: 'cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'credit', child: Text('Kartu Kredit')),
                          DropdownMenuItem(value: 'debit', child: Text('Debit')),
                          DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                          DropdownMenuItem(value: 'card', child: Text('Card (Legacy)')),
                          DropdownMenuItem(value: 'transfer', child: Text('Transfer (Legacy)')),
                        ],
                        onChanged: onChangeMethod,
                        decoration: const InputDecoration(hintText: 'Pilih metode'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 42,
                child: ElevatedButton(onPressed: onSearch, child: const Text('Cari')),
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
            ];

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fields[0],
                  const SizedBox(height: 12),
                  fields[2],
                  const SizedBox(height: 12),
                  fields[4],
                  const SizedBox(height: 12),
                  Row(children: [fields[6], const SizedBox(width: 8), fields[8]]),
                ],
              );
            }
            return Row(children: fields);
          },
        ),
      ),
    );
  }
}