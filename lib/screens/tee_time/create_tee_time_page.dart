import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modern_golf_reservations/app_scaffold.dart';
import 'package:modern_golf_reservations/models/tee_time_model.dart';
import 'package:modern_golf_reservations/services/tee_time_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:modern_golf_reservations/router.dart';

class CreateTeeTimePage extends StatefulWidget {
  final TeeTimeModel? initial;
  const CreateTeeTimePage({super.key, this.initial});

  @override
  State<CreateTeeTimePage> createState() => _CreateTeeTimePageState();
}

class _CreateTeeTimePageState extends State<CreateTeeTimePage> {
  final _repo = TeeTimeRepository();
  // Create form fields
  DateTime? _createDate;
  TimeOfDay? _createTime;
  final TextEditingController _playerCtrl = TextEditingController();
  final TextEditingController _countCtrl = TextEditingController(text: '1');
  final TextEditingController _notesCtrl = TextEditingController();
  // Edit single reservation fields when initial is provided
  DateTime? _editDate;
  TimeOfDay? _editTime;

  final _dateFmt = DateFormat('dd/MM/yyyy');

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
    final res = await showTimePicker(
      context: context,
      initialTime: _createTime ?? const TimeOfDay(hour: 7, minute: 0),
    );
    if (res != null) setState(() => _createTime = res);
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
      _countCtrl.text = (init.playerCount ?? 1).toString();
      _notesCtrl.text = init.notes ?? '';
      setState(() {});
    }
  }

  String _timeLabel(TimeOfDay? t) => t == null ? '--:--' : t.format(context);

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
    final name = _playerCtrl.text.trim();
    final count = int.tryParse(_countCtrl.text.trim());
    final hasDate = editMode ? _editDate != null : _createDate != null;
    final hasTime = editMode ? _editTime != null : _createTime != null;
    if (name.isEmpty) return 'Nama pemain wajib diisi';
    if (!hasDate) return 'Tanggal wajib dipilih';
    if (!hasTime) return 'Jam mulai wajib dipilih';
    if (count == null || count <= 0) return 'Jumlah pemain wajib angka > 0';
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
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _FieldLabel('Tanggal:'),
            _DateField(
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
            _FieldLabel('Jam Mulai:'),
            _DateField(
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
            _FieldLabel('Nama Pemain:'),
            TextField(
              controller: _playerCtrl,
              decoration: const InputDecoration(
                hintText: 'Nama Pemain',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            _FieldLabel('Jumlah Pemain:'),
            TextField(
              controller: _countCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Misal: 1',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            _FieldLabel('Catatan:'),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Opsional',
                border: OutlineInputBorder(),
              ),
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
                    playerName: _playerCtrl.text.trim(),
                    playerCount: int.tryParse(_countCtrl.text.trim()) ?? 1,
                    notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                    status: widget.initial!.status,
                  );
                  await _repo.updateReservation(updated);
                  if (!context.mounted) return;
                  Navigator.of(context).pop(true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF198754),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Changes'),
              ),
            ),
            const Divider(height: 32),
          ],
          Text(
            'Create Tee Time Reservation',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _FieldLabel('Tanggal:'),
          _DateField(
            hint: 'dd/mm/yyyy',
            value: _createDate == null ? '' : DateFormat('dd/MM/yyyy').format(_createDate!),
            onTap: _pickCreateDate,
            icon: Icons.calendar_today,
          ),
          const SizedBox(height: 12),
          _FieldLabel('Jam Mulai:'),
          _DateField(
            hint: '--:--',
            value: _timeLabel(_createTime),
            onTap: _pickCreateTime,
            icon: Icons.access_time,
          ),
          const SizedBox(height: 12),
          _FieldLabel('Nama Pemain:'),
          TextField(
            controller: _playerCtrl,
            decoration: const InputDecoration(
              hintText: 'Nama Pemain',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          _FieldLabel('Jumlah Pemain:'),
          TextField(
            controller: _countCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Misal: 1',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          _FieldLabel('Catatan:'),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Opsional',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 180,
            child: FilledButton.tonal(
              onPressed: () async {
                final err = _validate(editMode: false);
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err)),
                  );
                  return;
                }
                await _repo.createOrBookSlot(
                  date: _createDate!,
                  time: _formatTime(_createTime!),
                  playerName: _playerCtrl.text.trim(),
                  playerCount: int.tryParse(_countCtrl.text.trim()) ?? 1,
                  notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                );
                if (!context.mounted) return;
                // After saving, go to booking calendar and pre-select the created date
                GoRouter.of(context).goNamed(
                  AppRoute.teeBooking.name,
                  extra: DateTime(
                    _createDate!.year,
                    _createDate!.month,
                    _createDate!.day,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0D6EFD),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              '© 2024 | IT Department.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _DateField extends StatelessWidget {
  final String hint;
  final String value;
  final VoidCallback onTap;
  final IconData icon;
  const _DateField({
    required this.hint,
    required this.value,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: Icon(icon, size: 18),
          ),
          child: Text(value.isEmpty ? hint : value),
        ),
      ),
    );
  }
}
