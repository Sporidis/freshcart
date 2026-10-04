import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/app.dart';
import 'package:freshcart_flutter/demo/demo_backend.dart';
import 'package:freshcart_flutter/demo/demo_overrides.dart';
import 'package:freshcart_flutter/demo/demo_persona.dart';

/// One phone in the demo: the real [FreshCartApp] with its own
/// [ProviderContainer] (its own router, controllers and settings), on the
/// [backend] it shares with the other phone.
///
/// Which persona it is comes from the host page's
/// `addView({initialData: {persona: 'a' | 'b'}})`.
class DemoPhone extends StatefulWidget {
  const DemoPhone({required this.backend, super.key});

  final DemoBackend backend;

  @override
  State<DemoPhone> createState() => _DemoPhoneState();
}

class _DemoPhoneState extends State<DemoPhone> {
  ProviderContainer? _container;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Here, not in initState: View.of needs an inherited widget lookup.
    // Created once; the view id never changes for this State.
    _container ??= createPhoneContainer(
      widget.backend,
      _personaFor(View.of(context).viewId),
    );
  }

  @override
  void dispose() {
    _container?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UncontrolledProviderScope(
    container: _container!,
    child: const FreshCartApp(),
  );
}

/// The persona the host page asked for. Anything else (no initial data,
/// e.g. index.html's single view) is phone A.
DemoPersona _personaFor(int viewId) {
  final data = ui_web.views.getInitialData(viewId) as _DemoViewData?;
  return data?.persona == 'b' ? DemoPersona.b : DemoPersona.a;
}

/// The `initialData` object the host page passes to `addView`.
extension type _DemoViewData._(JSObject _) implements JSObject {
  external String? get persona;
}
