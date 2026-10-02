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
    duration: AppMotion.standard,
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

  void _open() {
    setState(() => _phase = _Phase.expanded);
    _reveal.forward();
    // Focus after this frame, because the text field doesn't exist yet.
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
                  // _reveal runs at a constant speed. We apply a curve
                  // (AppMotion.sheet) so the opening slows down at the end.
                  final openness = AppMotion.sheet.transform(_reveal.value);
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

/// The suggestion chips above the open field (decisions.md #64).
///
/// Its own widget, so the waiting logic is separate from the animation. It
/// listens to [field], waits until typing pauses, then asks
/// [itemSuggestionsProvider].
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
  /// How long to wait after the last key before asking the server. Asking
  /// on every key would send many requests at once.
  static const Duration _debounceDelay = Duration(milliseconds: 300);

  /// The text we actually ask suggestions for. Updated [_debounceDelay]
  /// after typing stops, and only with at least 2 letters.
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
      // Less than 2 letters: clear right away, no need to wait.
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
    // Use the delayed text, not the live text, or it would ask on every key.
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
    // Show at most 3 chips (the server sends up to 5).
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

/// The "already on the list" card: "{item} is already on {shop}, x{n}".
///
/// Main button: add 1 to the existing item's quantity. Second button: add
/// it as a new row anyway.
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

/// The button/pill itself. At [openness] 0 it's a round button in the
/// shop's colour, at 1 a wide white pill.
///
/// A separate widget so `Theme.of(context)` reads the theme from inside
/// WaveThemed. That way its colours change with the wave (decisions.md
/// #90).
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

  /// The text field. Null when fully closed, so WaveThemed can safely build
  /// this twice.
  final Widget? field;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final field = this.field;
    // The background goes from shop colour to white as it opens.
    final fill = Color.lerp(
      theme.colorScheme.primary,
      theme.colorScheme.surface,
      openness,
    )!;
    // The shadow: shop-coloured when closed, grey when open. Material's
    // `elevation` shadow can only be grey, so we draw our own shadow and
    // leave elevation at 0.
    final shadowColor = Color.lerp(
      theme.colorScheme.primary.withValues(alpha: 0.35),
      Colors.black.withValues(alpha: 0.10),
      openness.clamp(0.0, 1.0),
    )!;
    // One StadiumBorder for both: when width == height it's a circle, when
    // wider it's a pill.
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
                  // The placeholder fades in during the last 40% of opening,
                  // once there's room for it.
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
