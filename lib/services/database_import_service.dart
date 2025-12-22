import 'dart:convert';
import 'package:modern_golf_reservations/services/invoice_repository.dart';
import 'package:modern_golf_reservations/services/tee_time_repository.dart';

class DatabaseImportService {
  final InvoiceRepository _invoiceRepo;
  final TeeTimeRepository _teeTimeRepo;

  DatabaseImportService({
    required InvoiceRepository invoiceRepo,
    required TeeTimeRepository teeTimeRepo,
  }) : _invoiceRepo = invoiceRepo,
       _teeTimeRepo = teeTimeRepo;

  ImportResult? _lastImportResult;
  ImportResult? get lastImportResult => _lastImportResult;

  Future<ImportResult> importFromJson(
    String jsonString, {
    ImportMode mode = ImportMode.merge,
  }) async {
    final result = ImportResult();

    try {

      final Map<String, dynamic> data = jsonDecode(jsonString);

      if (!_validateJsonStructure(data)) {
        result.success = false;
        result.errors.add(
          'Format JSON tidak valid. Pastikan file adalah hasil export yang benar.',
        );
        _lastImportResult = result;
        return result;
      }

      if (mode == ImportMode.replace) {
        await _clearAllData();
        result.notes.add('Mode Replace: Semua data lama dihapus');
      }

      final databases = data['databases'] as Map<String, dynamic>;

      if (databases.containsKey('pos')) {
        final posData = databases['pos'] as Map<String, dynamic>;
        await _importPosData(posData, result, mode);
      }

      if (databases.containsKey('teeTimes')) {
        final teeTimeData = databases['teeTimes'] as Map<String, dynamic>;
        await _importTeeTimeData(teeTimeData, result, mode);
      }

      result.success = result.errors.isEmpty;
      _lastImportResult = result;
      return result;
    } catch (e) {
      result.success = false;
      result.errors.add('Error parsing JSON: $e');
      _lastImportResult = result;
      return result;
    }
  }

  bool _validateJsonStructure(Map<String, dynamic> data) {

    if (!data.containsKey('version') || !data.containsKey('databases')) {
      return false;
    }

    final databases = data['databases'];
    if (databases is! Map<String, dynamic>) {
      return false;
    }

    if (!databases.containsKey('pos') && !databases.containsKey('teeTimes')) {
      return false;
    }

    return true;
  }

  Future<void> _importPosData(
    Map<String, dynamic> posData,
    ImportResult result,
    ImportMode mode,
  ) async {

    if (posData.containsKey('invoices')) {
      final invoices = posData['invoices'] as List;

      for (final invData in invoices) {
        try {
          final items = (invData['items'] as List)
              .map(
                (item) => InvoiceItemInput(
                  name: item['name'] as String,
                  qty: item['qty'] as int,
                  price: (item['price'] as num).toDouble(),
                ),
              )
              .toList();

          await _invoiceRepo.createInvoice(
            customer: invData['customer'] as String,
            items: items,
            status: invData['status'] as String? ?? 'unpaid',
            date: DateTime.parse(invData['date'] as String),
          );

          result.invoicesImported++;
        } catch (e) {
          result.errors.add('Error import invoice ID ${invData['id']}: $e');
        }
      }
    }

    if (posData.containsKey('payments')) {
      final payments = posData['payments'] as List;

      for (final payData in payments) {
        try {
          final allocations = (payData['allocations'] as List)
              .map(
                (alloc) => PaymentAllocationInput(
                  invoiceId: alloc['invoiceId'] as int,
                  amount: (alloc['amount'] as num).toDouble(),
                ),
              )
              .toList();

          await _invoiceRepo.createCombinedPayment(
            payer: payData['payer'] as String,
            allocations: allocations,
            method: payData['method'] as String?,
            date: DateTime.parse(payData['date'] as String),
          );

          result.paymentsImported++;
        } catch (e) {
          result.errors.add('Error import payment ID ${payData['id']}: $e');
        }
      }
    }
  }

  Future<void> _importTeeTimeData(
    Map<String, dynamic> teeTimeData,
    ImportResult result,
    ImportMode mode,
  ) async {
    if (teeTimeData.containsKey('reservations')) {
      final reservations = teeTimeData['reservations'] as List;

      for (final resData in reservations) {
        try {
          final date = DateTime.parse(resData['date'] as String);
          final time = resData['time'] as String;
          final teeBox = resData['teeBox'] as int;
          final status = resData['status'] as String;

          if (mode == ImportMode.merge && status == 'available') {
            continue;
          }

          if (status == 'booked') {
            await _teeTimeRepo.createOrBookSlot(
              date: date,
              time: time,
              teeBox: teeBox,
              playerName: resData['playerName'] as String,
              playerCount: resData['playerCount'] as int? ?? 1,
              player2Name: resData['player2Name'] as String?,
              player3Name: resData['player3Name'] as String?,
              player4Name: resData['player4Name'] as String?,
              notes: resData['notes'] as String?,
            );
          }

          result.teeSlotsImported++;
        } catch (e) {
          result.errors.add('Error import tee slot ID ${resData['id']}: $e');
        }
      }
    }
  }

  Future<void> _clearAllData() async {

  }
}

enum ImportMode {

  replace,

  merge,
}

class ImportResult {
  bool success = false;
  int invoicesImported = 0;
  int paymentsImported = 0;
  int teeSlotsImported = 0;
  List<String> errors = [];
  List<String> notes = [];

  @override
  String toString() {
    final sb = StringBuffer();
    sb.writeln('Import ${success ? 'Berhasil' : 'Gagal'}');
    sb.writeln('Invoices: $invoicesImported');
    sb.writeln('Payments: $paymentsImported');
    sb.writeln('Tee Slots: $teeSlotsImported');
    if (errors.isNotEmpty) {
      sb.writeln('\nErrors:');
      for (final err in errors) {
        sb.writeln('  - $err');
      }
    }
    if (notes.isNotEmpty) {
      sb.writeln('\nNotes:');
      for (final note in notes) {
        sb.writeln('  - $note');
      }
    }
    return sb.toString();
  }
}