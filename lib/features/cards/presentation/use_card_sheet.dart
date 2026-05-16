import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/data/auth_controller.dart';
import '../../auth/domain/auth_models.dart';
import '../../auth/domain/task_models.dart';
import '../../house/data/house_repository.dart';
import '../../tasks/data/task_repository.dart';
import '../../tasks/presentation/category_controller.dart';
import '../../auth/domain/category_model.dart';
import '../domain/card_model.dart';
import 'card_controller.dart';

Future<bool> showUseCardSheet(
  BuildContext context,
  WidgetRef ref,
  CardModel card,
) async {
  if (!card.type.requiresTargetUser &&
      !card.type.requiresTargetTask &&
      !card.type.requiresTargetCategory) {
    return _useCardDirect(context, ref, card);
  }

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _UseCardSheet(card: card),
  );
  return result ?? false;
}

Future<bool> _useCardDirect(
  BuildContext context,
  WidgetRef ref,
  CardModel card,
) async {
  try {
    await ref.read(cardControllerProvider.notifier).useCard(card.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✓ ${card.type.displayName} activada'),
        backgroundColor: AppColors.success,
      ));
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppColors.error,
      ));
    }
    return false;
  }
}

class _UseCardSheet extends ConsumerStatefulWidget {
  const _UseCardSheet({required this.card});
  final CardModel card;

  @override
  ConsumerState<_UseCardSheet> createState() => _UseCardSheetState();
}

class _UseCardSheetState extends ConsumerState<_UseCardSheet> {
  UserSession? _selectedUser;
  TaskModel?   _selectedTask;
  CategoryModel? _selectedCategory;
  bool _loading = false;

  List<UserSession>?   _members;
  List<TaskModel>?     _tasks;
  List<CategoryModel>? _categories;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final currentUserId = ref.read(authControllerProvider).valueOrNull?.id;

      if (widget.card.type.requiresTargetUser ||
          widget.card.type.requiresTargetTask && widget.card.type == CardType.forceTask) {
        final members = await ref.read(houseRepositoryProvider).getMembers();
        _members = members.where((m) => m.id != currentUserId).toList();
      }

      if (widget.card.type.requiresTargetTask) {
        final allTasks = await ref.read(taskRepositoryProvider).getActiveTasks();
        _tasks = switch (widget.card.type) {
          CardType.forceTask      => allTasks.where((t) => t.status == TaskStatus.open).toList(),
          CardType.skipTask       => allTasks.where((t) =>
              t.status == TaskStatus.assigned && t.assignedTo == currentUserId).toList(),
          CardType.valueInflation => allTasks.where((t) => t.status == TaskStatus.open).toList(),
          CardType.cleanSlate     => allTasks.where((t) =>
              t.isForced && t.assignedTo == currentUserId).toList(),
          _ => allTasks,
        };
      }

