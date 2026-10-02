import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/haptics/haptics_controller.dart';

/// Lets widgets vibrate with `ref.haptic(...)`, respecting the user's setting.
extension HapticsRef on WidgetRef {
  /// Runs [feedback] (for example `HapticFeedback.lightImpact`) unless the
  /// user turned vibration off. While the setting is still loading, it
  /// counts as on.
  void haptic(Future<void> Function() feedback) {
    if (read(hapticsControllerProvider).value ?? true) unawaited(feedback());
  }
}
