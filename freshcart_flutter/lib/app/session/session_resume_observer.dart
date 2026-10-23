import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/features/lists/application/lists/lists_controller.dart';

/// Reloads the user's shopping lists when the app returns from the background.
///
/// The lists overview is fetched once, not streamed live. So if someone
/// creates, renames or deletes a list on another device while this app is in
/// the background, we would not see it. Re-fetching on resume fixes that.
///
/// Only the lists overview is refreshed here. Items and the open list are live
/// streams that reconnect themselves (`resilientWatch`). Refreshing them here
/// too would throw away offline items that have not been synced yet.
class SessionResumeObserver extends ConsumerStatefulWidget {
  /// Wraps [child] and listens to app lifecycle changes while mounted.
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
    // Start receiving lifecycle events (paused, resumed, ...) from Flutter.
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Stop receiving events, otherwise Flutter keeps a reference to a dead widget.
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // We only care about the moment the user comes back to the app.
    if (state != AppLifecycleState.resumed) return;
    // Throw away the cached lists so the controller fetches them again.
    ref.invalidate(listsControllerProvider);
  }

  // This widget draws nothing itself; it just passes its child through.
  @override
  Widget build(BuildContext context) => widget.child;
}
