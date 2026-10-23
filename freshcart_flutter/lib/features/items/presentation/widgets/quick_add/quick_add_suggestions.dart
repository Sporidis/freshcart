import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/features/items/application/item_history/item_history_providers.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/quick_add/suggestion_row.dart';

/// The suggestion chips above the open field (decisions.md #64).
///
/// Its own widget, so the waiting logic is separate from the animation. It
/// listens to [field], waits until typing pauses, then asks
/// [itemSuggestionsProvider].
class QuickAddSuggestions extends ConsumerStatefulWidget {
  const QuickAddSuggestions({
    required this.listId,
    required this.field,
    required this.visible,
    super.key,
  });

  final ListId listId;
  final TextEditingController field;
  final bool visible;

  @override
  ConsumerState<QuickAddSuggestions> createState() =>
      _QuickAddSuggestionsState();
}

class _QuickAddSuggestionsState extends ConsumerState<QuickAddSuggestions> {
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
