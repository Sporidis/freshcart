import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';

import 'demo_world.dart';

void main() {
  test('generated join codes always pass the domain parser', () {
    final db = DemoWorld().db;
    for (var i = 0; i < 200; i++) {
      final code = db.newJoinCode();
      expect(JoinCode.parse(code.value), Ok(code));
    }
  });

  test('ids are unique', () {
    final db = DemoWorld().db;
    final ids = {for (var i = 0; i < 50; i++) db.newId('x')};
    expect(ids, hasLength(50));
  });

  test('watch sends the current value, then again on every change', () async {
    final db = DemoWorld().db;
    var value = 1;
    final seen = <int>[];
    final sub = db.watch(() => value).listen(seen.add);
    await pumpEventQueue();
    value = 2;
    db.notify();
    await pumpEventQueue();
    await sub.cancel();
    expect(seen, [1, 2]);
  });
}
