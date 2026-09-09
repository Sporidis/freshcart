import 'package:freshcart_domain/freshcart_domain.dart';

/// One page of the onboarding wizard, in display order.
enum OnboardingStep { displayName, createList, addShop }

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
    this.shopName = '',
    this.isSubmitting = false,
    this.error,
  });

  final OnboardingStep step;
  final String displayName;
  final String listName;

  /// Blank means "skip adding a shop" — it's optional, unlike [listName].
  final String shopName;

  final bool isSubmitting;
  final Failure? error;

  OnboardingState copyWith({
    OnboardingStep? step,
    String? displayName,
    String? listName,
    String? shopName,
    bool? isSubmitting,
    Failure? error,
    bool clearError = false,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      displayName: displayName ?? this.displayName,
      listName: listName ?? this.listName,
      shopName: shopName ?? this.shopName,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get canContinue {
    switch (step) {
      case OnboardingStep.displayName:
        return _isDisplayNameValid(displayName);
      case OnboardingStep.createList:
        return _isListNameValid(listName);
      case OnboardingStep.addShop:
        return true; // shopName is optional
    }
  }

  bool _isDisplayNameValid(String displayName) {
    return displayName.isNotEmpty && displayName.length >= 2;
  }

  bool _isListNameValid(String listName) {
    return listName.isNotEmpty;
  }
}
