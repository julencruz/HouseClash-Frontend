import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/house_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/data/auth_controller.dart';
import '../../auth/domain/task_models.dart';
import 'create_task_sheet.dart' show EditTaskSheet;
import 'task_controller.dart';
import 'tasks_screen.dart' show getCategoryDisplayName;

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskControllerProvider).valueOrNull;
    final current = tasks?.firstWhere((t) => t.id == task.id, orElse: () => task) ?? task;

    final userSession = ref.watch(authControllerProvider).valueOrNull;
    final currentUserId = userSession?.id;
    final houseSession = ref.watch(houseStorageProvider).valueOrNull;
    final isCaptain = currentUserId != null && houseSession != null &&
        houseSession.isCaptain(currentUserId);
    final isMyTask = current.assignedTo == currentUserId;
    final status = current.status;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Mantenemos la acción de editar en la parte superior
          if (isCaptain || (isMyTask && status == TaskStatus.assigned))
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: AppColors.textPrimary),
              tooltip: 'Editar tarea',
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => EditTaskSheet(task: current),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Título centrado ───────────────────────────
            Text(
              current.title,
              style: AppTextStyles.displayLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // ── Chips: categoría + kudos (estilo estándar) ──
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                // Categoría — estilo surface igual que en el card de tarea
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.category_rounded, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 5),
                      Text(
                        getCategoryDisplayName(current.category.name),
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Kudos — mismo estilo que KudosBadge en AppBar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars_rounded, size: 14, color: AppColors.accentLight),
                      const SizedBox(width: 5),
                      Text(
                        '${current.kudosValue} Kudos',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.accentLight),
                      ),
                    ],
                  ),
                ),
                // Esfuerzo
                _SecondaryChip(
                  icon: switch (current.effort) {
                    Effort.low    => Icons.battery_1_bar_rounded,
                    Effort.medium => Icons.battery_4_bar_rounded,
                    Effort.high   => Icons.battery_full_rounded,
                  },
                  label: switch (current.effort) {
                    Effort.low    => 'Esfuerzo bajo',
                    Effort.medium => 'Esfuerzo medio',
                    Effort.high   => 'Esfuerzo alto',
                  },
                  color: switch (current.effort) {
                    Effort.low    => AppColors.success,
                    Effort.medium => AppColors.warning,
                    Effort.high   => AppColors.error,
                  },
                ),
                if (current.isForced)
                  _SecondaryChip(
                    icon: Icons.push_pin_rounded,
                    label: 'Forzada',
                    color: AppColors.accent,
                  ),
                if (current.recurrence != null)
                  _SecondaryChip(
                    icon: Icons.repeat_rounded,
                    label: _recurrenceLabel(current.recurrence!),
                    color: AppColors.primary,
                  ),
              ],
            ),

            // ── Deadline centrado ──────────────────────────
            if (current.deadline != null) ...[
              const SizedBox(height: 14),
              _DeadlineBanner(deadline: current.deadline!),
            ],

            const SizedBox(height: 20),

            // ── Estado ────────────────────────────────────
            _StatusRow(status: status),

            // ── Tarjeta de Detalles ───────────────────────
            if (current.description != null && current.description!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
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
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Detalles de la Tarea',
                          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      current.description!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // ── Acciones ──────────────────────────────────
            _ActionButtons(
              task: current,
              isMyTask: isMyTask,
              isCaptain: isCaptain,
              currentUserId: currentUserId,
            ),
          ],
        ),
      ),
    );
  }

  String _recurrenceLabel(String r) => switch (r) {
    'DAILY'     => 'Diaria',
    'WEEKLY'    => 'Semanal',
    'BIWEEKLY'  => 'Quincenal',
    'MONTHLY'   => 'Mensual',
    _           => r,
  };
}

// ── Chip secundario ────────────────────────────────────────
class _SecondaryChip extends StatelessWidget {
  const _SecondaryChip({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}

// ── Banner de deadline (centrado) ─────────────────────────
class _DeadlineBanner extends StatelessWidget {
  const _DeadlineBanner({required this.deadline});
  final DateTime deadline;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isOverdue = deadline.isBefore(now);
    final diff = deadline.difference(now);
    final isUrgent = !isOverdue && diff.inHours < 24;
    final color = isOverdue
        ? AppColors.error
        : isUrgent
            ? AppColors.warning
            : AppColors.textSecondary;
    final formatted = DateFormat('d MMM yyyy · HH:mm', 'es').format(deadline.toLocal());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            isOverdue ? 'Expiró: $formatted' : 'Límite: $formatted',
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// ── Estado ─────────────────────────────────────────────────
class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.status});
  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      TaskStatus.open          => ('Disponible',            AppColors.textHint, Icons.radio_button_unchecked),
      TaskStatus.assigned      => ('Asignada',              AppColors.primary,  Icons.person_rounded),
      TaskStatus.pendingReview => ('Pendiente de revisión', AppColors.warning,  Icons.hourglass_top_rounded),
      TaskStatus.approved      => ('Aprobada ✓',            AppColors.success,  Icons.check_circle_rounded),
      TaskStatus.autoApproved  => ('Auto-aprobada ✓',       AppColors.success,  Icons.check_circle_outline_rounded),
      TaskStatus.disputed      => ('Disputada',             AppColors.error,    Icons.error_rounded),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.labelMedium.copyWith(color: color)),
      ],
    );
  }
}

