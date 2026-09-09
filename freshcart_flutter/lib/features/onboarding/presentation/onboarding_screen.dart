import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding_controller.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding_state.dart';

@Preview(name: 'Onboarding Screen', size: Size(393, 852))
Widget welcomeScreenPreview() => const ProviderScope(
  child: MaterialApp(
    home: OnboardingScreen(),
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
    final canContinue = ref.watch(
      onboardingControllerProvider.select((s) => s.canContinue),
    );

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
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Step ${step.index + 1} of ${OnboardingStep.values.length}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: canContinue
                      ? () async {
                          if (step == OnboardingStep.values.last) {
                            await controller.finish();
                          } else {
                            controller.next();
                          }
                        }
                      : null,
                  child: Text(
                    step == OnboardingStep.values.last ? 'Finish' : 'Continue',
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What should we call you?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'This is how your household will see you on shared lists.',
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            onChanged: controller.updateDisplayName,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'e.g. Alex Janssens'),
          ),
        ],
      ),
    );
  }
}

// _CreateListStep and _AddShopStep follow the same shape, reading/writing
// listName / shopName instead.

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
