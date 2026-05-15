import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class HouseClashAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HouseClashAppBar({
    super.key,
    required this.title,
    this.kudos,
    this.actions,
  });

  final String title;
  final int? kudos;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        if (kudos != null) ...[
          KudosBadge(kudos: kudos!),
          const SizedBox(width: 16),
        ],
        ...?actions,
      ],
    );
  }
}

class KudosBadge extends StatelessWidget {
  const KudosBadge({super.key, required this.kudos});
  final int kudos;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentLight.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, color: AppColors.accentLight, size: 18),
          const SizedBox(width: 4),
          Text(
            '$kudos Kudos',
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.accentLight),
          ),
        ],
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.username,
    this.size = 40,
  });

  final String username;
  final double size;

  static const _colors = [
    AppColors.primary,
    AppColors.accent,
    AppColors.gold,
    AppColors.silver,
    AppColors.bronze,
  ];

  Color get _color {
    if (username.isEmpty) return AppColors.primary;
    final hash = username.codeUnits.fold(0, (a, b) => a + b);
    return _colors[hash % _colors.length];
  }

  String get _initials {
    final parts = username.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return username.substring(0, username.length.clamp(1, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = size * 0.36;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: _color.withValues(alpha: 0.45), width: size >= 60 ? 2 : 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: AppTextStyles.labelMedium.copyWith(
          color: _color,
          fontSize: fontSize,
          height: 1,
        ),
      ),
    );
  }
}
