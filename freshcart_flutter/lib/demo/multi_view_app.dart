import 'dart:ui' show FlutterView;

import 'package:flutter/widgets.dart';

/// Builds a widget for every view the host page adds, and drops it when the
/// view is removed. The current view is found with [View.of].
///
/// From the Flutter docs ("Embedding Flutter web", multi-view mode). The
/// host page adds and removes views with `app.addView` / `app.removeView`;
/// the engine reports both as a metrics change.
class MultiViewApp extends StatefulWidget {
  const MultiViewApp({required this.viewBuilder, super.key});

  final WidgetBuilder viewBuilder;

  @override
  State<MultiViewApp> createState() => _MultiViewAppState();
}

class _MultiViewAppState extends State<MultiViewApp>
    with WidgetsBindingObserver {
  Map<Object, Widget> _views = <Object, Widget>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateViews();
  }

  @override
  void didUpdateWidget(MultiViewApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The builder may have changed, so build every view again.
    _views.clear();
    _updateViews();
  }

  @override
  void didChangeMetrics() => _updateViews();

  void _updateViews() {
    final newViews = <Object, Widget>{
      for (final FlutterView view
          in WidgetsBinding.instance.platformDispatcher.views)
        view.viewId: _views[view.viewId] ?? _createViewWidget(view),
    };
    setState(() => _views = newViews);
  }

  Widget _createViewWidget(FlutterView view) => View(
    view: view,
    child: Builder(builder: widget.viewBuilder),
  );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ViewCollection(views: _views.values.toList(growable: false));
}
