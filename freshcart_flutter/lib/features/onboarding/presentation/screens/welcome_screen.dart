import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/app/router/app_router.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding/onboarding_state.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/basket_mark.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_primary_button.dart';
import 'package:go_router/go_router.dart';

/// The first screen a new user sees (design v3). Two buttons: "Get
/// started" and "I have an invite code".
///
/// The top is three tilted shop cards, stacked like lists on a table: the
/// app's idea (a list per shop) before any words. They drop in one after
/// another, then the text rises in under them.
class WelcomeScreen extends ConsumerStatefulWidget {
  /// Creates the welcome screen.
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  /// One controller for the whole entrance; each piece takes its own
  /// [Interval] of it, so they stay in step.
  late final AnimationController _intro = AnimationController(vsync: this);

  /// Side margin (24px, v3). Logo, text and buttons line up on it.
  static const double _sideInset = AppSpacing.xxl;

  /// The logo's size here (after flying in from the splash screen).
  static const double _markSize = 28;

  // v3 timings: cards 620ms, 90ms apart; text 420ms, starting at 280ms,
  // 60ms apart.
  static const int _cardMs = 620;
  static const int _cardStagger = 90;
  static const int _textStart = 280;
  static const int _textMs = 420;
  static const int _textStagger = 60;
  static const int _textPieces = 4; // headline, subhead, two buttons
  static const int _totalMs =
      _textStart + (_textPieces - 1) * _textStagger + _textMs;

  bool _started = false;

  /// This screen's own page transition, while it's still running.
  Animation<double>? _arrival;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Set up here, not in initState: reduced motion is read from the
    // MediaQuery, which isn't available in initState.
    _intro.duration = AppMotion.reduced(context)
        ? AppMotion.micro
        : const Duration(milliseconds: _totalMs);

