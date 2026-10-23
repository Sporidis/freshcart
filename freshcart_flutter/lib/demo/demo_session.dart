import 'dart:async';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/demo/demo_backend.dart';
import 'package:freshcart_flutter/demo/demo_stage.dart';
import 'package:freshcart_flutter/demo/director/demo_director.dart';

/// One showing of the demo: a fresh backend, a stage, and the intro
/// playing on it. Starts when the first phone appears.
class DemoSession {
  DemoSession() {
    unawaited(director.run());
  }

  final backend = DemoBackend(clock: systemClock);
  final stage = DemoStage();
  late final director = DemoDirector(stage);

  void _end() {
    director.cancel();
    stage.dispose();
    unawaited(backend.dispose());
  }
}

/// Keeps one [DemoSession] alive while any phone is open.
///
/// The portfolio's modal can close (both views removed) and reopen many
/// times per page load. Each reopening gets a fresh session, so the visitor
/// always sees the intro again on an empty backend.
class DemoSessions {
  DemoSession? _current;
  int _phones = 0;

  /// A phone appeared: join the running session, or start one.
  DemoSession attach() {
    _phones++;
    return _current ??= DemoSession();
  }

  /// A phone went away. The last one out ends the session.
  void detach(DemoSession session) {
    if (session != _current) return;
    _phones--;
    if (_phones > 0) return;
    _current = null;
    session._end();
  }
}
