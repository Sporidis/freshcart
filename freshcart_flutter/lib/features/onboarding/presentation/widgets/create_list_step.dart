import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding_controller.dart';

class CreateListStep extends ConsumerStatefulWidget {
  const CreateListStep({super.key});

  @override
  ConsumerState<CreateListStep> createState() => _CreateListStepState();
}

class _CreateListStepState extends ConsumerState<CreateListStep> {
  late final _controller = TextEditingController(
    text: ref.read(onboardingControllerProvider).listName,
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
            'Name your first list',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('You can add more later — a BBQ, a trip, a big shop.'),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            onChanged: controller.updateListName,
            decoration: const InputDecoration(hintText: 'e.g. Grocery List'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: ['Household', 'Big shop', 'BBQ']
                .map(
                  (suggestion) => ActionChip(
                    label: Text(suggestion),
                    onPressed: () {
                      _controller
                        ..text = suggestion
                        ..selection = TextSelection.collapsed(
                          offset: suggestion.length,
                        );
                      controller.updateListName(suggestion);
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

@Preview(
  group: 'Onboarding',
  name: 'Step 2 · Name the list',
  size: previewPhone,
)
Widget createListStepPreview() => previewPage(const CreateListStep());
