import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/tee_time_model.dart';

class TeeTimeRepository {
  Database? _db;

  Future<void> init() async {
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
        teeBox INTEGER,
        playerName TEXT,
        player2Name TEXT,
        player3Name TEXT,
        player4Name TEXT,
        playerCount INTEGER,
        notes TEXT,
        phoneNumber TEXT,
        status TEXT NOT NULL
      );
    ''');

    await _db!.execute(
      'CREATE INDEX IF NOT EXISTS idx_tee_times_date ON tee_times(date);',
    );
    await _db!.execute(
      'CREATE INDEX IF NOT EXISTS idx_tee_times_date_box ON tee_times(date, teeBox);',
    );
  }

  Future<void> _ensureColumns() async {
    final cols = await _db!.rawQuery("PRAGMA table_info('tee_times')");
    final names = cols.map((e) => e['name'] as String).toSet();
    if (!names.contains('playerCount')) {
      await _db!.execute(
        "ALTER TABLE tee_times ADD COLUMN playerCount INTEGER",
      );
    }
    if (!names.contains('notes')) {
      await _db!.execute("ALTER TABLE tee_times ADD COLUMN notes TEXT");
    }
    if (!names.contains('player2Name')) {
      await _db!.execute("ALTER TABLE tee_times ADD COLUMN player2Name TEXT");
    }
    if (!names.contains('player3Name')) {
      await _db!.execute("ALTER TABLE tee_times ADD COLUMN player3Name TEXT");
    }
    if (!names.contains('player4Name')) {
      await _db!.execute("ALTER TABLE tee_times ADD COLUMN player4Name TEXT");
    }
    if (!names.contains('teeBox')) {
      await _db!.execute("ALTER TABLE tee_times ADD COLUMN teeBox INTEGER");
    }
    if (!names.contains('phoneNumber')) {
      await _db!.execute("ALTER TABLE tee_times ADD COLUMN phoneNumber TEXT");
    }
  }

  Future<void> _seedIfEmpty() async {
    final res = await _db!.rawQuery('SELECT COUNT(*) AS c FROM tee_times');
    final count = (res.first['c'] as int?) ?? (res.first['c'] as num).toInt();
    if (count > 0) return;

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final daysToSeed = 21;
    final times = TeeTimeRepository.standardSlotTimes();

    final batch = _db!.batch();
    for (var d = 0; d < daysToSeed; d++) {
      final day = start.add(Duration(days: d));
      final dayIso = _iso(day);
      for (var i = 0; i < times.length; i++) {
        final time = times[i];

        batch.insert('tee_times', {
          'date': dayIso,
          'time': time,
          'teeBox': 1,
          'playerName': null,
          'playerCount': null,
          'notes': 'Tee Box 1',
          'status': 'available',
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        batch.insert('tee_times', {
          'date': dayIso,
          'time': time,
          'teeBox': 10,
          'playerName': null,
          'playerCount': null,
          'notes': 'Tee Box 10',
          'status': 'available',
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
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

  Future<List<TeeTimeModel>> getBookedForDate(DateTime date) async {
    final iso = _iso(date);
    final rows = await _db!.query(
      'tee_times',
      where: 'date = ? AND status = ?',
      whereArgs: [iso, 'booked'],
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

  Future<List<TeeTimeModel>> search({
    DateTime? date,
    String? playerQuery,
  }) async {
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
    final rows = await _db!.query(
      'tee_times',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return TeeTimeModel.fromMap(rows.first);
  }

  Future<void> bookSlot({required int id, required String playerName}) async {
    await _db!.update(
      'tee_times',
      {'playerName': playerName, 'status': 'booked'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> cancelBooking({required int id}) async {
    await _db!.update(
      'tee_times',
      {'playerName': null, 'status': 'available'},
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
        'teeBox': model.teeBox,
        'playerName': model.playerName,
        'player2Name': model.player2Name,
        'player3Name': model.player3Name,
        'player4Name': model.player4Name,
        'playerCount': model.playerCount,
        'notes': model.notes,
        'phoneNumber': model.phoneNumber,
        'status': model.status,
      },
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<void> deleteById(int id) async {
    await _db!.delete('tee_times', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> createOrBookSlot({
    required DateTime date,
    required String time,
    required int teeBox,
    required String playerName,
    required int playerCount,
    String? player2Name,
    String? player3Name,
    String? player4Name,
    String? notes,
    String? phoneNumber,
  }) async {
    final rows = await _db!.query(
      'tee_times',
      where: 'date = ? AND time = ? AND teeBox = ?',
      whereArgs: [_iso(date), time, teeBox],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      final id =
          (rows.first['id'] as int?) ?? (rows.first['id'] as num).toInt();
      await _db!.update(
        'tee_times',
        {
          'playerName': playerName,
          'player2Name': player2Name,
          'player3Name': player3Name,
          'player4Name': player4Name,
          'playerCount': playerCount,
          'notes': notes,
          'phoneNumber': phoneNumber,
          'status': 'booked',
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      await _db!.insert('tee_times', {
        'date': _iso(date),
        'time': time,
        'teeBox': teeBox,
        'playerName': playerName,
        'player2Name': player2Name,
        'player3Name': player3Name,
        'player4Name': player4Name,
        'playerCount': playerCount,
        'notes': notes,
        'phoneNumber': phoneNumber,
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

  Future<int> countPlayersOnDate(DateTime date) async {
    final iso = _iso(date);
    final rows = await _db!.rawQuery(
      "SELECT SUM(COALESCE(playerCount, 1)) AS c FROM tee_times WHERE date = ? AND status = 'booked'",
      [iso],
    );
    final val = rows.first['c'];
    if (val == null) return 0;
    return (val is int) ? val : (val as num).toInt();
  }

  Future<int> countPlayersInRange(
    DateTime startInclusive,
    DateTime endExclusive,
  ) async {
    final startIso = _iso(startInclusive);
    final endIso = _iso(endExclusive);
    final rows = await _db!.rawQuery(
      "SELECT SUM(COALESCE(playerCount, 1)) AS c FROM tee_times WHERE date >= ? AND date < ? AND status = 'booked'",
      [startIso, endIso],
    );
    final val = rows.first['c'];
    if (val == null) return 0;
    return (val is int) ? val : (val as num).toInt();
  }

  Future<int> countPlayersToday() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return countPlayersOnDate(today);
  }

  Future<int> countPlayersThisWeek() async {
    final now = DateTime.now();

    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 7));
    return countPlayersInRange(start, end);
  }

  Future<int> countPlayersThisMonth() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    return countPlayersInRange(start, end);
  }

  static List<String> standardSlotTimes() {
    List<String> buildRange(int sh, int sm, int eh, int em) {
      final start = DateTime(2000, 1, 1, sh, sm);
      final end = DateTime(2000, 1, 1, eh, em);
      final out = <String>[];
      var t = start;
      while (!t.isAfter(end)) {
        final hh = t.hour.toString().padLeft(2, '0');
        final mm = t.minute.toString().padLeft(2, '0');
        out.add('$hh:$mm');
        t = t.add(const Duration(minutes: 10));
      }
      return out;
    }

    return [...buildRange(6, 30, 8, 30), ...buildRange(11, 30, 14, 0)];
  }
}
