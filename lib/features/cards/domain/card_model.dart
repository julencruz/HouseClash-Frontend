import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum CardType {
  houseBonus,
  marketBoost,
  fastTrack,
  underdogBoost,
  categoryBoost,
  cleanSlate,
  skipTask,
  valueInflation,
  forceTask,
  stealKudos,
  unknown;

  static CardType fromString(String value) => switch (value) {
    'HOUSE_BONUS'      => CardType.houseBonus,
    'MARKET_BOOST'     => CardType.marketBoost,
    'FAST_TRACK'       => CardType.fastTrack,
    'UNDERDOG_BOOST'   => CardType.underdogBoost,
    'CATEGORY_BOOST'   => CardType.categoryBoost,
    'CLEAN_SLATE'      => CardType.cleanSlate,
    'SKIP_TASK'        => CardType.skipTask,
    'VALUE_INFLATION'  => CardType.valueInflation,
    'FORCE_TASK'       => CardType.forceTask,
    'STEAL_KUDOS'      => CardType.stealKudos,
    _                  => CardType.unknown,
  };

  String get displayName => switch (this) {
    CardType.houseBonus     => 'Bonus de casa',
    CardType.marketBoost    => 'Boost de mercado',
    CardType.fastTrack      => 'Fast Pass',
    CardType.underdogBoost  => 'Mejora la peor',
    CardType.categoryBoost  => 'Boost de categoria',
    CardType.cleanSlate     => 'Borrón y cuenta nueva',
    CardType.skipTask       => 'Saltar tarea',
    CardType.valueInflation => 'Duplica kudos',
    CardType.forceTask      => 'Forzar tarea',
    CardType.stealKudos     => 'Robar kudos',
    CardType.unknown        => 'Carta Desconocida',
  };

  String get description => switch (this) {
    CardType.houseBonus     => 'Añade +2 Kudos a todos los miembros de la casa.',
    CardType.marketBoost    => 'Añade +1 Kudos a todas las tareas disponibles.',
    CardType.fastTrack      => 'Aprueba automáticamente todas las tareas en revisión.',
    CardType.underdogBoost  => 'Añade +3 Kudos a la tarea disponible de menor valor.',
    CardType.categoryBoost  => 'Añade +1 Kudos a todas las tareas de una categoría.',
    CardType.cleanSlate     => 'Devuelve una de tus tareas forzadas al mercado.',
    CardType.skipTask       => 'Devuelve una tarea al mercado sin penalización de Kudos.',
    CardType.valueInflation => 'Duplica el valor en Kudos de una tarea disponible.',
    CardType.forceTask      => 'Asigna forzosamente una tarea a otro miembro.',
    CardType.stealKudos     => 'Roba Kudos de otro miembro de la casa.',
    CardType.unknown        => 'Efecto desconocido.',
  };

  String get category => switch (this) {
    CardType.houseBonus     => 'Colaborativa',
    CardType.marketBoost    => 'Colaborativa',
    CardType.fastTrack      => 'Colaborativa',
    CardType.underdogBoost  => 'Colaborativa',
    CardType.categoryBoost  => 'Colaborativa',
    CardType.cleanSlate     => 'Ventaja',
    CardType.skipTask       => 'Ventaja',
    CardType.valueInflation => 'Ventaja',
    CardType.forceTask      => 'Ofensiva',
    CardType.stealKudos     => 'Ofensiva',
    CardType.unknown        => '?',
  };

  IconData get icon => switch (this) {
    CardType.houseBonus     => Icons.home_rounded,
    CardType.marketBoost    => Icons.trending_up_rounded,
    CardType.fastTrack      => Icons.fast_forward_rounded,
    CardType.underdogBoost  => Icons.volunteer_activism_rounded,
    CardType.categoryBoost  => Icons.category_rounded,
    CardType.cleanSlate     => Icons.cleaning_services_rounded,
    CardType.skipTask       => Icons.skip_next_rounded,
    CardType.valueInflation => Icons.price_change_rounded,
    CardType.forceTask      => Icons.push_pin_rounded,
    CardType.stealKudos     => Icons.content_cut_rounded,
    CardType.unknown        => Icons.help_outline_rounded,
  };

  Color get color => switch (this) {
    CardType.houseBonus     => AppColors.primary,
    CardType.marketBoost    => AppColors.primary,
    CardType.fastTrack      => AppColors.success,
    CardType.underdogBoost  => AppColors.primaryLight,
    CardType.categoryBoost  => AppColors.primaryDark,
    CardType.cleanSlate     => AppColors.warning,
    CardType.skipTask       => AppColors.warning,
    CardType.valueInflation => Color(0xFF4A90D9),
    CardType.forceTask      => AppColors.accent,
    CardType.stealKudos     => AppColors.accent,
    CardType.unknown        => AppColors.textHint,
  };

  bool get requiresTargetUser => switch (this) {
    CardType.forceTask  => true,
    CardType.stealKudos => true,
    _                   => false,
  };

  bool get requiresTargetTask => switch (this) {
    CardType.forceTask      => true,
    CardType.skipTask       => true,
    CardType.valueInflation => true,
    CardType.cleanSlate     => true,
    _                       => false,
  };

  bool get requiresTargetCategory => this == CardType.categoryBoost;
}

class CardModel {
  final int id;
  final int userId;
  final CardType type;
  final DateTime acquiredAt;

  const CardModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.acquiredAt,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) => CardModel(
    id:         json['id'] as int,
    userId:     json['userId'] as int,
    type:       CardType.fromString(json['type'] as String),
    acquiredAt: DateTime.parse(json['acquiredAt'] as String),
  );
}
