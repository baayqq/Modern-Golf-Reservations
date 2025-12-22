import 'package:flutter/material.dart';

class ProductsHeader extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String>? onSearchChanged;
  final String sortBy;
  final ValueChanged<String>? onSortChanged;

  const ProductsHeader({
    super.key,
    required this.searchController,
    this.onSearchChanged,
    required this.sortBy,
    this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 560;
        final children = <Widget>[
          Expanded(
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Cari produk...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 42,
            width: 180,
            child: DropdownButtonFormField<String>(
              value: sortBy,
              items: const [
                DropdownMenuItem(value: 'name_asc', child: Text('Nama A-Z')),
                DropdownMenuItem(value: 'name_desc', child: Text('Nama Z-A')),
                DropdownMenuItem(value: 'price_low', child: Text('Harga Terendah')),
                DropdownMenuItem(value: 'price_high', child: Text('Harga Tertinggi')),
              ],
              onChanged: (v) => onSortChanged?.call(v ?? sortBy),
              decoration: const InputDecoration(hintText: 'Urutkan'),
            ),
          ),
        ];

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: isNarrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      children[0],
                      const SizedBox(height: 12),
                      children[2],
                    ],
                  )
                : Row(children: children),
          ),
        );
      },
    );
  }
}