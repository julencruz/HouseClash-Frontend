import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/card_model.dart';

Future<List<CardModel>?> showCardPackOpening(BuildContext context, Future<List<CardModel>> cardsFuture) {
  return showGeneralDialog<List<CardModel>>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.85),
    transitionDuration: const Duration(milliseconds: 250),
    transitionBuilder: (_, anim, __, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(anim), child: child),
    ),
    pageBuilder: (ctx, _, __) => _PackOpeningPage(cardsFuture: cardsFuture),
  );
}

enum _Stage { idle, tearing, burst, revealing, done }

class _PackOpeningPage extends StatefulWidget {
  final Future<List<CardModel>> cardsFuture;

  const _PackOpeningPage({required this.cardsFuture});

  @override
  State<_PackOpeningPage> createState() => _PackOpeningPageState();
}

class _PackOpeningPageState extends State<_PackOpeningPage> with TickerProviderStateMixin {
  _Stage _stage = _Stage.idle;
  List<Offset> _tearPoints = [];
  double _tearProgress = 0.0;
  List<CardModel> _cards = [];

  late final AnimationController _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 80));
  late final AnimationController _burstCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
  late final AnimationController _revealCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

  late final Animation<double> _topSlide = Tween<double>(begin: 0, end: -250).animate(CurvedAnimation(parent: _burstCtrl, curve: Curves.easeOutCubic));
  late final Animation<double> _botSlide = Tween<double>(begin: 0, end: 250).animate(CurvedAnimation(parent: _burstCtrl, curve: Curves.easeOutCubic));
  late final Animation<double> _fade = Tween<double>(begin: 1, end: 0).animate(CurvedAnimation(parent: _burstCtrl, curve: const Interval(0.4, 1)));

  final _packKey = GlobalKey();

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _burstCtrl.dispose();
    _revealCtrl.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails d) {
    if (_stage != _Stage.idle) return;
    final box = _packKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(d.globalPosition);
    setState(() {
      _stage = _Stage.tearing;
      _tearPoints = [local];
      _tearProgress = 0.0;
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_stage != _Stage.tearing) return;
    final box = _packKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final local = box.globalToLocal(d.globalPosition);
    final width = box.size.width;

    if (_tearPoints.isNotEmpty && local.dx < _tearPoints.last.dx - 10) return;

    final progress = (local.dx / width).clamp(0.0, 1.0);

    if ((progress * 10).floor() > (_tearProgress * 10).floor()) {
      _shakeCtrl.forward(from: 0);
    }

    setState(() {
      _tearPoints.add(local);
      _tearProgress = progress;
    });

    if (progress >= 0.85) _finishTear();
  }

  void _onPanEnd(DragEndDetails _) {
    if (_stage == _Stage.tearing && _tearProgress > 0.5) {
      _finishTear();
    } else if (_stage == _Stage.tearing) {
      setState(() {
        _tearPoints.clear();
        _tearProgress = 0.0;
        _stage = _Stage.idle;
      });
    }
  }

  bool _tearFinishing = false;

  Future<void> _finishTear() async {
    if (_tearFinishing) return;
    _tearFinishing = true;

    final box = _packKey.currentContext?.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 200.0;

    if (_tearPoints.isNotEmpty) {
      final lastPoint = _tearPoints.last;
      setState(() {
        _tearPoints.add(Offset(width, lastPoint.dy));
        _tearProgress = 1.0;
        _stage = _Stage.burst;
      });
    }

    final burstAnim = _burstCtrl.forward();
    List<CardModel>? cards;
    try {
      cards = await widget.cardsFuture;
    } catch (_) {
      cards = null;
    }

    await burstAnim;

    if (!mounted) return;
    if (cards == null) {
      Navigator.pop(context, null);
      return;
    }

    setState(() {
      _cards = cards!;
      _stage = _Stage.revealing;
    });

    await _revealCtrl.forward();

    if (!mounted) return;
    setState(() => _stage = _Stage.done);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: AnimatedOpacity(
                opacity: _stage == _Stage.done ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: IconButton(
                    onPressed: _stage == _Stage.done ? () => Navigator.pop(context, _cards) : null,
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_stage == _Stage.idle || _stage == _Stage.tearing)
                      _buildPackInteraction(),
                    if (_stage == _Stage.burst)
                      _buildBurstAnimation(),
                    if (_stage == _Stage.revealing || _stage == _Stage.done)
                      _buildReveal(),
                  ],
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: (_stage == _Stage.idle || _stage == _Stage.tearing) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: _buildInstruction(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackInteraction() {
    return GestureDetector(
      key: const ValueKey('pack'),
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: _shakeCtrl,
        builder: (_, child) => Transform.translate(
          offset: Offset(math.sin(_shakeCtrl.value * math.pi * 6) * 4, 0),
          child: child,
        ),
        child: SizedBox(
          key: _packKey,
          width: 200,
          height: 260,
          child: CustomPaint(
            painter: _PackPainter(tearPoints: _tearPoints),
          ),
        ),
      ),
    );
  }

  Widget _buildBurstAnimation() {
    return AnimatedBuilder(
      key: const ValueKey('burst'),
      animation: _burstCtrl,
      builder: (_, __) {
        return SizedBox(
          width: 200,
          height: 260,
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: _fade.value,
                  child: Transform.translate(
                    offset: Offset(0, _botSlide.value),
                    child: ClipPath(
                      clipper: _TearClipper(points: _tearPoints, isTop: false),
                      child: CustomPaint(
                        size: const Size(200, 260),
                        painter: _PackPainter(tearPoints: _tearPoints, isBursting: true),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: _fade.value,
                  child: Transform.translate(
                    offset: Offset(0, _topSlide.value),
                    child: ClipPath(
                      clipper: _TearClipper(points: _tearPoints, isTop: true),
                      child: CustomPaint(
                        size: const Size(200, 260),
                        painter: _PackPainter(tearPoints: _tearPoints, isBursting: true),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReveal() {
    return AnimatedBuilder(
      key: const ValueKey('reveal'),
      animation: _revealCtrl,
      builder: (_, __) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Sobre abierto!', style: AppTextStyles.h1.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          Text('Has conseguido ${_cards.length} cartas', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
          const SizedBox(height: 32),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: List.generate(_cards.length, (i) {
              final progress = _cards.isEmpty ? 0.0 : ((_revealCtrl.value - i * 0.15) / (1.0 - (_cards.length - 1) * 0.15)).clamp(0.0, 1.0);
              return _AnimatedCardChip(card: _cards[i], progress: progress);
            }),
          ),
          if (_stage == _Stage.done) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, _cards),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              label: Text('Continuar', style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstruction() {
    if (_stage == _Stage.idle) {
      return Text('Rasga el sobre', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        Container(
          width: 160, height: 6,
          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(3)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft, widthFactor: _tearProgress,
            child: Container(decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(3))),
          ),
        ),
      ],
    );
  }
}

class _TearClipper extends CustomClipper<Path> {
  final List<Offset> points;
  final bool isTop;

  _TearClipper({required this.points, required this.isTop});

  @override
  Path getClip(Size size) {
    final path = Path();
    if (points.isEmpty) {
      path.addRect(Rect.fromLTWH(0, isTop ? 0 : size.height / 2, size.width, size.height / 2));
      return path;
    }

    if (isTop) {
      path.lineTo(size.width, 0);
      path.lineTo(size.width, points.last.dy);
      for (int i = points.length - 1; i >= 0; i--) { path.lineTo(points[i].dx, points[i].dy); }
      path.lineTo(0, points.first.dy);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, points.last.dy);
      for (int i = points.length - 1; i >= 0; i--) { path.lineTo(points[i].dx, points[i].dy); }
      path.lineTo(0, points.first.dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_TearClipper old) => true;
}

class _PackPainter extends CustomPainter {
  final List<Offset> tearPoints;
  final bool isBursting;

  const _PackPainter({required this.tearPoints, this.isBursting = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(18));

    final bgPaint = Paint()..color = const Color(0xFF00916E);
    canvas.drawRRect(rrect, bgPaint);

    final borderPaint = Paint()..color = Colors.white.withValues(alpha: 0.18)..strokeWidth = 2..style = PaintingStyle.stroke;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(3, 3, w - 6, h - 6), const Radius.circular(15)), borderPaint);

    if (tearPoints.isEmpty && !isBursting) {
      final textPainter = TextPainter(
        text: TextSpan(text: '?', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 28, fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset((w - textPainter.width) / 2, (h - textPainter.height) / 2));
    }

    if (tearPoints.isNotEmpty && !isBursting) {
      _drawTear(canvas);
    }
  }

  void _drawTear(Canvas canvas) {
    if (tearPoints.length < 2) return;
    final path = Path()..moveTo(tearPoints.first.dx, tearPoints.first.dy);
    for (int i = 1; i < tearPoints.length; i++) {
      path.lineTo(tearPoints[i].dx, tearPoints[i].dy);
    }

    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.4)..strokeWidth = 5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: 0.9)..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_PackPainter old) => true;
}

class _AnimatedCardChip extends StatelessWidget {
  const _AnimatedCardChip({required this.card, required this.progress});
  final CardModel card;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final flip = Curves.easeOut.transform(progress.clamp(0.0, 1.0));
    return Opacity(
      opacity: flip.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, (1 - flip) * 40),
        child: Container(
          width: 130, padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: card.type.color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: card.type.color.withValues(alpha: 0.12), shape: BoxShape.circle), child: Icon(card.type.icon, color: card.type.color, size: 22)),
              const SizedBox(height: 6),
              Text(card.type.displayName, style: AppTextStyles.labelMedium, textAlign: TextAlign.center, maxLines: 2),
              const SizedBox(height: 2),
              Text(card.type.category, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
            ],
          ),
        ),
      ),
    );
  }
}