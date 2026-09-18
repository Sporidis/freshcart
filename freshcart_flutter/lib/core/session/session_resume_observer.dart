import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/features/items/application/items_controller.dart';
import 'package:freshcart_flutter/features/lists/application/lists_controller.dart';

/// Recovers realtime list/item streams after the app comes back from the
/// background.
///
/// Backgrounding the app kills the Serverpod client's underlying WebSocket.
/// Its already-open `watchList()` streams die with it and never reopen
/// themselves — Serverpod only retries with a fresh auth key on a stream's
/// *first* open, not one that dies mid-flight — so without this, a resumed
/// app is left showing a stale "you don't have access" error until the user
/// taps Retry (which works only because it forces a brand-new open). This
/// does the same thing Retry does, automatically, on every resume.
class SessionResumeObserver extends ConsumerStatefulWidget {
  /// Wraps [child], watching app lifecycle for as long as it is mounted.
  const SessionResumeObserver({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<SessionResumeObserver> createState() =>
      _SessionResumeObserverState();
}

class _SessionResumeObserverState extends ConsumerState<SessionResumeObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Invalidating without a family argument clears every cached instance,
    // so this doesn't need to know which list (if any) is currently open.
    ref.invalidate(listsControllerProvider);
    ref.invalidate(listByIdProvider);
    ref.invalidate(itemsControllerProvider);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
