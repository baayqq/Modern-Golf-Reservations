// DateField Widget
// Tujuan: Komponen input tanggal/waktu yang tampil seperti field read-only
// dengan ikon di kanan, dipakai untuk pilih tanggal atau jam.
import 'package:flutter/material.dart';

class DateField extends StatelessWidget {
  final String hint;
  final String value;
  final VoidCallback onTap;
  final IconData icon;

  const DateField({
    super.key,
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