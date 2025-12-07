// Widget: InvoiceTable
// Menampilkan tabel daftar invoice dengan checkbox, input nominal bayar, dan kolom-kolom utama.
// Memisahkan UI dari logika agar mudah diuji dan dipelihara.
import 'package:flutter/material.dart';
import 'package:modern_golf_reservations/models/invoice_models.dart';
import 'package:modern_golf_reservations/utils/currency.dart';
import 'payment_status_badge.dart';

class InvoiceTable extends StatefulWidget {
  final List<InvoiceItem> invoices;
  final Set<int> selectedInvoiceIds;
  final PaymentMode paymentMode;
  final Map<int, TextEditingController> amountControllers;
  final void Function(InvoiceItem inv, bool? checked) onCheckboxChanged;
  final void Function(InvoiceItem inv) onTapDetails;
  final String Function(DateTime dt) formatDate;

  const InvoiceTable({
    super.key,
    required this.invoices,
    required this.selectedInvoiceIds,
    required this.paymentMode,
    required this.amountControllers,
    required this.onCheckboxChanged,
    required this.onTapDetails,
    required this.formatDate,
  });

  @override
  State<InvoiceTable> createState() => _InvoiceTableState();
}

class _InvoiceTableState extends State<InvoiceTable> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final table = Table(
            columnWidths: const {
              0: FixedColumnWidth(56), // select
              1: FlexColumnWidth(1), // invoice id
              2: FlexColumnWidth(2), // customer name
              3: FlexColumnWidth(1.4), // total
              4: FlexColumnWidth(1.6), // bayar (input)
              5: FlexColumnWidth(1), // status
              6: FlexColumnWidth(1.2), // date
            },
            border: TableBorder.all(
              color: Theme.of(context).colorScheme.outline,
            ),
            children: [
              _headerRow(context, [
                'Select',
                'Invoice ID',
                'Customer Name',
                'Total Amount',
                'Bayar (Rp)',
                'Payment Status',
                'Date',
              ]),
              ...widget.invoices.map((inv) => _dataRow(context, inv)),
            ],
          );

          return Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.vertical,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: table,
              ),
            ),
          );
        },
      ),
    );
  }

  TableRow _headerRow(BuildContext context, List<String> headers) {
    return TableRow(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      children: headers
          .map(
            (h) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                h,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          )
          .toList(),
    );
  }

  TableRow _dataRow(BuildContext context, InvoiceItem inv) {
    final idInt = int.parse(inv.id);
    final amountCtrl =
        widget.amountControllers[idInt] ?? TextEditingController();
    widget.amountControllers[idInt] = amountCtrl;
    return TableRow(
      children: [
        // Select checkbox
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Checkbox(
            value: widget.selectedInvoiceIds.contains(idInt),
            onChanged: (val) => widget.onCheckboxChanged(inv, val),
          ),
        ),
        // Invoice ID (clickable)
        InkWell(
          onTap: () => widget.onTapDetails(inv),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              inv.id,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        // Customer Name
        InkWell(
          onTap: () => widget.onTapDetails(inv),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              inv.customer,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // Total Amount
        InkWell(
          onTap: () => widget.onTapDetails(inv),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(Formatters.idr(inv.total)),
          ),
        ),
        // Bayar (Rp) - input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: SizedBox(
            height: 36,
            child: TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Sisa: ${Formatters.idr(inv.outstanding)}',
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onChanged: (v) {
                final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                if (digits != v) {
                  amountCtrl.value = TextEditingValue(
                    text: digits,
                    selection: TextSelection.collapsed(offset: digits.length),
                  );
                }
              },
              onTap: () => widget.onTapDetails(inv),
            ),
          ),
        ),
        // Payment Status (badge)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: PaymentStatusBadge(status: inv.status),
        ),
        // Date
        InkWell(
          onTap: () => widget.onTapDetails(inv),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(widget.formatDate(inv.date), softWrap: true),
          ),
        ),
      ],
    );
  }
}
