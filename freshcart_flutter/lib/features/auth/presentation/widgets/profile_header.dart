import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/ui/user_avatar.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

/// The Settings screen's own header: avatar, name, email, and the door into
/// [EditProfileScreen].
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({required this.user, required this.t, super.key});

  final AsyncValue<Result<AuthUser>> user;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final displayName = user.dataOrNull?.displayName ?? '';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        UserAvatar(
          seed: user.dataOrNull?.id.value ?? '',
          initial: displayName.trim().isEmpty
              ? '?'
              : displayName.trim()[0].toUpperCase(),
          photoUrl: user.dataOrNull?.avatarPhotoUrl,
          color: user.dataOrNull?.avatarColor,
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
              if (user.dataOrNull?.email?.isNotEmpty ?? false)
                Text(
                  user.dataOrNull?.email ?? '',
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
