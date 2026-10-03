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
  /// Only asks for anonymous accounts: they only exist on this phone, so
  /// signing out loses them forever. A linked account can sign back in, so
  /// it returns true straight away.
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
