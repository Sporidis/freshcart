import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/app/app.dart';
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
/// and a Skip chip finishes the intro. When it unlocks, a "your turn" chip
/// takes its place for a few seconds, so the visitor knows they can try it.
class DemoPhone extends StatefulWidget {
  const DemoPhone({required this.sessions, super.key});

  final DemoSessions sessions;

  @override
  State<DemoPhone> createState() => _DemoPhoneState();
}

class _DemoPhoneState extends State<DemoPhone> {
  DemoSession? _session;
  ProviderContainer? _container;
  _ChipLabels _labels = _ChipLabels.en;

  /// Whether the "your turn" chip shows. Only after the intro, and only
  /// until it has done its job (see [_onLockedChanged]).
  bool _yourTurn = false;
  Timer? _yourTurnTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Here, not in initState: View.of needs an inherited widget lookup.
    // Created once; the view id never changes for this State.
    if (_container != null) return;
    final data = _viewData(View.of(context).viewId);
    final persona = data?.persona == 'b' ? DemoPersona.b : DemoPersona.a;
    _labels = data?.locale == 'nl' ? _ChipLabels.nl : _ChipLabels.en;
    final session = widget.sessions.attach();
    final container = createPhoneContainer(session.backend, persona);
    session.stage.register(persona, container);
    session.stage.locked.addListener(_onLockedChanged);
    _session = session;
    _container = container;
  }

  @override
  void dispose() {
    _yourTurnTimer?.cancel();
    // Before detaching: the last phone out disposes the stage with it.
    _session?.stage.locked.removeListener(_onLockedChanged);
    _container?.dispose();
    // After the container: the last phone out ends the session.
    if (_session case final session?) widget.sessions.detach(session);
    super.dispose();
  }

  /// Runs whenever the stage locks or unlocks: the intro ending, or Skip
  /// fast-forwarding it to the end.
  void _onLockedChanged() {
    if (_session!.stage.locked.value || !mounted) return;
    setState(() => _yourTurn = true);
    // Long enough to read after the pop and the dot's pulses (~3.3s).
    _yourTurnTimer?.cancel();
    _yourTurnTimer = Timer(const Duration(seconds: 6), _hideYourTurn);
  }

  void _hideYourTurn() {
    _yourTurnTimer?.cancel();
    if (_yourTurn && mounted) setState(() => _yourTurn = false);
  }

  @override
  Widget build(BuildContext context) => Directionality(
    // Above MaterialApp, so nothing provides a direction yet.
    textDirection: TextDirection.ltr,
    child: ValueListenableBuilder<bool>(
      valueListenable: _session!.stage.locked,
      child: MediaQuery(
        data: _withPhoneInsets(MediaQuery.of(context)),
        child: UncontrolledProviderScope(
          container: _container!,
          child: const FreshCartApp(embedded: true),
        ),
      ),
      builder: (context, locked, app) => Stack(
        fit: StackFit.expand,
        children: [
          // Taps and the keyboard both wait for the intro: an autofocused
          // field would otherwise take the visitor's typing mid-script.
          // The first tap after it is the visitor taking their turn, so the
          // hint has done its job.
          Listener(
            onPointerDown: (_) => _hideYourTurn(),
            child: ExcludeFocus(
              excluding: locked,
              child: AbsorbPointer(absorbing: locked, child: app),
            ),
          ),
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              // Skip → your turn pops rather than just swapping, so the
              // change itself catches the eye.
              child: AnimatedSwitcher(
                duration: _motion(context, 350),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.85, end: 1.0).animate(animation),
                    child: child,
                  ),
                ),
                child: locked
                    ? _Chip(
                        key: const ValueKey('skip'),
                        label: _labels.skip,
                        onTap: _session!.stage.skip,
                      )
                    : AnimatedOpacity(
                        key: const ValueKey('your-turn'),
                        opacity: _yourTurn ? 1 : 0,
                        duration: _motion(context, 300),
                        // A hint, not a control: taps go to the app below.
                        child: IgnorePointer(
                          child: _Chip(label: _labels.yourTurn, dot: true),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// A browser view has no status bar or home indicator, so its safe-area
/// insets are zero and the app's header would sit flush against the top of
/// the phone frame. These stand in for a phone's, so the app's own
/// SafeArea handling spaces it as it would on a device.
const _phoneInsets = EdgeInsets.only(top: 28, bottom: 12);

MediaQueryData _withPhoneInsets(MediaQueryData data) => data.copyWith(
  padding: data.padding + _phoneInsets,
  viewPadding: data.viewPadding + _phoneInsets,
);

/// [ms], or nothing at all when the visitor asked for reduced motion.
Duration _motion(BuildContext context, int ms) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : Duration(milliseconds: ms);

/// The chips' text. They sit above MaterialApp, so the app's translations
/// aren't available yet; the host page's `locale` picks one of these.
enum _ChipLabels {
  en(skip: 'Skip intro  ›', yourTurn: 'Your turn — add or tick something'),
  nl(
    skip: 'Intro overslaan  ›',
    yourTurn: 'Jouw beurt: voeg iets toe of vink iets af',
  );

  const _ChipLabels({required this.skip, required this.yourTurn});

  final String skip;
  final String yourTurn;
}

/// "Skip intro" and "your turn". Plain widgets only: it sits above
/// MaterialApp, so there's no Material, theme or translations here.
///
/// Inverted against the app (light on the dark theme, dark on the light
/// one) with a shadow: in the app's own colours it disappeared into the
/// dark theme's background.
class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.onTap, this.dot = false, super.key});

  final String label;
  final VoidCallback? onTap;

  /// A pulsing amber dot before the label, "live" like the portfolio's
  /// "Try the live demo" button.
  final bool dot;

  static const _light = Color(0xFFFAFAF8);
  static const _dark = Color(0xFF1A1A18);

  @override
  Widget build(BuildContext context) {
    // The demo's app follows the system theme, so this matches it.
    final appIsDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: appIsDark ? _light : _dark,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot) ...[const _PulsingDot(), const SizedBox(width: 8)],
            Text(
              label,
              style: TextStyle(
                color: appIsDark ? _dark : _light,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The "your turn" dot: a halo pulses out of it a few times, then it rests.
/// It never moves under reduced motion.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  static const _amber = Color(0xFFF5A623);

  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (!reduced && _pulse.status == AnimationStatus.dismissed) {
      _pulse.repeat(count: 3);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 8,
    child: AnimatedBuilder(
      animation: _pulse,
      builder: (context, dot) => Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // The halo grows and fades out; at rest (0 or 1) it's invisible.
          Transform.scale(
            scale: 1 + 1.8 * _pulse.value,
            child: Opacity(
              opacity: _pulse.value == 0 ? 0 : 0.55 * (1 - _pulse.value),
              child: dot,
            ),
          ),
          dot!,
        ],
      ),
      child: const DecoratedBox(
        decoration: BoxDecoration(color: _amber, shape: BoxShape.circle),
        child: SizedBox.square(dimension: 8),
      ),
    ),
  );
}

/// The `initialData` the host page passed to `addView`, if any. None (e.g.
/// index.html's single view) means phone A, in English.
_DemoViewData? _viewData(int viewId) =>
    ui_web.views.getInitialData(viewId) as _DemoViewData?;

/// The `initialData` object the host page passes to `addView`.
extension type _DemoViewData._(JSObject _) implements JSObject {
  external String? get persona;

  /// 'en' | 'nl', the portfolio page's language.
  external String? get locale;
}
