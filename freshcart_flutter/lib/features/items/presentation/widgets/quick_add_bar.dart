import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';
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
class QuickAddBar extends StatefulWidget {
  /// Creates the control.
  const QuickAddBar({
    required this.onQuickAdd,
    required this.onOpenDetails,
    required this.t,
    super.key,
  });

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

  @override
  State<QuickAddBar> createState() => _QuickAddBarState();
}

enum _Phase { collapsed, expanded }

class _QuickAddBarState extends State<QuickAddBar>
    with SingleTickerProviderStateMixin {
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
    super.dispose();
  }

  void _handleTextChanged() => setState(() {});

  bool get _hasText => _controller.text.trim().isNotEmpty;

  /// +, unrotated: collapsed (tap opens), or expanded with text (tap opens
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: SizedBox(
        height: _diameter,
        child: LayoutBuilder(
          builder: (context, constraints) => AnimatedBuilder(
            animation: _reveal,
            builder: (context, child) {
              final width = lerpDouble(
                _diameter,
                constraints.maxWidth,
                _reveal.value,
              )!;
              return Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: width,
                  height: _diameter,
                  // The same StadiumBorder throughout: at width == diameter
                  // its ends meet in the middle and it reads as a circle, at
                  // full width it reads as a pill. One shape, not a swap.
                  child: Material(
                    color: theme.colorScheme.primary,
                    elevation: 3,
                    shape: const StadiumBorder(),
                    child: Row(
                      children: [
                        if (_reveal.value > 0)
                          Expanded(
                            child: Opacity(
                              // Text only fades in past the point the pill
                              // has room to show it without clipping.
                              opacity: ((_reveal.value - 0.4) / 0.6).clamp(
                                0.0,
                                1.0,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 22),
                                child: TextField(
                                  controller: _controller,
                                  focusNode: _focus,
                                  enabled: !_busy,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  textInputAction: TextInputAction.done,
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                  cursorColor: theme.colorScheme.onPrimary,
                                  decoration: InputDecoration(
                                    hintText: widget.t.items.namePlaceholder,
                                    hintStyle: TextStyle(
                                      color: theme.colorScheme.onPrimary
                                          .withValues(alpha: 0.7),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  onSubmitted: (_) => _quickAdd(),
                                ),
                              ),
                            ),
                          ),
                        SizedBox(
                          width: _diameter,
                          height: _diameter,
                          child: IconButton(
                            onPressed: _busy ? null : _handleIconTap,
                            tooltip: _phase == _Phase.collapsed
                                ? widget.t.items.add
                                : (_hasText
                                      ? widget.t.items.add
                                      : widget.t.common.cancel),
                            icon: AnimatedRotation(
                              turns: _showsPlus ? 0 : 0.125,
                              duration: AppMotion.quick,
                              curve: AppMotion.enter,
                              child: Icon(
                                Icons.add,
                                color: theme.colorScheme.onPrimary,
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
    );
  }
}
