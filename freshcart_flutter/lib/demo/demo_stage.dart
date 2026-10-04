import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/demo/demo_persona.dart';

/// What the director and the phones share during one demo session: which
/// phone is which, whether the visitor may touch them yet, and Skip.
class DemoStage {
  final _phones = <DemoPersona, Completer<ProviderContainer>>{};

  /// True while the intro plays. The phones ignore the visitor until then.
  final locked = ValueNotifier<bool>(true);

  /// Set by Skip: the director stops pausing and finishes at once.
  bool fastForward = false;

  /// Called by a phone once its container exists.
  void register(DemoPersona persona, ProviderContainer container) {
    final waiting = _phones[persona];
    if (waiting == null || waiting.isCompleted) {
      _phones[persona] = Completer()..complete(container);
    } else {
      waiting.complete(container);
    }
  }

  /// The container of [persona]'s phone, once that phone exists.
  Future<ProviderContainer> phone(DemoPersona persona) =>
      _phones.putIfAbsent(persona, Completer.new).future;

  /// Skip: finish the intro now.
  void skip() => fastForward = true;

  void dispose() => locked.dispose();
}
