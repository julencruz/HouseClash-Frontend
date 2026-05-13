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
    'TASK_COMPLETED'    => ActivityLogType.taskCompleted,
    'TASK_APPROVED'     => ActivityLogType.taskApproved,
    'TASK_DISPUTED'     => ActivityLogType.taskDisputed,
    'TASK_AUTO_APPROVED'=> ActivityLogType.taskAutoApproved,
    'TASK_ASSIGNED'     => ActivityLogType.taskAssigned,
    'TASK_UNASSIGNED'   => ActivityLogType.taskUnassigned,
    'TASK_CREATED'      => ActivityLogType.taskCreated,
    'TASK_DELETED'      => ActivityLogType.taskDeleted,
    'CARD_PLAYED'       => ActivityLogType.cardPlayed,
    'CARD_PURCHASED'    => ActivityLogType.cardPurchased,
    'MEMBER_JOINED'     => ActivityLogType.memberJoined,
    'MEMBER_LEFT'       => ActivityLogType.memberLeft,
    _                   => ActivityLogType.unknown,
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
    required this.createdAt,
    required this.isPendingReview,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) => ActivityModel(
    id: json['id'] as int,
    houseId: json['houseId'] as int,
    type: ActivityLogType.fromString(json['type'] as String? ?? ''),
    actorUserId: json['actorUserId'] as int,
    actorUsername: json['actorUsername'] as String,
    targetUserId: json['targetUserId'] as int?,
    targetUsername: json['targetUsername'] as String?,
    taskId: json['taskId'] as int?,
    taskTitle: json['taskTitle'] as String?,
    cardType: json['cardType'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    isPendingReview: json['isPendingReview'] as bool? ?? false,
  );
}

extension ActivityLogTypeInfo on ActivityLogType {
  String message(String actor, String? target, String? task, String? card) {
    return switch (this) {
      ActivityLogType.taskCompleted    => '$actor ha completado la tarea "${task ?? ''}"',
      ActivityLogType.taskApproved     => '$actor ha aprobado la tarea "${task ?? ''}" de ${target ?? ''}',
      ActivityLogType.taskDisputed     => '$actor ha disputado la tarea "${task ?? ''}" de ${target ?? ''}',
      ActivityLogType.taskAutoApproved => 'La tarea "${task ?? ''}" de $actor fue auto-aprobada',
      ActivityLogType.taskAssigned     => '$actor se ha asignado la tarea "${task ?? ''}"',
      ActivityLogType.taskUnassigned   => '$actor se ha desasignado de "${task ?? ''}"',
      ActivityLogType.taskCreated      => '$actor ha creado la tarea "${task ?? ''}"',
      ActivityLogType.taskDeleted      => '$actor ha eliminado la tarea "${task ?? ''}"',
      ActivityLogType.cardPlayed       => '$actor ha lanzado la carta "${_formatCard(card)}"${target != null ? ' a $target' : ''}',
      ActivityLogType.cardPurchased    => '$actor ha comprado un sobre de cartas',
      ActivityLogType.memberJoined     => 'Bienvenido $actor a la casa',
      ActivityLogType.memberLeft       => '$actor ha abandonado la casa',
      ActivityLogType.unknown          => '$actor realizó una acción desconocida',
    };
  }

  String _formatCard(String? card) => card?.replaceAll('_', ' ') ?? '';

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

  Color get color {
    return switch (this) {
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
}

