import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/demo_hooks/scripted_field.dart';
import 'package:freshcart_flutter/core/demo_hooks/scripted_text_controller.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/demo/demo_persona.dart';
import 'package:freshcart_flutter/demo/demo_stage.dart';
import 'package:freshcart_flutter/features/items/data/repositories/item_repository_impl.dart';
import 'package:freshcart_flutter/features/onboarding/application/join_flow/join_flow_controller.dart';
import 'package:freshcart_flutter/features/onboarding/application/join_flow/join_flow_state.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding/onboarding_controller.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding/onboarding_state.dart';
import 'package:go_router/go_router.dart';

/// Plays the demo's intro on the two phones, then hands them to the
/// visitor: A onboards and creates a list, B joins it with A's code, A adds
/// an item that shows up on B.
///
/// It drives the app the way the screens do (controllers, the router, the
/// repositories), never with fake taps. Text goes through the scripted-text
/// hook, because the fields keep their text private.
class DemoDirector {
  DemoDirector(this._stage, {Random? random}) : _random = random ?? Random();

  final DemoStage _stage;
  final Random _random;
  bool _cancelled = false;

  static const _beat = Duration(milliseconds: 700);
  static const _linger = Duration(milliseconds: 1800);

  /// Stops the intro where it is (the session is going away).
  void cancel() => _cancelled = true;

  /// Plays the intro, then unlocks the phones. Skip makes it finish at once.
  Future<void> run() async {
    try {
      await _play();
    } on _Cancelled {
      return;
    } finally {
      // Even if the script broke, the visitor gets working phones.
      if (!_cancelled) _stage.locked.value = false;
    }
  }

  Future<void> _play() async {
    final a = await _stage.phone(DemoPersona.a);
    final b = await _stage.phone(DemoPersona.b);

    // Both splash screens must have moved on to Welcome first. Otherwise a
    // splash still finishing would send its phone back there.
    await _waitFor(() => _path(a) == Routes.welcome);
    await _waitFor(() => _path(b) == Routes.welcome);
    await _pause(_linger);

    final list = await _onboard(a);
    await _join(b, list.joinCode);
    _router(b).go(Routes.listDetail(list.id));
    await _pause(_beat);

    final added = await a
        .read(itemRepositoryProvider)
        .add(listId: list.id, name: 'Milk');
    _check(added, 'adding Milk');
    await _pause(_beat);
  }

  /// Phone A: Welcome -> onboarding -> the new list.
  Future<ShoppingList> _onboard(ProviderContainer a) async {
    _router(a).go(Routes.onboarding);
    await _waitFor(() => a.exists(onboardingControllerProvider));
    await WidgetsBinding.instance.endOfFrame;
    final onboarding = a.read(onboardingControllerProvider.notifier);
    OnboardingState state() => a.read(onboardingControllerProvider);

    await _pause(_beat);
    await _type(a, ScriptedField.onboardingName, DemoPersona.a.name);
    await _pause(_beat);
    _require(onboarding.continueIfValid(), 'the name step');

    // The list step fills in its default name one frame after it appears.
    // Typing before that would be overwritten.
    await _waitFor(() => state().listName.isNotEmpty);
    await _pause(_beat);
    await _type(a, ScriptedField.onboardingListName, 'Home');
    await _pause(_beat);
    _require(onboarding.continueIfValid(), 'the list step');

    // Shops: keep the two presets.
    await _waitFor(() => state().step == OnboardingStep.addShop);
    await _pause(_linger);
    _check(await onboarding.submit(), 'onboarding');

    // Invite: let the join code be seen before leaving.
    await _pause(_linger);
    final list = state().createdList!;
    _router(a).go(Routes.listDetail(list.id));
    await _pause(_beat);
    return list;
  }

  /// Phone B: Welcome -> join flow with [code]. Stays on the confirmation.
  Future<void> _join(ProviderContainer b, JoinCode code) async {
    _router(b).go(Routes.join);
    await _waitFor(() => b.exists(joinFlowControllerProvider));
    await WidgetsBinding.instance.endOfFrame;
    final join = b.read(joinFlowControllerProvider.notifier);

    await _pause(_beat);
    await _type(b, ScriptedField.joinName, DemoPersona.b.name);
    await _pause(_beat);
    _require(join.continueFromName(), 'the join name step');

    await _waitFor(
      () => b.read(joinFlowControllerProvider).step == JoinFlowStep.code,
    );
    await WidgetsBinding.instance.endOfFrame;
    await _pause(_beat);
    await _type(b, ScriptedField.joinCode, code.value);
    await _pause(_beat);
    _check(await join.submit(), 'joining');
    await _pause(_linger);
  }

  /// Types [text] into [field] one character at a time.
  Future<void> _type(
    ProviderContainer phone,
    ScriptedField field,
    String text,
  ) async {
    final scripted = phone.read(scriptedTextControllerProvider.notifier);
    for (var i = 1; i <= text.length; i++) {
      scripted.type(field, text.substring(0, i));
      await _pause(Duration(milliseconds: 60 + _random.nextInt(71)));
    }
  }

  /// A pause for the viewer. Skipped when fast-forwarding.
  Future<void> _pause(Duration duration) async {
    if (_cancelled) throw const _Cancelled();
    if (_stage.fastForward) return;
    await Future<void>.delayed(duration);
    if (_cancelled) throw const _Cancelled();
  }

  /// Waits until [condition] holds. Never skipped: it waits for the app,
  /// not for the viewer.
  Future<void> _waitFor(bool Function() condition) async {
    while (!condition()) {
      if (_cancelled) throw const _Cancelled();
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }
  }

  GoRouter _router(ProviderContainer phone) => phone.read(appRouterProvider);

  String _path(ProviderContainer phone) => _router(phone).state.uri.path;

  /// The script assumes the fakes accept everything it does. If one
  /// doesn't, that's a bug in the demo, so stop loudly.
  void _check(Result<Object?> result, String what) {
    if (result case Err(:final failure)) {
      throw StateError('Demo intro failed at $what: $failure');
    }
  }

  void _require(bool moved, String what) {
    if (!moved) throw StateError('Demo intro could not leave $what');
  }
}

class _Cancelled implements Exception {
  const _Cancelled();
}
