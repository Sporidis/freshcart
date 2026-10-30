import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_sizes.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/ui/avatar/initial_for.dart';
import 'package:freshcart_flutter/core/ui/avatar/user_avatar.dart';
import 'package:freshcart_flutter/core/ui/copy_to_clipboard.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_chevron.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_row.dart';
import 'package:freshcart_flutter/core/ui/settings/settings_section.dart';
import 'package:freshcart_flutter/features/lists/application/invite_section/invite_section_controller.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The household card: each member, then the invite.
///
/// Each member opens Household, where members are managed.
class ListMembersSection extends StatelessWidget {
  /// Creates the card for [list].
  const ListMembersSection({
    required this.list,
    required this.t,
    required this.onOpenHousehold,
    super.key,
  });

  final ShoppingList list;
  final Translations t;
  final VoidCallback onOpenHousehold;

  @override
  Widget build(BuildContext context) => SettingsSection(
    label: t.household.title,
    children: [
      for (final member in list.members)
        _MemberRow(member: member, t: t, onTap: onOpenHousehold),
      _InviteRow(listId: list.id, t: t),
    ],
  );
}

/// One household member: avatar, name, and "Owner" for the owner. Opens
/// Household.
class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.t,
    required this.onTap,
  });

  final ListMember member;
  final Translations t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SettingRow(
      leading: UserAvatar(
        seed: member.userId.value,
        initial: initialFor(member.displayName),
        photoUrl: member.avatarPhotoUrl,
        color: member.avatarColor,
        radius: AppSizes.avatarSmall / 2,
      ),
      title: member.displayName,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (member.isOwner)
            Text(
              t.household.owner,
              style: AppTextStyles.caption.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SettingChevron(),
        ],
      ),
    );
  }
}

/// The invite row. "Invite someone" until a member taps it, then "Invite
/// code   K7M2Q" in mono, with how long the code keeps working.
///
/// Tapping the code copies it; the code is swapped for "Copied" for a
/// moment, so the user sees it worked without a toast covering the screen
/// (same idea as `InviteCard`).
class _InviteRow extends ConsumerWidget {
  const _InviteRow({required this.listId, required this.t});

  final ListId listId;
  final Translations t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invite = ref.watch(inviteSectionControllerProvider(listId));
    void open() =>
        ref.read(inviteSectionControllerProvider(listId).notifier).open();

    return switch (invite) {
      AsyncData(value: Ok(:final value)) => _InviteCodeRow(
        invite: value,
        t: t,
      ),
      AsyncLoading() => SettingRow(
        title: t.household.inviteSomeone,
        trailing: const SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      // The row stays tappable, so the member can try again, with the
      // reason underneath.
      AsyncData(value: Err(:final failure)) => SettingRow(
        title: t.household.inviteSomeone,
        subtitle: failure.toMessage(t),
        onTap: open,
        trailing: const SettingChevron(),
      ),
      // Not asked yet. (The controller never stores an AsyncError; if it
      // ever did, asking again is the right offer.)
      null || AsyncError() => SettingRow(
        title: t.household.inviteSomeone,
        onTap: open,
        trailing: const SettingChevron(),
      ),
    };
  }
}

/// "Invite code   K7M2Q" in mono, and how long it keeps working. Tapping
/// copies the code.
class _InviteCodeRow extends StatelessWidget {
  const _InviteCodeRow({required this.invite, required this.t});

  final ListInvite invite;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final code = invite.code.value;
    final hoursLeft = invite.expiresAt.difference(DateTime.now()).inHours;
    return CopyToClipboard(
      text: code,
      builder: (context, copied, copy) => Semantics(
        hint: t.household.copyCode,
        child: SettingRow(
          title: t.household.inviteCode,
          subtitle: t.household.validFor(n: hoursLeft),
          titleStyle: AppTextStyles.body.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          onTap: copy,
          trailing: AnimatedSwitcher(
            duration: AppMotion.durationFor(context, AppMotion.quick),
            child: copied
                ? Text(
                    t.household.copied,
                    key: const ValueKey('copied'),
                    style: AppTextStyles.labelStrong.copyWith(
                      color: AppColors.success,
                    ),
                  )
                : Text(
                    code,
                    key: const ValueKey('code'),
                    style: AppTextStyles.code.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
