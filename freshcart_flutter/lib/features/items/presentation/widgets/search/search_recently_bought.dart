import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/haptics/haptics_ref.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
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
class SearchRecentlyBought extends ConsumerWidget {
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

    Widget row(NameHistoryEntry entry) => Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screen,
        vertical: AppSpacing.rowVertical - 3,
      ),
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
            onPressed: () async => report(await vm.addFromSearch(entry.name)),
          ),
        ],
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
  const _ReAddButton({required this.tooltip, required this.onPressed});

  final String tooltip;
  final Future<void> Function() onPressed;

  @override
  ConsumerState<_ReAddButton> createState() => _ReAddButtonState();
}

class _ReAddButtonState extends ConsumerState<_ReAddButton>
    with SingleTickerProviderStateMixin {
  /// True while adding. Stops a fast double-tap from adding twice.
  bool _busy = false;

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
    _pop.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_busy) return;
    setState(() => _busy = true);
    if (!AppMotion.reduced(context)) unawaited(_pop.forward(from: 0));
    ref.haptic(HapticFeedback.lightImpact);
    await widget.onPressed();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return TapTarget(
      onTap: _busy ? null : _handleTap,
      child: Semantics(
        button: true,
        label: widget.tooltip,
        child: InkWell(
          onTap: _busy ? null : _handleTap,
          customBorder: const CircleBorder(),
          child: AnimatedBuilder(
            animation: _overshoot,
            builder: (context, child) =>
                Transform.scale(scale: 1 + _overshoot.value, child: child),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: ink.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: Icon(Icons.add, size: 14, color: ink),
            ),
          ),
        ),
      ),
    );
  }
}
