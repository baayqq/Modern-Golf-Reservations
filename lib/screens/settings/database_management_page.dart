import 'package:flutter/material.dart';
import 'package:modern_golf_reservations/services/database_export_service.dart';
import 'package:modern_golf_reservations/services/database_import_service.dart';
import 'package:modern_golf_reservations/services/invoice_repository.dart';
import 'package:modern_golf_reservations/services/tee_time_repository.dart';
import 'package:modern_golf_reservations/app_scaffold.dart';

import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

class DatabaseManagementPage extends StatefulWidget {
  const DatabaseManagementPage({super.key});

  @override
  State<DatabaseManagementPage> createState() => _DatabaseManagementPageState();
}

class _DatabaseManagementPageState extends State<DatabaseManagementPage> {
  late DatabaseExportService _exportService;
  late DatabaseImportService _importService;
  late InvoiceRepository _invoiceRepo;
  late TeeTimeRepository _teeTimeRepo;

  bool _isLoading = false;
  bool _isInitialized = false;
  Map<String, dynamic>? _exportSummary;
  ImportResult? _lastImportResult;
  ExportScope _exportScope = ExportScope.all;
  ImportMode _importMode = ImportMode.merge;

  @override
  void initState() {
    super.initState();
    _initRepositories();
  }

  Future<void> _initRepositories() async {
    setState(() => _isLoading = true);

    _invoiceRepo = InvoiceRepository();
    _teeTimeRepo = TeeTimeRepository();

    await _invoiceRepo.init();
    await _teeTimeRepo.init();

    _exportService = DatabaseExportService(
      invoiceRepo: _invoiceRepo,
      teeTimeRepo: _teeTimeRepo,
    );

    _importService = DatabaseImportService(
      invoiceRepo: _invoiceRepo,
      teeTimeRepo: _teeTimeRepo,
    );

    _exportSummary = await _exportService.getExportSummary();

    setState(() {
      _isLoading = false;
      _isInitialized = true;
    });
  }

  Future<void> _handleExport() async {
    setState(() => _isLoading = true);

    try {
      String jsonData;
      String filename;

      switch (_exportScope) {
        case ExportScope.all:
          jsonData = await _exportService.exportAllData();
          filename = 'golf_backup_all_${_getTimestamp()}.json';
          break;
        case ExportScope.posOnly:
          jsonData = await _exportService.exportPosDataOnly();
          filename = 'golf_backup_pos_${_getTimestamp()}.json';
          break;
        case ExportScope.teeTimeOnly:
          jsonData = await _exportService.exportTeeTimeDataOnly();
          filename = 'golf_backup_teetime_${_getTimestamp()}.json';
          break;
      }

      if (kIsWeb) {
        final bytes = utf8.encode(jsonData);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', filename)
          ..click();
        html.Url.revokeObjectUrl(url);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Export berhasil! File: $filename'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Export gagal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleImport() async {
    if (kIsWeb) {
      final uploadInput = html.FileUploadInputElement()..accept = '.json';
      uploadInput.click();

      uploadInput.onChange.listen((e) async {
        final files = uploadInput.files;
        if (files == null || files.isEmpty) return;

        final reader = html.FileReader();
        reader.readAsText(files[0]);

        reader.onLoadEnd.listen((e) async {
          final jsonString = reader.result as String;
          await _performImport(jsonString);
        });
      });
    }
  }

  Future<void> _performImport(String jsonString) async {
    setState(() => _isLoading = true);

    try {
      final result = await _importService.importFromJson(
        jsonString,
        mode: _importMode,
      );

      await _invoiceRepo.recalculateAllInvoiceStatuses();

      setState(() {
        _lastImportResult = result;
      });

      _exportSummary = await _exportService.getExportSummary();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? '✅ Import berhasil! ${result.invoicesImported} invoices, ${result.paymentsImported} payments, ${result.teeSlotsImported} slots. Status invoice sudah di-recalculate.'
                : '❌ Import gagal dengan ${result.errors.length} errors',
          ),
          backgroundColor: result.success ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Import error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getTimestamp() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Database Management',
      body: _isLoading && !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📊 Database Summary',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          if (_exportSummary != null) ...[
                            _buildSummaryRow(
                              'Total Invoices',
                              '${_exportSummary!['totalInvoices']}',
                            ),
                            _buildSummaryRow(
                              'Total Payments',
                              '${_exportSummary!['totalPayments']}',
                            ),
                            _buildSummaryRow(
                              'Total Tee Slots',
                              '${_exportSummary!['totalTeeTimeSlots']}',
                            ),
                            _buildSummaryRow(
                              'Booked Slots',
                              '${_exportSummary!['bookedSlots']}',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.upload_file, size: 28),
                              const SizedBox(width: 8),
                              Text(
                                'Export Database',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Backup database Anda ke file JSON. File ini bisa digunakan untuk restore data di lain waktu.',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),

                          SegmentedButton<ExportScope>(
                            segments: const [
                              ButtonSegment(
                                value: ExportScope.all,
                                label: Text('Semua Data'),
                                icon: Icon(Icons.data_object),
                              ),
                              ButtonSegment(
                                value: ExportScope.posOnly,
                                label: Text('POS Only'),
                                icon: Icon(Icons.point_of_sale),
                              ),
                              ButtonSegment(
                                value: ExportScope.teeTimeOnly,
                                label: Text('Tee Time Only'),
                                icon: Icon(Icons.golf_course),
                              ),
                            ],
                            selected: {_exportScope},
                            onSelectionChanged:
                                (Set<ExportScope> newSelection) {
                                  setState(() {
                                    _exportScope = newSelection.first;
                                  });
                                },
                          ),

                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _handleExport,
                              icon: const Icon(Icons.download),
                              label: const Text('Export & Download JSON'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.file_download, size: 28),
                              const SizedBox(width: 8),
                              Text(
                                'Import Database',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Restore database dari file JSON backup. Pilih mode import yang sesuai.',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),

                          SegmentedButton<ImportMode>(
                            segments: const [
                              ButtonSegment(
                                value: ImportMode.merge,
                                label: Text('Merge'),
                                icon: Icon(Icons.merge),
                              ),
                              ButtonSegment(
                                value: ImportMode.replace,
                                label: Text('Replace'),
                                icon: Icon(Icons.swap_horiz),
                              ),
                            ],
                            selected: {_importMode},
                            onSelectionChanged: (Set<ImportMode> newSelection) {
                              setState(() {
                                _importMode = newSelection.first;
                              });
                            },
                          ),

                          const SizedBox(height: 8),
                          Text(
                            _importMode == ImportMode.merge
                                ? '📝 Merge: Gabung data baru dengan data existing'
                                : '⚠️ Replace: Hapus semua data lama dan ganti dengan data baru',
                            style: TextStyle(
                              fontSize: 12,
                              color: _importMode == ImportMode.replace
                                  ? Colors.orange
                                  : Colors.blue,
                            ),
                          ),

                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _handleImport,
                              icon: const Icon(Icons.upload),
                              label: const Text('Upload & Import JSON'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_lastImportResult != null) ...[
                    const SizedBox(height: 24),
                    Card(
                      color: _lastImportResult!.success
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Import Result',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(_lastImportResult.toString()),
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (_isLoading) ...[
                    const SizedBox(height: 24),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _invoiceRepo.close();
    _teeTimeRepo.close();
    super.dispose();
  }
}

enum ExportScope { all, posOnly, teeTimeOnly }
