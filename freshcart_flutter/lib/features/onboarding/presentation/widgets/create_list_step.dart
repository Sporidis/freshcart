import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
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
    final t = ref.watch(translationsProvider);
    final suggestions = [
      t.onboarding.suggestionHousehold,
      t.onboarding.suggestionBigShop,
      t.onboarding.suggestionBbq,
    ];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.onboarding.listTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(t.onboarding.listSubtitle),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            onChanged: controller.updateListName,
            decoration: InputDecoration(
              hintText: t.onboarding.listPlaceholder,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: suggestions
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
