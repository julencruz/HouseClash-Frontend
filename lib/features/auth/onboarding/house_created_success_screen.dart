import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class HouseCreatedSuccessScreen extends StatelessWidget {
  final String inviteCode;

  const HouseCreatedSuccessScreen({
    super.key,
    required this.inviteCode,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado al portapapeles')),
    );
  }

  void _shareCode() {
    Share.share('Únete a mi casa en HouseClash con este código: "$inviteCode"');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fort_rounded,
                  size: 72,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 32),

              Text(
                '¡Hogar creado!',
                style: AppTextStyles.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Eres el capitán de esta casa.\nComparte tu código para que tus compañeros puedan entrar.',
                style: AppTextStyles.secondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(
                      'CÓDIGO DE INVITACIÓN',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textHint,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            inviteCode,
                            style: AppTextStyles.h2.copyWith(
                              color: AppColors.primaryDark,
                              letterSpacing: 2.0,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _copyToClipboard(context),
                            child: const Icon(
                              Icons.copy_rounded,
                              color: AppColors.primaryDark,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _shareCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.share_rounded, size: 20),
                  label: Text(
                    'Compartir Enlace de Invitación',
                    style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go(AppRoutes.tasks),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Entrar',
                        style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

