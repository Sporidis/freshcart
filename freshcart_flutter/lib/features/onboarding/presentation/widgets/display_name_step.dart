import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding_controller.dart';

class DisplayNameStep extends ConsumerStatefulWidget {
  const DisplayNameStep({super.key});

  @override
  ConsumerState<DisplayNameStep> createState() => _DisplayNameStepState();
}

class _DisplayNameStepState extends ConsumerState<DisplayNameStep> {
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
                  _initialsFor(displayName),
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
