import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/haptics/haptics_ref.dart';

/// Builds a [CopyToClipboard] child: [copied] is true for a moment after
/// [copy] ran, so the child can show "Copied".
typedef CopyBuilder =
    Widget Function(BuildContext context, bool copied, VoidCallback copy);

/// Copies [text] to the clipboard, with a light vibration, and tells
/// [builder] to show "copied" for a moment.
///
/// Only the behaviour: each caller draws its own button, pill or row.
class CopyToClipboard extends ConsumerStatefulWidget {
  const CopyToClipboard({required this.text, required this.builder, super.key});

  final String text;
  final CopyBuilder builder;

  @override
  ConsumerState<CopyToClipboard> createState() => _CopyToClipboardState();
}

class _CopyToClipboardState extends ConsumerState<CopyToClipboard> {
  /// How long "copied" stays before the child goes back to normal.
  static const Duration _held = Duration(milliseconds: 1600);

  bool _copied = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    ref.haptic(HapticFeedback.lightImpact);
    if (!mounted) return;
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(_held, () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _copied, _copy);
}
