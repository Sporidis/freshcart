import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/haptics/haptics_provider.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/features/items/application/items_controller.dart';
import 'package:freshcart_flutter/features/items/application/recent_names_provider.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Search's pre-typing state (§06, "Recently bought"): browse every distinct
/// product name this list has had before, grouped by how recently it was
/// last added -- "the weekly-staples shortcut without building a template
/// feature," in the design's own words. Each row's "+" re-adds the name with
/// a pop, the same optimistic [ItemsController.add] the quick-add control
/// already rides.
///
/// Rendered inline in `SearchResults` rather than as its own destination:
/// the interactive prototype never models a separate "Recently bought"
/// screen or names how one would be reached, and the search screen already
/// has its own header (open, with a Cancel action) -- reusing it avoids
/// inventing a navigation destination the design doesn't actually specify.
///
/// Deliberately no shop dot per row, unlike every other item row in the app:
/// `NameHistoryEntry` doesn't carry one (see its own doc comment for why),
/// and guessing one from data that doesn't exist would be exactly the kind
/// of faked collaboration state `docs/design-gap-plan.md` repeatedly warns
/// against elsewhere in this codebase.
class SearchRecentlyBought extends ConsumerWidget {
  /// Creates the browse view for [listId].
  const SearchRecentlyBought({
    required this.listId,
    required this.t,
    required this.controller,
    required this.report,
    this.now = DateTime.now,
    super.key,
  });

  /// The list whose history is being browsed.
  final ListId listId;

  final Translations t;
  final ItemsController controller;
  final void Function(Failure?, {VoidCallback? onRetry}) report;

  /// Clock used to bucket entries by recency. Defaults to the real wall
  /// clock; tests override it so fixtures anchored to a fixed date stay
  /// correct regardless of when the test actually runs.
  final DateTime Function() now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries =
        ref.watch(recentNamesProvider(listId)).value ??
        const <NameHistoryEntry>[];
    // A brand-new list, or one where nothing has ever been added, simply has
    // no history yet -- not an error state, just nothing to show.
    if (entries.isEmpty) return const SizedBox.shrink();

    final buckets = bucketByRecency(entries, now());
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.42);

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
            onPressed: () async =>
                report(await controller.add(name: entry.name)),
          ),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
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

/// [NameHistoryEntry] grouped by recency; see [bucketByRecency].
typedef RecencyBuckets = ({
  List<NameHistoryEntry> thisWeek,
  List<NameHistoryEntry> lastWeek,
  List<NameHistoryEntry> earlier,
});

/// Buckets [entries] into "this week" / "last week" / "earlier" using
/// rolling 7-day windows measured back from [now], not calendar-week
/// boundaries -- the app ships five locales with different week-start
/// conventions (some start Monday, some Sunday), and a rolling window means
/// the same label reads the same regardless of which day a calendar week is
/// considered to start on.
///
/// [entries] is expected already ordered by [NameHistoryEntry.lastUsedAt]
/// descending (what [recentNamesProvider] returns) -- bucketing is a single
/// pass that preserves that order within each group, not a sort of its own.
RecencyBuckets bucketByRecency(List<NameHistoryEntry> entries, DateTime now) {
  final thisWeek = <NameHistoryEntry>[];
  final lastWeek = <NameHistoryEntry>[];
  final earlier = <NameHistoryEntry>[];
  for (final entry in entries) {
    final age = now.difference(entry.lastUsedAt);
    if (age <= const Duration(days: 7)) {
      thisWeek.add(entry);
    } else if (age <= const Duration(days: 14)) {
      lastWeek.add(entry);
    } else {
      earlier.add(entry);
    }
  }
  return (thisWeek: thisWeek, lastWeek: lastWeek, earlier: earlier);
}

/// The circular "+" that re-adds a name, with the design's own "pop" on tap
/// (§06: "Each + re-adds with a pop") -- the same overshoot-then-settle
/// shape `ItemTile`'s own `_iconPop` already uses for its swipe-to-delete
/// icon, just a smaller overshoot for a smaller, less urgent gesture -- plus
/// the `lightImpact()` haptic the spec calls for alongside it, which the pop
/// alone used to be missing.
class _ReAddButton extends ConsumerStatefulWidget {
  const _ReAddButton({required this.tooltip, required this.onPressed});

  final String tooltip;
  final Future<void> Function() onPressed;

  @override
  ConsumerState<_ReAddButton> createState() => _ReAddButtonState();
}

class _ReAddButtonState extends ConsumerState<_ReAddButton>
    with SingleTickerProviderStateMixin {
  /// Guards against a rapid double-tap starting a second add before the
  /// first has answered -- `QuickAddBar`'s own `_busy` shape, missing here
  /// before since nothing awaited [_ReAddButton.onPressed] to know when to
  /// release it.
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
    unawaited(_pop.forward(from: 0));
    if (ref.read(hapticsControllerProvider).value ?? true) {
      unawaited(HapticFeedback.lightImpact());
    }
    await widget.onPressed();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Semantics(
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
    );
  }
}
