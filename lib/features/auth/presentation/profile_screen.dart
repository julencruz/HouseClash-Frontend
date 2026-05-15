import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_widgets.dart';
import '../data/auth_controller.dart';
import '../domain/auth_models.dart';
import 'profile_edit_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authControllerProvider);
    final kudos = userAsync.valueOrNull?.kudosBalance ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: HouseClashAppBar(
        title: 'Perfil',
        kudos: kudos,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Editar perfil',
            onPressed: userAsync.valueOrNull != null
                ? () => showProfileEditSheet(context, ref, userAsync.value!)
                : null,
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => _ErrorView(
          onRetry: () => ref.read(authControllerProvider.notifier).refreshProfile(),
        ),
        data: (user) => user == null
            ? _ErrorView(
                onRetry: () => ref.read(authControllerProvider.notifier).refreshProfile(),
              )
            : _ProfileBody(user: user),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.user});

  final UserSession user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(authControllerProvider.notifier).refreshProfile(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
        children: [
          _AvatarSection(user: user),
          const SizedBox(height: 32),
          _StatCardWide(
            label: 'Total de Kudos ganados',
            value: _formatStat(user.totalKudosEarned),
            icon: Icons.stars_rounded,
            color: AppColors.accentLight,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCardSquare(
                  label: 'Tareas\ncompletadas',
                  value: _formatStat(user.totalTasksCompleted),
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCardSquare(
                  label: 'Cartas\njugadas',
                  value: _formatStat(user.totalCardsPlayed),
                  icon: Icons.style_rounded,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StatCardWide(
            label: 'Kudos actuales',
            value: _formatStat(user.kudosBalance),
            icon: Icons.account_balance_wallet_rounded,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  static String _formatStat(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({required this.user});

  final UserSession user;

  static const _avatarColors = [
    AppColors.primary,
    AppColors.accent,
    AppColors.gold,
    AppColors.silver,
    AppColors.bronze,
  ];

  Color get _color => user.username.isEmpty
      ? AppColors.primary
      : _avatarColors[user.username.codeUnitAt(0) % _avatarColors.length];

  String get _initials {
    final parts = user.username.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return user.username.length >= 2
        ? user.username.substring(0, 2).toUpperCase()
        : user.username.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: _color.withValues(alpha: 0.35), width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            _initials,
            style: AppTextStyles.h1.copyWith(color: _color, fontSize: 32),
          ),
        ),
        const SizedBox(height: 16),
        Text(user.username, style: AppTextStyles.h2),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _StatCardWide extends StatelessWidget {
  const _StatCardWide({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: AppTextStyles.h1.copyWith(
                    color: color,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: color.withValues(alpha: 0.18), size: 60),
        ],
      ),
    );
  }
}

class _StatCardSquare extends StatelessWidget {
  const _StatCardSquare({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(fontSize: 28),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text('Error al cargar el perfil', style: AppTextStyles.bodyMedium),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ],
      ),
    );
  }
}

