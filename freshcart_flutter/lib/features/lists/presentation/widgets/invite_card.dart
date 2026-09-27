import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/haptics/haptics_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The list's join code, with a copy button that confirms itself.
///
/// The button morphs to a checkmark for 1.6 s rather than firing a snackbar:
/// the feedback belongs on the control that was pressed, and a snackbar for
/// something this small would cover the very thing they are about to share.
class InviteCard extends ConsumerStatefulWidget {
  /// Creates the card for [joinCode].
  const InviteCard({required this.joinCode, required this.t, super.key});

  /// The code someone types to join.
  final String joinCode;

  /// Translations for the active locale.
  final Translations t;

  @override
  ConsumerState<InviteCard> createState() => _InviteCardState();
}

class _InviteCardState extends ConsumerState<InviteCard> {
  static const Duration _held = Duration(milliseconds: 1600);

  bool _copied = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.joinCode));
    if (ref.read(hapticsControllerProvider).value ?? true) {
      unawaited(HapticFeedback.lightImpact());
    }
    if (!mounted) return;
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(_held, () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.4,
        ),
        borderRadius: BorderRadius.circular(AppRadii.input),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              widget.joinCode,
              style: AppTextStyles.codeLarge.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            onPressed: _copy,
            tooltip: widget.t.household.copyCode,
            icon: AnimatedSwitcher(
              duration: AppMotion.durationFor(context, AppMotion.quick),
              child: _copied
                  ? Icon(
                      Icons.check_circle,
                      key: const ValueKey('copied'),
                      color: theme.colorScheme.tertiary,
                    )
                  : const Icon(Icons.copy_outlined, key: ValueKey('copy')),
            ),
          ),
        ],
      ),
    );
  }
}
