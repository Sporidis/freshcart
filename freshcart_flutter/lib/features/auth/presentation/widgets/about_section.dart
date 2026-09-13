import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/features/auth/data/auth_repository_provider.dart';
import 'package:freshcart_flutter/features/auth/presentation/widgets/section_label.dart';
import 'package:freshcart_flutter/features/auth/presentation/widgets/setting_option.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

/// The Settings screen's "Help & feedback" group, ending in sign-out.
class AboutSection extends StatelessWidget {
  const AboutSection({required this.t, super.key});

  final Translations t;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SectionLabel(text: t.settings.helpFeedback),
          const SizedBox(height: 12),
          SettingOption(title: t.settings.termsOfService, onTap: () {}),
          Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () async {
                final result = await ref.read(authRepositoryProvider).signOut();
                if (!context.mounted) return;
                if (result.isOk) {
                  ref.invalidate(currentUserProvider);
                  final router = GoRouter.maybeOf(context);
                  if (router != null) {
                    router.go(Routes.welcome);
                  } else {
                    Navigator.of(context).maybePop();
                  }
                }
              },
              child: Text(
                t.settings.signOut,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ),
          Text(
            t.settings.appVersion(version: '1.0.0'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
