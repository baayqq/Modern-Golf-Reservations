import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modern_golf_reservations/app_scaffold.dart';
import 'package:modern_golf_reservations/models/tee_time_model.dart';
import 'package:modern_golf_reservations/services/tee_time_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:modern_golf_reservations/router.dart';
import 'package:modern_golf_reservations/services/invoice_repository.dart';
import 'package:modern_golf_reservations/config/fees.dart';
import 'create_tee_time_folder/field_label.dart';
import 'create_tee_time_folder/date_field.dart';
import 'create_tee_time_folder/time_list.dart';
import 'create_tee_time_folder/player_fields.dart';

class CreateTeeTimePage extends StatefulWidget {
  final TeeTimeModel? initial;
  const CreateTeeTimePage({super.key, this.initial});

  @override
  State<CreateTeeTimePage> createState() => _CreateTeeTimePageState();
}

class _CreateTeeTimePageState extends State<CreateTeeTimePage> {
  final _repo = TeeTimeRepository();

  DateTime? _createDate;
  TimeOfDay? _createTime;

  String? _createTeeBox;
  final TextEditingController _playerCtrl = TextEditingController();
  final TextEditingController _player2Ctrl = TextEditingController();
  final TextEditingController _player3Ctrl = TextEditingController();
  final TextEditingController _player4Ctrl = TextEditingController();

  final TextEditingController _countCtrl = TextEditingController(text: '');
  final TextEditingController _notesCtrl = TextEditingController();

  DateTime? _editDate;
  TimeOfDay? _editTime;

