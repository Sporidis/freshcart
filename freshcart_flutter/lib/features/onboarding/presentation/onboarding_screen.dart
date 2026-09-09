import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding_controller.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding_state.dart';

@Preview(name: 'Onboarding Screen', size: Size(393, 852))
Widget welcomeScreenPreview() => ProviderScope(
  child: MaterialApp(
    theme: AppTheme.light(AppTheme.brandSeed),
    home: const OnboardingScreen(),
    debugShowCheckedModeBanner: false,
  ),
);

class OnboardingScreen extends ConsumerStatefulWidget {
  final bool isInvited;
  const OnboardingScreen({super.key, this.isInvited = false});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final step = ref.watch(onboardingControllerProvider.select((s) => s.step));

    // The controller is the source of truth for the step; this just makes
    // the PageView follow it instead of the other way around.
    ref.listen(onboardingControllerProvider.select((s) => s.step), (
      _,
      next,
    ) {
      _pageController.animateToPage(
        next.index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });

    return Scaffold(
      appBar: AppBar(
        leading: step == OnboardingStep.values.first
            ? null
            : BackButton(onPressed: controller.back),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Step indicator
                  Row(
                    children: List.generate(
                      OnboardingStep.values.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: step.index == index ? 24 : 6,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: step.index == index
                              ? Colors.black
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Step ${step.index + 1} of ${OnboardingStep.values.length}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                // No user-driven scrolling — Continue/Back own navigation.
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _DisplayNameStep(),
                  _CreateListStep(),
                  _AddShopStep(),
                ],
              ),
            ),
            const _ContinueButton(),
          ],
        ),
      ),
    );
  }
}

class _ContinueButton extends ConsumerWidget {
  const _ContinueButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final step = ref.watch(onboardingControllerProvider).step;
    final canContinue = ref.watch(onboardingControllerProvider).canContinue;

    return AnimatedSwitcher(
      duration: AppMotion.bouncy,
      switchInCurve: AppMotion.pop,
      switchOutCurve: AppMotion.exit,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.88,
              end: 1,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: canContinue
          ? Padding(
              key: const ValueKey('continue-button'),
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (step == OnboardingStep.values.last) {
                      await controller.finish();
                    } else {
                      controller.next();
                    }
                  },
                  child: Text(
                    step == OnboardingStep.values.last ? 'Finish' : 'Continue',
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(key: ValueKey('hidden-button')),
    );
  }
}

class _CreateListStep extends ConsumerWidget {
  const _CreateListStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What's the name of your list?",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'This is how your household will see the list.',
          ),
          const SizedBox(height: 24),
          TextField(
            onChanged: controller.updateListName,
            decoration: const InputDecoration(hintText: 'e.g. Grocery List'),
          ),
        ],
      ),
    );
  }
}

class _DisplayNameStep extends ConsumerStatefulWidget {
  const _DisplayNameStep();

  @override
  ConsumerState<_DisplayNameStep> createState() => _DisplayNameStepState();
}

class _DisplayNameStepState extends ConsumerState<_DisplayNameStep> {
  late final _controller = TextEditingController(
    text: ref.read(onboardingControllerProvider).displayName,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final displayName = ref.watch(
      onboardingControllerProvider.select((state) => state.displayName),
    );
    final initials = _initialsFor(displayName);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What should we call you?',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'This is how your household sees you on shared lists.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.avatarColorFor(displayName),
                foregroundColor: Colors.white,
                child: Text(
                  initials,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: controller.updateDisplayName,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Alex Janssens',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _initialsFor(String displayName) {
  final trimmedName = displayName.trim();
  if (trimmedName.isEmpty) return '?';

  final words = trimmedName.split(RegExp(r'\s+'));
  if (words.length == 1) return words.first.characters.first.toUpperCase();
  return '${words.first.characters.first}${words.last.characters.first}'
      .toUpperCase();
}

class _AddShopStep extends ConsumerStatefulWidget {
  const _AddShopStep();

  @override
  ConsumerState<_AddShopStep> createState() => _AddShopStepState();
}

class _AddShopStepState extends ConsumerState<_AddShopStep> {
  late final _controller = TextEditingController(
    text: ref.read(onboardingControllerProvider).shopName,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What's the name of your shop?",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'This is how your household will see the shop.',
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            onChanged: controller.updateShopName,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'e.g. Local Market'),
          ),
        ],
      ),
    );
  }
}
