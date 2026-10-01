import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/reveal/wave_themed.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
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
    required this.findDuplicate,
    required this.onBumpDuplicate,
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

  /// The existing item [name] would duplicate in the active shop, or null --
  /// Component Library §03's "Duplicate warning." A pure lookup against
  /// already-loaded state, not a query, so it can run on every keystroke.
  final ShoppingItem? Function(String name) findDuplicate;

  /// The duplicate card's "Make it x{n}" action: bumps [item]'s quantity by
  /// one. Same success contract as [onQuickAdd].
  final Future<bool> Function(ShoppingItem item) onBumpDuplicate;

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

  /// The existing item the typed name would duplicate, or null. Recomputed
  /// on every build -- `_handleTextChanged` already calls `setState` on
  /// every keystroke, the same way [_hasText] stays live.
  ShoppingItem? get _duplicate =>
      _hasText ? widget.findDuplicate(_controller.text.trim()) : null;

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

  /// Enter's handler: "takes the primary option" (Component Library §03) --
  /// the duplicate card's bump when one is showing, the ordinary quick-add
  /// otherwise.
  Future<void> _handleSubmit() async {
    final duplicate = _duplicate;
    if (duplicate != null) {
      await _bump(duplicate);
    } else {
      await _quickAdd();
    }
  }

  Future<void> _bump(ShoppingItem item) async {
    if (_busy) return;
    setState(() => _busy = true);
    final bumped = await widget.onBumpDuplicate(item);
    if (!mounted) return;
    setState(() => _busy = false);
    if (bumped) {
      _controller.clear();
      _focus.requestFocus();
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
    final duplicate = _duplicate;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        4,
        AppSpacing.screen,
        22,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // The duplicate card and the suggestion chips share one slot above
          // the capsule and are mutually exclusive (Flow 11: a frame never
          // shows both) -- an exact match is more specific than "here's
          // what you might mean," so it takes the slot when there is one.
          AnimatedSwitcher(
            duration: AppMotion.durationFor(context, AppMotion.quick),
            child: duplicate != null
                ? _DuplicateCard(
                    key: const ValueKey('duplicate-card'),
                    item: duplicate,
                    shopName: widget.activeShopName ?? '',
                    t: widget.t,
                    onBump: () => unawaited(_bump(duplicate)),
                    onAddAnyway: () => unawaited(_quickAdd()),
                  )
                : _SuggestionChips(
                    key: const ValueKey('suggestion-chips'),
                    listId: widget.listId,
                    field: _controller,
                    visible: _phase == _Phase.expanded,
                  ),
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
                                  onSubmitted: _handleSubmit,
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
    super.key,
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
    final fetched = _query.isEmpty
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
    // Component Library §03: "Max 3" -- the server's own floor
    // (ItemService.suggestNames) defaults to 5, so the cap belongs here,
    // at the one place that actually draws the chip row.
    final suggestions = fetched.take(3).toList();

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

/// The exact-match duplicate warning (Component Library §03; Flow Screens
/// v2's "Already on the list"): "{item} is already on {shop}, x{n}," with a
/// primary action that bumps the existing row's quantity instead of
/// creating a second one, and a secondary escape hatch for when a second
/// row really is what's wanted.
class _DuplicateCard extends StatelessWidget {
  const _DuplicateCard({
    required this.item,
    required this.shopName,
    required this.t,
    required this.onBump,
    required this.onAddAnyway,
    super.key,
  });

  final ShoppingItem item;
  final String shopName;
  final Translations t;
  final VoidCallback onBump;
  final VoidCallback onAddAnyway;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.items.alreadyOnShop(
                  name: item.name,
                  shop: shopName,
                  quantity: item.quantity,
                ),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.gapSmall),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onBump,
                      child: Text(
                        t.items.makeItX(quantity: item.quantity + 1),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.gapSmall),
                  OutlinedButton(
                    onPressed: onAddAnyway,
                    child: Text(t.items.addAnyway),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
    // Component Library §03: resting is "shop-tinted, elevation 6" with a
    // colour-matched glow (`0 8px 22px rgba(shop, .35)`); once open it
    // "flattens into the sheet-adjacent surface" -- a plain neutral shadow
    // (`rgba(0,0,0,.10)`), same geometry. A Material `elevation` can't
    // produce the tinted half of that (its shadow is always neutral), so
    // the shadow is painted here instead and Material's own left at 0.
    final shadowColor = Color.lerp(
      theme.colorScheme.primary.withValues(alpha: 0.35),
      Colors.black.withValues(alpha: 0.10),
      openness.clamp(0.0, 1.0),
    )!;
    // The same StadiumBorder throughout: at width == height its ends meet
    // and it reads as a circle, at full width as a pill.
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          key: const ValueKey('quick-add-pill'),
          color: fill,
          elevation: 0,
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
      ),
    );
  }
}
