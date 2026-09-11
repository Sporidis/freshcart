import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/core/theme/appearance_provider.dart';
import 'package:freshcart_flutter/core/ui/user_avatar.dart';
import 'package:freshcart_flutter/features/auth/data/auth_repository_provider.dart';
import 'package:freshcart_flutter/features/auth/presentation/upgrade_nudge.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

class PreferencesSection extends ConsumerWidget {
  const PreferencesSection({required this.t, super.key});

  final Translations t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.settings.preferences,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SettingDropdownOption<Appearance>(
          title: t.settings.appearance,
          value: appearance,
          options: {
            Appearance.system: t.settings.currentAppearance(
              mode: t.settings.appearanceSystem,
            ),
            Appearance.light: t.settings.currentAppearance(
              mode: t.settings.appearanceLight,
            ),
            Appearance.dark: t.settings.currentAppearance(
              mode: t.settings.appearanceDark,
            ),
          },
          onChanged: (value) =>
              ref.read(appearanceControllerProvider.notifier).select(value),
        ),
        SettingDropdownOption<AppLocale>(
          title: t.settings.language,
          value: ref.watch(activeLocaleProvider),
          options: {
            AppLocale.nl: 'Nederlands',
            AppLocale.en: 'English',
            AppLocale.fr: 'Français',
            AppLocale.ru: 'Русский',
            AppLocale.tl: 'Tagalog',
          },
          onChanged: (value) =>
              ref.read(activeLocaleProvider.notifier).select(value),
        ),
        SettingOption(title: t.settings.notifications, onTap: () {}),
        SettingToggleOption(
          title: t.settings.keepCheckedItems,
          description: t.settings.keepCheckedItemsBody,
          value: true,
          onChanged: (_) {},
        ),
        SettingToggleOption(
          title: t.settings.haptics,
          value: true,
          onChanged: (_) {},
        ),
      ],
    );
  }
}

class SettingDropdownOption<T> extends StatelessWidget {
  const SettingDropdownOption({
    super.key,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      style: ListTileStyle.list,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: Border(
        bottom: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      title: Text(title),
      trailing: Text(options[value] ?? value.toString()),
      onTap: () async {
        final chosen = await showDialog<T>(
          context: context,
          builder: (context) => SimpleDialog(
            title: Text(title),
            children: options.entries
                .map(
                  (entry) => ListTile(
                    title: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(entry.value),
                    ),
                    trailing: entry.key == value
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => Navigator.of(context).pop(entry.key),
                  ),
                )
                .toList(),
          ),
        );
        if (chosen != null) onChanged(chosen);
      },
    );
  }
}

class SettingToggleOption extends StatelessWidget {
  const SettingToggleOption({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.description,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: Border(
        bottom: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      title: Text(title),
      subtitle: description != null
          ? Text(description!, style: Theme.of(context).textTheme.bodySmall)
          : null,
      value: value,
      onChanged: onChanged,
    );
  }
}

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
            'App version: 1.0.0',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class ListsAndShopsSection extends ConsumerWidget {
  const ListsAndShopsSection({required this.t, this.firstList, super.key});

  final Translations t;
  final ShoppingList? firstList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final displayName = user.value?.valueOrNull?.displayName.trim() ?? '';
    final initial = displayName.isEmpty ? '?' : displayName[0].toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(text: t.settings.listsAndShops.toUpperCase()),
        const SizedBox(height: 12),
        SettingOption(
          title: t.settings.manageLists,
          onTap: () => context.push(Routes.lists),
        ),
        if (firstList != null) ...[
          SettingOption(
            title: t.settings.manageShops,
            onTap: () => context.push(Routes.manageShops(firstList!.id)),
          ),
          SettingOption(
            title: t.settings.household,
            trailingIcons: [
              UserAvatar(
                seed: user.value?.valueOrNull?.id.value ?? '',
                initial: initial,
                photoUrl: user.value?.valueOrNull?.avatarPhotoUrl,
                color: user.value?.valueOrNull?.avatarColor,
              ),
            ],
            onTap: () => context.push(Routes.household(firstList!.id)),
          ),
        ],
      ],
    );
  }
}

class SettingOption extends StatelessWidget {
  const SettingOption({
    super.key,
    required this.title,
    required this.onTap,
    this.trailingIcons,
  });

  final String title;
  final VoidCallback onTap;
  final List<Widget>? trailingIcons;

  @override
  Widget build(BuildContext context) {
    final icons = trailingIcons;
    return ListTile(
      style: ListTileStyle.list,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: Border(
        bottom: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icons case final values? when values.isNotEmpty)
            SizedBox(
              width: 24 + ((values.length - 1) * 12),
              height: 24,
              child: Stack(
                children: [
                  for (var i = 0; i < values.length; i++)
                    Positioned(
                      left: i * 12,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        child: values[i],
                      ),
                    ),
                ],
              ),
            ),
          if (icons?.isNotEmpty ?? false) const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({required this.user, required this.t, super.key});

  final AsyncValue<Result<AuthUser>> user;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final displayName = user.value?.valueOrNull?.displayName ?? '';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        UserAvatar(
          seed: user.value?.valueOrNull?.id.value ?? '',
          initial: displayName.trim().isEmpty
              ? '?'
              : displayName.trim()[0].toUpperCase(),
          photoUrl: user.value?.valueOrNull?.avatarPhotoUrl,
          color: user.value?.valueOrNull?.avatarColor,
          radius: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(displayName, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              if (user.value?.valueOrNull?.email?.isNotEmpty ?? false)
                Text(
                  user.value?.valueOrNull?.email ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        TextButton(
          child: Text(t.settings.editProfile),
          onPressed: () => context.push(Routes.editProfile),
        ),
      ],
    );
  }
}

class AccountCard extends StatelessWidget {
  const AccountCard({required this.user, required this.t, super.key});

  final AuthUser user;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linked = !user.isAnonymous;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              linked ? Icons.verified_user_outlined : Icons.shield_outlined,
              color: linked ? AppColors.success : theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    linked ? t.account.linked : t.account.title,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    linked ? (user.email ?? '') : t.account.body,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (!linked) ...[
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => showLinkEmailDialog(context),
                      child: Text(t.account.action),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.bold,
    ),
  );
}
