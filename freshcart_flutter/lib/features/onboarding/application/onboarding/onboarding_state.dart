import 'package:freshcart_domain/freshcart_domain.dart';

/// One page of the onboarding wizard, in display order.
enum OnboardingStep { displayName, createList, addShop, invite }

class OnboardingShopDraft {
  const OnboardingShopDraft({required this.name, required this.color});

  final String name;
  final HexColor color;
}

/// The shops the "Where do you shop?" step offers out of the box, in order.
///
/// The one place they're named: the wizard pre-selects the first two of
/// these, and the step lists all of them plus anything the user typed in.
final List<OnboardingShopDraft> presetShops = [
  OnboardingShopDraft(
    name: 'Albert Heijn',
    color: HexColor.fromArgb(0xFF2456A6),
  ),
  OnboardingShopDraft(name: 'Colruyt', color: HexColor.fromArgb(0xFFE8791A)),
  OnboardingShopDraft(name: 'Delhaize', color: HexColor.fromArgb(0xFFC0392B)),
];

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
    this.createdList,
  });

  final OnboardingStep step;
  final String displayName;
  final String listName;

  final List<OnboardingShopDraft> selectedShops;

  final bool isSubmitting;
  final Failure? error;

  /// The list [OnboardingController.submit] created, once the shops step is
  /// done — only set once submission succeeds, which is also the only time
  /// the wizard reaches [OnboardingStep.invite], the one step that needs it
  /// (to show the real join code, not a placeholder).
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

  /// Every shop the add-shop step lists: the presets, then any shop the
  /// user added themselves (presets never twice).
  List<OnboardingShopDraft> get shopOptions => [
    ...presetShops,
    for (final shop in selectedShops)
      if (!presetShops.any((preset) => preset.name == shop.name)) shop,
  ];

  bool isShopSelected(String name) =>
      selectedShops.any((shop) => shop.name == name);
}
