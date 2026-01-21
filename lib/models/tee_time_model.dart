class TeeTimeModel {
  final int? id;
  final DateTime date;
  final String time;
  final int? teeBox;
  final String? playerName;

  final String? player2Name;
  final String? player3Name;
  final String? player4Name;
  final int? playerCount;
  final String? notes;
  final String? phoneNumber;
  final String status;

  const TeeTimeModel({
    this.id,
    required this.date,
    required this.time,
    this.teeBox,
    this.playerName,
    this.player2Name,
    this.player3Name,
    this.player4Name,
    this.playerCount,
    this.notes,
    this.phoneNumber,
    required this.status,
  });

  TeeTimeModel copyWith({
    int? id,
    DateTime? date,
    String? time,
    int? teeBox,
    String? playerName,
    String? player2Name,
    String? player3Name,
    String? player4Name,
    int? playerCount,
    String? notes,
    String? phoneNumber,
    String? status,
  }) {
    return TeeTimeModel(
      id: id ?? this.id,
      date: date ?? this.date,
      time: time ?? this.time,
      teeBox: teeBox ?? this.teeBox,
      playerName: playerName ?? this.playerName,
      player2Name: player2Name ?? this.player2Name,
      player3Name: player3Name ?? this.player3Name,
      player4Name: player4Name ?? this.player4Name,
      playerCount: playerCount ?? this.playerCount,
      notes: notes ?? this.notes,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'date': _dateToIso(date),
    'time': time,
    'teeBox': teeBox,
    'playerName': playerName,
    'player2Name': player2Name,
    'player3Name': player3Name,
    'player4Name': player4Name,
    'playerCount': playerCount,
    'notes': notes,
    'phoneNumber': phoneNumber,
    'status': status,
  };

  static TeeTimeModel fromMap(Map<String, Object?> map) {
    return TeeTimeModel(
      id:
          (map['id'] as int?) ??
          (map['id'] is num ? (map['id'] as num).toInt() : null),
      date: DateTime.parse((map['date'] as String)),
      time: map['time'] as String,
      teeBox:
          (map['teeBox'] as int?) ??
          (map['teeBox'] is num ? (map['teeBox'] as num).toInt() : null),
      playerName: map['playerName'] as String?,
      player2Name: map['player2Name'] as String?,
      player3Name: map['player3Name'] as String?,
      player4Name: map['player4Name'] as String?,
      playerCount:
          (map['playerCount'] as int?) ??
          (map['playerCount'] is num
              ? (map['playerCount'] as num).toInt()
              : null),
      notes: map['notes'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      status: map['status'] as String,
    );
  }

  static String _dateToIso(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().split('T').first;

  @override
  String toString() =>
      'TeeTimeModel(id: $id, date: ${_dateToIso(date)}, time: $time, teeBox: $teeBox, playerName: $playerName, player2Name: $player2Name, player3Name: $player3Name, player4Name: $player4Name, playerCount: $playerCount, notes: $notes, phoneNumber: $phoneNumber, status: $status)';
}
