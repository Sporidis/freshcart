import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_fill.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_radii.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/ui/dashed_outline_painter.dart';
import 'package:freshcart_flutter/core/ui/tap_target.dart';

/// The list's empty state (design v3): a ghost of the list it will become
/// (three rows with dashed rings in the accent colour), a title, one line,
/// and a pill that starts adding.
///
/// The ghost shows what to do instead of describing it. The accent comes
/// from the theme, so on a shop tab it's that shop's colour.
///
/// It arrives like v3's `emptyIn`: after [delay], the whole thing fades in
/// over 240ms while its parts (each ghost row, the title, the line, the
/// pill) rise 10px, 380ms each and 55ms apart. One controller drives it
/// all, so the parts can't drift. Give each empty state its own key (per
/// tab), or a switch between two empty tabs reuses this one and nothing
/// plays.
class ItemsEmptyState extends StatefulWidget {
  const ItemsEmptyState({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    this.delay = afterRemoval,
    super.key,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  /// How long to wait before arriving.
  final Duration delay;

  /// The v3 wait after the last row has left, so the rows are gone before
  /// the ghost comes in.
  static const Duration afterRemoval = Duration(milliseconds: 140);

  /// The v3 wait on a tab switch: the switch itself is the cue.
  static const Duration afterTabSwitch = Duration(milliseconds: 40);

  @override
  State<ItemsEmptyState> createState() => _ItemsEmptyStateState();
}

class _ItemsEmptyStateState extends State<ItemsEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this);
  bool _started = false;

  static const int _fadeMs = 240;
  static const int _partMs = 380;
  static const int _stepMs = 55;
  static const double _rise = 10;

  /// Three ghost rows, title, line, pill.
  static const int _parts = 6;

  int get _delayMs => widget.delay.inMilliseconds;
  int get _totalMs => _delayMs + (_parts - 1) * _stepMs + _partMs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Here, not in initState: reduced motion comes from the MediaQuery.
    _intro.duration = AppMotion.reduced(context)
        ? AppMotion.micro
        : Duration(milliseconds: _totalMs);
    unawaited(_intro.forward());
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Animation<double> _slice(int startMs, int lengthMs, Curve curve) {
    if (AppMotion.reduced(context)) return _intro;
    return CurvedAnimation(
      parent: _intro,
      curve: Interval(
        startMs / _totalMs,
        math.min(1, (startMs + lengthMs) / _totalMs),
        curve: curve,
      ),
    );
  }

  /// Part [i] fading in as it rises into place.
  Widget _part(int i, Widget child) {
    final animation = _slice(_delayMs + i * _stepMs, _partMs, AppMotion.enter);
    final rise = AppMotion.reduced(context) ? 0.0 : _rise;
    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, rise * (1 - animation.value)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: _slice(_delayMs, _fadeMs, Curves.linear),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 36, 32, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GhostCard(row: _part),
            const SizedBox(height: 22),
            _part(
              3,
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: AppTextStyles.cardTitle.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 6),
            _part(
              4,
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 270),
                child: Text(
                  widget.body,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 15,
                    height: 21 / 15,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _part(
              5,
              _ActionPill(label: widget.actionLabel, onTap: widget.onAction),
            ),
          ],
        ),
      ),
    );
  }
}

/// A 230px card with three placeholder rows, fading out down the card.
/// The card arrives with the whole state's fade; [row] brings each row in
/// as its own part (0, 1, 2), as in v3.
class _GhostCard extends StatelessWidget {
  const _GhostCard({required this.row});

  final Widget Function(int index, Widget child) row;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget ghostRow(double width, double opacity) => Opacity(
      opacity: opacity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 20,
              child: CustomPaint(
                painter: DashedOutlinePainter(
                  color: scheme.primary.withValues(alpha: .55),
                  strokeWidth: 2,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Container(
              width: width,
              height: 8,
              decoration: BoxDecoration(
                color: scheme.fill,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
    return Container(
      width: 230,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .06),
            offset: const Offset(0, 10),
            blurRadius: 28,
          ),
        ],
      ),
      child: Column(
        children: [
          row(0, ghostRow(120, 1)),
          row(1, ghostRow(86, .7)),
          row(2, ghostRow(140, .4)),
        ],
      ),
    );
  }
}

/// "+ Add a product": a 44px outlined pill with an accent plus.
class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      child: TapTarget(
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.fromLTRB(14, 0, 18, 0),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 14,
                  color: scheme.onPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTextStyles.bodyStrong.copyWith(
                  fontSize: 15,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
