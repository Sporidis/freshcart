import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
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
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The household card: each member, then the invite code.
///
/// Each member opens Household, where members are managed (decisions.md
/// #69: link, don't copy). v3: the code is right here, no need to go to
/// Household to find it.
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
      _InviteCodeRow(code: list.joinCode.value, t: t),
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

/// "Invite code   K7M2Q" in mono. Tapping copies the code; the code is
/// swapped for "Copied" for a moment, so the user sees it worked without a
/// toast covering the screen (same idea as `InviteCard`).
class _InviteCodeRow extends StatelessWidget {
  const _InviteCodeRow({required this.code, required this.t});

  final String code;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CopyToClipboard(
      text: code,
      builder: (context, copied, copy) => Semantics(
        hint: t.household.copyCode,
        child: SettingRow(
          title: t.household.inviteCode,
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
