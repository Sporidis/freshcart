import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/welcome_screen_animations.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/blob_background.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/cart_painter.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/grocery_item_shapes.dart';

@Preview(name: 'Welcome Screen', size: Size(393, 852))
Widget welcomeScreenPreview() => ProviderScope(
  child: MaterialApp(
    theme: AppTheme.light(AppTheme.brandSeed),
    home: const WelcomeScreen(),
    debugShowCheckedModeBanner: false,
  ),
);

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  late final WelcomeScreenAnimations _animations;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    _animations = WelcomeScreenAnimations(vsync: this)..playIntro();
  }

  Future<void> _handleStart() async {
    if (_exiting) return;
    setState(() => _exiting = true);
    await _animations.playExit();
    if (!mounted) return;
    _navigateToOnboarding();
  }

  void _navigateToOnboarding() {
    // Onboarding flow / routing hooks in here later.
  }

  @override
  void dispose() {
    _animations.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context, [WidgetRef? ref]) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final anim = _animations;

    return Scaffold(
      body: Stack(
        children: [
          // Aurora-style gradient backdrop.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.surface,
                    Color.alphaBlend(
                      colors.primary.withValues(alpha: 0.06),
                      colors.surface,
                    ),
                  ],
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: anim.blobFade,
            child: Stack(
              children: [
                Blob(
                  color: colors.primary,
                  size: 260,
                  alignment: const Alignment(-1.3, -0.9),
                ),
                Blob(
                  color: colors.tertiary,
                  size: 220,
                  alignment: const Alignment(1.3, 0.8),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  FadeTransition(
                    opacity: anim.cartFade,
                    child: SizedBox(
                      height: 220,
                      child: AnimatedBuilder(
                        animation: anim.cartListenable,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(anim.cartOffsetX, 0),
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            clipBehavior: Clip.none,
                            children: [
                              // Behind the items, so they read as inside the cart.
                              CustomPaint(
                                size: const Size(220, 150),
                                painter: CartBackPainter(
                                  color: colors.primary,
                                  wheelRotation: anim.wheelRotation,
                                ),
                              ),
                              FallingItem(
                                path: anim.item1Path,
                                rotate: anim.item1Rotate,
                                bottom: 108,
                                child: AppleShape(color: colors.tertiary),
                              ),
                              FallingItem(
                                path: anim.item2Path,
                                rotate: anim.item2Rotate,
                                bottom: 110,
                                child: const CartonShape(),
                              ),
                              FallingItem(
                                path: anim.item3Path,
                                rotate: anim.item3Rotate,
                                bottom: 114,
                                child: BreadShape(color: colors.secondary),
                              ),
                              // In front of the items, so the basket occludes their lower half.
                              CustomPaint(
                                size: const Size(220, 150),
                                painter: CartFrontPainter(
                                  color: colors.primary,
                                  fillColor: colors.surface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeTransition(
                    opacity: anim.contentExitOpacity,
                    child: FadeTransition(
                      opacity: anim.titleFade,
                      child: SlideTransition(
                        position: anim.titleSlide,
                        child: Column(
                          children: [
                            Text(
                              'FreshCart',
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Shop together, in real time.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 4),
                  FadeTransition(
                    opacity: anim.contentExitOpacity,
                    child: FadeTransition(
                      opacity: anim.buttonFade,
                      child: SlideTransition(
                        position: anim.buttonSlide,
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _exiting ? null : _handleStart,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Start'),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
