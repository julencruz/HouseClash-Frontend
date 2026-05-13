import 'package:flutter/material.dart';

enum ActivityLogType {
  taskCompleted,
  taskApproved,
  taskDisputed,
  taskAutoApproved,
  taskAssigned,
  taskUnassigned,
  taskCreated,
  taskDeleted,
  cardPlayed,
  cardPurchased,
  memberJoined,
  memberLeft,
  unknown;

  static ActivityLogType fromString(String value) => switch (value) {
    'TASK_COMPLETED'     => ActivityLogType.taskCompleted,
    'TASK_APPROVED'      => ActivityLogType.taskApproved,
    'TASK_DISPUTED'      => ActivityLogType.taskDisputed,
    'TASK_AUTO_APPROVED' => ActivityLogType.taskAutoApproved,
    'TASK_ASSIGNED'      => ActivityLogType.taskAssigned,
    'TASK_UNASSIGNED'    => ActivityLogType.taskUnassigned,
    'TASK_CREATED'       => ActivityLogType.taskCreated,
    'TASK_DELETED'       => ActivityLogType.taskDeleted,
    'CARD_PLAYED'        => ActivityLogType.cardPlayed,
    'CARD_PURCHASED'     => ActivityLogType.cardPurchased,
    'MEMBER_JOINED'      => ActivityLogType.memberJoined,
    'MEMBER_LEFT'        => ActivityLogType.memberLeft,
    _                    => ActivityLogType.unknown,
  };
}

class ActivityModel {
  final int id;
  final int houseId;
  final ActivityLogType type;
  final int actorUserId;
  final String actorUsername;
  final int? targetUserId;
  final String? targetUsername;
  final int? taskId;
  final String? taskTitle;
  final String? cardType;
  final int? kudosValue;
  final DateTime createdAt;
  final bool isPendingReview;

  const ActivityModel({
    required this.id,
    required this.houseId,
    required this.type,
    required this.actorUserId,
    required this.actorUsername,
    this.targetUserId,
    this.targetUsername,
    this.taskId,
    this.taskTitle,
    this.cardType,
    this.kudosValue,
    required this.createdAt,
    required this.isPendingReview,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) => ActivityModel(
    id:            json['id'] as int,
    houseId:       json['houseId'] as int,
    type:          ActivityLogType.fromString(json['type'] as String? ?? ''),
    actorUserId:   json['actorUserId'] as int,
    actorUsername: json['actorUsername'] as String,
    targetUserId:  json['targetUserId'] as int?,
    targetUsername:json['targetUsername'] as String?,
    taskId:        json['taskId'] as int?,
    taskTitle:     json['taskTitle'] as String?,
    cardType:      json['cardType'] as String?,
    kudosValue:    json['kudosValue'] as int?,
    createdAt:     DateTime.parse(json['createdAt'] as String),
    isPendingReview: json['isPendingReview'] as bool? ?? false,
  );
}

extension ActivityLogTypeInfo on ActivityLogType {
  String _formatCard(String? card) => card?.replaceAll('_', ' ') ?? '';

  TextSpan richMessage(
    String actor,
    String? target,
    String? task,
    String? card,
    TextStyle base,
  ) {
    final bold = base.copyWith(fontWeight: FontWeight.w700);
    TextSpan b(String text) => TextSpan(text: text, style: bold);
    TextSpan n(String text) => TextSpan(text: text, style: base);

    final spans = switch (this) {
      ActivityLogType.taskCompleted    => [b(actor), n(' ha completado la tarea '), b(task ?? '')],
      ActivityLogType.taskApproved     => [b(actor), n(' ha aprobado la tarea '), b(task ?? ''), n(' de '), b(target ?? '')],
      ActivityLogType.taskDisputed     => [b(actor), n(' ha disputado la tarea '), b(task ?? ''), n(' de '), b(target ?? '')],
      ActivityLogType.taskAutoApproved => [n('La tarea '), b(task ?? ''), n(' de '), b(actor), n(' fue auto-aprobada')],
      ActivityLogType.taskAssigned     => [b(actor), n(' se ha asignado la tarea '), b(task ?? '')],
      ActivityLogType.taskUnassigned   => [b(actor), n(' se ha desasignado de '), b(task ?? '')],
      ActivityLogType.taskCreated      => [b(actor), n(' ha creado la tarea '), b(task ?? '')],
      ActivityLogType.taskDeleted      => [b(actor), n(' ha eliminado la tarea '), b(task ?? '')],
      ActivityLogType.cardPlayed       => [b(actor), n(' ha lanzado la carta '), b(_formatCard(card)), if (target != null) ...[n(' a '), b(target)]],
      ActivityLogType.cardPurchased    => [b(actor), n(' ha comprado un sobre de cartas')],
      ActivityLogType.memberJoined     => [n('Bienvenido '), b(actor), n(' a la casa')],
      ActivityLogType.memberLeft       => [b(actor), n(' ha abandonado la casa')],
      ActivityLogType.unknown          => [b(actor), n(' realizó una acción desconocida')],
    };

    return TextSpan(children: spans);
  }

