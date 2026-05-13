import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/data/auth_controller.dart';
import '../../tasks/presentation/task_controller.dart';
import '../domain/activity_model.dart';
import 'activity_controller.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(activityControllerProvider);
    final userSession = ref.watch(authControllerProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Actividad', style: AppTextStyles.h1),
      ),
      body: activityAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Text(
                'No hay actividad reciente',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
              ),
            );
          }

          final reversed = entries.reversed.toList();
          final grouped = _groupByDay(reversed);
          final days = grouped.keys.toList();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(activityControllerProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: days.length,
              itemBuilder: (context, i) {
                final day = days[i];
                final dayEntries = grouped[day]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DayHeader(day: day),
                    ...dayEntries.map((e) => _ActivityTile(
                      entry: e,
                      currentUserId: userSession?.id,
                    )),
                  ],
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error al cargar actividad', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.read(activityControllerProvider.notifier).refresh(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, List<ActivityModel>> _groupByDay(List<ActivityModel> entries) {
    final map = <String, List<ActivityModel>>{};
    final now = DateTime.now();
    for (final e in entries) {
      final date = e.createdAt.toLocal();
      String key;
      if (_isSameDay(date, now)) {
        key = 'HOY';
      } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
        key = 'AYER';
      } else {
        key = DateFormat('d MMM', 'es').format(date).toUpperCase();
      }
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});
  final String day;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Row(
        children: [
          Text(
            day,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textHint,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Divider(color: AppColors.border, height: 1),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends ConsumerWidget {
  const _ActivityTile({required this.entry, required this.currentUserId});
  final ActivityModel entry;
  final int? currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = entry.type;
    final message = type.message(
      entry.actorUsername,
      entry.targetUsername,
      entry.taskTitle,
      entry.cardType,
    );
    final time = DateFormat('HH:mm').format(entry.createdAt.toLocal());
    final initials = _initials(entry.actorUsername);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _avatarColor(entry.actorUsername),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: AppTextStyles.labelMedium.copyWith(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (entry.taskTitle != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  entry.taskTitle!,
                                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                                ),
                              ),
                              if (_showKudos(type))
                                Row(
                                  children: [
                                    const Icon(Icons.stars_rounded, color: AppColors.accentLight, size: 14),
                                    const SizedBox(width: 2),
                                    Text(
                                      _kudosLabel(type),
                                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.accentLight),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      Text(message, style: AppTextStyles.bodySmall),
                      if (entry.isPendingReview) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.hourglass_top_rounded, size: 12, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text(
                              'Pendiente de revisión',
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.warning),
                            ),
                          ],
                        ),
                      ],
                      if (entry.isPendingReview && entry.actorUserId != currentUserId) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.thumb_down_rounded, size: 14),
                                label: const Text('Disputar'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(color: AppColors.error),
                                  minimumSize: const Size(0, 36),
                                  textStyle: AppTextStyles.labelMedium,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                onPressed: () async {
                                  if (entry.taskId != null) {
                                    await ref.read(taskControllerProvider.notifier)
                                        .validateTask(entry.taskId!, 'DISPUTE');
                                    ref.read(activityControllerProvider.notifier).refresh();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.thumb_up_rounded, size: 14),
                                label: const Text('Aprobar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  minimumSize: const Size(0, 36),
                                  textStyle: AppTextStyles.labelMedium,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                onPressed: () async {
                                  if (entry.taskId != null) {
                                    await ref.read(taskControllerProvider.notifier)
                                        .validateTask(entry.taskId!, 'APPROVE');
                                    ref.read(activityControllerProvider.notifier).refresh();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: Text(
                            'Pendiente de validación',
                            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, bottom: 4),
                  child: Text(
                    time,
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _showKudos(ActivityLogType type) => type == ActivityLogType.taskCompleted ||
      type == ActivityLogType.taskApproved ||
      type == ActivityLogType.taskAutoApproved;

  String _kudosLabel(ActivityLogType type) => switch (type) {
    ActivityLogType.taskCompleted    => '+kudos',
    ActivityLogType.taskApproved     => '+kudos',
    ActivityLogType.taskAutoApproved => '+kudos',
    _ => '',
  };

  String _initials(String username) {
    final parts = username.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return username.substring(0, username.length.clamp(0, 2)).toUpperCase();
  }

  Color _avatarColor(String username) {
    final colors = [
      const Color(0xFF00916E),
      const Color(0xFFA44A3F),
      const Color(0xFF4A6FA5),
      const Color(0xFF6B5E5B),
      const Color(0xFFBE7E63),
      const Color(0xFF5C7A3E),
      const Color(0xFF7B5EA7),
    ];
    final hash = username.codeUnits.fold(0, (a, b) => a + b);
    return colors[hash % colors.length];
  }
}
