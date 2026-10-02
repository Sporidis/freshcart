import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/shake_on_error.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding/onboarding_controller.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_entrance.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_step_header.dart';

/// Step 2: name your first list.
///
/// Starts with a default name, already selected. Most people can just tap
/// Continue. To change it, just start typing (it replaces the selection).
class CreateListStep extends ConsumerStatefulWidget {
  const CreateListStep({super.key});

  @override
  ConsumerState<CreateListStep> createState() => _CreateListStepState();
}

class _CreateListStepState extends ConsumerState<CreateListStep> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(onboardingControllerProvider).listName;
    final text = draft.isEmpty
        ? ref.read(translationsProvider).onboarding.defaultListName
        : draft;
    _controller = TextEditingController(text: text)
      ..selection = TextSelection(baseOffset: 0, extentOffset: text.length);
    if (draft.isEmpty) {
      // Delayed until after this frame: Riverpod doesn't allow changing a
      // provider while widgets are building, and initState is part of that.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(onboardingControllerProvider.notifier).updateListName(text);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _useSuggestion(String suggestion) {
    _controller
      ..text = suggestion
      ..selection = TextSelection.collapsed(offset: suggestion.length);
    ref.read(onboardingControllerProvider.notifier).updateListName(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final error = ref.watch(
      onboardingControllerProvider.select((s) => s.error),
    );
    final t = ref.watch(translationsProvider);
    final suggestions = [
      t.onboarding.suggestionHousehold,
      t.onboarding.suggestionBigShop,
      t.onboarding.suggestionBbq,
    ];
    final errorText = error?.toMessage(t);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sheetH,
        AppSpacing.screen,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingStepHeader(
            title: t.onboarding.listTitle,
            subtitle: t.onboarding.listSubtitle,
          ),
          const SizedBox(height: AppSpacing.screen),
          OnboardingEntrance(
            index: 2,
            child: ShakeOnError(
              errorText: errorText,
              child: TextField(
                controller: _controller,
                onChanged: controller.updateListName,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: t.onboarding.listPlaceholder,
                  errorText: errorText,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.gap),
          OnboardingEntrance(
            index: 3,
            child: Wrap(
              spacing: AppSpacing.gapSmall,
              runSpacing: AppSpacing.gapSmall,
              children: [
                for (final suggestion in suggestions)
                  _SuggestionPill(
                    label: suggestion,
                    onTap: () => _useSuggestion(suggestion),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A suggested name, as a pill with only a border. Not [ActionChip],
/// because its filled look competed with the Continue button.
class _SuggestionPill extends StatelessWidget {
  const _SuggestionPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTapTarget,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gap),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
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
