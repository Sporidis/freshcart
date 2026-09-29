import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/reveal/wave_themed.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/features/items/application/item_history/item_history_providers.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/quick_add/quick_add_button.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/quick_add/quick_add_field.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/quick_add/suggestion_row.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The floating control that replaces a persistent add-item bar.
///
/// Two ways to add something, both from the same control, because "fast" and
/// "detailed" want different affordance:
///
///  * Type a name and hit Return -- [onQuickAdd] fires immediately with just
///    that name, the field clears and stays focused, ready for the next one.
///    This is the path for rattling off a list, and it must stay exactly as
///    fast as the old always-visible field was.
///  * Type a name and tap the button instead of Return -- [onOpenDetails]
///    fires with the typed text, for setting a quantity or a shop before it
///    is actually added.
///
/// A single [Icons.add] glyph carries all three of its meanings by rotating
/// 1/8 turn rather than swapping icons: un-rotated it is a "+" (closed, or
/// "add these details"); rotated it is an "×" (open, empty field --
/// "cancel"). The same glyph rotating both ways is what makes "the x turns
/// back into a plus" a literal description of what happens, not a metaphor
/// implemented as two different icons cross-fading.
///
/// Resting, this is a single circle "tinted to the active shop" (the
/// design's own words) -- elevated, with a colour-matched shadow. Open, it
/// "flattens into the sheet-adjacent surface": the pill itself goes back to
/// plain white/surface with a hairline border, and the shop's colour survives
/// as two smaller things instead -- a leading dot before the text, and the
/// trailing button's own fill, which then also answers "is there anything to
/// commit": grey and muted while the field is empty, shop-coloured the
/// moment there is text.
class QuickAddBar extends StatefulWidget {
  /// Key on the [Transform.scale] the first-run pulse (§11) drives -- a test
  /// scopes to it to read the pulse's live scale, the same role
  /// `ItemTile.checkKey`/`editKey` play for that widget's own rows.
  static const pulseKey = Key('quick-add-bar-pulse');

  /// Creates the control.
  const QuickAddBar({
    required this.listId,
    required this.onQuickAdd,
    required this.onOpenDetails,
    required this.t,
    this.activeShopName,
    this.firstRun = false,
    super.key,
  });

  /// The list this bar adds to -- needed to scope the suggestion chips'
  /// query (decisions #64) to this list's own history.
  final ListId listId;

  /// Adds [name] with default quantity and no shop. Returning false keeps
  /// the text in the field for a retry, the same contract the old
  /// AddItemField's onSubmit had.
  final Future<bool> Function(String name) onQuickAdd;

  /// Opens the details sheet, pre-filled with [name], and reports whether it
  /// actually added something. True clears the field and collapses the bar
  /// back to a bare button; false (cancelled, or the write failed) leaves
  /// the typed text in place for another attempt.
  final Future<bool> Function(String name) onOpenDetails;

  /// Translations for the active locale.
  final Translations t;

  /// The active shop tab's name, or null on "All" (or when the list has no
  /// shops yet) -- drives the placeholder ("Add to Colruyt" vs. a generic
  /// prompt) and the leading dot. The colour itself is not a separate
  /// parameter: it is already `theme.colorScheme.primary` -- the pill is
  /// wrapped in [WaveThemed] (see this widget's own `build`), which is what
  /// makes that value correct at any given moment during a shop switch,
  /// not this widget itself.
  final String? activeShopName;

  /// Whether this is a brand-new, still-empty list -- the FAB's own
  /// first-run coach mark (§11: "the FAB pulses gently three times... then
  /// stops for good -- no arrow, no persistent coach mark"). Read once, at
  /// mount, the same way [ItemTile.justAdded] is -- see this state class's
  /// own `initState`.
  final bool firstRun;

  @override
  State<QuickAddBar> createState() => _QuickAddBarState();
}

enum _Phase { collapsed, expanded }

