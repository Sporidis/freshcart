import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/list_repository_impl.dart';
import 'package:freshcart_flutter/features/onboarding/application/join_flow/join_flow_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'join_flow_controller.g.dart';

/// Drives the join-by-code flow: a name, then a code, then whichever list
/// that code identifies.
///
/// A separate controller from [OnboardingController] rather than a second
/// mode bolted onto it — the two flows share exactly one step in the design
/// (asking for a name) and diverge completely after it; forcing them into
/// one state machine would mean every field on `OnboardingState` (list name,
/// shop drafts) growing a "not applicable on this path" case.
@riverpod
class JoinFlowController extends _$JoinFlowController {
  @override
  JoinFlowState build() => const JoinFlowState();

  void updateDisplayName(String value) {
    state = state.copyWith(displayName: value, clearError: true);
  }

  void updateCode(String value) {
    state = state.copyWith(code: value, clearError: true);
  }

  /// Advances from the name step to the code step. Plain and synchronous —
  /// unlike [submit], nothing is written anywhere yet.
  void continueFromName() {
    if (state.step != JoinFlowStep.name) return;
    state = state.copyWith(step: JoinFlowStep.code, clearError: true);
  }

  /// Returns to the previous step, if any.
  void back() {
    if (state.step == JoinFlowStep.code) {
      state = state.copyWith(step: JoinFlowStep.name, clearError: true);
    }
  }

  /// Sets the display name, then joins the list [state.code] identifies.
  ///
  /// Stops at the first failure, same reasoning as
  /// [OnboardingController.submit]: a failure here always names something
  /// the user just typed (an empty name, or a code with no match), not a
  /// generic "something went wrong". On success, advances to
  /// [JoinFlowStep.confirmation] itself.
  Future<Result<void>> submit() async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    final nameResult = await SetDisplayName(ref.read(authRepositoryProvider))(
      state.displayName,
    );
    if (nameResult case Err(:final failure)) {
      state = state.copyWith(isSubmitting: false, error: failure);
      return Err(failure);
    }

    final joinResult = await JoinList(ref.read(listRepositoryProvider))(
      state.code,
    );
    if (joinResult case Err(:final failure)) {
      state = state.copyWith(isSubmitting: false, error: failure);
      return Err(failure);
    }

    state = state.copyWith(
      isSubmitting: false,
      joinedList: (joinResult as Ok<ShoppingList>).value,
      step: JoinFlowStep.confirmation,
    );
    return const Ok(null);
  }
}
