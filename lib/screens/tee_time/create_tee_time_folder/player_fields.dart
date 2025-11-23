// PlayerFields Widget
// Tujuan: Menampilkan field nama pemain berdasarkan jumlah pemain (1-4).
// Menggunakan controller dari halaman induk agar state tetap terpusat.
import 'package:flutter/material.dart';
import 'field_label.dart';

class PlayerFields extends StatelessWidget {
  final int? count;
  final TextEditingController playerCtrl;
  final TextEditingController player2Ctrl;
  final TextEditingController player3Ctrl;
  final TextEditingController player4Ctrl;

  const PlayerFields({
    super.key,
    required this.count,
    required this.playerCtrl,
    required this.player2Ctrl,
    required this.player3Ctrl,
    required this.player4Ctrl,
  });

  @override
  Widget build(BuildContext context) {
    final c = count;
    if (c == null) return const SizedBox.shrink();

    final children = <Widget>[];
    if (c >= 1) {
      children.addAll([
        const FieldLabel('Pemain 1'),
        TextField(
          controller: playerCtrl,
          decoration: const InputDecoration(
            hintText: 'Nama Pemain 1',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
      ]);
    }
    if (c >= 2) {
      children.addAll([
        const FieldLabel('Pemain 2'),
        TextField(
          controller: player2Ctrl,
          decoration: const InputDecoration(
            hintText: 'Nama Pemain 2',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
      ]);
    }
    if (c >= 3) {
      children.addAll([
        const FieldLabel('Pemain 3'),
        TextField(
          controller: player3Ctrl,
          decoration: const InputDecoration(
            hintText: 'Nama Pemain 3',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
      ]);
    }
    if (c >= 4) {
      children.addAll([
        const FieldLabel('Pemain 4'),
        TextField(
          controller: player4Ctrl,
          decoration: const InputDecoration(
            hintText: 'Nama Pemain 4',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
      ]);
    }

    return Column(children: children);
  }
}