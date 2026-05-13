import 'package:flutter/material.dart';

import '../../cards/domain/card_model.dart';

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
  memberKicked,
  captainTransferred,
  unknown;

  static ActivityLogType fromString(String value) => switch (value) {
    'TASK_COMPLETED'        => ActivityLogType.taskCompleted,
    'TASK_APPROVED'         => ActivityLogType.taskApproved,
    'TASK_DISPUTED'         => ActivityLogType.taskDisputed,
    'TASK_AUTO_APPROVED'    => ActivityLogType.taskAutoApproved,
    'TASK_ASSIGNED'         => ActivityLogType.taskAssigned,
    'TASK_UNASSIGNED'       => ActivityLogType.taskUnassigned,
    'TASK_CREATED'          => ActivityLogType.taskCreated,
    'TASK_DELETED'          => ActivityLogType.taskDeleted,
    'CARD_PLAYED'           => ActivityLogType.cardPlayed,
    'CARD_USED'             => ActivityLogType.cardPlayed,
    'CARD_EFFECT'           => ActivityLogType.cardPlayed,
    'CARD_EFFECT_USED'      => ActivityLogType.cardPlayed,
    'CARD_PURCHASED'        => ActivityLogType.cardPurchased,
    'CARD_PACK_OPENED'      => ActivityLogType.cardPurchased,
    'MEMBER_JOINED'         => ActivityLogType.memberJoined,
    'MEMBER_LEFT'           => ActivityLogType.memberLeft,
    'MEMBER_KICKED'         => ActivityLogType.memberKicked,
    'CAPTAIN_TRANSFERRED'   => ActivityLogType.captainTransferred,
    _                       => ActivityLogType.unknown,
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
  String formatCard(String? card) {
    if (card == null) return '';
    return CardType.fromString(card).displayName;
  }

  String cardDescription(String? card) {
    if (card == null) return '';
    return CardType.fromString(card).description;
  }

  IconData cardIcon(String? card) {
    if (card == null) return Icons.style_rounded;
    return CardType.fromString(card).icon;
  }

  Color cardColor(String? card) {
    if (card == null) return const Color(0xFFA44A3F);
    return CardType.fromString(card).color;
  }

  TextSpan richMessage(
    String actor,
    String? target,
    String? task,
    String? card,
    TextStyle base, {
    int? kudosValue,
  }) {
    final bold = base.copyWith(fontWeight: FontWeight.w700);
    TextSpan b(String text) => TextSpan(text: text, style: bold);
    TextSpan n(String text) => TextSpan(text: text, style: base);

    List<InlineSpan> cardPlayedSpans() {
      final cardName = formatCard(card);
      final isSteal = card == 'STEAL_KUDOS';
      final spans = <InlineSpan>[b(actor), n(' ha usado la carta '), b('"$cardName"')];
      if (target != null && isSteal && kudosValue != null) {
        spans.addAll([n(' y ha robado '), b('$kudosValue kudos'), n(' a '), b(target)]);
      } else if (target != null && task != null) {
        spans.addAll([n(' sobre '), b(target), n(' y la tarea es: '), b('"$task"')]);
      } else if (target != null) {
        spans.addAll([n(' a '), b(target)]);
      } else if (task != null) {
        spans.addAll([n(' en la tarea '), b('"$task"')]);
      }
      return spans;
    }

    final spans = switch (this) {
      ActivityLogType.taskCompleted    => [
          b(actor), n(' ha completado la tarea '), b('"${task ?? ''}"'),
          if (kudosValue != null) ...[n(' que vale '), b('$kudosValue kudos')],
        ],
      ActivityLogType.taskApproved     => [
          b(actor), n(' ha aceptado la tarea '), b('"${task ?? ''}"'), n(' de '), b(target ?? ''),
          if (kudosValue != null) ...[n(' y ha ganado '), b('$kudosValue kudos')],
          n('\n'),b(actor), n(' ha recibido '), b('1 kudos'), n(' por ser el primero en validar'),
        ],
      ActivityLogType.taskDisputed     => [b(actor), n(' ha disputado la tarea '), b('"${task ?? ''}"'), n(' de '), b(target ?? '')],
      ActivityLogType.taskAutoApproved => [
          n('La tarea '), b('"${task ?? ''}"'), n(' de '), b(actor), n(' fue auto-aprobada'),
          if (kudosValue != null) ...[n(' y ha ganado '), b('$kudosValue kudos')],
        ],
      ActivityLogType.taskAssigned     => [b(actor), n(' se ha asignado la tarea '), b(task ?? '')],
      ActivityLogType.taskUnassigned   => [b(actor), n(' se ha desasignado de '), b(task ?? '')],
      ActivityLogType.taskCreated      => [b(actor), n(' ha creado la tarea '), b(task ?? '')],
      ActivityLogType.taskDeleted      => [b(actor), n(' ha eliminado la tarea '), b(task ?? '')],
      ActivityLogType.cardPlayed       => cardPlayedSpans(),
      ActivityLogType.cardPurchased    => [b(actor), n(' ha comprado un sobre de cartas')],
      ActivityLogType.memberJoined     => [n('Bienvenido '), b(actor), n(' a la casa')],
      ActivityLogType.memberLeft       => [b(actor), n(' ha abandonado la casa')],
      ActivityLogType.memberKicked     => [b(actor), n(' ha sido expulsado de la casa')],
      ActivityLogType.captainTransferred=> [b(actor), n(' ha sido nombrado capitán de la casa')],
      ActivityLogType.unknown          => card != null
          ? cardPlayedSpans()
          : [b(actor), n(' realizó una acción desconocida')],
    };

    return TextSpan(children: spans);
  }

  Color cardBackground(String? cardTypeStr) {
    if (this == ActivityLogType.unknown && cardTypeStr != null) {
      return const Color(0xFFFEF9EC);
    }
    return switch (this) {
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
      ActivityLogType.memberJoined      => const Color(0xFFEDF7F5),
      ActivityLogType.memberLeft        => const Color(0xFFF5F5F5),
      ActivityLogType.memberKicked      => const Color(0xFFFDF0F0),
      ActivityLogType.captainTransferred=> const Color(0xFFFFF8E1),
      ActivityLogType.unknown           => const Color(0xFFFFFFFF),
    };
  }

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
    ActivityLogType.memberKicked     => Icons.cancel_rounded,
    ActivityLogType.captainTransferred=> Icons.star_rounded,
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
    ActivityLogType.memberKicked     => const Color(0xFFBE6363),
    ActivityLogType.captainTransferred=> const Color(0xFF00916E),
    ActivityLogType.unknown          => const Color(0xFFAA9E9B),
  };
}
