import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/house_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/domain/task_models.dart';
import '../../auth/domain/category_model.dart';
import '../../auth/data/auth_controller.dart';
import 'task_controller.dart';
import 'category_controller.dart';

const _recurrenceOptions = [
  (value: 'DAILY', label: 'Diaria'),
  (value: 'WEEKLY', label: 'Semanal'),
  (value: 'BIWEEKLY', label: 'Quincenal'),
  (value: 'MONTHLY', label: 'Mensual'),
];

class CreateTaskSheet extends ConsumerStatefulWidget {
  const CreateTaskSheet({super.key});

  @override
  ConsumerState<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends ConsumerState<CreateTaskSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _categoryNameController = TextEditingController();

  Effort _effort = Effort.low;
  CategoryModel? _selectedCategory;
  String? _recurrence;
  DateTime? _deadline;
  bool _isSubmitting = false;

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.card,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null) return;

    if (!context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline ?? now),
    );

    setState(() {
      _deadline = time == null
          ? DateTime(date.year, date.month, date.day, 23, 59)
          : DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _showCreateCategoryDialog(BuildContext ctx, int houseId) async {
    _categoryNameController.clear();

    final created = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Nueva categoría', style: AppTextStyles.h2),
        content: TextField(
          controller: _categoryNameController,
          textCapitalization: TextCapitalization.sentences,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ej: Cocina, Baño...',
          ),
          style: AppTextStyles.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (created != true || _categoryNameController.text.trim().isEmpty) return;

    final name = _categoryNameController.text.trim();

    Future.microtask(() async {
      if (!mounted) return;
      try {
        await ref.read(categoryControllerProvider.notifier).createCategory(
          name: name,
          houseId: houseId,
        );

        if (mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text('Categoría "$name" creada'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text('Error al crear la categoría: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    });
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null || session.houseId == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(taskControllerProvider.notifier).createTask(
        title: title,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        effort: _effort,
        houseId: session.houseId!,
        categoryId: _selectedCategory?.id,
        recurrence: _recurrence,
        deadline: _deadline,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear la tarea: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userSession = ref.watch(authControllerProvider).valueOrNull;
    final houseSession = ref.watch(houseStorageProvider).valueOrNull;
    final categoriesAsync = ref.watch(categoryControllerProvider);

    final isCaptain = userSession != null &&
        houseSession != null &&
        houseSession.isCaptain(userSession.id);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Nueva tarea', style: AppTextStyles.h1),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textHint,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Título',
                labelStyle: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                hintText: 'Ej: Fregar los platos',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                labelText: 'Detalles (opcional)',
                labelStyle: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                hintText: 'Instrucciones para tus compañeros...',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 28),

            categoriesAsync.when(
              data: (categories) {
                final filteredCategories = categories
                    .where((cat) => cat.name.toLowerCase() != 'uncategorized')
                    .toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Categoría',
                          style: filteredCategories.isEmpty
                              ? AppTextStyles.labelLarge.copyWith(
                            color: AppColors.textHint,
                          )
                              : AppTextStyles.labelLarge,
                        ),
                        const Spacer(),
                        if (isCaptain)
                          TextButton.icon(
                            onPressed: () => _showCreateCategoryDialog(
                              context,
                              houseSession.houseId,
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Crear categoría'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              textStyle: AppTextStyles.labelSmall,
                            ),
                          ),
                      ],
                    ),
                    if (filteredCategories.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<CategoryModel?>(
                        value: _selectedCategory,
                        hint: Text(
                          'Selecciona una categoría',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                        dropdownColor: AppColors.surface,
                        items: [
                          const DropdownMenuItem<CategoryModel?>(
                            value: null,
                            child: Text('Ninguna'),
                          ),
                          ...filteredCategories.map(
                                (cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat.name),
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedCategory = val),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),

            Text('Nivel de esfuerzo', style: AppTextStyles.labelLarge),
            const SizedBox(height: 12),
            SegmentedButton<Effort>(
              style: SegmentedButton.styleFrom(
                backgroundColor: AppColors.surface,
                selectedBackgroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              segments: [
                ButtonSegment(
                  value: Effort.low,
                  label: Text('Bajo', style: AppTextStyles.labelSmall.copyWith(color: _effort == Effort.low ? Colors.white : AppColors.textPrimary)),
                  icon: Icon(Icons.bolt, size: 16, color: _effort == Effort.low ? Colors.white : AppColors.textPrimary),
                ),
                ButtonSegment(
                  value: Effort.medium,
                  label: Text('Medio', style: AppTextStyles.labelSmall.copyWith(color: _effort == Effort.medium ? Colors.white : AppColors.textPrimary)),
                  icon: Icon(Icons.bolt, size: 16, color: _effort == Effort.medium ? Colors.white : AppColors.textPrimary),
                ),
                ButtonSegment(
                  value: Effort.high,
                  label: Text('Alto', style: AppTextStyles.labelSmall.copyWith(color: _effort == Effort.high ? Colors.white : AppColors.textPrimary)),
                  icon: Icon(Icons.bolt, size: 16, color: _effort == Effort.high ? Colors.white : AppColors.textPrimary),
                ),
              ],
              selected: {_effort},
              onSelectionChanged: (s) => setState(() => _effort = s.first),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stars_rounded, size: 16, color: AppColors.accentLight),
                const SizedBox(width: 4),
                Text(
                  'Recompensa: ${_effort.baseKudos} kudos',
                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.accentLight, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text('Recurrencia', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: _recurrence,
              hint: Text('Sin recurrencia', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
              dropdownColor: AppColors.surface,
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Ninguna')),
                ..._recurrenceOptions.map((opt) => DropdownMenuItem(value: opt.value, child: Text(opt.label))),
              ],
              onChanged: (val) => setState(() => _recurrence = val),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
            const SizedBox(height: 28),
            Text('Fecha límite', style: AppTextStyles.labelLarge),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDeadline,
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _deadline != null ? AppColors.primary : AppColors.border, width: _deadline != null ? 1.5 : 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 18, color: _deadline != null ? AppColors.primary : AppColors.textHint),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _deadline != null
                            ? '${_deadline!.day.toString().padLeft(2, '0')}/${_deadline!.month.toString().padLeft(2, '0')}/${_deadline!.year}  —  ${_deadline!.hour.toString().padLeft(2, '0')}:${_deadline!.minute.toString().padLeft(2, '0')}'
                            : 'Sin fecha límite',
                        style: AppTextStyles.bodyMedium.copyWith(color: _deadline != null ? AppColors.textPrimary : AppColors.textHint, fontWeight: _deadline != null ? FontWeight.w600 : FontWeight.normal),
                      ),
                    ),
                    if (_deadline != null)
                      GestureDetector(
                        onTap: () => setState(() => _deadline = null),
                        child: const Icon(Icons.cancel_rounded, size: 20, color: AppColors.textHint),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Text('Crear tarea', style: AppTextStyles.h3.copyWith(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _categoryNameController.dispose();
    super.dispose();
  }
}