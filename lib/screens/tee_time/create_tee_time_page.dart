import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modern_golf_reservations/app_scaffold.dart';

class CreateTeeTimePage extends StatefulWidget {
  const CreateTeeTimePage({super.key});

  @override
  State<CreateTeeTimePage> createState() => _CreateTeeTimePageState();
}

class _CreateTeeTimePageState extends State<CreateTeeTimePage> {
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  final _dateFmt = DateFormat('dd/MM/yyyy');

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final res = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDate: _startDate ?? now,
    );
    if (res != null) setState(() => _startDate = res);
  }

  Future<void> _pickEndDate() async {
    final base = _startDate ?? DateTime.now();
    final res = await showDatePicker(
      context: context,
      firstDate: DateTime(base.year - 5),
      lastDate: DateTime(base.year + 5),
      initialDate: _endDate ?? base,
    );
    if (res != null) setState(() => _endDate = res);
  }

  Future<void> _pickStartTime() async {
    final res = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 7, minute: 0),
    );
    if (res != null) setState(() => _startTime = res);
  }

  Future<void> _pickEndTime() async {
    final res = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 17, minute: 0),
    );
    if (res != null) setState(() => _endTime = res);
  }

  String _timeLabel(TimeOfDay? t) => t == null ? '--:--' : t.format(context);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Create Tee Time',
      body: ListView(
        children: [
          Text(
            'Create Tee Sheet with Custom Time Slots (10-Minute Intervals)',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // Start Date
          _FieldLabel('Start Date:'),
          _DateField(
            hint: 'dd/mm/yyyy',
            value: _startDate == null ? '' : _dateFmt.format(_startDate!),
            onTap: _pickStartDate,
            icon: Icons.calendar_today,
          ),
          const SizedBox(height: 12),

          // End Date
          _FieldLabel('End Date:'),
          _DateField(
            hint: 'dd/mm/yyyy',
            value: _endDate == null ? '' : _dateFmt.format(_endDate!),
            onTap: _pickEndDate,
            icon: Icons.calendar_today,
          ),
          const SizedBox(height: 12),

          // Start Time
          _FieldLabel('Start Time:'),
          _DateField(
            hint: '--:--',
            value: _timeLabel(_startTime),
            onTap: _pickStartTime,
            icon: Icons.access_time,
          ),
          const SizedBox(height: 12),

          // End Time
          _FieldLabel('End Time:'),
          _DateField(
            hint: '--:--',
            value: _timeLabel(_endTime),
            onTap: _pickEndTime,
            icon: Icons.access_time,
          ),
          const SizedBox(height: 20),

          // Submit
          SizedBox(
            width: 180,
            child: FilledButton.tonal(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0D6EFD),
                foregroundColor: Colors.white,
              ),
              child: const Text('Create Tee Sheet'),
            ),
          ),
          const SizedBox(height: 40),

          // Footer like sample
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
