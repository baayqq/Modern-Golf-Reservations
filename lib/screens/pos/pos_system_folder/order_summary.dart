// Purpose: Reusable order summary (cart) section for POS System.
// Shows list of items, quantities, subtotals, and checkout button.

import 'package:flutter/material.dart';
import '../../../models/pos_models.dart';
import '../../../utils/currency.dart';

class OrderSummary extends StatelessWidget {
  final List<OrderItem> items;
  final void Function(OrderItem item) onIncrement;
  final void Function(OrderItem item) onDecrement;
  final void Function(OrderItem item) onRemove;
  final VoidCallback onCheckout;

  const OrderSummary({
    super.key,
    required this.items,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final total = OrderSummaryHelper.total(items);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan Pesanan',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Keranjang kosong'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final it = items[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                it.product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${Formatters.idr(it.product.price)} x ${it.quantity}',
                              ),
                            ],
                          ),
                        ),
                        Text(Formatters.idr(it.subtotal)),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => onDecrement(it),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('${it.quantity}'),
                            IconButton(
                              onPressed: () => onIncrement(it),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            IconButton(
                              onPressed: () => onRemove(it),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  Formatters.idr(total),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCheckout,
                icon: const Icon(Icons.receipt_long, size: 18),
                label: const Text('Checkout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
