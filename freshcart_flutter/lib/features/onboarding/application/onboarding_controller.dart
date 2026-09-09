import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/auth/data/auth_repository_provider.dart';
import 'package:freshcart_flutter/features/lists/application/list_use_case_providers.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding_state.dart';
import 'package:freshcart_flutter/features/shops/data/shop_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_controller.g.dart';

/// A plain default so onboarding doesn't need its own colour picker.
///
/// The shop can be recoloured later from the shops screen — this just gets a
/// first list unblocked (`docs/decisions.md` shop-colour theming).
final _defaultShopColor = HexColor.fromArgb(0xFF4CAF50);

/// Drives the onboarding wizard: holds the draft answers, moves between
/// [OnboardingStep]s, and submits them on [finish].
///
/// One controller for the whole wizard rather than one per step — the steps
/// share a single submission at the end, so splitting the draft state up
/// would just mean re-joining it right before [finish] anyway.
@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  OnboardingState build() => const OnboardingState();

  void updateDisplayName(String value) {
    state = state.copyWith(displayName: value, clearError: true);
  }

  void updateListName(String value) {
    state = state.copyWith(listName: value, clearError: true);
  }

  void updateShopName(String value) {
    state = state.copyWith(shopName: value, clearError: true);
  }

  /// Advances to the next step, if any.
  void next() {
    const steps = OnboardingStep.values;
    final index = steps.indexOf(state.step);
    if (index >= steps.length - 1) return;
    state = state.copyWith(step: steps[index + 1], clearError: true);
  }

  /// Returns to the previous step, if any.
  void back() {
    const steps = OnboardingStep.values;
    final index = steps.indexOf(state.step);
    if (index <= 0) return;
    state = state.copyWith(step: steps[index - 1], clearError: true);
  }

  /// Submits the draft: sets the display name, creates the first list, and
  /// creates the shop if one was named.
  ///
  /// Stops at the first failure rather than continuing partially, so the
  /// wizard's error always names something the user just typed.
  Future<Result<void>> finish() async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    final name = state.displayName.trim();
    if (name.isNotEmpty) {
      final result = await ref
          .read(authRepositoryProvider)
          .setDisplayName(name);
      if (result case Err(:final failure)) {
        state = state.copyWith(isSubmitting: false, error: failure);
        return Err(failure);
      }
    }

    final listResult = await ref.read(createListUseCaseProvider)(
      state.listName,
    );
    if (listResult case Err(:final failure)) {
      state = state.copyWith(isSubmitting: false, error: failure);
      return Err(failure);
    }
    final list = (listResult as Ok<ShoppingList>).value;

    final shopName = state.shopName.trim();
    if (shopName.isNotEmpty) {
      final shopResult = await ref
          .read(shopRepositoryProvider)
          .create(listId: list.id, name: shopName, color: _defaultShopColor);
      if (shopResult case Err(:final failure)) {
        state = state.copyWith(isSubmitting: false, error: failure);
        return Err(failure);
      }
    }

    state = state.copyWith(isSubmitting: false);
    return const Ok(null);
  }
}