    // Wait until the page has finished sliding in. Started at once, the
    // cards drop during the slide, so the two movements add up to a
    // diagonal lurch, and the fast start of the drop is spent off-screen.
    final arrival = ModalRoute.of(context)?.animation;
    if (arrival == null || arrival.isCompleted) {
      _intro.forward();
    } else {
      _arrival = arrival..addStatusListener(_onArrival);
    }
  }

  void _onArrival(AnimationStatus status) {
    if (!status.isCompleted) return;
    _arrival?.removeStatusListener(_onArrival);
    _arrival = null;
    if (mounted) _intro.forward();
  }

  @override
  void dispose() {
    _arrival?.removeStatusListener(_onArrival);
    _intro.dispose();
    super.dispose();
  }

  /// The part of [_intro] for one piece, starting at [startMs] and lasting
  /// [lengthMs]. Under reduced motion every piece just fades over the whole
  /// (short) run.
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

  Animation<double> _card(int i) =>
      _slice(i * _cardStagger, _cardMs, AppMotion.emphasized);

  Animation<double> _text(int i) =>
      _slice(_textStart + i * _textStagger, _textMs, AppMotion.enter);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider);
    final reduced = AppMotion.reduced(context);

    Widget rise(int i, Widget child) =>
        _Rise(animation: _text(i), travel: reduced ? 0 : 14, child: child);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Where the splash logo lands. The Hero tag must match the
            // splash screen's, or it would just fade instead of fly.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _sideInset,
                AppSpacing.md,
                _sideInset,
                0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Hero(
                  tag: BasketMark.heroTag,
                  child: BasketMark(
                    size: _markSize,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _ShopCardsScene(cards: _card, reduced: reduced),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _sideInset,
                0,
                _sideInset,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  rise(
                    0,
                    Text(
                      t.welcome.headline,
                      style: AppTextStyles.largeTitle.copyWith(
                        fontSize: 34,
                        height: 39 / 34,
                        letterSpacing: -.8,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  rise(
                    1,
                    Text(
                      t.welcome.subhead,
                      style: AppTextStyles.body.copyWith(
                        height: 23 / 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  rise(
                    2,
                    OnboardingPrimaryButton(
                      label: t.welcome.getStarted,
                      onPressed: () => context.go(Routes.onboarding),
                    ),
                  ),
                  const SizedBox(height: 10),
                  rise(
                    3,
                    OutlinedButton(
                      onPressed: () => context.go(Routes.join),
                      child: Text(t.welcome.haveInviteCode),
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
}

/// Fades [child] in while it rises [travel] px into place.
class _Rise extends StatelessWidget {
  const _Rise({
    required this.animation,
    required this.travel,
    required this.child,
  });

  final Animation<double> animation;
  final double travel;
  final Widget child;

  // FadeTransition, not an Opacity rebuilt every frame: it updates the
  // opacity layer directly, without rebuilding or repainting the child.
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: animation,
    child: AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, travel * (1 - animation.value)),
        child: child,
      ),
    ),
  );
}

/// The three shop cards, as in v3: back-left, back-right, then one in
/// front, each tilted a little differently.
///
/// The names and colours are the preset shops onboarding offers next, so
/// the picture matches what the user is about to pick.
class _ShopCardsScene extends StatelessWidget {
  const _ShopCardsScene({required this.cards, required this.reduced});

  /// The entrance animation for card i (in paint order).
  final Animation<double> Function(int i) cards;
  final bool reduced;

  static const double _height = 300;

  // (preset index, offset of the card's left edge from the centre, top,
  // tilt in degrees, which of its three rows is ticked).
  static const _layout = [
    (1, -150.0, 40.0, -7.0, 1),
    (0, -70.0, 10.0, 5.0, 0),
    (2, -110.0, 120.0, -2.0, 2),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: _height,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final centre = constraints.maxWidth / 2;
              return Stack(
                children: [
                  for (final (i, (shop, dx, top, tilt, ticked))
                      in _layout.indexed)
                    Positioned(
                      left: centre + dx,
                      top: top,
                      child: _Drop(
                        animation: cards(i),
                        tilt: tilt * math.pi / 180,
                        reduced: reduced,
                        child: _ShopCard(
                          shop: presetShops[shop],
                          ticked: ticked,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A card's entrance (v3): from 40px lower, upright and at 94%, it drops
/// into place and turns to its [tilt].
class _Drop extends StatelessWidget {
  const _Drop({
    required this.animation,
    required this.tilt,
    required this.reduced,
    required this.child,
  });

  final Animation<double> animation;
  final double tilt;
  final bool reduced;
  final Widget child;

  // Cheap per frame on purpose: the card (with its big blurred shadow) is
  // painted once into its own layer by the RepaintBoundary, then only
  // moved, turned and faded. An Opacity here would repaint it offscreen
  // every frame.
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: animation,
    child: AnimatedBuilder(
      animation: animation,
      child: RepaintBoundary(child: child),
      builder: (context, child) {
        final v = animation.value;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translateByDouble(0, reduced ? 0 : 40 * (1 - v), 0, 1)
            ..rotateZ(reduced ? tilt : tilt * v)
            ..scaleByDouble(
              reduced ? 1 : .94 + .06 * v,
              reduced ? 1 : .94 + .06 * v,
              1,
              1,
            ),
          child: child,
        );
      },
    ),
  );
}

/// One 230px card: the shop's dot and name in mono, then three rows of
/// placeholder bars. One row is ticked in the shop's colour.
class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.shop, required this.ticked});

  final OnboardingShopDraft shop;
  final int ticked;

  static const _barWidths = [110.0, 80.0, 130.0];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = shop.color.toColor();
    return Container(
      width: 230,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        // Theme colours, so the card is dark in dark mode. The border keeps
        // it visible there, where a shadow alone barely shows.
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000), // black 12%
            offset: Offset(0, 14),
            blurRadius: 34,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            spacing: 7,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              Text(
                shop.name.toUpperCase(),
                style: AppTextStyles.eyebrow.copyWith(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final (i, width) in _barWidths.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                spacing: 10,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == ticked ? color : null,
                      border: i == ticked
                          ? null
                          : Border.all(
                              color: scheme.onSurface.withValues(alpha: .32),
                              width: 1.5,
                            ),
                    ),
                  ),
                  Opacity(
                    opacity: i == ticked ? .6 : 1,
                    child: Container(
                      width: i == ticked ? width * .7 : width,
                      height: 7,
                      decoration: BoxDecoration(
                        color: scheme.fill,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
