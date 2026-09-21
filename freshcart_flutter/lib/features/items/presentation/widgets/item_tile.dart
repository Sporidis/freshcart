import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/haptics/haptics_provider.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/core/ui/user_avatar.dart';
import 'package:freshcart_flutter/features/items/application/items_controller.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The fraction of the row's width a swipe must cross before it commits to
/// deleting, per the Motion spec (§10).
const _swipeDismissThreshold = 0.4;

/// How far the checkbox slides right to make room for the selection circle,
/// per the Motion spec (§10).
const _checkboxSlide = 8.0;

/// The row's corner radius, used by [_ItemTileState._getRowDecoration]'s
/// background and the row's own [InkWell].
const _rowBorderRadius = 8.0;

/// One row of a shopping list.
class ItemTile extends ConsumerStatefulWidget {
  /// Key on the leading checkbox/selection circle, shared across every row
  /// rather than keyed to one item's id: it plays the same role
  /// `find.byType(Checkbox)` used to before the row grew its own bespoke
  /// [_CheckCircle], and a test scopes it to one row via
  /// `find.descendant(of: <that row's own finder>, ...)`, same as before.
  static const checkKey = Key('item-check');

  /// Key on the trailing edit [IconButton], shared across every row the same
  /// way [checkKey] is -- a test scopes it to one row via
  /// `find.descendant(of: <that row's own finder>, ...)`.
  static const editKey = Key('item-edit');

  /// Creates a tile for [item].
  const ItemTile({
    required this.item,
    required this.checkedByMember,
    required this.onToggle,
    required this.onEdit,
    required this.onSwipeDelete,
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelection,
    required this.onLongPress,
    required this.index,
    required this.canReorder,
    required this.t,
    this.shopDotColor,
    this.highlightQuery,
    this.justAdded = false,
    this.checkMoveEntering = false,
    this.checkMoveExiting = false,
    super.key,
  });

  /// The item to render.
  final ShoppingItem item;

  /// Who checked it off, already resolved from the list's membership, or
  /// null. Carries the name *and* the avatar (photo, chosen colour, or
  /// neither) so the subtitle can render both without a second lookup.
  final ListMember? checkedByMember;

  /// Called when the checkbox is tapped, or the row itself outside
  /// selection mode (decisions #82: toggling is the whole-row gesture now,
  /// not just the leading circle's).
  final VoidCallback onToggle;

  /// Called when the trailing edit [IconButton] is tapped.
  final VoidCallback onEdit;

  /// Called once the swipe commits to deleting the row. Returns the undo
  /// action, which this tile wires into the snackbar it shows.
  final void Function() Function() onSwipeDelete;

  /// Whether the list is in multi-select mode right now.
  final bool selectionMode;

  /// Whether this row is one of the selected ones. Only meaningful while
  /// [selectionMode] is true.
  final bool selected;

  /// Called when a tap should toggle this row's selection rather than its
  /// checked state -- i.e. every tap while [selectionMode] is true.
  final VoidCallback onToggleSelection;

  /// Called once the long-press gesture fires (§10: 500 ms), to enter or add
  /// to the selection.
  final VoidCallback onLongPress;

  /// This row's position within the open, reorderable rows -- for the
  /// selection reveal's stagger (§10: 25 ms per row) and, doubling up, for
  /// [ReorderableDragStartListener] when [canReorder] is true. Rows that
  /// cannot be multi-selected or dragged (the Done section) pass 0.
  final int index;

  /// Whether this row can be dragged to reorder -- true only on the open
  /// rows of a single shop tab (§10: "cross-shop reordering is meaningless"),
  /// and never while [selectionMode] is active, since a drag and a
  /// selection tap would otherwise compete for the same gesture.
  final bool canReorder;

  /// Translations for the active locale.
  final Translations t;

  /// The item's shop colour, shown as a small dot before its name. Null
  /// hides the dot -- used only in search results (§16: "results become one
  /// flat list across all shops with the shop dot doing the disambiguating"),
  /// since a single shop tab already makes the shop obvious from context.
  final Color? shopDotColor;

  /// The search query to bold matching substrings of the name against
  /// (§16: "weight-600 rather than highlighted"). Null or empty leaves the
  /// name plain.
  final String? highlightQuery;

  /// Whether this row is the one [ItemsController.add] just landed, so it
  /// should play its one-shot entrance: a scale from 0.94 and a tinted flash
  /// that fades over 900 ms (§09, "The add control"). Read once, at mount --
  /// see the state class's own `initState`.
  final bool justAdded;

