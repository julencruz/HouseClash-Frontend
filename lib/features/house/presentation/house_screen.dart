import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/auth/house_storage.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_widgets.dart';
import '../../auth/data/auth_controller.dart';
import '../domain/house_models.dart';
import 'house_details_controller.dart';
import 'house_edit_sheet.dart';
import 'ranking_controller.dart';

class HouseScreen extends ConsumerStatefulWidget {
  const HouseScreen({super.key});

  @override
  ConsumerState<HouseScreen> createState() => _HouseScreenState();
}

class _HouseScreenState extends ConsumerState<HouseScreen> {
  _RankingTab _activeTab = _RankingTab.kudos;

  Future<void> _confirmLeaveHouse() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Salir de la casa', style: AppTextStyles.h3),
        content: Text(
          '¿Seguro que quieres abandonar la casa?\nPerderás el acceso a todas las tareas y datos.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Salir', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await ref.read(houseDetailsControllerProvider.notifier).leaveHouse();
      if (mounted) context.go(AppRoutes.joinOrCreateHouse);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            e.toString().contains('owner') || e.toString().contains('403')
                ? 'El capitán debe transferir la capitanía antes de salir.'
                : 'Error al salir: $e',
          ),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final houseAsync = ref.watch(houseDetailsControllerProvider);
    final rankingAsync = ref.watch(rankingControllerProvider);
    final userAsync = ref.watch(authControllerProvider);
    final kudos = userAsync.valueOrNull?.kudosBalance ?? 0;
    final currentUserId = userAsync.valueOrNull?.id ?? 0;
    final isCaptain =
        ref.watch(houseStorageProvider).valueOrNull?.isCaptain(currentUserId) ??
            false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: houseAsync.when(
        data: (details) => HouseClashAppBar(
          title: details.house.name,
          kudos: kudos,
          actions: [
            if (isCaptain)
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'Gestionar casa',
                onPressed: () => showHouseEditSheet(
                  context,
                  ref,
                  house: details.house,
                  members: details.members,
                  currentUserId: currentUserId,
                ),
              ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Salir de la casa',
              color: AppColors.error,
              onPressed: _confirmLeaveHouse,
            ),
          ],
        ),
        loading: () => HouseClashAppBar(title: '', kudos: kudos),
        error: (_, __) => HouseClashAppBar(title: '', kudos: kudos),
      ),
      body: houseAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text('Error al cargar la casa', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.read(houseDetailsControllerProvider.notifier).refresh(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (details) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await ref.read(houseDetailsControllerProvider.notifier).refresh();
            await ref.read(rankingControllerProvider.notifier).refresh();
            await ref.read(authControllerProvider.notifier).refreshProfile();
          },
          child: Column(
            children: [
              if (details.house.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 16, color: AppColors.textHint),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            details.house.description,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              Padding(
                padding: EdgeInsets.fromLTRB(20, details.house.description.isNotEmpty ? 12 : 16, 20, 12),
                child: _InviteSection(
                  inviteCode: details.house.inviteCode,
                  isCaptain: isCaptain,
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _SegmentTab(
                        label: 'Los más ricos',
                        active: _activeTab == _RankingTab.kudos,
                        onTap: () =>
                            setState(() => _activeTab = _RankingTab.kudos),
                      ),
                      _SegmentTab(
                        label: 'Los más trabajadores',
                        active: _activeTab == _RankingTab.tasks,
                        onTap: () =>
                            setState(() => _activeTab = _RankingTab.tasks),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1, color: AppColors.border),

              Expanded(
                child: _buildRankingBody(
                    rankingAsync, currentUserId),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankingBody(
      AsyncValue<List<MemberStats>> rankingAsync, int currentUserId) {
    return rankingAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 40),
            const SizedBox(height: 8),
            Text('Error al cargar el ranking', style: AppTextStyles.bodyMedium),
            TextButton(
              onPressed: () =>
                  ref.read(rankingControllerProvider.notifier).refresh(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
      data: (allStats) {
        final byKudos = [...allStats]
          ..sort((a, b) => b.kudosBalance.compareTo(a.kudosBalance));
        final byTasks = [...allStats]
          ..sort((a, b) => b.tasksCompleted.compareTo(a.tasksCompleted));

        final sorted = _activeTab == _RankingTab.kudos ? byKudos : byTasks;

        if (sorted.isEmpty) {
          return Center(
            child: Text('Sin datos de ranking',
                style:
                    AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
          );
        }

        final ranked = sorted.asMap().entries
            .map((e) => MemberStats(
                  user: e.value.user,
                  kudosBalance: e.value.kudosBalance,
                  tasksCompleted: e.value.tasksCompleted,
                  rank: e.key + 1,
                ))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          itemCount: ranked.length,
          itemBuilder: (context, index) => _RankingTile(
            stats: ranked[index],
            isMe: ranked[index].user.id == currentUserId,
            showKudos: _activeTab == _RankingTab.kudos,
          ),
        );
      },
    );
  }
}

// ── Sección código de invitación ──────────────────────────────

class _InviteSection extends StatelessWidget {
  const _InviteSection({
    required this.inviteCode,
    required this.isCaptain,
  });

  final String inviteCode;
  final bool isCaptain;

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text('Código copiado',
              style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
        ]),
      ),
    );
  }

  void _share() {
    SharePlus.instance.share(ShareParams(
      text: 'Únete a mi casa en HouseClash con el código: "$inviteCode"',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Invitar compañeros', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    inviteCode,
                    style: AppTextStyles.h2.copyWith(
                        color: AppColors.primary, letterSpacing: 2),
                  ),
                ),
              ),
              if (isCaptain) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _copy(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.copy_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 14, color: AppColors.textHint),
              const SizedBox(width: 6),
              Text('El código caduca cada 72 horas',
                  style: AppTextStyles.hint.copyWith(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _share,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.share_rounded, size: 18),
              label: Text('Compartir código',
                  style:
                      AppTextStyles.labelLarge.copyWith(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Segmented tab ─────────────────────────────────────────────

enum _RankingTab { kudos, tasks }

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: active ? AppColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.shadow.withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: active
                ? AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary)
                : AppTextStyles.labelMedium.copyWith(color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// ── Ranking tile ──────────────────────────────────────────────

class _RankingTile extends StatelessWidget {
  const _RankingTile({
    required this.stats,
    required this.isMe,
    required this.showKudos,
  });

  final MemberStats stats;
  final bool isMe;
  final bool showKudos;

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return AppColors.gold;
      case 2:
        return AppColors.silver;
      case 3:
        return AppColors.bronze;
      default:
        return AppColors.worse;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = _rankColor(stats.rank);
    final value = showKudos ? stats.kudosBalance : stats.tasksCompleted;
    final label = showKudos ? 'KUDOS' : 'TAREAS';
    final username = stats.user.username;
    final initials = username.length >= 2
        ? username.substring(0, 2).toUpperCase()
        : username.toUpperCase();

    final avatarColors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.gold,
      AppColors.silver,
      AppColors.bronze,
    ];
    final avatarColor = username.isEmpty
        ? AppColors.primary
        : avatarColors[username.codeUnitAt(0) % avatarColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text('${stats.rank}',
                style: AppTextStyles.labelLarge.copyWith(color: rankColor)),
          ),
          const SizedBox(width: 10),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: avatarColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(initials,
                style: AppTextStyles.labelMedium.copyWith(color: avatarColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              username + (isMe ? ' (tú)' : ''),
              style: AppTextStyles.labelLarge,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$value',
                style: AppTextStyles.h2.copyWith(
                  color: showKudos ? AppColors.accentLight : AppColors.primary,
                ),
              ),
              Text(label,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textHint)),
            ],
          ),
        ],
      ),
    );
  }
}

