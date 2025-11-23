// FieldLabel Widget
// Tujuan: Menampilkan label teks kecil di atas input agar konsisten dan reusable.
// Dapat digunakan di berbagai form termasuk halaman Create Tee Time.
import 'package:flutter/material.dart';

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}