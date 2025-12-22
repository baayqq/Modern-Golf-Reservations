class DateFormatters {

  static String compactDateTime12h(DateTime dt) {
    final d = _two(dt.day);
    final m = _two(dt.month);
    final y = dt.year;
    final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = _two(dt.minute);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$d/$m/$y, ${_two(h12)}:$minute $ampm';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}