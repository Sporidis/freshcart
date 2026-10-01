import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/list_repository_impl.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding/onboarding_state.dart';
import 'package:freshcart_flutter/features/shops/data/repositories/shop_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_controller.g.dart';

/// A plain default so onboarding doesn't need its own colour picker.
///
/// The shop can be recoloured later from the shops screen — this just gets a
/// first list unblocked (`docs/decisions.md` shop-colour theming).
/// Drives the onboarding wizard: holds the draft answers, moves between
/// [OnboardingStep]s, and submits them on [finish].
///
/// One controller for the whole wizard rather than one per step — the steps
/// share a single submission at the end, so splitting the draft state up
/// would just mean re-joining it right before [finish] anyway.
@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  OnboardingState build() =>
      OnboardingState(selectedShops: presetShops.take(2).toList());

  void updateDisplayName(String value) {
    state = state.copyWith(displayName: value, clearError: true);
  }

  void updateListName(String value) {
    state = state.copyWith(listName: value, clearError: true);
  }

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

  /// Advances past the current step if its answer is valid; otherwise records
  /// why in [OnboardingState.error] and stays put.
  ///
  /// This is what lets Continue stay on screen the whole time (Motion spec
  /// §07: "Continue stays fixed -- never re-animates") instead of hiding
  /// until the field is valid: the button is always pressable, and pressing
  /// it with a bad answer is what surfaces the inline error. The next
  /// keystroke clears it again -- every `update*` above already passes
  /// `clearError: true`.
  ///
  /// Returns whether it advanced, so the caller can fire the step haptic
  /// only on a real advance.
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
  /// creates every selected shop. Called when leaving [OnboardingStep.addShop]
  /// rather than at the very end of the wizard — [OnboardingStep.invite],
  /// the step after it, shows the *real* list's join code, so the list has
  /// to exist before that step can render.
  ///
  /// Stops at the first failure rather than continuing partially, so the
  /// wizard's error always names something the user just typed. On success,
  /// advances to [OnboardingStep.invite] itself; the caller does not need a
  /// separate [next] call.
  Future<Result<void>> submit() async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    // Trimming and length are the use case's business now, not this
    // controller's — the wizard just hands over what the user typed.
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