// ── Botones de acción ──────────────────────────────────────
class _ActionButtons extends ConsumerWidget {
  const _ActionButtons({
    required this.task,
    required this.isMyTask,
    required this.isCaptain,
    required this.currentUserId,
  });

  final TaskModel task;
  final bool isMyTask;
  final bool isCaptain;
  final int? currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(taskControllerProvider.notifier);
    final status = task.status;
    final buttons = <Widget>[];

    // ── OPEN: asignar ─────────────────────────────────────
    if (status == TaskStatus.open) {
      buttons.add(_PrimaryButton(
        icon: Icons.person_add_rounded,
        label: 'Asígnatela',
        color: AppColors.primary,
        onPressed: () async {
          await notifier.assignTask(task.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('"${task.title}" asignada!'),
              backgroundColor: AppColors.primary,
            ));
          }
        },
      ));
    }

    // ── ASSIGNED / DISPUTED (mía) ─────────────────────────
    if ((status == TaskStatus.assigned || status == TaskStatus.disputed) && isMyTask) {
      if (task.isForced) {
        buttons.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            const Icon(Icons.push_pin_rounded, size: 13, color: AppColors.accent),
            const SizedBox(width: 6),
            Expanded(child: Text(
              'Tarea forzada. Necesitas una carta para desasignarte.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.accent),
            )),
          ]),
        ));
      }
      if (status == TaskStatus.disputed) {
        buttons.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, size: 13, color: AppColors.warning),
            const SizedBox(width: 6),
            Expanded(child: Text(
              'La tarea fue disputada. Puedes volver a completarla.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
            )),
          ]),
        ));
      }
      buttons.add(Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: Icon(task.isForced ? Icons.push_pin_rounded : Icons.undo_rounded, size: 16),
            label: const Text('Desasignar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: task.isForced ? AppColors.textDisabled : AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
              minimumSize: const Size(0, 48),
              textStyle: AppTextStyles.labelMedium,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: task.isForced ? null : () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Desasignar tarea'),
                  content: const Text('Si te desasignas perderás 3 kudos.\n\n¿Estás seguro?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Desasignar (-3 kudos)'),
                    ),
                  ],
                ),
              );
              if (confirm != true) return;
              notifier.unassignTask(task.id);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Completar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              textStyle: AppTextStyles.labelMedium,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => notifier.completeTask(task.id),
          ),
        ),
      ]));
    }

    // ── PENDING REVIEW (no mía) ────────────────────────────
    if (status == TaskStatus.pendingReview && !isMyTask) {
      buttons.add(Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.thumb_down_rounded, size: 16),
            label: const Text('Disputar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size(0, 48),
              textStyle: AppTextStyles.labelMedium,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => notifier.validateTask(task.id, 'DISPUTE'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.thumb_up_rounded, size: 16),
            label: const Text('Aprobar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              textStyle: AppTextStyles.labelMedium,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => notifier.validateTask(task.id, 'APPROVE'),
          ),
        ),
      ]));
    }

    // ── PENDING REVIEW (mía) ──────────────────────────────
    if (status == TaskStatus.pendingReview && isMyTask) {
      buttons.add(Row(children: [
        const Icon(Icons.hourglass_top_rounded, size: 14, color: AppColors.warning),
        const SizedBox(width: 6),
        Text('Esperando que alguien valide esta tarea...',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
      ]));
    }

    // ── Eliminar (capitán) ────────────────────────────────
    if (isCaptain) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(height: 12));
      buttons.add(_PrimaryButton(
        icon: Icons.delete_outline_rounded,
        label: 'Eliminar tarea',
        color: AppColors.error,
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('¿Eliminar tarea?'),
              content: Text('¿Estás seguro de que quieres eliminar "${task.title}"?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Eliminar'),
                ),
              ],
            ),
          );
          if (confirm != true || !context.mounted) return;
          await notifier.deleteTask(task.id);
          if (context.mounted) Navigator.of(context).pop();
        },
      ));
    }

    if (buttons.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: buttons);
  }
}

// ── Botón primario reutilizable ────────────────────────────
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 50),
          textStyle: AppTextStyles.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: onPressed,
      ),
    );
  }
}