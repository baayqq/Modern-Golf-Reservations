import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/tee_time_model.dart';

class TeeTimeRepository {
  Database? _db;

  Future<void> init() async {
    // Use SQLite via WASM on web
    final factory = databaseFactoryFfiWeb;
    _db = await factory.openDatabase('tee_times.db');
    await _createTables();
    await _ensureColumns();
    await _seedIfEmpty();
  }

  Future<void> _createTables() async {
    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS tee_times (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        playerName TEXT,
        playerCount INTEGER,
        notes TEXT,
        status TEXT NOT NULL
      );
    ''');
    // Index to speed up per-day queries
    await _db!.execute(
      'CREATE INDEX IF NOT EXISTS idx_tee_times_date ON tee_times(date);',
    );
  }

  Future<void> _ensureColumns() async {
    final cols = await _db!.rawQuery("PRAGMA table_info('tee_times')");
    final names = cols.map((e) => e['name'] as String).toSet();
    if (!names.contains('playerCount')) {
      await _db!.execute("ALTER TABLE tee_times ADD COLUMN playerCount INTEGER");
    }
    if (!names.contains('notes')) {
      await _db!.execute("ALTER TABLE tee_times ADD COLUMN notes TEXT");
    }
  }

  Future<void> _seedIfEmpty() async {
    final res = await _db!.rawQuery('SELECT COUNT(*) AS c FROM tee_times');
    final count = (res.first['c'] as int?) ?? (res.first['c'] as num).toInt();
    if (count > 0) return;

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final daysToSeed = 21; // 3 weeks of sample data
    final times = <String>['06:30','07:30','08:30','09:30','10:30','11:30','12:30','13:30','14:30','15:30','16:30'];

    final batch = _db!.batch();
    for (var d = 0; d < daysToSeed; d++) {
      final day = start.add(Duration(days: d));
      final dayIso = _iso(day);
      for (var i = 0; i < times.length; i++) {
        final time = times[i];
        // deterministic demo: mark some slots booked
        final booked = ((d + i) % 5 == 0); // approx 20% booked
        batch.insert(
          'tee_times',
          {
            'date': dayIso,
            'time': time,
            'playerName': booked ? 'Demo Player ${d + 1}' : null,
            'playerCount': booked ? 1 : null,
            'notes': null,
            'status': booked ? 'booked' : 'available',
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
    await batch.commit(noResult: true);
  }

  Future<List<TeeTimeModel>> getSlotsForDate(DateTime date) async {
    final iso = _iso(date);
    final rows = await _db!.query(
      'tee_times',
      where: 'date = ?',
      whereArgs: [iso],
      orderBy: 'time ASC',
    );
    return rows.map((e) => TeeTimeModel.fromMap(e)).toList();
  }

  Future<List<TeeTimeModel>> getAllReservations({String? status}) async {
    final rows = await _db!.query(
      'tee_times',
      where: status == null ? null : 'status = ?',
      whereArgs: status == null ? null : [status],
      orderBy: 'date ASC, time ASC',
    );
    return rows.map((e) => TeeTimeModel.fromMap(e)).toList();
  }

  Future<List<TeeTimeModel>> search({DateTime? date, String? playerQuery}) async {
    final whereParts = <String>[];
    final args = <Object?>[];
    if (date != null) {
      whereParts.add('date = ?');
      args.add(_iso(date));
    }
    if (playerQuery != null && playerQuery.trim().isNotEmpty) {
      whereParts.add('playerName LIKE ?');
      args.add('%${playerQuery.trim()}%');
    }
    final whereClause = whereParts.isEmpty ? null : whereParts.join(' AND ');
    final rows = await _db!.query(
      'tee_times',
      where: whereClause,
      whereArgs: whereClause == null ? null : args,
      orderBy: 'date ASC, time ASC',
    );
    return rows.map((e) => TeeTimeModel.fromMap(e)).toList();
  }

  Future<TeeTimeModel?> getById(int id) async {
    final rows = await _db!.query('tee_times', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return TeeTimeModel.fromMap(rows.first);
  }

  Future<void> bookSlot({required int id, required String playerName}) async {
    await _db!.update(
      'tee_times',
      {
        'playerName': playerName,
        'status': 'booked',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> cancelBooking({required int id}) async {
    await _db!.update(
      'tee_times',
      {
        'playerName': null,
        'status': 'available',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateReservation(TeeTimeModel model) async {
    await _db!.update(
      'tee_times',
      {
        'date': _iso(model.date),
        'time': model.time,
        'playerName': model.playerName,
        'playerCount': model.playerCount,
        'notes': model.notes,
        'status': model.status,
      },
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<void> deleteById(int id) async {
    await _db!.delete('tee_times', where: 'id = ?', whereArgs: [id]);
  }

  /// Create new reservation or convert existing available slot into booked.
  Future<void> createOrBookSlot({
    required DateTime date,
    required String time,
    required String playerName,
    required int playerCount,
    String? notes,
  }) async {
    // Check if a row exists for this date+time
    final rows = await _db!.query(
      'tee_times',
      where: 'date = ? AND time = ?',
      whereArgs: [_iso(date), time],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      // Update existing row
      final id = (rows.first['id'] as int?) ?? (rows.first['id'] as num).toInt();
      await _db!.update(
        'tee_times',
        {
          'playerName': playerName,
          'playerCount': playerCount,
          'notes': notes,
          'status': 'booked',
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      // Insert new row
      await _db!.insert('tee_times', {
        'date': _iso(date),
        'time': time,
        'playerName': playerName,
        'playerCount': playerCount,
        'notes': notes,
        'status': 'booked',
      });
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  String _iso(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().split('T').first;

  Future<bool> hasAnyBookedInMonth(DateTime month) async {
    final startIso = _iso(DateTime(month.year, month.month, 1));
    final endIso = _iso(DateTime(month.year, month.month + 1, 1));
    final rows = await _db!.query(
      'tee_times',
      columns: ['id'],
      where: 'date >= ? AND date < ? AND status = ?',
      whereArgs: [startIso, endIso, 'booked'],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}