  Future<void> _pickCreateDate() async {
    final now = DateTime.now();
    final res = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDate: _createDate ?? now,
    );
    if (res != null) setState(() => _createDate = res);
  }

  Future<void> _pickCreateTime() async {

    final slotStrings = TeeTimeRepository.standardSlotTimes();
    final slotTOD = slotStrings.map(_parseTime).toList();
    final itemsBox1 = slotTOD;
    final itemsBox10 = slotTOD;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Pilih jam (06:30–14:00)'),
          content: SizedBox(
            width: 520,
            height: 520,
            child: DefaultTabController(
              length: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TabBar(
                    labelColor: Theme.of(context).colorScheme.primary,
                    tabs: const [
                      Tab(text: 'Tee Box 1'),
                      Tab(text: 'Tee Box 10'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      children: [
                        TimeList(
                          boxLabel: '1',
                          times: itemsBox1,
                          onPick: (tod) {
                            setState(() {
                              _createTime = tod;
                              _createTeeBox = '1';
                            });
                            Navigator.of(ctx).pop();
                          },
                        ),
                        TimeList(
                          boxLabel: '10',
                          times: itemsBox10,
                          onPick: (tod) {
                            setState(() {
                              _createTime = tod;
                              _createTeeBox = '10';
                            });
                            Navigator.of(ctx).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _repo.init();
    final init = widget.initial;
    if (init != null) {
      _editDate = init.date;
      _editTime = _parseTime(init.time);
      _playerCtrl.text = init.playerName ?? '';
      _player2Ctrl.text = init.player2Name ?? '';
      _player3Ctrl.text = init.player3Name ?? '';
      _player4Ctrl.text = init.player4Name ?? '';
      _countCtrl.text = init.playerCount == null ? '' : init.playerCount!.toString();
      _notesCtrl.text = init.notes ?? '';
      setState(() {});
    }
  }

  String _timeLabel(TimeOfDay? t) {
    if (t == null) return '--:--';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: h, minute: m);
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String? _validate({required bool editMode}) {
    final count = int.tryParse(_countCtrl.text.trim());
    final hasDate = editMode ? _editDate != null : _createDate != null;
    final hasTime = editMode ? _editTime != null : _createTime != null;
    if (!hasDate) return 'Tanggal wajib dipilih';
    if (!hasTime) return 'Jam mulai wajib dipilih';
    if (count == null) return 'Jumlah pemain wajib dipilih';
    if (count <= 0) return 'Jumlah pemain wajib angka > 0';
    if (count < 1 || count > 4) return 'Jumlah pemain maksimal 4';
    final name = _playerCtrl.text.trim();
    final p2 = _player2Ctrl.text.trim();
    final p3 = _player3Ctrl.text.trim();
    final p4 = _player4Ctrl.text.trim();
    if (count >= 1 && name.isEmpty) return 'Nama pemain 1 wajib diisi';
    if (count >= 2 && p2.isEmpty) return 'Nama pemain 2 wajib diisi';
    if (count >= 3 && p3.isEmpty) return 'Nama pemain 3 wajib diisi';
    if (count >= 4 && p4.isEmpty) return 'Nama pemain 4 wajib diisi';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Create Tee Time',
      body: ListView(
        children: [
          if (widget.initial != null) ...[
            Text(
              'Edit Tee Time Reservation',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const FieldLabel('Tanggal:'),
            DateField(
              hint: 'dd/mm/yyyy',
              value: _editDate == null ? '' : DateFormat('dd/MM/yyyy').format(_editDate!),
              onTap: () async {
                final now = DateTime.now();
                final res = await showDatePicker(
                  context: context,
                  firstDate: DateTime(now.year - 5),
                  lastDate: DateTime(now.year + 5),
                  initialDate: _editDate ?? now,
                );
                if (res != null) setState(() => _editDate = res);
              },
              icon: Icons.calendar_today,
            ),
            const SizedBox(height: 12),
            const FieldLabel('Jam Mulai:'),
            DateField(
              hint: '--:--',
              value: _timeLabel(_editTime),
              onTap: () async {
                final res = await showTimePicker(
                  context: context,
                  initialTime: _editTime ?? const TimeOfDay(hour: 7, minute: 0),
                );
                if (res != null) setState(() => _editTime = res);
              },
              icon: Icons.access_time,
            ),
            const SizedBox(height: 12),
            const FieldLabel('Jumlah Pemain:'),
            DropdownButtonFormField<int>(
              value: int.tryParse(_countCtrl.text.trim()),
              items: const [1, 2, 3, 4]
                  .map((e) => DropdownMenuItem<int>(value: e, child: Text(e.toString())))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _countCtrl.text = v.toString();
                  if (v < 4) _player4Ctrl.clear();
                  if (v < 3) _player3Ctrl.clear();
                  if (v < 2) _player2Ctrl.clear();
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Belum memilih jumlah pemain',
              ),
            ),
            const SizedBox(height: 12),
            PlayerFields(
              count: int.tryParse(_countCtrl.text.trim()),
              playerCtrl: _playerCtrl,
              player2Ctrl: _player2Ctrl,
              player3Ctrl: _player3Ctrl,
              player4Ctrl: _player4Ctrl,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 180,
              child: FilledButton.tonal(
                onPressed: () async {
                  final err = _validate(editMode: true);
                  if (err != null || widget.initial?.id == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(err ?? 'Data tidak valid')),
                    );
                    return;
                  }
                  final updated = TeeTimeModel(
                    id: widget.initial!.id,
                    date: _editDate!,
                    time: _formatTime(_editTime!),
                    teeBox: widget.initial!.teeBox,
                    playerName: _playerCtrl.text.trim(),
                    player2Name: _player2Ctrl.text.trim().isEmpty ? null : _player2Ctrl.text.trim(),
                    player3Name: _player3Ctrl.text.trim().isEmpty ? null : _player3Ctrl.text.trim(),
                    player4Name: _player4Ctrl.text.trim().isEmpty ? null : _player4Ctrl.text.trim(),
                    playerCount: int.tryParse(_countCtrl.text.trim()) ?? 1,
                    notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                    status: widget.initial!.status,
                  );
                  await _repo.updateReservation(updated);
                  if (!context.mounted) return;
                  Navigator.of(context).pop(true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
                child: const Text('Save Changes'),
              ),
            ),
            const Divider(height: 32),
          ],
          Text(
            'Create Tee Time Reservation',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          const FieldLabel('Tanggal:'),
          DateField(
            hint: 'dd/mm/yyyy',
            value: _createDate == null ? '' : DateFormat('dd/MM/yyyy').format(_createDate!),
            onTap: _pickCreateDate,
            icon: Icons.calendar_today,
          ),
          const SizedBox(height: 12),
          const FieldLabel('Jam Mulai:'),
          DateField(
            hint: '--:--',
            value: _createTime == null
                ? _timeLabel(_createTime)
                : '${_timeLabel(_createTime)} (Tee Box ${_createTeeBox ?? '-'})',
            onTap: _pickCreateTime,
            icon: Icons.access_time,
          ),
          const SizedBox(height: 12),
          const FieldLabel('Jumlah Pemain:'),
          DropdownButtonFormField<int>(
            value: int.tryParse(_countCtrl.text.trim()),
            items: const [1, 2, 3, 4]
                .map((e) => DropdownMenuItem<int>(value: e, child: Text(e.toString())))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _countCtrl.text = v.toString();
                if (v < 4) _player4Ctrl.clear();
                if (v < 3) _player3Ctrl.clear();
                if (v < 2) _player2Ctrl.clear();
              });
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Belum memilih jumlah pemain',
            ),
          ),
          const SizedBox(height: 12),
          PlayerFields(
            count: int.tryParse(_countCtrl.text.trim()),
            playerCtrl: _playerCtrl,
            player2Ctrl: _player2Ctrl,
            player3Ctrl: _player3Ctrl,
            player4Ctrl: _player4Ctrl,
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 16),
          SizedBox(
            width: 180,
            child: FilledButton.tonal(
              onPressed: () async {
                final err = _validate(editMode: false);
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                  return;
                }
                await _repo.createOrBookSlot(
                  date: _createDate!,
                  time: _formatTime(_createTime!),
                  teeBox: int.tryParse(_createTeeBox ?? '') ?? 1,
                  playerName: _playerCtrl.text.trim(),
                  playerCount: (int.tryParse(_countCtrl.text.trim()) ?? 1).clamp(1, 4),
                  player2Name: _player2Ctrl.text.trim().isEmpty ? null : _player2Ctrl.text.trim(),
                  player3Name: _player3Ctrl.text.trim().isEmpty ? null : _player3Ctrl.text.trim(),
                  player4Name: _player4Ctrl.text.trim().isEmpty ? null : _player4Ctrl.text.trim(),
                  notes: _createTeeBox == null ? null : 'Tee Box ${_createTeeBox}',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reservasi berhasil dibuat. Silakan buka POS untuk membuat invoice/pembayaran.'),
                  ),
                );
                if (!context.mounted) return;
                GoRouter.of(context).goNamed(
                  AppRoute.teeBooking.name,
                  extra: DateTime(_createDate!.year, _createDate!.month, _createDate!.day),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Save'),
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Text('© 2025 | Fitri Dwi Astuti.', style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}