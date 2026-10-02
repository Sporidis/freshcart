import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/list_repository_impl.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding/onboarding_state.dart';
import 'package:freshcart_flutter/features/shops/data/repositories/shop_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_controller.g.dart';

/// Runs the onboarding wizard: keeps the user's answers, moves between
/// [OnboardingStep]s, and saves everything with [submit].
///
/// One controller for all steps (not one per step), because all answers
/// are saved together in [submit].
@riverpod
class OnboardingController extends _$OnboardingController {
  /// Starts on step 1, with the first two preset shops already selected.
  @override
  OnboardingState build() =>
      OnboardingState(selectedShops: presetShops.take(2).toList());

  /// Updates the name the user is typing. Clears any error.
  void updateDisplayName(String value) {
    state = state.copyWith(displayName: value, clearError: true);
  }

  /// Updates the list name the user is typing. Clears any error.
  void updateListName(String value) {
    state = state.copyWith(listName: value, clearError: true);
  }

  /// Selects the shop [name] if it isn't selected, or unselects it if it is.
  void toggleShop(String name, HexColor color) {
    final shops = [...state.selectedShops];
    final index = shops.indexWhere((shop) => shop.name == name);
    if (index == -1) {
      shops.add(OnboardingShopDraft(name: name, color: color));
    } else {
      shops.removeAt(index);
    }
    state = state.copyWith(selectedShops: shops, clearError: true);
  }

  /// Adds a shop the user typed in themselves, already selected. Ignored if
  /// the name is empty or already in the list.
  void addShop(String name, HexColor color) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || state.isShopSelected(trimmedName)) return;
    state = state.copyWith(
      selectedShops: [
        ...state.selectedShops,
        OnboardingShopDraft(name: trimmedName, color: color),
      ],
      clearError: true,
    );
  }

  /// Goes to the next step if the answer is valid. If not, saves the error
  /// in [OnboardingState.error] and stays on this step.
  ///
  /// This is why Continue can always be pressed: pressing it with a bad
  /// answer shows the error. Typing again clears it (the `update` methods
  /// above pass `clearError: true`).
  ///
  /// Returns true if it moved on, so the screen only vibrates then.
  bool continueIfValid() {
    final check = switch (state.step) {
      OnboardingStep.displayName => AuthUser.validateDisplayName(
        state.displayName,
      ),
      OnboardingStep.createList => ShoppingList.validateName(state.listName),
      OnboardingStep.addShop || OnboardingStep.invite => const Ok(''),
    };
    if (check case Err(:final failure)) {
      state = state.copyWith(error: failure);
      return false;
    }
    next();
    return true;
  }

  /// Goes to the next step, without checking the answer.
  void next() {
    const steps = OnboardingStep.values;
    final index = steps.indexOf(state.step);
    if (index >= steps.length - 1) return;
    state = state.copyWith(step: steps[index + 1], clearError: true);
  }

  /// Goes back one step (does nothing on step 1).
  void back() {
    const steps = OnboardingStep.values;
    final index = steps.indexOf(state.step);
    if (index <= 0) return;
    state = state.copyWith(step: steps[index - 1], clearError: true);
  }

  /// Saves everything: the user's name, the first list, and the selected
  /// shops.
  ///
  /// Called after the shops step, not at the very end. The last step
  /// (invite) shows the list's real join code, so the list must exist by
  /// then.
  ///
  /// Stops at the first error. If everything works, it moves to the invite
  /// step by itself (no need to call [next]).
  Future<Result<void>> submit() async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    // Pass the name as typed. The use case trims and validates it.
    final result = await SetDisplayName(ref.read(authRepositoryProvider))(
      state.displayName,
    );
    if (result case Err(:final failure)) {
      state = state.copyWith(isSubmitting: false, error: failure);
      return Err(failure);
    }

    final listResult = await CreateList(ref.read(listRepositoryProvider))(
      state.listName,
    );
    if (listResult case Err(:final failure)) {
      state = state.copyWith(isSubmitting: false, error: failure);
      return Err(failure);
    }
    final list = (listResult as Ok<ShoppingList>).value;

    for (final shop in state.selectedShops) {
      final shopResult = await CreateShop(ref.read(shopRepositoryProvider))(
        listId: list.id,
        name: shop.name,
        color: shop.color,
      );
      if (shopResult case Err(:final failure)) {
        state = state.copyWith(isSubmitting: false, error: failure);
        return Err(failure);
      }
    }

    state = state.copyWith(
      isSubmitting: false,
      createdList: list,
      step: OnboardingStep.invite,
    );
    return const Ok(null);
  }
}
