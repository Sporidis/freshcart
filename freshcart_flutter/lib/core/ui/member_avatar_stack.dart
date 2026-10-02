import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/initial_for.dart';
import 'package:freshcart_flutter/core/ui/user_avatar.dart';

/// Small overlapping avatars of who's on a list. Shows at most three, then
/// "+N" for the rest. The full list is on the Household screen.
///
/// Used in the drawer and in list settings.
class MemberAvatarStack extends StatelessWidget {
  const MemberAvatarStack({required this.members, super.key});

  final List<ListMember> members;

  static const int _maxShown = 3;
  static const double _diameter = 22;
  static const double _overlap = 7;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = members.take(_maxShown).toList();
    final overflow = members.length - shown.length;
    return SizedBox(
      height: _diameter,
      width:
          _diameter +
          (shown.length - 1 + (overflow > 0 ? 1 : 0)) * (_diameter - _overlap),
      child: Stack(
        children: [
          for (final (index, member) in shown.indexed)
            Positioned(
              left: index * (_diameter - _overlap),
              child: _MemberAvatar(
                member: member,
                borderColor: theme.colorScheme.surface,
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: shown.length * (_diameter - _overlap),
              child: Container(
                width: _diameter,
                height: _diameter,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.outlineVariant,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '+$overflow',
                  style: AppTextStyles.captionStrong.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member, required this.borderColor});

  final ListMember member;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final initial = initialFor(member.displayName);
    return UserAvatar(
      seed: member.userId.value,
      initial: initial,
      photoUrl: member.avatarPhotoUrl,
      color: member.avatarColor,
      radius: 11,
      border: Border.all(color: borderColor, width: 1.5),
    );
  }
}
