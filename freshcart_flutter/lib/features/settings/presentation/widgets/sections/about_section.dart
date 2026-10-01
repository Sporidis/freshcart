import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/destructive_button.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_row.dart';
import 'package:freshcart_flutter/core/ui/settings/settings_section.dart';
import 'package:freshcart_flutter/features/auth/application/profile/profile_controller.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

/// The Settings screen's "About" group: sign out, and the app version.
///
/// No "Terms of Service" or "Help & feedback" rows until they have a real
/// destination -- a row that does nothing when tapped reads as broken, and
/// these are the first rows a sceptical new user pokes at.
class AboutSection extends ConsumerWidget {
  const AboutSection({required this.t, required this.isAnonymous, super.key});

  final Translations t;

  /// Whether signing out would lose this account's lists for good. Pass
  /// true while the profile is still loading -- confirming once too often
  /// is harmless, skipping it once too often is not.
  final bool isAnonymous;

  /// An anonymous account exists only on this device (the account card's
  /// own copy says so), so signing it out is the one irreversible action in
  /// Settings -- it asks first. A linked account loses nothing, and signs
  /// straight out.
  Future<bool> _confirmSignOut(BuildContext context) async {
    if (!isAnonymous) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(t.settings.signOutConfirmTitle),
            content: Text(t.settings.signOutConfirmBody),
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
    if (!await _confirmSignOut(context)) return;
    final failure = await ref
        .read(profileControllerProvider.notifier)
        .signOut();
    if (!context.mounted || failure != null) return;
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go(Routes.welcome);
    } else {
      await Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsSection(
      label: t.settings.about,
      children: [
        SettingRow(
          title: t.settings.signOut,
          titleStyle: AppTextStyles.body.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
          trailing: Text(
            t.settings.appVersion(version: '1.0.0'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          onTap: () => _signOut(context, ref),
        ),
      ],
    );
  }
}
