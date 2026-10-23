import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/app.dart';
import 'package:freshcart_flutter/demo/demo_overrides.dart';
import 'package:freshcart_flutter/demo/demo_persona.dart';
import 'package:freshcart_flutter/demo/demo_session.dart';

/// One phone in the demo: the real [FreshCartApp] with its own
/// [ProviderContainer] (its own router, controllers and settings), on the
/// backend of the [DemoSession] it shares with the other phone.
///
/// Which persona it is comes from the host page's
/// `addView({initialData: {persona: 'a' | 'b'}})`. While the session's
/// stage is locked (the intro is playing), the visitor can't tap or type,
/// and a Skip chip finishes the intro.
class DemoPhone extends StatefulWidget {
  const DemoPhone({required this.sessions, super.key});

  final DemoSessions sessions;

  @override
  State<DemoPhone> createState() => _DemoPhoneState();
}

class _DemoPhoneState extends State<DemoPhone> {
  DemoSession? _session;
  ProviderContainer? _container;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Here, not in initState: View.of needs an inherited widget lookup.
    // Created once; the view id never changes for this State.
    if (_container != null) return;
    final persona = _personaFor(View.of(context).viewId);
    final session = widget.sessions.attach();
    final container = createPhoneContainer(session.backend, persona);
    session.stage.register(persona, container);
    _session = session;
    _container = container;
  }

  @override
  void dispose() {
    _container?.dispose();
    // After the container: the last phone out ends the session.
    if (_session case final session?) widget.sessions.detach(session);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    // Above MaterialApp, so nothing provides a direction yet.
    textDirection: TextDirection.ltr,
    child: ValueListenableBuilder<bool>(
      valueListenable: _session!.stage.locked,
      child: UncontrolledProviderScope(
        container: _container!,
        child: const FreshCartApp(),
      ),
      builder: (context, locked, app) => Stack(
        fit: StackFit.expand,
        children: [
          // Taps and the keyboard both wait for the intro: an autofocused
          // field would otherwise take the visitor's typing mid-script.
          ExcludeFocus(
            excluding: locked,
            child: AbsorbPointer(absorbing: locked, child: app),
          ),
          if (locked)
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(child: _SkipChip(onTap: _session!.stage.skip)),
            ),
        ],
      ),
    ),
  );
}

/// "Skip intro". Plain widgets only: it sits above MaterialApp, so there's
/// no Material, theme or translations here.
class _SkipChip extends StatelessWidget {
  const _SkipChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xCC1A1A18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Skip intro  ›',
        style: TextStyle(
          color: Color(0xFFFAFAF8),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.none,
        ),
      ),
    ),
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