  Color get cardBackground => switch (this) {
    ActivityLogType.taskCompleted    => const Color(0xFFEDF7F1),
    ActivityLogType.taskApproved     => const Color(0xFFEDF7F1),
    ActivityLogType.taskAutoApproved => const Color(0xFFEDF7F1),
    ActivityLogType.taskDisputed     => const Color(0xFFFDF0F0),
    ActivityLogType.taskAssigned     => const Color(0xFFF3F5F6),
    ActivityLogType.taskCreated      => const Color(0xFFF4EFF4),
    ActivityLogType.taskUnassigned   => const Color(0xFFFDF5EE),
    ActivityLogType.taskDeleted      => const Color(0xFFFDF5EE),
    ActivityLogType.cardPlayed       => const Color(0xFFFEF9EC),
    ActivityLogType.cardPurchased    => const Color(0xFFFEF9EC),
    ActivityLogType.memberJoined     => const Color(0xFFEDF7F5),
    ActivityLogType.memberLeft       => const Color(0xFFF5F5F5),
    ActivityLogType.unknown          => const Color(0xFFFFFFFF),
  };

  IconData get icon => switch (this) {
    ActivityLogType.taskCompleted    => Icons.check_circle_outline_rounded,
    ActivityLogType.taskApproved     => Icons.thumb_up_rounded,
    ActivityLogType.taskDisputed     => Icons.thumb_down_rounded,
    ActivityLogType.taskAutoApproved => Icons.check_circle_rounded,
    ActivityLogType.taskAssigned     => Icons.person_add_rounded,
    ActivityLogType.taskUnassigned   => Icons.person_remove_rounded,
    ActivityLogType.taskCreated      => Icons.add_task_rounded,
    ActivityLogType.taskDeleted      => Icons.delete_rounded,
    ActivityLogType.cardPlayed       => Icons.style_rounded,
    ActivityLogType.cardPurchased    => Icons.shopping_bag_rounded,
    ActivityLogType.memberJoined     => Icons.waving_hand_rounded,
    ActivityLogType.memberLeft       => Icons.exit_to_app_rounded,
    ActivityLogType.unknown          => Icons.info_outline_rounded,
  };

  Color get color => switch (this) {
    ActivityLogType.taskCompleted    => const Color(0xFF009048),
    ActivityLogType.taskApproved     => const Color(0xFF009048),
    ActivityLogType.taskAutoApproved => const Color(0xFF009048),
    ActivityLogType.taskDisputed     => const Color(0xFFBE6363),
    ActivityLogType.taskAssigned     => const Color(0xFF00916E),
    ActivityLogType.taskUnassigned   => const Color(0xFFBE7E63),
    ActivityLogType.taskCreated      => const Color(0xFF00916E),
    ActivityLogType.taskDeleted      => const Color(0xFFBE6363),
    ActivityLogType.cardPlayed       => const Color(0xFFA44A3F),
    ActivityLogType.cardPurchased    => const Color(0xFFA44A3F),
    ActivityLogType.memberJoined     => const Color(0xFF00916E),
    ActivityLogType.memberLeft       => const Color(0xFF6B5E5B),
    ActivityLogType.unknown          => const Color(0xFFAA9E9B),
  };
}
