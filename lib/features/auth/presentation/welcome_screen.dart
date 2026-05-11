import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _TexturedBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 160,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                  const SizedBox(height: 32),
                  Text.rich(
                    TextSpan(
                      text: 'Bienvenido a\n',
                      style: AppTextStyles.displayMedium.copyWith(
                        color: AppColors.primary,
                        height: 1.2,
                      ),
                      children: const [
                        TextSpan(
                          text: 'House',
                          style: TextStyle(color: AppColors.primary),
                        ),
                        TextSpan(
                          text: 'Clash',
                          style: TextStyle(color: AppColors.warning),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Convierte las tareas de casa\nen un arma para sabotear al resto.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(flex: 3),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => context.go(AppRoutes.login),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'Inicia Sesión',
                        style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => context.go(AppRoutes.register),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'Regístrate',
                        style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TexturedBackground extends StatelessWidget {
  const _TexturedBackground();

  static const _icons = [
    Icons.home_outlined,
    Icons.check_circle_outline_rounded,
    Icons.star_outline_rounded,
    Icons.cleaning_services_outlined,
    Icons.local_laundry_service_outlined,
    Icons.kitchen_outlined,
    Icons.emoji_events_outlined,
    Icons.style_outlined,
    Icons.bolt_outlined,
    Icons.workspace_premium_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _IconPatternPainter(_icons),
    );
  }
}

class _IconPatternPainter extends CustomPainter {
  final List<IconData> icons;

  _IconPatternPainter(this.icons);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    const iconSize = 28.0;
    final cols = (size.width / 72).ceil() + 1;
    final rows = (size.height / 72).ceil() + 1;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final icon = icons[random.nextInt(icons.length)];
        final opacity = 0.04 + random.nextDouble() * 0.05;
        final rotation = (random.nextDouble() - 0.5) * 0.6;

        final offsetX = col * 72.0 + random.nextDouble() * 20 - 10;
        final offsetY = row * 72.0 + random.nextDouble() * 20 - 10;

        textPainter.text = TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: iconSize,
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            color: AppColors.primary.withOpacity(opacity),
          ),
        );
        textPainter.layout();

        canvas.save();
        canvas.translate(offsetX + iconSize / 2, offsetY + iconSize / 2);
        canvas.rotate(rotation);
        canvas.translate(-iconSize / 2, -iconSize / 2);
        textPainter.paint(canvas, Offset.zero);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}