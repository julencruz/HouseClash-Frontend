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
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Código copiado', style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
          ],
        ),
      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.home_work_rounded,
                  size: 34,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),

              Text('¡Hogar creado!', style: AppTextStyles.displayMedium),
              const SizedBox(height: 8),
              Text(
                'Eres el capitán de esta casa.\nComparte el código para que tus compañeros puedan entrar.',
                style: AppTextStyles.secondary,
              ),

              const SizedBox(height: 40),

              Text(
                'CÓDIGO DE INVITACIÓN',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textHint,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: inviteCode.split('').map((char) => _CodeChar(char: char)).toList(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _copyToClipboard(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.copy_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Text(
                    'El código caduca cada 72 horas',
                    style: AppTextStyles.hint,
                  ),
                ],
              ),

              const Spacer(flex: 2),

              ElevatedButton.icon(
                onPressed: _shareCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 52),
                ),
                icon: const Icon(Icons.share_rounded, size: 18),
                label: Text(
                  'Compartir código',
                  style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () => context.go(AppRoutes.tasks),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: AppColors.card,
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Text('Entrar a la casa', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeChar extends StatelessWidget {
  const _CodeChar({required this.char});
  final String char;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: Text(
        char,
        style: AppTextStyles.h2.copyWith(
          color: AppColors.primary,
          letterSpacing: 0,
        ),
      ),
    );
  }
}