class _QuickAddBarState extends State<QuickAddBar>
    with TickerProviderStateMixin {
  static const double _diameter = 56;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  _Phase _phase = _Phase.collapsed;
  bool _busy = false;

  /// Drives the roll-out: 0 is the bare circle, 1 is the fully-open pill.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: AppMotion.standard,
  );

  /// The first-run coach mark (§11): three gentle scale pulses, 900ms apart,
  /// then stops for good. Modeled directly on the old `_AddNudgeArrow`'s own
  /// three-bounce `TweenSequence` shape -- one controller running the whole
  /// sequence rather than a loop of awaited delays, which would keep firing
  /// after the widget is gone.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: AppMotion.celebrate * 3,
  );
  static const int _pulseBeats = 3;
  late final Animation<double> _pulseScale = TweenSequence<double>([
    for (var i = 0; i < _pulseBeats; i++) ...[
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.06,
        ).chain(CurveTween(curve: AppMotion.enter)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.06,
          end: 1.0,
        ).chain(CurveTween(curve: AppMotion.enter)),
        weight: 1,
      ),
    ],
  ]).animate(_pulse);

  @override
  void initState() {
    super.initState();
    // The icon's rotation depends on whether there is text, which changes on
    // every keystroke -- listening directly is simpler than plumbing a
    // second piece of state that only ever mirrors the controller's own.
    _controller.addListener(_handleTextChanged);
    if (widget.firstRun) _pulse.forward();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    _focus.dispose();
    _reveal.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _handleTextChanged() => setState(() {});

  bool get _hasText => _controller.text.trim().isNotEmpty;

  /// +, un-rotated: collapsed (tap opens), or expanded with text (tap opens
  /// the details sheet). ×, 1/8 turn: expanded and empty (tap cancels).
  bool get _showsPlus => _phase == _Phase.collapsed || _hasText;

  void _open() {
    setState(() => _phase = _Phase.expanded);
    _reveal.forward();
    // The field does not exist in the tree until this frame builds it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _collapse() {
    setState(() => _phase = _Phase.collapsed);
    _reveal.reverse();
    _focus.unfocus();
  }

  void _handleIconTap() {
    switch (_phase) {
      case _Phase.collapsed:
        _open();
      case _Phase.expanded:
        if (_hasText) {
          unawaited(_openDetails());
        } else {
          _collapse();
        }
    }
  }

  Future<void> _openDetails() async {
    if (_busy) return;
    setState(() => _busy = true);
    final added = await widget.onOpenDetails(_controller.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    if (added) {
      _controller.clear();
      _collapse();
    }
  }

  Future<void> _quickAdd() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _busy) return;
    setState(() => _busy = true);
    final added = await widget.onQuickAdd(name);
    if (!mounted) return;
    setState(() => _busy = false);
    if (added) {
      _controller.clear();
      // Stays open, refocused: adding several things in a row is the whole
      // point of the fast path, and closing after each one would undo it.
      _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = widget.activeShopName == null
        ? widget.t.items.namePlaceholder
        : widget.t.items.addTo(shop: widget.activeShopName!);

    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 4, 26, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _SuggestionChips(
            listId: widget.listId,
            field: _controller,
            visible: _phase == _Phase.expanded,
          ),
          SizedBox(
            height: _diameter,
            child: LayoutBuilder(
              builder: (context, constraints) => AnimatedBuilder(
                animation: Listenable.merge([_reveal, _pulse]),
                builder: (context, child) {
                  // "260ms, easeOutQuint on width" (§09) -- _reveal itself
                  // runs linearly (AnimationController has no curve of its
                  // own); everything riding its progress curves through
                  // AppMotion.sheet instead of the raw value, so the roll
                  // decelerates into place rather than moving at a constant
                  // rate the whole way.
                  final openness = AppMotion.sheet.transform(_reveal.value);
                  final width = lerpDouble(
                    _diameter,
                    constraints.maxWidth,
                    openness,
                  )!;
                  // Only while collapsed -- the coach mark's whole point is
                  // drawing the eye to the closed button; pulsing while someone
                  // is already typing would just be noise. Reduced motion drops
                  // the pulse entirely, the same non-negotiable rule every other
                  // animation in this codebase follows.
                  final pulseScale =
                      _phase == _Phase.collapsed && !AppMotion.reduced(context)
                      ? _pulseScale.value
                      : 1.0;
                  return Align(
                    alignment: Alignment.centerRight,
                    // Both the first-run pulse and WaveThemed's own bounce
                    // (below) scale around the *centre of whatever box
                    // they're given* -- this SizedBox is sized to exactly
                    // `width`, the pill's own true bounds, whether that's a
                    // collapsed circle or the fully open pill. Previously
                    // both wrapped this whole row (suggestions included),
                    // a box that's always the *screen's* width with the
                    // button sitting flush against its right edge; scaling
                    // that box pivoted around a point near the screen's
                    // horizontal centre, well outside the button, which is
                    // what made both pulse and bounce visibly lurch
                    // sideways instead of popping in place. The same
                    // oversized box was also what WaveThemed's own "has the
                    // wave physically reached me" check was comparing
                    // against, so tightening the wrap fixes that too.
                    child: Transform.scale(
                      key: QuickAddBar.pulseKey,
                      scale: pulseScale,
                      child: WaveThemed(
                        bounce: true,
                        // Only while fully collapsed (not just "in
                        // `_Phase.collapsed`" -- that flips the instant
                        // `_collapse()` is called, while `_reveal` is still
                        // easing `openness` back down over the next ~260ms,
                        // during which the `TextField` below is still
                        // mounted): `localReveal` builds this `Builder`
                        // *twice* (old-themed underneath, new-themed on
                        // top, clipped to the wave) so the wave can visibly
                        // sweep across the pill's own fill instead of
                        // flipping it all at once -- safe only when there's
                        // no `TextField` in it (`if (openness > 0)` below)
                        // to attach the same `FocusNode`/
                        // `TextEditingController` twice. Anything short of
                        // fully closed falls back to the plain single-copy
                        // flip, same as before.
                        localReveal: openness <= 0,
                        child: _Pill(
                          openness: openness,
                          width: width,
                          height: _diameter,
                          field: openness > 0
                              ? QuickAddField(
                                  controller: _controller,
                                  focusNode: _focus,
                                  enabled: !_busy,
                                  placeholder: placeholder,
                                  showShopDot: widget.activeShopName != null,
                                  onSubmitted: _quickAdd,
                                )
                              : null,
                          button: QuickAddButton(
                            showsPlus: _showsPlus,
                            muted: _phase == _Phase.expanded && !_hasText,
                            tooltip: _phase == _Phase.expanded && !_hasText
                                ? widget.t.common.cancel
                                : widget.t.items.add,
                            onPressed: _busy ? null : _handleIconTap,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The suggestion chips above the open field (§09, decisions #64).
///
/// Its own widget so the debounce lives apart from the roll-out animation:
/// it listens to the same [field], waits for typing to settle, and only
/// then asks [itemSuggestionsProvider].
class _SuggestionChips extends ConsumerStatefulWidget {
  const _SuggestionChips({
    required this.listId,
    required this.field,
    required this.visible,
  });

  final ListId listId;
  final TextEditingController field;
  final bool visible;

  @override
  ConsumerState<_SuggestionChips> createState() => _SuggestionChipsState();
}

class _SuggestionChipsState extends ConsumerState<_SuggestionChips> {
  /// How long to wait after the last keystroke before asking the server --
  /// a network call per keystroke would mean several in-flight requests
  /// racing each other for every word typed.
  static const Duration _debounceDelay = Duration(milliseconds: 300);

  /// The query actually being watched: lags the typed text by
  /// [_debounceDelay], and only once it clears the same two-character floor
  /// the server itself enforces.
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.field.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.field.removeListener(_onTextChanged);
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    final text = widget.field.text.trim();
    if (text.length < 2) {
      // Below the floor: clear immediately rather than waiting out a
      // debounce for a query that would come back empty anyway.
      if (_query.isNotEmpty) setState(() => _query = '');
      return;
    }
    _debounce = Timer(_debounceDelay, () {
      if (mounted) setState(() => _query = text);
    });
  }

  void _pick(String suggestion) {
    widget.field
      ..text = suggestion
      ..selection = TextSelection.collapsed(offset: suggestion.length);
  }

  @override
  Widget build(BuildContext context) {
    // Watching with the live, pre-debounce text would fire the request on
    // every keystroke -- the exact thing debouncing is for.
    final suggestions = _query.isEmpty
        ? const <String>[]
        : ref
                  .watch(
                    itemSuggestionsProvider(
                      listId: widget.listId,
                      query: _query,
                    ),
                  )
                  .value ??
              const <String>[];

    return AnimatedSize(
      duration: AppMotion.durationFor(context, AppMotion.standard),
      curve: AppMotion.enter,
      alignment: Alignment.bottomCenter,
      child: widget.visible && suggestions.isNotEmpty
          ? SuggestionRow(suggestions: suggestions, onTap: _pick)
          : const SizedBox(width: double.infinity),
    );
  }
}

/// The pill itself at a given [openness]: a shop-coloured circle at 0, a
/// plain surface pill at 1.
///
/// A widget of its own rather than an inline Builder, and still reading
/// `Theme.of` from its own context: it sits *inside* WaveThemed's gated
/// Theme (decisions #90), so every colour below rides the wave rather than
/// the ambient theme.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.openness,
    required this.width,
    required this.height,
    required this.field,
    required this.button,
  });

  final double openness;
  final double width;
  final double height;

  /// The text field; null while fully collapsed, so WaveThemed can safely
  /// build this pill twice without attaching one FocusNode twice.
  final Widget? field;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final field = this.field;
    // "Flattens into the sheet-adjacent surface" -- one continuous lerp
    // riding the same width animation.
    final fill = Color.lerp(
      theme.colorScheme.primary,
      theme.colorScheme.surface,
      openness,
    )!;
    // The same StadiumBorder throughout: at width == height its ends meet
    // and it reads as a circle, at full width as a pill.
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        key: const ValueKey('quick-add-pill'),
        color: fill,
        elevation: 3,
        shape: StadiumBorder(
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(
              alpha: openness.clamp(0.0, 1.0),
            ),
          ),
        ),
        child: Row(
          children: [
            if (field != null)
              Expanded(
                // "Placeholder text fades in over the last 40%" (§09) --
                // the pill needs room first, or it would clip.
                child: Opacity(
                  opacity: ((openness - 0.6) / 0.4).clamp(0.0, 1.0),
                  child: field,
                ),
              ),
            button,
          ],
        ),
      ),
    );
  }
}