  /// True only on this row's very first build in the section it just
  /// arrived in -- a checked item's first frame in Done, or an unchecked
  /// item's first frame back among the open rows (§04/§12). Read once, at
  /// mount, same contract as [justAdded] -- see the state class's own
  /// `initState`.
  final bool checkMoveEntering;

  /// True while this already-mounted row has just been told to leave its
  /// current section -- the other half of the same move [checkMoveEntering]
  /// starts on the row's arriving copy. Unlike [checkMoveEntering] this is
  /// read on every rebuild, not just at mount, since the row was already
  /// settled here and needs telling when that changes -- see the state
  /// class's own `didUpdateWidget`.
  final bool checkMoveExiting;

  @override
  ConsumerState<ItemTile> createState() => _ItemTileState();
}

// TODO(decisions #84 follow-up): this State has grown to seven
// AnimationControllers plus press/long-press/swipe/dismiss handling -- worth
// splitting (e.g. swipe/dismiss into its own wrapper widget) as its own
// commit with its own test run, not mixed into a feature change.
class _ItemTileState extends ConsumerState<ItemTile>
    with TickerProviderStateMixin {
  /// Whether this row's haptic feedback should actually fire, per the
  /// user's own Settings preference (default on -- see [HapticsController]).
  bool get _hapticsOn => ref.read(hapticsControllerProvider).value ?? true;

  /// Drives the strike-through wipe and the fade to 45%.
  late final AnimationController _strike = AnimationController(
    vsync: this,
    duration: AppMotion.quick,
    value: widget.item.isChecked ? 1 : 0,
  );

  /// Drives [_CheckCircle]'s fill: 340ms `easeOutBack` overshoot on
  /// checking (Component Library §02 -- "overshoots because the user did
  /// it"), a plain, un-curved reverse on unchecking -- same asymmetry
  /// [_strike] already uses, for the same reason.
  late final AnimationController _checkFill = AnimationController(
    vsync: this,
    duration: AppMotion.bouncy,
    value: widget.item.isChecked ? 1 : 0,
  );

  /// The row's own scale: the long-press "keep holding" tell (0.97) and its
  /// spring-back, both driven directly rather than through a Tween, since
  /// each has its own target reached from `animateTo` calls at different
  /// moments rather than a single start-to-end run.
  late final AnimationController _pressScale = AnimationController(
    vsync: this,
    duration: AppMotion.quick,
    value: 1,
  );

  /// Set 300 ms into a press; cancelled on release or once the long press
  /// fires. Its own field rather than reusing `_pressScale`'s ticking,
  /// because "has 300 ms passed" is a plain wall-clock question independent
  /// of animation state.
  Timer? _pressTellTimer;

  /// Reveals the selection circle and slides the checkbox aside on entering
  /// selection mode (§10: 240 ms, staggered by [ItemTile.index]); reverses,
  /// unstaggered, on exit. Starts already-settled rather than at 0 so a row
  /// built fresh *while* selection mode is active (scrolled into view, for
  /// instance) does not visibly animate in from nothing.
  late final AnimationController _selectionReveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: widget.selectionMode ? 1 : 0,
  );

  /// The new-row entrance: scale 0.94 → 1 with a tinted flash fading out
  /// alongside it, over 900 ms (§09). Runs once, from [initState] -- unlike
  /// [widget.justAdded] itself, which [ItemsSection] can only guarantee is
  /// true for the single build this row's `ItemTile` first mounts on, this
  /// animation's own value must keep going for the full 900 ms regardless of
  /// what the flag does after that.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    value: widget.justAdded ? 0 : 1,
  );
  late final Animation<double> _entranceEased = CurvedAnimation(
    parent: _entrance,
    curve: AppMotion.enter,
  );

  /// This row's presence within its *current* section: 1 is fully settled
  /// here, 0 is fully gone -- the open<->Done cross-section move (§04/§12).
  /// Driven by [ItemTile.checkMoveEntering] (0→1, from [didChangeDependencies]
  /// at first mount, or from [didUpdateWidget] if it flips true again on an
  /// already-mounted element -- e.g. unchecking a row while it's still
  /// mid-cascade re-arms this on the same Open-side element rather than
  /// remounting a fresh one) and [ItemTile.checkMoveExiting] (1→0, from
  /// [didUpdateWidget]) rather than [widget.item.isChecked] directly, since a
  /// row's *own* checked state and which section it is *currently rendering
  /// in* are different questions -- see items_section.dart's `tileFor`, which
  /// computes both flags per the section a given `ItemTile` instance is
  /// actually mounted in.
  late final AnimationController _checkMove = AnimationController(
    vsync: this,
    duration: AppMotion.standard,
    // A fresh element born already mid-exit (e.g. a live update lands an
    // item that is already checked-and-transitioning, from another
    // device's action) starts already gone rather than flashing visible
    // first, same reasoning as [_entrance]'s own initial value.
    value: widget.checkMoveEntering || widget.checkMoveExiting ? 0 : 1,
  );

  @override
  void initState() {
    super.initState();
    if (widget.justAdded) {
      if (_hapticsOn) unawaited(HapticFeedback.lightImpact());
      _entrance.forward();
    }
  }

  /// Whether the one-shot [_checkMove] entrance below has already fired --
  /// `didChangeDependencies` (unlike `initState`) can run more than once,
  /// but [ItemTile.checkMoveEntering] must only ever animate this row's
  /// arrival a single time, the same "read once" contract [justAdded] has.
  bool _checkMoveEntranceStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // AppMotion.durationFor/curveFor read MediaQuery, which cannot be
    // depended on from initState (the element isn't linked into the tree
    // for dependency notifications yet) -- didChangeDependencies is the
    // first point after initState where that's safe, and it still runs
    // before the first build, so there's no visible flash either way.
    if (widget.checkMoveEntering && !_checkMoveEntranceStarted) {
      _checkMoveEntranceStarted = true;
      unawaited(
        _checkMove.animateTo(
          1,
          duration: AppMotion.durationFor(
            context,
            widget.item.isChecked ? AppMotion.standard : AppMotion.quick,
          ),
          curve: AppMotion.curveFor(context, AppMotion.enter),
        ),
      );
    }
  }

  /// How far the current swipe has traveled, 0 to 1 of the row's width.
  /// Feeds [_iconScale]; set from [_handleSwipeUpdate].
  double _swipeProgress = 0;

  /// Plays the delete icon's overshoot-and-settle "pop" the instant a swipe
  /// crosses the dismiss threshold (Motion spec §10).
  late final AnimationController _iconPop = AnimationController(
    vsync: this,
    duration: AppMotion.quick,
  );
  late final Animation<double> _iconPopOvershoot = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.15), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 0.15, end: 0.0), weight: 1),
  ]).animate(CurvedAnimation(parent: _iconPop, curve: Curves.easeOut));

  /// The delete icon's scale: 0.7 while under 30% of the row's width,
  /// ramping linearly to 1 by the time the row is fully swiped (§10), plus
  /// whatever overshoot [_iconPop] is currently playing.
  double get _iconScale {
    const rampStart = 0.3;
    final base = _swipeProgress <= rampStart
        ? 0.7
        : 0.7 +
              0.3 *
                  ((_swipeProgress - rampStart) / (1 - rampStart)).clamp(
                    0.0,
                    1.0,
                  );
    return base + _iconPopOvershoot.value;
  }

  @override
  void didUpdateWidget(ItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.isChecked != oldWidget.item.isChecked) {
      if (widget.item.isChecked) {
        _strike.forward();
        unawaited(
          _checkFill.animateTo(
            1,
            duration: AppMotion.durationFor(context, AppMotion.bouncy),
            curve: AppMotion.curveFor(context, AppMotion.pop),
          ),
        );
      } else {
        // Unchecking reverses with no overshoot: the intent is unambiguous.
        _strike.reverse();
        unawaited(
          _checkFill.animateTo(
            0,
            duration: AppMotion.durationFor(context, AppMotion.quick),
          ),
        );
      }
    }
    if (widget.selectionMode != oldWidget.selectionMode) {
      if (widget.selectionMode) {
        unawaited(_enterSelectionReveal());
      } else {
        // Exiting is not staggered -- only the entry draws the eye down the
        // list; leaving should read as one dismissal, not a second wave.
        _selectionReveal.reverse();
      }
    }
    if (widget.checkMoveExiting && !oldWidget.checkMoveExiting) {
      unawaited(
        _checkMove.animateTo(
          0,
          duration: AppMotion.durationFor(
            context,
            widget.item.isChecked ? AppMotion.standard : AppMotion.quick,
          ),
          curve: AppMotion.curveFor(context, AppMotion.exit),
        ),
      );
    }
    // Mirrors the block above -- [didChangeDependencies] only ever drives
    // [_checkMove]'s 0→1 entrance for a row's first-ever mount. Unchecking a
    // row while it's still `transitioning` (mid-cascade, or waiting out its
    // own exit timer -- see `RecentlyChecked.release`) re-arms
    // `checkMoveEntering` on this *same*, already-mounted element rather than
    // remounting a fresh one, so without this branch `_checkMove` never
    // restarts and the row stays stuck wherever its exit tween last left it
    // -- collapsed and invisible, but still a member of the Open list.
    if (widget.checkMoveEntering && !oldWidget.checkMoveEntering) {
      unawaited(
        _checkMove.animateTo(
          1,
          duration: AppMotion.durationFor(
            context,
            widget.item.isChecked ? AppMotion.standard : AppMotion.quick,
          ),
          curve: AppMotion.curveFor(context, AppMotion.enter),
        ),
      );
    }
  }

  @override
  void dispose() {
    _strike.dispose();
    _checkFill.dispose();
    _iconPop.dispose();
    _pressScale.dispose();
    _pressTellTimer?.cancel();
    _selectionReveal.dispose();
    _entrance.dispose();
    _checkMove.dispose();
    super.dispose();
  }

  void _handleToggle() {
    // Haptics fire on commitment, and on check only -- confirming a tick is
    // useful, confirming an undo is noise.
    if (!widget.item.isChecked && _hapticsOn) {
      unawaited(HapticFeedback.lightImpact());
    }
    widget.onToggle();
  }

  void _toggleSelection() {
    if (_hapticsOn) unawaited(HapticFeedback.selectionClick());
    widget.onToggleSelection();
  }

  /// A tap on the leading circle: while selecting, the circle means
  /// "selected", not "bought" (Component Library §01), so it toggles
  /// selection the same as tapping anywhere else on the row would. Outside
  /// selection mode it toggles checked, same as [_activateRow] -- kept as
  /// its own target rather than folded away now that the row does the same
  /// thing, since it is still the row's clearest "this is what tapping does"
  /// affordance.
  void _activateLeading() {
    if (widget.selectionMode) {
      _toggleSelection();
    } else {
      _handleToggle();
    }
  }

  /// A tap on the row itself: toggles selection while selecting, otherwise
  /// toggles checked (decisions #82 -- reverting #74's "row opens editing"
  /// in favour of the whole row being the check target, since a 22px circle
  /// is too small a hit area for the action done most often). Editing now
  /// lives on its own trailing [IconButton], see [ItemTile.editKey].
  void _activateRow() {
    if (widget.selectionMode) {
      _toggleSelection();
    } else {
      _handleToggle();
    }
  }

  Future<void> _enterSelectionReveal() async {
    await Future<void>.delayed(AppMotion.selectionStagger(widget.index));
    if (!mounted) return;
    _selectionReveal.forward();
  }

  /// The finger touched down: starts the clock on the "keep holding" tell.
  void _handlePressStart(PointerDownEvent event) {
    _pressTellTimer?.cancel();
    // 300 ms per §10 -- the row starts easing toward 0.97 from here, so it
    // visibly reaches it right around the 500 ms mark the long press fires.
    _pressTellTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      unawaited(_pressScale.animateTo(0.97, duration: AppMotion.quick));
    });
  }

  /// The finger lifted or the gesture was cancelled before firing: whatever
  /// tell had started springs back.
  ///
  /// `Listener` sits outside `Dismissible`/`InkWell`, so hit-test dispatch
  /// reaches those inner recognizers -- and can fire e.g. `_activateRow`'s
  /// `onToggle`, which may remove and dispose this very row -- before it
  /// reaches this outer callback for the same pointer-up. The `mounted`
  /// check is what keeps that ordering from touching a disposed
  /// [_pressScale].
  void _handlePressEnd(PointerEvent event) {
    _pressTellTimer?.cancel();
    _pressTellTimer = null;
    if (!mounted) return;
    unawaited(_pressScale.animateTo(1, duration: AppMotion.quick));
  }

  /// The long press committed (§10: 500 ms): confirms with a haptic, snaps
  /// the row back to size, and hands off to the controller.
  void _handleLongPressFire() {
    _pressTellTimer?.cancel();
    _pressTellTimer = null;
    if (_hapticsOn) unawaited(HapticFeedback.mediumImpact());
    if (!mounted) return;
    unawaited(_pressScale.animateTo(1, duration: AppMotion.quick));
    widget.onLongPress();
  }

  /// Turns one swipe-drag update into the feedback the Motion spec (§10)
  /// asks for: the delete icon tracking the drag, plus a haptic and an
  /// overshoot "pop" the instant the swipe crosses the dismiss threshold.
  void _handleSwipeUpdate(DismissUpdateDetails details) {
    setState(() => _swipeProgress = details.progress);

    // `details.reached` is true for every frame past the threshold, not just
    // the first -- comparing against `details.previousReached` (rather than,
    // say, the old `_swipeProgress`) is what isolates the single frame the
    // drag actually crossed it, so the haptic and pop fire once per crossing
    // instead of once per frame.
    if (details.reached && !details.previousReached) {
      if (_hapticsOn) unawaited(HapticFeedback.mediumImpact());
      _iconPop.forward(from: 0);
    }
  }

  /// Commits the swipe: hands off to the controller, which hides the row and
  /// returns the undo action, then offers that action through a snackbar.
  void _handleDismissed(BuildContext context) {
    final undo = widget.onSwipeDelete();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(widget.t.items.itemRemoved(name: widget.item.name)),
          duration: ItemsController.swipeUndoWindow,
          action: SnackBarAction(label: widget.t.common.undo, onPressed: undo),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    // Wraps the row's own content in the open<->Done cross-section move
    // (§04/§12) -- visually inert at rest (_checkMove.value == 1, the
    // overwhelming majority of a row's life), so applying it unconditionally
    // is safe and avoids a conditionally-present wrapper that would itself
    // risk upsetting Column/ReorderableListView's key-based reconciliation.
    return SizeTransition(
      sizeFactor: _checkMove,
      // Equivalent to the deprecated axisAlignment: -1 for Axis.vertical
      // (the SizeTransition default) -- collapses toward the top.
      alignment: Alignment.topLeft,
      child: FadeTransition(
        opacity: _checkMove,
        child: Listener(
          // Raw pointer events, not a second gesture recognizer: a `Listener`
          // sits outside Flutter's gesture arena entirely, so timing the 300 ms
          // tell here cannot compete with -- or steal -- the tap and long-press
          // recognizers the `ListTile` below owns.
          onPointerDown: _handlePressStart,
          onPointerUp: _handlePressEnd,
          onPointerCancel: _handlePressEnd,
          child: Dismissible(
            key: ValueKey(widget.item.id.value),
            // Selection mode owns the gesture instead: a swipe mid-select would
            // be ambiguous between "delete this one" and "drag to select".
            direction: widget.selectionMode
                ? DismissDirection.none
                : DismissDirection.endToStart,
            dismissThresholds: const {
              DismissDirection.endToStart: _swipeDismissThreshold,
            },
            // 220 ms per the Motion spec (§10) -- the default resize is slower.
            resizeDuration: const Duration(milliseconds: 220),
            onUpdate: _handleSwipeUpdate,
            background: _buildSwipeBackground(),
            onDismissed: (_) => _handleDismissed(context),
            child: _buildAnimatedRow(context, child: _buildRow(context)),
          ),
        ),
      ),
    );
  }

  /// The delete icon revealed behind a swipe: tracks the drag via
  /// [_iconScale] and plays [_iconPop]'s overshoot the instant the swipe
  /// crosses the dismiss threshold (Motion spec §10).
  Widget _buildSwipeBackground() {
    return ColoredBox(
      color: AppColors.destructive,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 24),
          child: AnimatedBuilder(
            animation: _iconPop,
            builder: (context, child) =>
                Transform.scale(scale: _iconScale, child: child),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
        ),
      ),
    );
  }

  /// Wraps [child] (the row itself) in the row-level animation: the
  /// press-scale tell, the new-row entrance scale + tint flash, and the
  /// checked-off fade. `child` is passed through to [AnimatedBuilder]
  /// rather than rebuilt on every tick, since none of those animations
  /// change the row's own content.
  Widget _buildAnimatedRow(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([_strike, _pressScale, _entrance]),
      builder: (context, child) {
        final tint = widget.shopDotColor ?? theme.colorScheme.primary;
        return Transform.scale(
          scale: _pressScale.value * lerpDouble(0.94, 1, _entranceEased.value)!,
          // Material, not a plain DecoratedBox: ListTile paints its own
          // splashes on the nearest Material ancestor, and a coloured
          // DecoratedBox sitting between it and that ancestor would hide
          // them (a real, debug-mode-flagged issue, not a style choice).
          child: Material(
            // Fades to nothing over the same 900 ms the scale settles in
            // over -- there is no resting tint once it is done.
            color: tint.withValues(alpha: 0.16 * (1 - _entranceEased.value)),
            child: Opacity(
              // 45% once checked: present, but plainly already in the trolley.
              opacity: 1 - (_strike.value * 0.55),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }

  /// `ListTile` has no way to key a background/radius change off [selected]
  Widget _buildRow(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final subtitle = _buildSubtitle(muted);
    final selected = widget.selected;

    return AnimatedContainer(
      duration: AppMotion.durationFor(context, AppMotion.quick),
      curve: AppMotion.enter,
      margin: EdgeInsets.symmetric(horizontal: selected ? 6 : 0),
      decoration: _getRowDecoration(theme, selected),
      // BoxDecoration.border only ever draws a solid line -- there is no
      // dashed BorderStyle to pick -- so a pending row's dashed stripe is
      // painted by hand instead, as a second layer on top of everything
      // else this Material/InkWell subtree draws. CustomPaint sizes itself
      // to its child, which fills exactly the same box the decoration above
      // paints its background into, so the stripe is positioned against
      // that same box.
      child: CustomPaint(
        foregroundPainter: widget.item.pending
            ? const _PendingStripe(color: Colors.grey)
            : null,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: _activateRow,
            onLongPress: _handleLongPressFire,
            borderRadius: BorderRadius.circular(_rowBorderRadius),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: selected ? 10 : 16,
                vertical: AppSpacing.rowVertical,
              ),
              child: Row(
                children: [
                  _buildLeadingSlot(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTitleRow(theme: theme, muted: muted),
                        if (subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: subtitle,
                          ),
                      ],
                    ),
                  ),
                  // Hidden during selection, same as the reference's own
                  // "selected" state: "gains a drag handle, loses the
                  // quantity" -- how many to buy has nothing to do with
                  // picking rows for a bulk action.
                  if (!widget.selectionMode) ...[
                    const SizedBox(width: 6),
                    Text(
                      'x${widget.item.quantity}',
                      style: AppTextStyles.caption.copyWith(color: muted),
                    ),
                  ],
                  // Hidden during selection, same as the quantity --
                  // editing one row makes no sense mid-bulk-select.
                  if (!widget.selectionMode) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      key: ItemTile.editKey,
                      icon: const Icon(Icons.edit_outlined),
                      iconSize: 20,
                      color: muted,
                      visualDensity: VisualDensity.compact,
                      // Reuses the edit sheet's own title rather than
                      // adding a new translation key across five locales
                      // for one tooltip string.
                      tooltip: widget.t.items.editProductTitle,
                      onPressed: widget.onEdit,
                    ),
                  ],
                  if (widget.canReorder) ...[
                    const SizedBox(width: 4),
                    ReorderableDragStartListener(
                      index: widget.index,
                      child: Icon(Icons.drag_handle, color: muted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The row's background: the selected tint, or transparent. The pending
  /// dashed outline is a separate [CustomPaint] layer in [_buildRow], not
  /// part of this decoration -- [BoxDecoration.border] cannot express a
  /// dashed line, only ever a solid one.
  BoxDecoration _getRowDecoration(ThemeData theme, bool selected) {
    return BoxDecoration(
      color: selected
          ? (theme.brightness == Brightness.dark
                ? AppColors.selectedRowDark
                : AppColors.selectedRowLight)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(_rowBorderRadius),
    );
  }

  /// The checkbox/selection circle, cross-faded with each other as
  /// [_selectionReveal] runs (§10: 240 ms, staggered by [ItemTile.index]).
  /// Its own tap target, independent of the row's -- see [_activateLeading].
  Widget _buildLeadingSlot() {
    return GestureDetector(
      key: ItemTile.checkKey,
      onTap: _activateLeading,
      child: AnimatedBuilder(
        animation: Listenable.merge([_selectionReveal, _checkFill]),
        builder: (context, child) {
          final selectionProgress = _selectionReveal.value;
          final slotWidth = widget.selectionMode
              ? 34 * selectionProgress
              : 34 * _checkFill.value.clamp(0.0, 1.0);
          return SizedBox(
            width: slotWidth,
            height: 22,
            child: ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 34,
                  height: 22,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Opacity(
                        opacity: selectionProgress,
                        child: _SelectionCircle(
                          key: ValueKey(widget.selected),
                          selected: widget.selected,
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(_checkboxSlide * selectionProgress, 0),
                        child: Opacity(
                          opacity: 1 - selectionProgress,
                          child: _CheckCircle(fill: _checkFill),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// The item's name (struck through and search-highlighted as needed),
  /// plus the shop dot and quantity that share its line. No note glyph --
  /// the note itself is the subtitle line now, not a permanent icon here.
  Widget _buildTitleRow({required ThemeData theme, required Color muted}) {
    final item = widget.item;
    return Row(
      children: [
        if (widget.shopDotColor != null) ...[
          Container(
            key: const ValueKey('shop-dot'),
            width: AppSizes.shopDot,
            height: AppSizes.shopDot,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.shopDotColor,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: _StrikeThrough(
            progress: _strike,
            color: muted,
            child: Text.rich(
              TextSpan(
                children: _highlightSpans(
                  item.name,
                  widget.highlightQuery,
                  theme.textTheme.bodyLarge,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// The row's caption line: a note if it has one, otherwise -- once checked
  /// -- who checked it off, avatar included. A note wins over "checked by":
  /// the note is the shopper's own instruction and stays visible even after
  /// the item is in the trolley, the same priority [_subtitle] always had.
  Widget? _buildSubtitle(Color muted) {
    final note = widget.item.note;
    if (note != null && !note.isEmpty) {
      return Text(
        note.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption.copyWith(color: muted),
      );
    }

    final member = widget.checkedByMember;
    if (!widget.item.isChecked || member == null) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            widget.t.items.checkedBy(name: member.displayName),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(color: muted),
          ),
        ),
        const SizedBox(width: 4),
        UserAvatar(
          seed: member.userId.value,
          initial: member.displayName.isEmpty
              ? '?'
              : member.displayName[0].toUpperCase(),
          photoUrl: member.avatarPhotoUrl,
          color: member.avatarColor,
          radius: 10,
        ),
      ],
    );
  }
}

/// The circle that stands in for the checkbox once selection mode is active:
/// outlined while unselected, filled with a check once tapped. The 120 ms
/// fill is [AnimatedContainer]'s own transition, driven purely by [selected]
/// changing -- no controller of its own, since nothing here needs staggering
/// or to be read mid-flight the way the reveal does.
class _SelectionCircle extends StatelessWidget {
  const _SelectionCircle({required this.selected, super.key});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final outline = Theme.of(context).colorScheme.outline;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? primary : Colors.transparent,
        border: Border.all(color: selected ? primary : outline, width: 1.5),
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}

/// The row's own checked state, drawn as CheckCircle (Component Library
/// §02): a plain 22px outline until [fill] moves, then a solid disc scales
/// in underneath the outline and a tick fades in "behind" it.
///
/// Filled from `colorScheme.primary`, not [ItemTile.shopDotColor] -- the dot
/// beside the name is *this item's own* shop; the fill is the *active tab's*
/// colour (ink on "All", the shop's colour inside a tab wrapped in
/// `AppTheme.forShop`), and the two can differ, in search results spanning
/// every shop above all. The scoped theme from decisions #73 is what makes
/// reading it straight off [Theme.of] correct here.
class _CheckCircle extends AnimatedWidget {
  const _CheckCircle({required Animation<double> fill})
    : super(listenable: fill);

  @override
  Widget build(BuildContext context) {
    final fill = (listenable as Animation<double>).value;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final outline = theme.colorScheme.outline;

    return SizedBox(
      width: 22,
      height: 22,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: outline, width: 1.5),
            ),
          ),
          if (fill > 0)
            Transform.scale(
              scale: fill,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary,
                ),
                child: const SizedBox(width: 22, height: 22),
              ),
            ),
          if (fill > 0.3)
            Opacity(
              // The tick fades in over the fill's own last 70% of travel --
              // "80ms behind the fill" (§02), approximated from the same
              // progress rather than a second controller for 80ms of it.
              opacity: ((fill - 0.3) / 0.7).clamp(0.0, 1.0),
              child: const Icon(Icons.check, size: 14, color: Colors.white),
            ),
        ],
      ),
    );
  }
}

/// Splits [text] into spans of [base], with every match of [query] set to
/// weight 600 instead (§16: "weight-600 rather than highlighted" -- no
/// background colour, just a heavier weight). A null or empty [query]
/// returns [text] as a single plain span.
///
/// Every non-overlapping match is bolded, not just the first: a name
/// containing the query twice should not read as if only one of them
/// matched.
List<InlineSpan> _highlightSpans(String text, String? query, TextStyle? base) {
  if (query == null || query.isEmpty) {
    return [TextSpan(text: text, style: base)];
  }

  final lowerText = text.toLowerCase();
  final lowerQuery = query.toLowerCase();
  final bold = base?.copyWith(fontWeight: FontWeight.w600);
  final spans = <InlineSpan>[];
  var cursor = 0;
  while (true) {
    final match = lowerText.indexOf(lowerQuery, cursor);
    if (match < 0) {
      spans.add(TextSpan(text: text.substring(cursor), style: base));
      break;
    }
    if (match > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, match), style: base));
    }
    spans.add(
      TextSpan(text: text.substring(match, match + query.length), style: bold),
    );
    cursor = match + query.length;
  }
  return spans;
}

/// Draws a strike-through across [child] as [progress] runs 0 to 1.
///
/// Painted rather than set as [TextDecoration.lineThrough], which would snap
/// on the frame the value flips. The line wipes left to right instead, which
/// is what makes checking something off feel like an action rather than a
/// state change.
class _StrikeThrough extends StatelessWidget {
  const _StrikeThrough({
    required this.progress,
    required this.color,
    required this.child,
  });

  final Animation<double> progress;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // With motion reduced there is nothing to wipe, so it is drawn or it is
    // not -- but it is still drawn, because it carries meaning, not polish.
    if (AppMotion.reduced(context)) {
      return CustomPaint(
        foregroundPainter: _StrikePainter(
          progress: progress.value > 0 ? 1 : 0,
          color: color,
        ),
        child: child,
      );
    }
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) => CustomPaint(
        foregroundPainter: _StrikePainter(
          progress: progress.value,
          color: color,
        ),
        child: child,
      ),
      child: child,
    );
  }
}

class _StrikePainter extends CustomPainter {
  const _StrikePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final y = size.height / 2;
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width * progress.clamp(0, 1), y),
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_StrikePainter old) =>
      old.progress != progress || old.color != color;
}

/// Draws a dashed vertical stripe along the row's left edge, standing in for
/// a full-row outline -- there is no `BorderStyle` for a dashed line
/// (`BoxDecoration.border` can only ever draw a solid one), so a pending
/// row's cue is painted by hand instead of expressed as a decoration.
///
/// [_inset] holds it off the row's own left edge, which otherwise sits flush
/// against the screen edge -- a border with no breathing room read as a
/// rendering glitch rather than a deliberate cue.
class _PendingStripe extends CustomPainter {
  const _PendingStripe({required this.color});

  final Color color;

  static const _strokeWidth = 2.5;
  static const _dashLength = 4.0;
  static const _gapLength = 3.0;
  static const _inset = 6.0;
  static const _verticalInset = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    var y = _verticalInset;
    final bottom = size.height - _verticalInset;
    while (y < bottom) {
      final dashEnd = (y + _dashLength).clamp(0.0, bottom);
      canvas.drawLine(Offset(_inset, y), Offset(_inset, dashEnd), paint);
      y += _dashLength + _gapLength;
    }
  }

  @override
  bool shouldRepaint(_PendingStripe old) => old.color != color;
}

@Preview(group: 'Items', name: 'Item row · every state', size: Size(393, 340))
Widget itemTilePreview() {
  final t = previewTranslations;
  final now = DateTime.utc(2026, 3, 1, 12);
  ShoppingItem item({
    required String id,
    required String name,
    int quantity = 1,
    bool isChecked = false,
    bool pending = false,
    Note? note,
  }) => ShoppingItem(
    id: ItemId(id),
    listId: ListId('list-1'),
    name: name,
    addedBy: UserId('user-1'),
    createdAt: now,
    updatedAt: now,
    quantity: quantity,
    isChecked: isChecked,
    pending: pending,
    note: note,
    checkedBy: isChecked ? UserId('user-2') : null,
    checkedAt: isChecked ? now : null,
  );

  return previewPiece(
    Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ItemTile(
          item: item(id: 'a', name: 'Bananas', quantity: 6),
          checkedByMember: null,
          onToggle: () {},
          onEdit: () {},
          onSwipeDelete: () => () {},
          selectionMode: false,
          selected: false,
          onToggleSelection: () {},
          onLongPress: () {},
          index: 0,
          canReorder: false,
          t: t,
        ),
        ItemTile(
          item: item(
            id: 'b',
            name: 'Olive oil',
            note: Note(
              text: 'the green tin',
              authorId: UserId('user-1'),
              updatedAt: now,
            ),
          ),
          checkedByMember: null,
          onToggle: () {},
          onEdit: () {},
          onSwipeDelete: () => () {},
          selectionMode: false,
          selected: false,
          onToggleSelection: () {},
          onLongPress: () {},
          index: 0,
          canReorder: false,
          t: t,
        ),
        ItemTile(
          item: item(id: 'c', name: 'Milk', quantity: 2, isChecked: true),
          checkedByMember: ListMember(
            userId: UserId('user-2'),
            displayName: 'Sam',
            role: MemberRole.member,
            joinedAt: now,
          ),
          onToggle: () {},
          onEdit: () {},
          onSwipeDelete: () => () {},
          selectionMode: false,
          selected: false,
          onToggleSelection: () {},
          onLongPress: () {},
          index: 0,
          canReorder: false,
          t: t,
        ),
        ItemTile(
          item: item(id: 'd', name: 'Olive oil'),
          shopDotColor: const Color(0xFFE8791A),
          checkedByMember: null,
          onToggle: () {},
          onEdit: () {},
          onSwipeDelete: () => () {},
          selectionMode: false,
          selected: false,
          onToggleSelection: () {},
          onLongPress: () {},
          index: 0,
          canReorder: false,
          justAdded: true,
          t: t,
        ),
        ItemTile(
          item: item(id: 'e', name: 'Eggs', pending: true),
          checkedByMember: null,
          onToggle: () {},
          onEdit: () {},
          onSwipeDelete: () => () {},
          selectionMode: false,
          selected: false,
          onToggleSelection: () {},
          onLongPress: () {},
          index: 0,
          canReorder: false,
          t: t,
        ),
      ],
    ),
  );
}
