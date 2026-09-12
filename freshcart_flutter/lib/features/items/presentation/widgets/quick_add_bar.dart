import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/features/items/application/item_suggestions_provider.dart';
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
class QuickAddBar extends ConsumerStatefulWidget {
  /// Creates the control.
  const QuickAddBar({
    required this.listId,
    required this.onQuickAdd,
    required this.onOpenDetails,
    required this.t,
    this.activeShopName,
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
  /// parameter: it is already `theme.colorScheme.primary`, since selecting a
  /// shop tab re-themes the whole app to that shop's colour (decisions #32).
  final String? activeShopName;

  @override
  ConsumerState<QuickAddBar> createState() => _QuickAddBarState();
}

enum _Phase { collapsed, expanded }

class _QuickAddBarState extends ConsumerState<QuickAddBar>
    with SingleTickerProviderStateMixin {
  static const double _diameter = 56;
  static const double _buttonDiameter = 44;

  /// How long to wait after the last keystroke before actually asking the
  /// server for suggestions -- a network call per keystroke would mean
  /// several in-flight requests racing each other for every word typed.
  static const Duration _suggestDebounce = Duration(milliseconds: 300);

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  _Phase _phase = _Phase.collapsed;
  bool _busy = false;

  /// The query [itemSuggestionsProvider] is actually watching -- lags the
  /// live typed text by [_suggestDebounce], and only once it clears the
  /// same two-character floor the server itself enforces.
  String _debouncedQuery = '';
  Timer? _debounce;

  /// Drives the roll-out: 0 is the bare circle, 1 is the fully-open pill.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: AppMotion.standard,
  );

  @override
  void initState() {
    super.initState();
    // The icon's rotation depends on whether there is text, which changes on
    // every keystroke -- listening directly is simpler than plumbing a
    // second piece of state that only ever mirrors the controller's own.
    _controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    _focus.dispose();
    _reveal.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _handleTextChanged() {
    setState(() {});
    _debounce?.cancel();
    final text = _controller.text.trim();
    if (text.length < 2) {
      // Below the floor: clear immediately rather than waiting out a debounce
      // for a query that would come back empty anyway.
      if (_debouncedQuery.isNotEmpty) setState(() => _debouncedQuery = '');
      return;
    }
    _debounce = Timer(_suggestDebounce, () {
      if (mounted) setState(() => _debouncedQuery = text);
    });
  }

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
    final theme = Theme.of(context);
    final shopColor = theme.colorScheme.primary;
    final placeholder = widget.activeShopName == null
        ? widget.t.items.namePlaceholder
        : widget.t.items.addTo(shop: widget.activeShopName!);

    // Grey and muted while there is nothing to commit; shop-coloured (and
    // white-on-colour) the moment there is text, or while still collapsed --
    // matching the resting FAB, which has no "empty" state of its own to
    // distinguish.
    final buttonIsMuted = _phase == _Phase.expanded && !_hasText;
    final buttonColor = buttonIsMuted
        ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
        : shopColor;
    final glyphColor = buttonIsMuted
        ? theme.colorScheme.onSurface.withValues(alpha: 0.55)
        : theme.colorScheme.onPrimary;

    // Only once the debounce has actually settled on a query -- watching the
    // provider with the live, pre-debounce text would fire the request (and
    // the loading state) on every keystroke, the exact thing debouncing is
    // for.
    final suggestions = _debouncedQuery.isEmpty
        ? const <String>[]
        : ref
                  .watch(
                    itemSuggestionsProvider(
                      listId: widget.listId,
                      query: _debouncedQuery,
                    ),
                  )
                  .value ??
              const <String>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedSize(
            duration: AppMotion.durationFor(context, AppMotion.standard),
            curve: AppMotion.enter,
            alignment: Alignment.bottomCenter,
            child: _phase == _Phase.expanded && suggestions.isNotEmpty
                ? _SuggestionRow(
                    suggestions: suggestions,
                    onTap: (suggestion) => setState(() {
                      _controller.text = suggestion;
                      _controller.selection = TextSelection.collapsed(
                        offset: suggestion.length,
                      );
                    }),
                  )
                : const SizedBox(width: double.infinity),
          ),
          SizedBox(
            height: _diameter,
            child: LayoutBuilder(
              builder: (context, constraints) => AnimatedBuilder(
                animation: _reveal,
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
                  // The pill's own fill: shop-coloured at rest, plain surface
                  // once open -- "flattens into the sheet-adjacent surface"
                  // (design note). One continuous lerp rather than a hard swap,
                  // since it rides the same width animation.
                  final fill = Color.lerp(
                    shopColor,
                    theme.colorScheme.surface,
                    openness,
                  )!;
                  final borderAlpha = openness.clamp(0.0, 1.0);
                  return Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: width,
                      height: _diameter,
                      // The same StadiumBorder throughout: at width == diameter
                      // its ends meet in the middle and it reads as a circle, at
                      // full width it reads as a pill. One shape, not a swap.
                      child: Material(
                        color: fill,
                        elevation: 3,
                        shape: StadiumBorder(
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: borderAlpha,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            if (openness > 0)
                              Expanded(
                                child: Opacity(
                                  // "Placeholder text fades in over the last
                                  // 40%" (§09) -- the pill needs room to show
                                  // it without clipping first.
                                  opacity: ((openness - 0.6) / 0.4).clamp(
                                    0.0,
                                    1.0,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 18),
                                    child: Row(
                                      children: [
                                        if (widget.activeShopName != null) ...[
                                          Container(
                                            key: const ValueKey(
                                              'quick-add-dot',
                                            ),
                                            width: AppSizes.shopDot,
                                            height: AppSizes.shopDot,
                                            decoration: BoxDecoration(
                                              color: shopColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 11),
                                        ],
                                        Expanded(
                                          child: TextField(
                                            controller: _controller,
                                            focusNode: _focus,
                                            enabled: !_busy,
                                            textCapitalization:
                                                TextCapitalization.sentences,
                                            textInputAction:
                                                TextInputAction.done,
                                            style: TextStyle(
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                            cursorColor: shopColor,
                                            decoration: InputDecoration(
                                              hintText: placeholder,
                                              hintStyle: TextStyle(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                              border: InputBorder.none,
                                              isDense: true,
                                            ),
                                            onSubmitted: (_) => _quickAdd(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: AnimatedContainer(
                                key: const ValueKey('quick-add-icon-bg'),
                                duration: AppMotion.quick,
                                width: _buttonDiameter,
                                height: _buttonDiameter,
                                decoration: BoxDecoration(
                                  color: buttonColor,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: _busy ? null : _handleIconTap,
                                  tooltip: _phase == _Phase.collapsed
                                      ? widget.t.items.add
                                      : (_hasText
                                            ? widget.t.items.add
                                            : widget.t.common.cancel),
                                  icon: AnimatedRotation(
                                    turns: _showsPlus ? 0 : 0.125,
                                    duration: AppMotion.quick,
                                    // "easeOutBack on the glyph rotation"
                                    // (§09) -- the same overshoot AppMotion.pop
                                    // already names for exactly this kind of
                                    // "settles with a small bounce" motion.
                                    curve: AppMotion.curveFor(
                                      context,
                                      AppMotion.pop,
                                    ),
                                    child: Icon(Icons.add, color: glyphColor),
                                  ),
                                ),
                              ),
                            ),
                          ],
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

/// The chip row that floats just above the pill once there is enough typed
/// to suggest something -- traced from §09's own frame 4 markup ("Olive
/// oil", "Olives", "Olive tapenade", riding just above the field).
class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.suggestions, required this.onTap});

  final List<String> suggestions;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: suggestions.length,
          separatorBuilder: (context, index) => const SizedBox(width: 7),
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return Material(
              color: theme.colorScheme.surface,
              shape: StadiumBorder(
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              elevation: 1,
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => onTap(suggestion),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  child: Center(
                    child: Text(
                      suggestion,
                      style: AppTextStyles.label.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
