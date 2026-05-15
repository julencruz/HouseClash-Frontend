import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_widgets.dart';
import '../../auth/data/auth_controller.dart';
import '../domain/card_model.dart';
import 'card_controller.dart';
import 'card_pack_opening.dart';
import 'use_card_sheet.dart';

class CardsScreen extends ConsumerWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(cardControllerProvider);
    final userAsync  = ref.watch(authControllerProvider);
    final kudos      = userAsync.valueOrNull?.kudosBalance ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: HouseClashAppBar(title: 'Tienda', kudos: kudos),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await ref.read(cardControllerProvider.notifier).refresh();
          await ref.read(authControllerProvider.notifier).refreshProfile();
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _CardPackSection(kudos: kudos),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text('Mis Cartas', style: AppTextStyles.h2),
              ),
            ),

            cardsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text('Error al cargar las cartas', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.read(cardControllerProvider.notifier).refresh(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (cards) => cards.isEmpty
                  ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Symbols.playing_cards,
                          size: 64, color: AppColors.textHint),
                      const SizedBox(height: 16),
                      Text('No tienes cartas todavía',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textHint)),
                      const SizedBox(height: 6),
                      Text('¡Compra un sobre para conseguirlas!',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textHint)),
                    ],
                  ),
                ),
              )
                  : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid(
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => _CardTile(card: cards[index]),
                    childCount: cards.length,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardPackSection extends ConsumerStatefulWidget {
  const _CardPackSection({required this.kudos});
  final int kudos;

  @override
  ConsumerState<_CardPackSection> createState() => _CardPackSectionState();
}

class _CardPackSectionState extends ConsumerState<_CardPackSection> {
  static const _packCost = 50;

  Future<void> _openPack() async {
    if (widget.kudos < _packCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes suficientes Kudos para abrir un sobre.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final cardsFuture = ref.read(cardControllerProvider.notifier).openPack();

    await showCardPackOpening(context, cardsFuture);
  }

  @override
  Widget build(BuildContext context) {
    final canBuy = widget.kudos >= _packCost;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2_rounded,
                size: 48, color: AppColors.textHint),
          ),
          const SizedBox(height: 12),
          Text('Sobre de cartas', style: AppTextStyles.h2),
          const SizedBox(height: 4),
          Text(
            'Contiene 4 cartas para ayudarte en las tareas diarias.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 160,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _openPack,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                canBuy ? AppColors.primary : AppColors.textDisabled,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22)),
              ),
              icon: const Icon(Icons.shopping_cart_rounded, size: 18),
              label: Text(
                '$_packCost Kudos',
                style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTile extends ConsumerStatefulWidget {
  const _CardTile({required this.card});
  final CardModel card;

  @override
  ConsumerState<_CardTile> createState() => _CardTileState();
}

class _CardTileState extends ConsumerState<_CardTile> {
  bool _loading = false;

  Future<void> _useCard() async {
    setState(() => _loading = true);
    try {
      final used = await showUseCardSheet(context, ref, widget.card);
      if (used && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✓ ${widget.card.type.displayName} activada'),
          backgroundColor: AppColors.success,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final color = card.type.color;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.type.category,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(card.type.icon, size: 22, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            card.type.displayName,
            style: AppTextStyles.labelLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              card.type.description,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: _loading ? null : _useCard,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.zero,
              ),
              child: _loading
                  ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : Text('Usar', style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}