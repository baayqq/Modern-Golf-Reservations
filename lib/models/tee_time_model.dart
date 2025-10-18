/// Tee time data model
class TeeTimeModel {
  final int? id;
  final DateTime date;
  final String time; // HH:mm
  final String? playerName;
  final int? playerCount; // jumlah pemain
  final String? notes; // catatan
  final String status; // 'available' | 'booked'

  const TeeTimeModel({
    this.id,
    required this.date,
    required this.time,
    this.playerName,
    this.playerCount,
    this.notes,
    required this.status,
  });

  TeeTimeModel copyWith({
    int? id,
    DateTime? date,
    String? time,
    String? playerName,
    int? playerCount,
    String? notes,
    String? status,
  }) {
    return TeeTimeModel(
      id: id ?? this.id,
      date: date ?? this.date,
      time: time ?? this.time,
      playerName: playerName ?? this.playerName,
      playerCount: playerCount ?? this.playerCount,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'date': _dateToIso(date),
        'time': time,
        'playerName': playerName,
        'playerCount': playerCount,
        'notes': notes,
        'status': status,
      };

  static TeeTimeModel fromMap(Map<String, Object?> map) {
    return TeeTimeModel(
      id: (map['id'] as int?) ?? (map['id'] is num ? (map['id'] as num).toInt() : null),
      date: DateTime.parse((map['date'] as String)),
      time: map['time'] as String,
      playerName: map['playerName'] as String?,
      playerCount: (map['playerCount'] as int?) ?? (map['playerCount'] is num ? (map['playerCount'] as num).toInt() : null),
      notes: map['notes'] as String?,
      status: map['status'] as String,
    );
  }

  static String _dateToIso(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().split('T').first;

  @override
  String toString() =>
      'TeeTimeModel(id: $id, date: ${_dateToIso(date)}, time: $time, playerName: $playerName, playerCount: $playerCount, notes: $notes, status: $status)';
}