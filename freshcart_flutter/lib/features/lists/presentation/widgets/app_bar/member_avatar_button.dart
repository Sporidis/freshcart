import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/ui/initial_for.dart';
import 'package:freshcart_flutter/core/ui/user_avatar.dart';
import 'package:freshcart_flutter/features/lists/application/list/list_providers.dart';
import 'package:go_router/go_router.dart';

/// Your avatar in the app bar. Tap to open the Household screen (members
/// and invite code).
class MemberAvatarButton extends ConsumerWidget {
  const MemberAvatarButton({required this.list, super.key});

  final ShoppingList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(myMembershipProvider(list));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => context.go(Routes.household(list.id)),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: me == null
              ? const CircleAvatar(radius: 16, child: Text('?'))
              : UserAvatar(
                  seed: me.userId.value,
                  initial: initialFor(me.displayName),
                  photoUrl: me.avatarPhotoUrl,
                  color: me.avatarColor,
                  radius: 16,
                ),
        ),
      ),
    );
  }
}
