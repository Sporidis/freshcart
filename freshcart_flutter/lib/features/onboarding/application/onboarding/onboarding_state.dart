import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding/onboarding_shop_draft.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding/onboarding_step.dart';

/// The shops offered on the "Where do you shop?" step.
///
/// The first two are selected by default. The user can also add their own.
final List<OnboardingShopDraft> presetShops = [
  OnboardingShopDraft(
    name: 'Albert Heijn',
    color: HexColor.fromArgb(0xFF2456A6),
  ),
  OnboardingShopDraft(name: 'Colruyt', color: HexColor.fromArgb(0xFFE8791A)),
  OnboardingShopDraft(name: 'Delhaize', color: HexColor.fromArgb(0xFFC0392B)),
];

/// The user's answers in the onboarding wizard, before they're saved.
///
/// Nothing is saved until [OnboardingController.submit]. This lives in
/// `application/`, not the domain, because it's only screen state.
class OnboardingState {
  const OnboardingState({
    this.step = OnboardingStep.displayName,
    this.displayName = '',
    this.listName = '',
    this.selectedShops = const [],
    this.isSubmitting = false,
    this.error,
    this.createdList,
  });

  final OnboardingStep step;
  final String displayName;
  final String listName;

  final List<OnboardingShopDraft> selectedShops;

  final bool isSubmitting;
  final Failure? error;

  /// The list that [OnboardingController.submit] created. Null until then.
  /// The invite step uses it to show the real join code.
  final ShoppingList? createdList;

  OnboardingState copyWith({
    OnboardingStep? step,
    String? displayName,
    String? listName,
    List<OnboardingShopDraft>? selectedShops,
    bool? isSubmitting,
    Failure? error,
    bool clearError = false,
    ShoppingList? createdList,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      displayName: displayName ?? this.displayName,
      listName: listName ?? this.listName,
      selectedShops: selectedShops ?? this.selectedShops,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      createdList: createdList ?? this.createdList,
    );
  }

  /// All shops shown on the shops step: the presets, then the ones the user
  /// added (without duplicates).
  List<OnboardingShopDraft> get shopOptions => [
    ...presetShops,
    for (final shop in selectedShops)
      if (!presetShops.any((preset) => preset.name == shop.name)) shop,
  ];

  bool isShopSelected(String name) =>
      selectedShops.any((shop) => shop.name == name);
}
