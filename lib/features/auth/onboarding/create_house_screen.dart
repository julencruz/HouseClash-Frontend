import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../activity/presentation/activity_controller.dart';
import '../../auth/data/auth_controller.dart';
import '../../cards/presentation/card_controller.dart';
import '../../house/data/house_controller.dart';
import '../../house/presentation/house_details_controller.dart';
import '../../house/presentation/ranking_controller.dart';
import '../../tasks/presentation/category_controller.dart';
import '../../tasks/presentation/task_controller.dart';

class CreateHouseScreen extends ConsumerStatefulWidget {
  const CreateHouseScreen({super.key});

  @override
  ConsumerState<CreateHouseScreen> createState() => _CreateHouseScreenState();
}

class _CreateHouseScreenState extends ConsumerState<CreateHouseScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _refreshAllCache() async {
    await ref.read(authControllerProvider.notifier).refreshProfile();
    ref.read(taskControllerProvider.notifier).refresh();
    ref.read(cardControllerProvider.notifier).refresh();
    ref.read(activityControllerProvider.notifier).refresh();
    ref.invalidate(houseDetailsControllerProvider);
    ref.invalidate(rankingControllerProvider);
    ref.invalidate(categoryControllerProvider);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final code = await ref.read(houseControllerProvider.notifier).createHouse(
      _nameController.text.trim(),
      _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );
    if (code != null && mounted) {
      await _refreshAllCache();
      if (mounted) context.go('${AppRoutes.houseCreatedSuccess}?code=$code');
    }
  }

  String _parseError(Object? error) {
    if (error == null) return 'Error desconocido';
    if (error.runtimeType.toString().contains('DioException')) {
      final dioError = error as dynamic;
      final response = dioError.response;
      if (response != null && response.statusCode == 409) {
        return 'Ya perteneces a una casa';
      }
      if (response != null && response.statusCode == 400) {
        return 'Datos inválidos (Error 400)';
      }
      return 'Error del servidor: ${response?.statusCode}';
    }
    return 'Algo ha ido mal. Inténtalo de nuevo';
  }

  @override
  Widget build(BuildContext context) {
    final houseState = ref.watch(houseControllerProvider);
    final isLoading = houseState.isLoading;

    ref.listen(houseControllerProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_parseError(next.error))),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text('Crea tu casa', style: AppTextStyles.displayLarge),
                const SizedBox(height: 12),
                Text(
                  'Ponle nombre a tu territorio. Aquí manda el que reparte tareas.',
                  style: AppTextStyles.secondary,
                ),
                const SizedBox(height: 32),

                // Nombre
                Text('Nombre de la casa', style: AppTextStyles.labelLarge),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'Ej: El Piso de la Muerte',
                    prefixIcon: Icon(Icons.home_rounded, color: AppColors.textHint, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Dale un nombre a tu casa';
                    if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Descripción
                Text('Descripción (opcional)', style: AppTextStyles.labelLarge),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descriptionController,
                  style: AppTextStyles.bodyLarge,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Ej: Aquí se limpia o se sufre',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.description_outlined, color: AppColors.textHint, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Botón crear
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: isLoading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.add_circle_outline_rounded, size: 20),
                    label: Text(
                      'Crear casa',
                      style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Alternativa
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.pushReplacement(AppRoutes.joinHouse),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      elevation: 0,
                      side: const BorderSide(color: AppColors.accent, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '¿Tienes código? Únete a una casa',
                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.accent),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Info cards
                const _InfoCard(
                  icon: Icons.star_rounded,
                  iconColor: AppColors.gold,
                  title: '¿Qué son los Kudos?',
                  description:
                      'Son los puntos que ganas al completar tareas. Cuantos más Kudos, más alto estás en el ránquing y más te temen tus compañeros.',
                ),
                const SizedBox(height: 12),
                const _InfoCard(
                  icon: Icons.style_rounded,
                  iconColor: AppColors.accent,
                  title: '¿Qué son las Cartas?',
                  description:
                      'Son poderes especiales que desbloqueas con Kudos. Úsalas para sabotear o para librarte de tareas. Estrategia pura.',
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge),
                const SizedBox(height: 4),
                Text(description, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

