class UserSession {
  final int    id;
  final String username;
  final String email;
  final int?   houseId;
  final int    kudosBalance;

  const UserSession({
    required this.id,
    required this.username,
    required this.email,
    required this.kudosBalance,
    this.houseId,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
    id:           json['id'] as int,
    username:     json['username'] as String,
    email:        json['email'] as String,
    houseId:      json['houseId'] as int?,
    kudosBalance: json['kudosBalance'] as int,
  );
}