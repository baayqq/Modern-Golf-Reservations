import 'dart:convert';
import 'package:modern_golf_reservations/services/invoice_repository.dart';
import 'package:modern_golf_reservations/services/tee_time_repository.dart';

class DatabaseExportService {
  final InvoiceRepository _invoiceRepo;
  final TeeTimeRepository _teeTimeRepo;

  DatabaseExportService({
    required InvoiceRepository invoiceRepo,
    required TeeTimeRepository teeTimeRepo,
  }) : _invoiceRepo = invoiceRepo,
       _teeTimeRepo = teeTimeRepo;

  Future<String> exportAllData() async {
    final posData = await _exportPosData();
    final teeTimeData = await _exportTeeTimeData();

    final exportMap = {
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
      'databases': {'pos': posData, 'teeTimes': teeTimeData},
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(exportMap);
  }

  Future<String> exportPosDataOnly() async {
    final posData = await _exportPosData();

    final exportMap = {
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
      'databases': {'pos': posData},
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(exportMap);
  }

  Future<String> exportTeeTimeDataOnly() async {
    final teeTimeData = await _exportTeeTimeData();

    final exportMap = {
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
      'databases': {'teeTimes': teeTimeData},
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(exportMap);
  }

  Future<Map<String, dynamic>> _exportPosData() async {

    final invoiceRows = await _invoiceRepo.getInvoices();
    final invoices = <Map<String, dynamic>>[];

    for (final invRow in invoiceRows) {
      final invoiceId = invRow['id'] as int;

      final itemRows = await _invoiceRepo.getItemsForInvoice(invoiceId);
      final items = itemRows
          .map(
            (itemRow) => {
              'id': itemRow['id'],
              'name': itemRow['name'],
              'qty': itemRow['qty'],
              'price': itemRow['price'],
            },
          )
          .toList();

      final paidAmount = await _invoiceRepo.getPaidAmountForInvoice(invoiceId);

      invoices.add({
        'id': invRow['id'],
        'customer': invRow['customer'],
        'total': invRow['total'],
        'status': invRow['status'],
        'date': invRow['date'],
        'paidAmount': paidAmount,
        'items': items,
      });
    }

    final paymentRows = await _invoiceRepo.getPayments();
    final payments = <Map<String, dynamic>>[];

    for (final payRow in paymentRows) {
      final paymentId = payRow['id'] as int;

      final allocRows = await _invoiceRepo.getAllocationsForPayment(paymentId);
      final allocations = allocRows
          .map(
            (allocRow) => {
              'invoiceId': allocRow['invoiceId'],
              'amount': allocRow['amount'],
              'customer': allocRow['customer'],
            },
          )
          .toList();

      payments.add({
        'id': payRow['id'],
        'payer': payRow['payer'],
        'amount': payRow['amount'],
        'method': payRow['method'],
        'date': payRow['date'],
        'allocations': allocations,
      });
    }

    return {'invoices': invoices, 'payments': payments};
  }

  Future<Map<String, dynamic>> _exportTeeTimeData() async {

    final slots = await _teeTimeRepo.getAllReservations();

    final reservations = slots
        .map(
          (slot) => {
            'id': slot.id,
            'date': slot.date.toIso8601String().split('T').first,
            'time': slot.time,
            'teeBox': slot.teeBox,
            'playerName': slot.playerName,
            'player2Name': slot.player2Name,
            'player3Name': slot.player3Name,
            'player4Name': slot.player4Name,
            'playerCount': slot.playerCount,
            'notes': slot.notes,
            'status': slot.status,
          },
        )
        .toList();

    return {'reservations': reservations};
  }

  Future<Map<String, dynamic>> getExportSummary() async {
    final invoiceRows = await _invoiceRepo.getInvoices();
    final paymentRows = await _invoiceRepo.getPayments();
    final teeTimeSlots = await _teeTimeRepo.getAllReservations();

    return {
      'totalInvoices': invoiceRows.length,
      'totalPayments': paymentRows.length,
      'totalTeeTimeSlots': teeTimeSlots.length,
      'bookedSlots': teeTimeSlots.where((s) => s.status == 'booked').length,
    };
  }
}