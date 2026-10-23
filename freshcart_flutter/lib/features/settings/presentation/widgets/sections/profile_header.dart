import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/avatar/initial_for.dart';
import 'package:freshcart_flutter/core/ui/avatar/user_avatar.dart';
import 'package:freshcart_flutter/features/auth/presentation/widgets/edit_profile_sheet.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The top of Settings: avatar, name, the email (if linked, with a tick),
/// and an "Edit" link to the `EditProfileSheet`.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({required this.user, required this.t, super.key});

  final AsyncValue<Result<AuthUser>> user;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final account = user.dataOrNull;
    final displayName = account?.displayName ?? '';
    final email = account?.email;
    final linked = account != null && !account.isAnonymous && email != null;

    return Row(
      children: [
        UserAvatar(
          seed: account?.id.value ?? '',
          initial: initialFor(displayName),
          photoUrl: account?.avatarPhotoUrl,
          color: account?.avatarColor,
          radius: AppSizes.avatarLarge / 2,
        ),
        const SizedBox(width: AppSpacing.gap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName, style: theme.textTheme.titleMedium),
              if (linked)
                Row(
                  children: [
                    const Icon(
                      Icons.verified,
                      size: AppSizes.shopDotLarge,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.gapSmall / 2),
                    Flexible(
                      child: Text(
                        email,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        // Styled as a bold text link (like in the drawer), so it doesn't
        // stand out more than the rows below.
        TextButton(
          onPressed: () => showEditProfileSheet(context),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            textStyle: AppTextStyles.labelStrong,
          ),
          child: Text(t.settings.editProfile),
        ),
      ],
    );
  }
}