      if (widget.card.type.requiresTargetCategory) {
        _categories = ref.read(categoryControllerProvider).valueOrNull;
        _categories ??= await ref.read(categoryControllerProvider.notifier).build();
      }

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    }
  }

  bool get _canConfirm {
    if (widget.card.type.requiresTargetUser && _selectedUser == null) return false;
    if (widget.card.type.requiresTargetTask && _selectedTask == null) return false;
    if (widget.card.type.requiresTargetCategory && _selectedCategory == null) return false;
    return true;
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      await ref.read(cardControllerProvider.notifier).useCard(
        widget.card.id,
        targetUserId:     _selectedUser?.id,
        targetTaskId:     _selectedTask?.id,
        targetCategoryId: _selectedCategory?.id,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: card.type.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(card.type.icon, color: card.type.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(card.type.displayName, style: AppTextStyles.h2),
                        Text(card.type.description,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: _loadError != null
                  ? Center(
                      child: Text('Error al cargar datos',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.error)))
                  : (_members == null &&
                          _tasks == null &&
                          _categories == null &&
                          widget.card.type.requiresTargetUser ||
                      widget.card.type.requiresTargetTask ||
                      widget.card.type.requiresTargetCategory)
                      ? _buildLoadingOrContent(scrollCtrl)
                      : _buildLoadingOrContent(scrollCtrl),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_canConfirm && !_loading) ? _confirm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.border,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text('Usar carta', style: AppTextStyles.labelLarge
                            .copyWith(color: Colors.white)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOrContent(ScrollController scrollCtrl) {
    final isReady = (widget.card.type.requiresTargetUser ? _members != null : true) &&
        (widget.card.type.requiresTargetTask ? _tasks != null : true) &&
        (widget.card.type.requiresTargetCategory ? _categories != null : true);

    if (!isReady) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      children: [
        if (widget.card.type.requiresTargetUser && _members != null) ...[
          _SectionLabel(
            icon: Icons.person_rounded,
            label: widget.card.type == CardType.forceTask
                ? 'Selecciona a quién asignar la tarea'
                : 'Selecciona el objetivo',
          ),
          ..._members!.map((m) => _UserTile(
                member: m,
                selected: _selectedUser?.id == m.id,
                onTap: () => setState(() => _selectedUser = m),
              )),
          const SizedBox(height: 16),
        ],
        if (widget.card.type.requiresTargetTask && _tasks != null) ...[
          _SectionLabel(
            icon: Icons.task_alt_rounded,
            label: switch (widget.card.type) {
              CardType.skipTask       => 'Selecciona tu tarea asignada',
              CardType.valueInflation => 'Selecciona la tarea a inflar',
              CardType.cleanSlate     => 'Selecciona la tarea forzada a liberar',
              _                       => 'Selecciona la tarea',
            },
          ),
          if (_tasks!.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                switch (widget.card.type) {
                  CardType.skipTask   => 'No tienes tareas asignadas.',
                  CardType.cleanSlate => 'No tienes tareas forzadas. Esta carta no puede usarse ahora.',
                  _                   => 'No hay tareas disponibles.',
                },
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textHint),
              ),
            )
          else
            ..._tasks!.map((t) => _TaskTile(
                  task: t,
                  selected: _selectedTask?.id == t.id,
                  onTap: () => setState(() => _selectedTask = t),
                )),
          const SizedBox(height: 16),
        ],
        if (widget.card.type.requiresTargetCategory && _categories != null) ...[
          const _SectionLabel(
            icon: Icons.category_rounded,
            label: 'Selecciona la categoría',
          ),
          if (_categories!.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No hay categorías.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textHint)),
            )
          else
            ..._categories!.map((c) => _CategoryTile(
                  category: c,
                  selected: _selectedCategory?.id == c.id,
                  onTap: () => setState(() => _selectedCategory = c),
                )),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.primary)),
          ],
        ),
      );
}

class _UserTile extends StatelessWidget {
  const _UserTile(
      {required this.member, required this.selected, required this.onTap});
  final UserSession member;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                member.username.substring(0, 1).toUpperCase(),
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.username, style: AppTextStyles.labelLarge),
                  Text('${member.kudosBalance} Kudos',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textHint)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile(
      {required this.task, required this.selected, required this.onTap});
  final TaskModel task;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(task.title, style: AppTextStyles.labelLarge),
                      ),
                      if (task.isForced)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.push_pin_rounded, size: 10, color: AppColors.accent),
                              const SizedBox(width: 3),
                              Text('Forzada',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.accent,
                                    fontSize: 10,
                                  )),
                            ],
                          ),
                        ),
                    ],
                  ),
                  Text('${task.kudosValue} Kudos · ${task.category.name}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textHint)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile(
      {required this.category, required this.selected, required this.onTap});
  final CategoryModel category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.category_rounded,
                size: 18, color: AppColors.textHint),
            const SizedBox(width: 12),
            Expanded(
              child: Text(category.name, style: AppTextStyles.labelLarge),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

