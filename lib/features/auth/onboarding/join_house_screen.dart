import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/data/auth_controller.dart';
import '../../house/data/house_controller.dart';

class JoinHouseScreen extends ConsumerStatefulWidget {
  const JoinHouseScreen({super.key});

  @override
  ConsumerState<JoinHouseScreen> createState() => _JoinHouseScreenState();
}

class _JoinHouseScreenState extends ConsumerState<JoinHouseScreen> {
  String _inviteCode = '';

  Future<void> _submit() async {
    if (_inviteCode.length < 6) return;
    await ref.read(houseControllerProvider.notifier).joinHouse(_inviteCode);
    if (mounted && !ref.read(houseControllerProvider).hasError) {
      await ref.read(authControllerProvider.notifier).refreshProfile();
    }
  }

  String _parseError(Object? error) {
    if (error == null) return 'Error desconocido';
    if (error.runtimeType.toString().contains('DioException')) {
      final dioError = error as dynamic;
      final response = dioError.response;
      if (response != null && response.statusCode == 404) {
        return 'El código de invitación no existe o ha expirado';
      }
      if (response != null && response.statusCode == 400) {
        return 'Código inválido';
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                'Introduce el código',
                style: AppTextStyles.displayLarge
              ),
              const SizedBox(height: 12),

              Text(
                'Introduce el código de la casa para entrar en territorio enemigo.',
                style: AppTextStyles.secondary,
              ),
              const SizedBox(height: 20),
              _PinCodeField(
                onChanged: (code) {
                  setState(() {
                    _inviteCode = code;
                  });
                },
              ),
              const SizedBox(height: 35),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_inviteCode.length == 6 && !isLoading) ? _submit : null,
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
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : const Icon(Icons.check_circle_outline_rounded, size: 20),
                  label: Text(
                    'Unirse al caos',
                    style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.pushReplacement(AppRoutes.createHouse),
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
                    '¿No tienes código? Crea tu propia casa',
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

class _PinCodeField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _PinCodeField({required this.onChanged});

  @override
  State<_PinCodeField> createState() => _PinCodeFieldState();
}

class _PinCodeFieldState extends State<_PinCodeField> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.length > 1) {
      final text = value.trim().toUpperCase();
      for (int i = 0; i < 6; i++) {
        if (i < text.length) {
          _controllers[i].text = text[i];
        }
      }
      final nextIndex = text.length < 6 ? text.length : 5;
      _focusNodes[nextIndex].requestFocus();
    } else if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }
    
    final currentCode = _controllers.map((c) => c.text).join();
    widget.onChanged(currentCode);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return Container(
          width: 48,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Focus(
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
                if (_controllers[index].text.isEmpty && index > 0) {
                  _focusNodes[index - 1].requestFocus();
                  _controllers[index - 1].text = '';
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: Center(
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                style: AppTextStyles.h1.copyWith(color: AppColors.textPrimary, height: 1.0),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: (value) => _onChanged(value, index),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.transparent,
                  counterText: "",
                  hintText: "•",
                  hintStyle: TextStyle(color: AppColors.textHint, fontSize: 32, height: 1.0),
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}