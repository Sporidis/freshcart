import 'package:freshcart_domain/freshcart_domain.dart';

/// One page of the onboarding wizard, in display order.
enum OnboardingStep { displayName, createList, addShop }

class OnboardingShopDraft {
  const OnboardingShopDraft({required this.name, required this.color});

  final String name;
  final HexColor color;
}

/// The onboarding wizard's draft answers.
///
/// Nothing here is persisted until [OnboardingController.finish] submits it —
/// that's why this is a plain state class living in `application/`, not a
/// domain entity: the domain has no concept of an in-progress onboarding.
class OnboardingState {
  const OnboardingState({
    this.step = OnboardingStep.displayName,
    this.displayName = '',
    this.listName = '',
    this.selectedShops = const [],
    this.isSubmitting = false,
    this.error,
  });

  final OnboardingStep step;
  final String displayName;
  final String listName;

  final List<OnboardingShopDraft> selectedShops;

  final bool isSubmitting;
  final Failure? error;

  OnboardingState copyWith({
    OnboardingStep? step,
    String? displayName,
    String? listName,
    List<OnboardingShopDraft>? selectedShops,
    bool? isSubmitting,
    Failure? error,
    bool clearError = false,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      displayName: displayName ?? this.displayName,
      listName: listName ?? this.listName,
      selectedShops: selectedShops ?? this.selectedShops,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool isShopSelected(String name) =>
      selectedShops.any((shop) => shop.name == name);

  /// Whether the current step's answer is good enough to move on.
  ///
  /// Delegates to the domain's own validators rather than restating their
  /// rules: this only decides whether to *enable* the button, and if the
  /// enabling rule and the writing rule disagree the user gets a button that
  /// does nothing. The use cases enforce; this merely predicts.
  bool get canContinue => switch (step) {
    OnboardingStep.displayName => AuthUser.validateDisplayName(
      displayName,
    ).isOk,
    OnboardingStep.createList => ShoppingList.validateName(listName).isOk,
    OnboardingStep.addShop => true,
  };
}
