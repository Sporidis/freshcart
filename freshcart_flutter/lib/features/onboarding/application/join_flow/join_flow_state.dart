import 'package:freshcart_domain/freshcart_domain.dart';

/// The steps of the "join with a code" flow, in order.
///
/// Shorter than onboarding: the user joins an existing list, so there's no
/// list, shops or invite step.
enum JoinFlowStep { name, code, confirmation }

/// The user's answers in the join flow, before they're saved.
///
/// Nothing is saved until [JoinFlowController.submit]. Only screen state,
/// like [OnboardingState].
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

  /// The list that was joined. Set once [JoinFlowController.submit] works.
  /// The confirmation step shows its name.
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
}
