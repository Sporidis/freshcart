import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/list_repository_impl.dart';
import 'package:freshcart_flutter/features/onboarding/application/join_flow/join_flow_state.dart';
import 'package:freshcart_flutter/features/onboarding/application/join_flow/join_flow_step.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'join_flow_controller.g.dart';

/// Runs the "join with a code" flow: ask the name, then the code, then
/// join that list.
///
/// Separate from [OnboardingController]. The two flows only share the
/// "your name" step. Combining them would fill `OnboardingState` with
/// fields that don't apply when joining (list name, shops).
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

  /// Goes from the name step to the code step if the name is valid. If not,
  /// saves the error in [JoinFlowState.error] and stays. Works like
  /// `OnboardingController.continueIfValid`.
  ///
  /// Nothing is saved yet. Returns true if it moved on.
  bool continueFromName() {
    if (state.step != JoinFlowStep.name) return false;
    if (AuthUser.validateDisplayName(state.displayName) case Err(
      :final failure,
    )) {
      state = state.copyWith(error: failure);
      return false;
    }
    state = state.copyWith(step: JoinFlowStep.code, clearError: true);
    return true;
  }

  /// Goes back one step (does nothing on the first step).
  void back() {
    if (state.step == JoinFlowStep.code) {
      state = state.copyWith(step: JoinFlowStep.name, clearError: true);
    }
  }

  /// Saves the user's name, then joins the list with code [state.code].
  ///
  /// Stops at the first error. If it works, moves to
  /// [JoinFlowStep.confirmation] by itself.
  Future<Result<void>> submit() async {
    // Check the code first, before saving anything. Otherwise a half-typed
    // code would still save the name, and then fail on joining.
    if (JoinCode.parse(state.code) case Err(:final failure)) {
      state = state.copyWith(error: failure);
      return Err(failure);
    }
    state = state.copyWith(isSubmitting: true, clearError: true);

    final nameResult = await SetDisplayName(ref.read(authRepositoryProvider))(
      state.displayName,
    );
    if (nameResult case Err(:final failure)) {
      state = state.copyWith(isSubmitting: false, error: failure);
      return Err(failure);
    }

    // Keep the colour the avatar showed while the name was typed, so lists
    // show the same one (decisions.md #111). Not if the user already chose
    // a colour. Cosmetic: if saving fails, the automatic colour is used.
    final auth = ref.read(authRepositoryProvider);
    if (auth.currentUser?.avatarColor == null) {
      await auth.setAvatarColor(AppColors.avatarHexColorFor(state.displayName));
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
