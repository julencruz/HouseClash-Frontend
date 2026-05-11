import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class JoinOrCreateHouseScreen extends StatelessWidget {
  const JoinOrCreateHouseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text.rich(
                TextSpan(
                  style: AppTextStyles.displayLarge,
                  children: const [
                    TextSpan(text: 'Juega tus '),
                    TextSpan(
                      text: 'cartas',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Crea un piso nuevo para dictar las normas,\no únete al caos de tus compañeros.',
                style: AppTextStyles.secondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              _HouseOptionCard(
                themeColor: AppColors.primary,
                icon: Icons.home_work_rounded,
                title: 'Crea tu casa',
                description: 'Sé el capitán del piso. Crea una nueva casa, invita al resto y empieza a repartir tareas.',
                buttonLabel: 'Crear casa',
                buttonIcon: Icons.add_circle_outline_rounded,
                onTap: () => context.push(AppRoutes.createHouse),
              ),
              const SizedBox(height: 20),

              _HouseOptionCard(
                themeColor: AppColors.accent,
                icon: Icons.group_add_rounded,
                title: 'Únete a una casa',
                description: '¿Tienes un código? Úsalo para entrar en territorio enemigo. Tus compañeros te esperan.',
                buttonLabel: 'Unirse con código',
                buttonIcon: Icons.key_rounded,
                onTap: () => context.push(AppRoutes.joinHouse),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HouseOptionCard extends StatelessWidget {
  const _HouseOptionCard({
    required this.themeColor,
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.onTap,
  });

  final Color themeColor;
  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final IconData buttonIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: themeColor, size: 28),
          ),
          const SizedBox(height: 16),

          Text(title, style: AppTextStyles.h2),
          const SizedBox(height: 6),

          Text(description, style: AppTextStyles.secondary),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(buttonIcon, size: 18),
              label: Text(
                buttonLabel,
                style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}