import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/haptics/haptics_controller.dart';

/// Fires the app's own haptics only while the user has them on.
extension HapticsRef on WidgetRef {
  /// Runs [feedback] (e.g. `HapticFeedback.lightImpact`) unless the Haptics
  /// setting is off. "Still loading" counts as on -- the same default
  /// [HapticsController] itself starts from -- and that default lives here
  /// once rather than at every call site.
  void haptic(Future<void> Function() feedback) {
    if (read(hapticsControllerProvider).value ?? true) unawaited(feedback());
  }
}
