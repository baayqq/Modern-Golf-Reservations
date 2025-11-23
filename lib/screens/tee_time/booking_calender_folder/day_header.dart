// DayHeader
// Widget label hari (Sun-Mon-...) untuk header kalender bulanan.
// Tujuan: reusable, ringan, dan konsisten di seluruh tampilan kalender.
import 'package:flutter/material.dart';

class DayHeader extends StatelessWidget {
  final String label;
  const DayHeader(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF0D6EFD),
            decoration: TextDecoration.underline,
            decorationColor: Color(0xFF0D6EFD),
            decorationThickness: 1,
          ),
        ),
      ),
    );
  }
}