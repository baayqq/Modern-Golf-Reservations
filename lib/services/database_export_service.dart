import 'dart:convert';
import 'package:modern_golf_reservations/services/invoice_repository.dart';
import 'package:modern_golf_reservations/services/tee_time_repository.dart';

/// Service untuk mengekspor database ke format JSON.
///
/// Fitur:
/// - Export semua data (POS + Tee Time)
/// - Export per-modul (hanya POS atau hanya Tee Time)
/// - Format JSON yang terstruktur dan mudah dibaca
class DatabaseExportService {
  final InvoiceRepository _invoiceRepo;
  final TeeTimeRepository _teeTimeRepo;

  DatabaseExportService({
    required InvoiceRepository invoiceRepo,
    required TeeTimeRepository teeTimeRepo,
  }) : _invoiceRepo = invoiceRepo,
       _teeTimeRepo = teeTimeRepo;

  /// Export semua data dari kedua database (POS dan Tee Time)
  Future<String> exportAllData() async {
    final posData = await _exportPosData();
    final teeTimeData = await _exportTeeTimeData();

    final exportMap = {
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
      'databases': {'pos': posData, 'teeTimes': teeTimeData},
    };

    // Pretty print JSON dengan indentasi untuk kemudahan debugging
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(exportMap);
  }

  /// Export hanya data POS (invoices, payments)
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

  /// Export hanya data Tee Time (reservations)
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

  /// Internal: Export data POS dengan struktur relasional
  Future<Map<String, dynamic>> _exportPosData() async {
    // Get all invoices
    final invoiceRows = await _invoiceRepo.getInvoices();
    final invoices = <Map<String, dynamic>>[];

    for (final invRow in invoiceRows) {
      final invoiceId = invRow['id'] as int;

      // Get items for this invoice
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

      // Get paid amount and allocations for this invoice
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

    // Get all payments with their allocations
    final paymentRows = await _invoiceRepo.getPayments();
    final payments = <Map<String, dynamic>>[];

    for (final payRow in paymentRows) {
      final paymentId = payRow['id'] as int;

      // Get allocations for this payment
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

  /// Internal: Export data Tee Time
  Future<Map<String, dynamic>> _exportTeeTimeData() async {
    // Get all reservations (including available slots if they exist)
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

  /// Get summary statistik untuk preview sebelum export
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
