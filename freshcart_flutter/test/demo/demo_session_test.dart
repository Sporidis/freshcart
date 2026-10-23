import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_flutter/demo/demo_session.dart';

/// The portfolio's modal closes and reopens the phones many times per page
/// load. Every reopening must be a clean session.
void main() {
  test('two phones open together share one session', () {
    final sessions = DemoSessions();
    final a = sessions.attach();
    final b = sessions.attach();
    expect(b, same(a));
  });

  test('the session lives until the last phone leaves', () {
    final sessions = DemoSessions();
    final first = sessions.attach();
    sessions
      ..attach()
      ..detach(first);

    // One phone still open: a phone added now joins the same session.
    final again = sessions.attach();
    expect(again, same(first));
  });

  test('reopening after closing starts a fresh session', () {
    final sessions = DemoSessions();
    final first = sessions.attach();
    sessions
      ..attach()
      ..detach(first)
      ..detach(first);

    final reopened = sessions.attach();
    expect(reopened, isNot(same(first)));
    expect(reopened.backend, isNot(same(first.backend)));
    // The old backend is closed, but a late save notifying it is harmless.
    expect(first.backend.notify, returnsNormally);
  });

  test('a phone from an old session leaving does not end the new one', () {
    final sessions = DemoSessions();
    final old = sessions.attach();
    sessions.detach(old);
    final current = sessions.attach();

    sessions.detach(old); // a late dispose from the previous showing
    expect(sessions.attach(), same(current));
  });
}
