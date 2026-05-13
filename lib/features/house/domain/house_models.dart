import '../../auth/domain/auth_models.dart';

class HouseModel {
  final int id;
  final String name;
  final String description;
  final String inviteCode;
  final int createdBy;

  const HouseModel({
    required this.id,
    required this.name,
    required this.description,
    required this.inviteCode,
    required this.createdBy,
  });

  factory HouseModel.fromJson(Map<String, dynamic> json) => HouseModel(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        inviteCode: json['inviteCode'] as String,
        createdBy: json['createdBy'] as int,
      );
}

class HouseDetailsModel {
  final HouseModel house;
  final List<UserSession> members;

  const HouseDetailsModel({required this.house, required this.members});

  factory HouseDetailsModel.fromJson(Map<String, dynamic> json) =>
      HouseDetailsModel(
        house: HouseModel.fromJson(json['house'] as Map<String, dynamic>),
        members: (json['members'] as List)
            .map((m) => UserSession.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}

class MemberStats {
  final UserSession user;
  final int kudosBalance;
  final int tasksCompleted;
  final int rank;

  const MemberStats({
    required this.user,
    required this.kudosBalance,
    required this.tasksCompleted,
    required this.rank,
  });

  factory MemberStats.fromJson(Map<String, dynamic> json) => MemberStats(
        user: UserSession.fromJson(json['user'] as Map<String, dynamic>),
        kudosBalance: json['kudosBalance'] as int,
        tasksCompleted: json['tasksCompleted'] as int,
        rank: json['rank'] as int,
      );
}

enum RankingPeriod { WEEKLY, MONTHLY, ALL_TIME }

extension RankingPeriodExt on RankingPeriod {
  String get label {
    switch (this) {
      case RankingPeriod.WEEKLY:
        return 'Semana';
      case RankingPeriod.MONTHLY:
        return 'Mes';
      case RankingPeriod.ALL_TIME:
        return 'Total';
    }
  }

  String get value {
    switch (this) {
      case RankingPeriod.WEEKLY:
        return 'WEEKLY';
      case RankingPeriod.MONTHLY:
        return 'MONTHLY';
      case RankingPeriod.ALL_TIME:
        return 'ALL_TIME';
    }
  }
}

