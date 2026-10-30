import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/app/router/app_router.dart';
import 'package:freshcart_flutter/core/offline/status/offline_status_providers.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/ui/destructive_button.dart';
import 'package:freshcart_flutter/core/ui/feedback/failure_snack_bar.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_row.dart';
import 'package:freshcart_flutter/core/ui/settings/settings_section.dart';
import 'package:freshcart_flutter/features/auth/application/profile/profile_controller.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

/// The "About" section in Settings: sign out, and the app version.
///
/// No "Terms" or "Help" rows yet, because there's nowhere for them to go.
/// A row that does nothing looks broken.
class AboutSection extends ConsumerWidget {
  const AboutSection({required this.t, required this.isAnonymous, super.key});

  final Translations t;

  /// Whether signing out would delete this account's lists forever. Pass
  /// true while still loading, to be safe.
  final bool isAnonymous;

  /// Asks "are you sure?" before signing out. Returns true to continue.
  ///
  /// Only asks when something would be lost: an anonymous account only
  /// exists on this phone, so signing out loses it forever; and changes
  /// made offline that haven't reached the server yet are deleted with the
  /// rest of this phone's data. Otherwise (a linked account, nothing
  /// waiting) it returns true straight away: they can sign back in.
  Future<bool> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final pending = await ref
        .read(profileControllerProvider.notifier)
        .pendingChangeCount();
    if (!isAnonymous && pending == 0) return true;
    if (!context.mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(t.settings.signOutConfirmTitle),
            // One row per thing that would be lost, each with its own
            // icon, so two separate warnings don't read as one paragraph.
            content: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.lg,
              children: [
                if (isAnonymous)
                  _SignOutLoss(
                    icon: Icons.no_accounts_outlined,
                    text: t.settings.signOutConfirmBody,
                  ),
                if (pending > 0)
                  _SignOutLoss(
                    icon: Icons.cloud_off_outlined,
                    text: t.settings.signOutPendingChanges(n: pending),
                  ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(t.common.cancel),
              ),
              DestructiveButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(t.settings.signOut),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    if (!await _confirmSignOut(context, ref)) return;
    final failure = await ref
        .read(profileControllerProvider.notifier)
        .signOut();
    if (!context.mounted) return;
    if (failure != null) {
      showFailureSnackBar(
        context,
        failure: failure,
        t: t,
        // The app looked online, but the server wasn't reached. Say that
        // nothing happened: the dialog just warned that things would be
        // lost.
        message: failure is NetworkFailure
            ? t.settings.signOutFailedOffline
            : null,
      );
      return;
    }
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go(Routes.welcome);
    } else {
      await Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    // Signing out needs the server (it ends the session there too). When
    // the phone knows it has no network, say so instead of letting the
    // user through a warning to an attempt that can only fail. Looking
    // online is no guarantee, so _signOut still handles a failed attempt.
    final offline =
        ref.watch(connectivityStatusProvider).value ==
        ConnectivityStatus.offline;
    return SettingsSection(
      label: t.settings.about,
      children: [
        SettingRow(
          title: t.settings.signOut,
          titleStyle: AppTextStyles.body.copyWith(
            color: offline ? scheme.onSurfaceVariant : scheme.error,
          ),
          subtitle: offline ? t.settings.signOutNeedsConnection : null,
          trailing: Text(
            t.settings.appVersion(version: '1.0.0'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          onTap: offline ? null : () => _signOut(context, ref),
        ),
      ],
    );
  }
}

/// One thing signing out would lose: an icon, and the sentence saying what.
///
/// The icon sits in a box exactly one line of text tall, so it lines up
/// with the middle of the first line, however many lines the text wraps to.
class _SignOutLoss extends StatelessWidget {
  const _SignOutLoss({required this.icon, required this.text});

  final IconData icon;
  final String text;

  /// The text's line height, as a multiple of its font size.
  static const double _lineHeight = 1.4;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = AppTextStyles.body.copyWith(
      color: scheme.onSurfaceVariant,
      height: _lineHeight,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.md,
      children: [
        SizedBox(
          height: style.fontSize! * _lineHeight,
          child: Icon(icon, size: 20, color: scheme.error),
        ),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}
