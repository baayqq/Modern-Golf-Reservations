import 'package:flutter/material.dart';

class BookingSearchSheet extends StatefulWidget {
  final void Function(String bookingId) onSelect;

  const BookingSearchSheet({super.key, required this.onSelect});

  @override
  State<BookingSearchSheet> createState() => _BookingSearchSheetState();
}

class _BookingSearchSheetState extends State<BookingSearchSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  final List<String> _results = [];
  bool _loading = false;

  Future<void> _search() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 400));

    final q = _searchCtrl.text.trim();
    _results
      ..clear()
      ..addAll(q.isEmpty
          ? []
          : List.generate(5, (i) => 'BK-${DateTime.now().millisecondsSinceEpoch % 10000}-${i + 1}'));
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Cari Booking', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Masukkan nama / kode booking',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _search,
                      child: const Text('Cari'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_results.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Tidak ada hasil')), 
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final id = _results[i];
                    return ListTile(
                      title: Text('Booking $id'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => widget.onSelect(id),
                    );
                  },
                ),
              if (!isWide) const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

Future<void> showBookingSearchSheet({
  required BuildContext context,
  required void Function(String bookingId) onSelect,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BookingSearchSheet(onSelect: onSelect),
  );
}