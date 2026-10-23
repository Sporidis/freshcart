import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/ui/avatar/initial_for.dart';
import 'package:freshcart_flutter/core/ui/avatar/user_avatar.dart';
import 'package:freshcart_flutter/features/auth/application/profile/profile_controller.dart';
import 'package:freshcart_flutter/features/auth/presentation/widgets/edit_profile_sheet.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The top of the drawer (design v3): your avatar and name, with "Edit
/// profile" under it. Tap to edit your profile.
class ListsDrawerHeader extends ConsumerWidget {
  const ListsDrawerHeader({required this.t, super.key});

  final Translations t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final me = ref.watch(profileControllerProvider).value?.valueOrNull;

    return InkWell(
      onTap: () async {
        // Close the drawer first, so the sheet rises over the list.
        Navigator.of(context).pop();
        await showEditProfileSheet(context);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.sm,
          AppSpacing.screen,
          18,
        ),
        child: Row(
          children: [
            UserAvatar(
              seed: me?.id.value ?? '',
              initial: initialFor(me?.displayName ?? ''),
              photoUrl: me?.avatarPhotoUrl,
              color: me?.avatarColor,
              radius: 21,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    me?.displayName ?? '',
                    style: AppTextStyles.bodyStrong.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    t.profile.title,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
