import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/quick_add/duplicate_item_card.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/quick_add/quick_add_button.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/quick_add/quick_add_field.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/quick_add/quick_add_pill.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/quick_add/quick_add_suggestions.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/wave_themed.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The floating "+" button that opens into a text field to add items.
///
/// Two ways to add:
///  * Type a name and press Enter: [onQuickAdd] adds it right away. The
///    field clears and stays open for the next item. This is the fast way
///    to add many items.
///  * Type a name and tap the button: [onOpenDetails] opens the item sheet,
///    to set a quantity or shop first.
///
/// The button icon is one "+" that rotates:
///  * "+": closed, or open with text (tap = add with details);
///  * rotated 45° to "×": open with empty field (tap = close).
///
/// Closed, it's a round button in the shop's colour, with a coloured
/// shadow. Open, it becomes a wide white pill. The shop colour then only
/// shows as a dot before the text, and on the button (grey while the field
/// is empty, shop colour once there's text).
class QuickAddBar extends StatefulWidget {
  /// Key on the pulsing [Transform.scale], so tests can find it and read
  /// its scale.
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

  /// The list to add to. Suggestions come from this list's history
  /// (decisions.md #64).
  final ListId listId;

  /// Adds [name] right away. Return false (failed) to keep the text in the
  /// field, so the user can try again.
  final Future<bool> Function(String name) onQuickAdd;

  /// Opens the item sheet with [name] filled in. Returns true if something
  /// was added (then the field clears and closes). False (cancelled or
  /// failed) keeps the text.
  final Future<bool> Function(String name) onOpenDetails;

  /// Returns the item with the same name in the selected shop, or null. For
  /// the "already on the list" warning. Only looks at loaded items (no
  /// server call), so it's fine to run on every key.
  final ShoppingItem? Function(String name) findDuplicate;

  /// "Make it x{n}" on the duplicate card: adds 1 to [item]'s quantity.
  /// Returns true if it worked, like [onQuickAdd].
  final Future<bool> Function(ShoppingItem item) onBumpDuplicate;

  /// Translations for the active locale.
  final Translations t;

  /// The selected shop's name, or null on "All". Used for the placeholder
  /// ("Add to Colruyt") and the dot.
  ///
  /// The colour isn't passed in: it's `theme.colorScheme.primary`, which
  /// [WaveThemed] keeps correct during a shop switch.
  final String? activeShopName;

  /// Whether this is a brand-new empty list. Then the button pulses 3
  /// times to get attention, and stops. Only checked once, when the widget
  /// is created.
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

  /// The open/close animation: 0 is the round button, 1 is the open pill.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: AppMotion.fabRollOpen,
    reverseDuration: AppMotion.fabRollClose,
  );

  /// [_reveal] with the v3 curves: it rolls open on the iOS curve and
  /// closes on the accelerating exit, each with its own duration.
  late final CurvedAnimation _openness = CurvedAnimation(
    parent: _reveal,
    curve: AppMotion.ios,
    reverseCurve: AppMotion.exitStd,
  );

  /// The first-run pulse: 3 small pulses, 900 ms apart, then it stops.
  ///
  /// One controller for all 3 (not a loop with delays), so it stops when
  /// the widget is disposed.
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
    // Rebuild on every key, because the icon depends on whether there's
    // text.
    _controller.addListener(_handleTextChanged);
    if (widget.firstRun) _pulse.forward();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    _focus.dispose();
    _openness.dispose();
    _reveal.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _handleTextChanged() => setState(() {});

  bool get _hasText => _controller.text.trim().isNotEmpty;

  /// The item the typed name would duplicate, or null. Checked on every
  /// build (which happens on every key).
  ShoppingItem? get _duplicate =>
      _hasText ? widget.findDuplicate(_controller.text.trim()) : null;

  /// What tapping the button does:
  /// - closed: open the field;
  /// - open with text: open the item sheet;
  /// - open and empty ("×"): close.
  bool get _showsPlus => _phase == _Phase.collapsed || _hasText;

  /// Under reduced motion the pill doesn't roll out: it fades over 120ms.
  void _syncRevealSpeed() {
    final reduced = AppMotion.reduced(context);
    _reveal
      ..duration = reduced ? AppMotion.micro : AppMotion.fabRollOpen
      ..reverseDuration = reduced ? AppMotion.micro : AppMotion.fabRollClose;
  }

  void _open() {
    setState(() => _phase = _Phase.expanded);
    _syncRevealSpeed();
    _reveal.forward();
    // Focus after this frame, because the text field doesn't exist yet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _collapse() {
    setState(() => _phase = _Phase.collapsed);
    _syncRevealSpeed();
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

  /// What Enter does: if the duplicate card is showing, "Make it x{n}".
  /// Otherwise, quick add.
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
      // Stay open with the keyboard, so the user can add the next item.
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
          // Above the field: either the duplicate card or the suggestions,
          // never both. The duplicate card wins.
          AnimatedSwitcher(
            duration: AppMotion.durationFor(context, AppMotion.quick),
            child: duplicate != null
                ? DuplicateItemCard(
                    key: const ValueKey('duplicate-card'),
                    item: duplicate,
                    shopName: widget.activeShopName ?? '',
                    t: widget.t,
                    onBump: () => unawaited(_bump(duplicate)),
                    onAddAnyway: () => unawaited(_quickAdd()),
                  )
                : QuickAddSuggestions(
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
                  final openness = _openness.value;
                  final width = lerpDouble(
                    _diameter,
                    constraints.maxWidth,
                    openness,
                  )!;
                  // Only pulse while closed (not while typing), and never
                  // with reduced motion.
                  final pulseScale =
                      _phase == _Phase.collapsed && !AppMotion.reduced(context)
                      ? _pulseScale.value
                      : 1.0;
                  return Align(
                    alignment: Alignment.centerRight,
                    // Exactly as wide as the button/pill. The pulse and the
                    // bounce grow from the centre of this box, so it must
                    // be the button's own size, or the button would jump
                    // sideways. WaveThemed also uses this box to check when
                    // the wave reaches the button.
                    child: Transform.scale(
                      key: QuickAddBar.pulseKey,
                      scale: pulseScale,
                      child: WaveThemed(
                        bounce: true,
                        // Let the wave sweep across the button, but only
                        // when it's fully closed (openness == 0).
                        // `localReveal` builds the button twice, which is
                        // only safe without the TextField inside. (Checking
                        // `_Phase.collapsed` isn't enough: that changes
                        // right away, while the close animation still has
                        // the TextField for ~260 ms.)
                        localReveal: openness <= 0,
                        child: QuickAddPill(
                          openness: openness,
                          width: width,
                          height: _diameter,
                          field: openness > 0
                              ? QuickAddField(
                                  controller: _controller,
                                  focusNode: _focus,
                                  enabled: !_busy,
                                  placeholder: placeholder,
                                  // v3: always, in the accent (ink on All).
                                  showShopDot: true,
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
