import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/haptics/haptics_ref.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/ui/motion/cascade_in.dart';
import 'package:freshcart_flutter/core/ui/tap_target.dart';
import 'package:freshcart_flutter/features/items/application/item_history/item_history_providers.dart';
import 'package:freshcart_flutter/features/items/application/item_history/recency_buckets.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_controller.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// "Recently bought": shown in search before typing anything.
///
/// Lists every item name this list ever had, grouped by when it was last
/// added (this week, last week, earlier). Each row has a "+" to add it
/// again, using [ItemsSectionController.addFromSearch]. A quick way to
/// re-add your usual items.
///
/// Shown inside `SearchResults`, not as its own screen.
///
/// No shop dot on these rows: the history doesn't store a shop
/// (`NameHistoryEntry`), and we don't guess one.
///
/// Design v3: 52px rows that cascade in, and the "+" turns into a filled
/// tick for a moment after adding, so it's clear it worked (the pop alone
/// was easy to miss, and with reduced motion there was nothing).
class SearchRecentlyBought extends ConsumerWidget {
  /// v3 row height, the same as the settings rows.
  static const double _rowHeight = 52;

  /// Creates the browse view for [listId].
  const SearchRecentlyBought({
    required this.listId,
    required this.t,
    required this.vm,
    required this.report,
    super.key,
  });

  /// The list whose history to show.
  final ListId listId;

  final Translations t;
  final ItemsSectionController vm;
  final void Function(Failure?, {VoidCallback? onRetry}) report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buckets = ref.watch(recentlyBoughtProvider(listId));
    // No history yet (new list). Not an error, just nothing to show.
    if (buckets.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final muted = theme.textTheme.labelSmall?.color;

    Widget sectionHeader(String label) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        22,
        AppSpacing.screen,
        4,
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.eyebrow.copyWith(color: muted),
      ),
    );

    var position = 0;
    Widget row(NameHistoryEntry entry) => CascadeIn(
      index: position++,
      step: const Duration(milliseconds: 30),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _rowHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  entry.name,
                  style: AppTextStyles.body.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              _ReAddButton(
                tooltip: t.search.addAgain,
                addedLabel: t.search.added,
                onPressed: () async {
                  final failure = await vm.addFromSearch(entry.name);
                  report(failure);
                  return failure == null;
                },
              ),
            ],
          ),
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            18,
            AppSpacing.screen,
            0,
          ),
          child: Text(
            t.search.recentlyBought,
            style: AppTextStyles.bodyStrong.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        if (buckets.thisWeek.isNotEmpty) ...[
          sectionHeader(t.search.thisWeek),
          for (final entry in buckets.thisWeek) row(entry),
        ],
        if (buckets.lastWeek.isNotEmpty) ...[
          sectionHeader(t.search.lastWeek),
          for (final entry in buckets.lastWeek) row(entry),
        ],
        if (buckets.earlier.isNotEmpty) ...[
          sectionHeader(t.search.earlier),
          for (final entry in buckets.earlier) row(entry),
        ],
      ],
    );
  }
}

/// The round "+" that adds a name again. On tap it does a small "pop"
/// (grows a bit, then back) and a light vibration.
class _ReAddButton extends ConsumerStatefulWidget {
  const _ReAddButton({
    required this.tooltip,
    required this.addedLabel,
    required this.onPressed,
  });

  final String tooltip;

  /// Read out, and shown as a tick, for a moment after adding.
  final String addedLabel;

  /// Adds the name again; true if it worked.
  final Future<bool> Function() onPressed;

  @override
  ConsumerState<_ReAddButton> createState() => _ReAddButtonState();
}

class _ReAddButtonState extends ConsumerState<_ReAddButton>
    with SingleTickerProviderStateMixin {
  /// True while adding. Stops a fast double-tap from adding twice.
  bool _busy = false;

  /// True for a moment after adding: the "+" shows a tick.
  bool _added = false;
  Timer? _settle;

  static const Duration _addedHold = Duration(milliseconds: 1200);

  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: AppMotion.quick,
  );
  late final Animation<double> _overshoot = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.25), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 0.25, end: 0.0), weight: 1),
  ]).animate(CurvedAnimation(parent: _pop, curve: Curves.easeOut));

  @override
  void dispose() {
    _settle?.cancel();
    _pop.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_busy) return;
    setState(() => _busy = true);
    if (!AppMotion.reduced(context)) unawaited(_pop.forward(from: 0));
    ref.haptic(HapticFeedback.lightImpact);
    final added = await widget.onPressed();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _added = added;
    });
    if (!added) return;
    _settle?.cancel();
    _settle = Timer(_addedHold, () {
      if (mounted) setState(() => _added = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = scheme.onSurface;
    final quick = AppMotion.durationFor(context, AppMotion.quick);
    return TapTarget(
      onTap: _busy ? null : _handleTap,
      child: Semantics(
        button: true,
        liveRegion: _added,
        label: _added ? widget.addedLabel : widget.tooltip,
        child: InkWell(
          onTap: _busy ? null : _handleTap,
          customBorder: const CircleBorder(),
          child: AnimatedBuilder(
            animation: _overshoot,
            builder: (context, child) =>
                Transform.scale(scale: 1 + _overshoot.value, child: child),
            child: AnimatedContainer(
              duration: quick,
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _added ? scheme.primary : ink.withValues(alpha: 0),
                border: Border.all(
                  color: _added ? scheme.primary : ink.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: AnimatedSwitcher(
                duration: quick,
                child: _added
                    ? Icon(
                        Icons.check_rounded,
                        key: const ValueKey('added'),
                        size: 14,
                        color: scheme.onPrimary,
                      )
                    : Icon(
                        Icons.add,
                        key: const ValueKey('add'),
                        size: 14,
                        color: ink,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
