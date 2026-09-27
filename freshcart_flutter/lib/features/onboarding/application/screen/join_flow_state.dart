import 'package:freshcart_domain/freshcart_domain.dart';

/// One page of the join-by-code flow, in display order.
///
/// Shorter than [OnboardingStep] (`onboarding_state.dart`) — this is the
/// welcome screen's *other* exit, for someone joining a list someone else
/// already made rather than starting their own, so there is no list, shop
/// or invite step to walk through.
enum JoinFlowStep { name, code, confirmation }

/// The join flow's draft answers.
///
/// Nothing here is persisted until [JoinFlowController.submit] submits it —
/// same reasoning as [OnboardingState]: this is in-progress UI state, not
/// something the domain has any concept of.
class JoinFlowState {
  const JoinFlowState({
    this.step = JoinFlowStep.name,
    this.displayName = '',
    this.code = '',
    this.isSubmitting = false,
    this.error,
    this.joinedList,
  });

  final JoinFlowStep step;
  final String displayName;
  final String code;

  final bool isSubmitting;
  final Failure? error;

  /// Set once [JoinFlowController.submit] succeeds — the confirmation step's
  /// only reason to exist is showing which real list this became.
  final ShoppingList? joinedList;

  JoinFlowState copyWith({
    JoinFlowStep? step,
    String? displayName,
    String? code,
    bool? isSubmitting,
    Failure? error,
    bool clearError = false,
    ShoppingList? joinedList,
  }) {
    return JoinFlowState(
      step: step ?? this.step,
      displayName: displayName ?? this.displayName,
      code: code ?? this.code,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      joinedList: joinedList ?? this.joinedList,
    );
  }

  /// Whether the current step's answer is good enough to move on. Mirrors
  /// [OnboardingState.canContinue]'s own rule: delegate to the domain's
  /// validators rather than restate them, and use this only to enable the
  /// button — the use cases still enforce the rule for real.
  bool get canContinue => switch (step) {
    JoinFlowStep.name => AuthUser.validateDisplayName(displayName).isOk,
    JoinFlowStep.code => JoinCode.parse(code).isOk,
    JoinFlowStep.confirmation => true,
  };
}
