import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/house_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/data/auth_controller.dart';
import '../../auth/domain/category_model.dart';
import '../../auth/domain/task_models.dart';
import 'category_controller.dart';
import 'task_controller.dart';
import 'create_task_sheet.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  int? _selectedCategoryId;
  bool _myTasksFilter = false;

  void _showCategoryOptions(CategoryModel cat) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Editar nombre'),
              onTap: () {
                Navigator.pop(ctx);
                _editCategory(cat);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: AppColors.error),
              title: const Text('Eliminar categoría', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteCategory(cat);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editCategory(CategoryModel cat) async {
    final ctrl = TextEditingController(text: cat.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar categoría', style: AppTextStyles.h2),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != cat.name) {
      try {
        await ref.read(categoryControllerProvider.notifier).updateCategory(cat.id, newName);
        ref.read(taskControllerProvider.notifier).refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Categoría actualizada'), backgroundColor: AppColors.primary),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al actualizar'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _deleteCategory(CategoryModel cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar categoría', style: AppTextStyles.h2),
        content: Text('¿Seguro que quieres eliminar "${cat.name}"? Las tareas asociadas se quedarán sin categoría.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(categoryControllerProvider.notifier).deleteCategory(cat.id);
        if (_selectedCategoryId == cat.id) {
          setState(() => _selectedCategoryId = null);
        }
        ref.read(taskControllerProvider.notifier).refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Categoría eliminada'), backgroundColor: AppColors.textSecondary),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al eliminar'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskControllerProvider);
    final categoriesAsync = ref.watch(categoryControllerProvider);
    final userSession = ref.watch(authControllerProvider).valueOrNull;
    final houseSession = ref.watch(houseStorageProvider).valueOrNull;
    final kudos = userSession?.kudosBalance ?? 0;
    final isCaptain = userSession != null && houseSession != null
        && houseSession.isCaptain(userSession.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Tareas', style: AppTextStyles.h1),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
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
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 38,
            child: categoriesAsync.when(
              data: (categories) => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: 'Todas',
                    isSelected: _selectedCategoryId == null && !_myTasksFilter,
                    onTap: () => setState(() { _selectedCategoryId = null; _myTasksFilter = false; }),
                  ),
                  _FilterChip(
                    label: 'Mis tareas',
                    isSelected: _myTasksFilter,
                    onTap: () => setState(() { _selectedCategoryId = null; _myTasksFilter = true; }),
                  ),
                  ...categories.map((cat) {
                    final isUncategorized = cat.name.toLowerCase() == 'uncategorized';
                    return _FilterChip(
                      label: getCategoryDisplayName(cat.name),
                      isSelected: _selectedCategoryId == cat.id && !_myTasksFilter,
                      onTap: () => setState(() { _selectedCategoryId = cat.id; _myTasksFilter = false; }),
                      onLongPress: (isCaptain && !isUncategorized)
                          ? () => _showCategoryOptions(cat)
                          : null,
                    );
                  })
                ],
              ),
              loading: () => const Center(
                child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                var filtered = tasks;
                if (_myTasksFilter) {
                  filtered = tasks.where((t) => t.assignedTo == userSession?.id).toList();
                } else if (_selectedCategoryId != null) {
                  filtered = tasks.where((t) => t.category.id == _selectedCategoryId).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'Todavía no hay tareas',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref.read(taskControllerProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16, top: 10),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _TaskCard(
                        task: filtered[index],
                        currentUserId: userSession?.id,
                        isCaptain: isCaptain,
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
                    Text('Error al cargar las tareas', style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => ref.read(taskControllerProvider.notifier).refresh(),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => const CreateTaskSheet(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  const _TaskCard({
    required this.task,
    required this.currentUserId,
    required this.isCaptain,
  });

  final TaskModel task;
  final int? currentUserId;
  final bool isCaptain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMyTask = task.assignedTo == currentUserId;
    final status = task.status;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _buildDismissible(context, ref, isMyTask, status),
    );
  }

  Widget _buildDismissible(BuildContext ctx, WidgetRef ref, bool isMyTask, TaskStatus status) {
    final canAssign = status == TaskStatus.open;

    DismissDirection direction;
    if (isCaptain && canAssign) {
      direction = DismissDirection.horizontal;
    } else if (isCaptain) {
      direction = DismissDirection.startToEnd;
    } else if (canAssign) {
      direction = DismissDirection.endToStart;
    } else {
      direction = DismissDirection.none;
    }

    return Dismissible(
      key: ValueKey('task-${task.id}'),
      direction: direction,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
            SizedBox(height: 4),
            Text('Eliminar', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_add_rounded, color: Colors.white, size: 26),
            const SizedBox(height: 4),
            Text('Asignar', style: AppTextStyles.labelSmall.copyWith(color: Colors.white)),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          final confirm = await showDialog<bool>(
            context: ctx,
            builder: (dialogCtx) => AlertDialog(
              title: const Text('¿Eliminar tarea?'),
              content: Text('¿Estás seguro de que quieres eliminar "${task.title}"?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancelar')),
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, true),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Eliminar'),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await ref.read(taskControllerProvider.notifier).deleteTask(task.id);
            return true;
          }
          return false;
        } else {
          ref.read(taskControllerProvider.notifier).assignTask(task.id);
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text('"${task.title}" asignada!'),
            backgroundColor: AppColors.primary,
          ));
          return false;
        }
      },
      child: _buildCard(ctx, ref, isMyTask, status),
    );
  }

  Widget _buildCard(BuildContext ctx, WidgetRef ref, bool isMyTask, TaskStatus status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor(status)),
        boxShadow: [
          BoxShadow(color: AppColors.shadow.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  getCategoryDisplayName(task.category.name),
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.stars_rounded, color: AppColors.accentLight, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${task.kudosValue}',
                    style: AppTextStyles.h3.copyWith(color: AppColors.accentLight),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(task.title, style: AppTextStyles.h2),
          const SizedBox(height: 10),
          _StatusBadge(status: status),
          ..._buildActions(ctx, ref, isMyTask, status),
        ],
      ),
    );
  }

  Color _borderColor(TaskStatus status) => switch (status) {
    TaskStatus.open          => AppColors.border,
    TaskStatus.assigned      => AppColors.primary.withValues(alpha: 0.3),
    TaskStatus.pendingReview => AppColors.warning.withValues(alpha: 0.5),
    TaskStatus.approved      => AppColors.success.withValues(alpha: 0.4),
    TaskStatus.autoApproved  => AppColors.success.withValues(alpha: 0.4),
    TaskStatus.disputed      => AppColors.error.withValues(alpha: 0.4),
  };

  List<Widget> _buildActions(BuildContext ctx, WidgetRef ref, bool isMyTask, TaskStatus status) {
    final notifier = ref.read(taskControllerProvider.notifier);

    if ((status == TaskStatus.assigned || status == TaskStatus.disputed) && isMyTask) {
      return [
        const SizedBox(height: 12),
        if (status == TaskStatus.disputed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.warning),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'La tarea fue disputada. Puedes volver a completarla.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.undo_rounded, size: 16),
                label: const Text('Desasignar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  minimumSize: const Size(0, 38),
                  textStyle: AppTextStyles.labelMedium,
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: ctx,
                    builder: (dialogCtx) => AlertDialog(
                      title: const Text('Desasignar tarea'),
                      content: const Text(
                        'Si te desasignas de esta tarea perderás 3 kudos como penalización.\n\n¿Estás seguro?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(foregroundColor: AppColors.error),
                          onPressed: () => Navigator.of(dialogCtx).pop(true),
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
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Completar'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  textStyle: AppTextStyles.labelMedium,
                ),
                onPressed: () {
                  notifier.completeTask(task.id);
                },
              ),
            ),
          ],
        ),
      ];
    }

    if (status == TaskStatus.pendingReview && !isMyTask) {
      return [
        const SizedBox(height: 12),
        Text('Pendiente de validación', style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.thumb_down_rounded, size: 16),
                label: const Text('Disputar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size(0, 38),
                  textStyle: AppTextStyles.labelMedium,
                ),
                onPressed: () {
                  notifier.validateTask(task.id, 'DISPUTE');
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.thumb_up_rounded, size: 16),
                label: const Text('Aprobar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  minimumSize: const Size(0, 38),
                  textStyle: AppTextStyles.labelMedium,
                ),
                onPressed: () {
                  notifier.validateTask(task.id, 'APPROVE');
                },
              ),
            ),
          ],
        ),
      ];
    }

    if (status == TaskStatus.pendingReview && isMyTask) {
      return [
        const SizedBox(height: 8),
        Text(
          'Esperando que alguien valide esta tarea...',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
        ),
      ];
    }

    return [];
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      TaskStatus.open          => ('Disponible',          AppColors.textHint,     Icons.radio_button_unchecked),
      TaskStatus.assigned      => ('Asignada',           AppColors.primary,      Icons.person_rounded),
      TaskStatus.pendingReview => ('Pendiente de revisión',  AppColors.warning,      Icons.hourglass_top_rounded),
      TaskStatus.approved      => ('Aprobada ✓',          AppColors.success,      Icons.check_circle_rounded),
      TaskStatus.autoApproved  => ('Auto-aprobada ✓',     AppColors.success,      Icons.check_circle_outline_rounded),
      TaskStatus.disputed      => ('Disputada',           AppColors.error,        Icons.error_rounded),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.labelSmall.copyWith(color: color)),
      ],
    );
  }
}

String getCategoryDisplayName(String name) {
  if (name.toLowerCase() == 'uncategorized') return 'Sin categoría';
  return name;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.isSelected, required this.onTap, this.onLongPress});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? Colors.transparent : AppColors.border),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}