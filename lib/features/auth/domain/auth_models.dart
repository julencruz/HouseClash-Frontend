class UserSession {
  final int id;
  final String username;
  final String email;
  final int? houseId;
  final int kudosBalance;
  final DateTime createdAt;
  final int totalTasksCompleted;
  final int totalKudosEarned;
  final int totalCardsPlayed;

  const UserSession({
    required this.id,
    required this.username,
    required this.email,
    required this.kudosBalance,
    required this.createdAt,
    required this.totalTasksCompleted,
    required this.totalKudosEarned,
    required this.totalCardsPlayed,
    this.houseId,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
    id: json['id'] as int,
    username: json['username'] as String,
    email: json['email'] as String,
    houseId: json['houseId'] as int?,
    kudosBalance: json['kudosBalance'] as int,
    createdAt: _parseDateTime(json['createdAt']),
    totalTasksCompleted: json['totalTasksCompleted'] as int? ?? 0,
    totalKudosEarned: json['totalKudosEarned'] as int? ?? 0,
    totalCardsPlayed: json['totalCardsPlayed'] as int? ?? 0,
  );
}

DateTime _parseDateTime(dynamic value) {
  if (value is String) return DateTime.parse(value);
  if (value is List) {
    return DateTime(
      value[0] as int,
      value[1] as int,
      value[2] as int,
      value.length > 3 ? value[3] as int : 0,
      value.length > 4 ? value[4] as int : 0,
      value.length > 5 ? value[5] as int : 0,
    );
  }
  throw FormatException('Formato de fecha no reconocido: $value');
}
