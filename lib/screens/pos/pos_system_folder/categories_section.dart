// Purpose: Reusable categories section for POS System.
// Displays categories as responsive selectable chips.

import 'package:flutter/material.dart';
import '../../../models/pos_models.dart';

class CategoriesSection extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelectCategory;

  const CategoriesSection({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final chipPadding = isWide ? const EdgeInsets.symmetric(horizontal: 10) : const EdgeInsets.symmetric(horizontal: 6);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final c in categories)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: ChoiceChip(
                    label: Text(c.name),
                    selected: selectedCategoryId == c.id,
                    onSelected: (_) => onSelectCategory(selectedCategoryId == c.id ? null : c.id),
                    padding: chipPadding,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}