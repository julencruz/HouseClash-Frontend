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

/// Badge de Kudos estandarizado. Úsalo en AppBar actions o headers.
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
