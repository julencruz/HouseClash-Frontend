import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/domain/auth_models.dart';
import '../../auth/domain/category_model.dart';
import '../../tasks/presentation/category_controller.dart';
import '../domain/house_models.dart';
import 'house_details_controller.dart';

Future<void> showHouseEditSheet(
    BuildContext context,
    WidgetRef ref, {
      required HouseModel house,
      required List<UserSession> members,
      required int currentUserId,
    }) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => ProviderScope(
      parent: ProviderScope.containerOf(context),
      child: _HouseEditSheet(
        house: house,
        members: members,
        currentUserId: currentUserId,
      ),
    ),
  );
}

class _HouseEditSheet extends ConsumerStatefulWidget {
  const _HouseEditSheet({
    required this.house,
    required this.members,
    required this.currentUserId,
  });

  final HouseModel house;
  final List<UserSession> members;
  final int currentUserId;

  @override
  ConsumerState<_HouseEditSheet> createState() => _HouseEditSheetState();
}

class _HouseEditSheetState extends ConsumerState<_HouseEditSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _nameCtrl;
  bool _savingName = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nameCtrl = TextEditingController(text: widget.house.name);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || name == widget.house.name) return;
    setState(() => _savingName = true);
    try {
      await ref.read(houseDetailsControllerProvider.notifier).updateName(name);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        _showError('Error al guardar: $e');
      }
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _kickMember(UserSession member) async {
    final ok = await _confirm(
      title: 'Expulsar miembro',
      body: '¿Expulsar a ${member.username} de la casa?',
      confirmLabel: 'Expulsar',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(houseDetailsControllerProvider.notifier).kickMember(member.id);
      if (mounted) _showSuccess('${member.username} expulsado');
    } catch (e) {
      if (mounted) _showError('Error: $e');
    }
  }

  Future<void> _transfer(UserSession member) async {
    final ok = await _confirm(
      title: 'Transferir capitanía',
      body:
      '¿Transferir la capitanía a ${member.username}?\nNo se puede deshacer sin su cooperación.',
      confirmLabel: 'Transferir',
      destructive: false,
    );
    if (!ok || !mounted) return;
    try {
      await ref
          .read(houseDetailsControllerProvider.notifier)
          .transferOwnership(member.id);
      if (mounted) {
        Navigator.of(context).pop();
        _showSuccess('Capitanía transferida a ${member.username}');
      }
    } catch (e) {
      if (mounted) _showError('Error: $e');
    }
  }

  Future<void> _addCategory() async {
    final name = await _textDialog(title: 'Nueva categoría', hint: 'Nombre');
    if (name == null || name.isEmpty) return;
    await ref.read(categoryControllerProvider.notifier).createCategory(
      name: name,
      houseId: widget.house.id,
    );
  }

  Future<void> _editCategory(CategoryModel c) async {
    final name = await _textDialog(
        title: 'Editar categoría', hint: 'Nombre', initial: c.name);
    if (name == null || name.isEmpty || name == c.name) return;
    await ref.read(categoryControllerProvider.notifier).updateCategory(c.id, name);
  }

  Future<void> _deleteCategory(CategoryModel c) async {
    final ok = await _confirm(
      title: 'Eliminar categoría',
      body: '¿Eliminar "${_displayCat(c.name)}"?',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(categoryControllerProvider.notifier).deleteCategory(c.id);
  }

  String _displayCat(String name) =>
      name.toLowerCase() == 'uncategorized' ? 'Sin categoría' : name;

  Future<bool> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
    required bool destructive,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(title, style: AppTextStyles.h3),
        content: Text(body, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              confirmLabel,
              style: TextStyle(
                  color: destructive ? AppColors.error : AppColors.primary),
            ),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<String?> _textDialog({
    required String title,
    required String hint,
    String? initial,
  }) async {
    final ctrl = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(title, style: AppTextStyles.h3),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text('Aceptar',
                style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return result;
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.success,
    ));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
    ));
  }

  Color _avatarColor(String name) {
    const cols = [
      AppColors.primary, AppColors.accent, AppColors.gold,
      AppColors.silver, AppColors.bronze,
    ];
    return name.isEmpty ? AppColors.primary : cols[name.codeUnitAt(0) % cols.length];
  }

  @override
  Widget build(BuildContext context) {
    final liveMembers =
        ref.watch(houseDetailsControllerProvider).valueOrNull?.members ??
            widget.members;
    final others =
    liveMembers.where((m) => m.id != widget.currentUserId).toList();
    final categoriesAsync = ref.watch(categoryControllerProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 14),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Gestionar casa', style: AppTextStyles.h2, textAlign: TextAlign.left),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textHint,
                  indicator: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow.withValues(alpha: 0.4),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  padding: const EdgeInsets.all(3),
                  labelStyle: AppTextStyles.labelMedium,
                  unselectedLabelStyle: AppTextStyles.labelMedium,
                  tabs: const [Tab(text: 'Casa'), Tab(text: 'Categorías')],
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    children: [
                      _sectionLabel(Icons.edit_rounded, 'Nombre de la casa'),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameCtrl,
                              style: AppTextStyles.bodyMedium,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.surface,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                  const BorderSide(color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                  const BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.primary),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _savingName ? null : _saveName,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _savingName
                                ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                                : Text('Guardar',
                                style: AppTextStyles.labelMedium
                                    .copyWith(color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      _sectionLabel(Icons.group_rounded,
                          'Miembros (${liveMembers.length})'),
                      const SizedBox(height: 10),
                      if (others.isEmpty)
                        _emptyCard('No hay otros miembros en la casa.')
                      else
                        ...others.map((m) {
                          final color = _avatarColor(m.username);
                          final ini = m.username.length >= 2
                              ? m.username.substring(0, 2).toUpperCase()
                              : m.username.toUpperCase();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.18),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(ini,
                                      style: AppTextStyles.labelMedium
                                          .copyWith(color: color)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(m.username,
                                          style: AppTextStyles.labelLarge),
                                      Text('${m.kudosBalance} kudos',
                                          style: AppTextStyles.bodySmall.copyWith(
                                              color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                _iconBtn(
                                  Icons.shield_rounded,
                                  AppColors.primary,
                                  'Transferir capitanía',
                                      () => _transfer(m),
                                ),
                                const SizedBox(width: 6),
                                _iconBtn(
                                  Icons.person_remove_rounded,
                                  AppColors.error,
                                  'Expulsar',
                                      () => _kickMember(m),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                  categoriesAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (cats) => ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _sectionLabel(Icons.label_rounded, 'Categorías'),
                            GestureDetector(
                              onTap: _addCategory,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add_rounded,
                                        size: 16, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text('Nueva',
                                        style: AppTextStyles.labelSmall
                                            .copyWith(color: AppColors.primary)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...cats.map((c) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: c.isDefault
                                      ? AppColors.textHint
                                      : AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text(_displayCat(c.name),
                                      style: AppTextStyles.bodyMedium)),
                              if (c.isDefault)
                                Text('por defecto',
                                    style: AppTextStyles.labelSmall
                                        .copyWith(color: AppColors.textHint))
                              else ...[
                                _iconBtn(
                                  Icons.edit_rounded,
                                  AppColors.textSecondary,
                                  'Editar',
                                      () => _editCategory(c),
                                ),
                                const SizedBox(width: 6),
                                _iconBtn(
                                  Icons.delete_rounded,
                                  AppColors.error,
                                  'Eliminar',
                                      () => _deleteCategory(c),
                                ),
                              ],
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: AppColors.textSecondary),
      const SizedBox(width: 6),
      Text(label,
          style: AppTextStyles.labelMedium
              .copyWith(color: AppColors.textSecondary)),
    ],
  );

  Widget _emptyCard(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(text,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
  );

  Widget _iconBtn(
      IconData icon, Color color, String tooltip, VoidCallback onTap) =>
      Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      );
}