import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/ui/avatar/initial_for.dart';
import 'package:freshcart_flutter/core/ui/avatar/user_avatar.dart';

/// Small overlapping avatars of who's on a list. Shows at most three, then
/// "+N" for the rest. The full list is on the Household screen.
///
/// Used in the drawer and in list settings.
class MemberAvatarStack extends StatelessWidget {
  const MemberAvatarStack({
    required this.members,
    this.diameter = 22,
    this.overlap = 7,
    this.borderColor,
    super.key,
  });

  final List<ListMember> members;

  /// 22 in the drawer and settings; the list header uses 30.
  final double diameter;
  final double overlap;

  /// The ring that separates overlapping avatars. Defaults to the surface
  /// colour; pass the background when the stack sits on it (the header).
  final Color? borderColor;

  static const int _maxShown = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ring = borderColor ?? theme.colorScheme.surface;
    final shown = members.take(_maxShown).toList();
    final overflow = members.length - shown.length;
    return SizedBox(
      height: diameter,
      width:
          diameter +
          (shown.length - 1 + (overflow > 0 ? 1 : 0)) * (diameter - overlap),
      child: Stack(
        children: [
          for (final (index, member) in shown.indexed)
            Positioned(
              left: index * (diameter - overlap),
              child: _MemberAvatar(
                member: member,
                radius: diameter / 2,
                borderColor: ring,
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: shown.length * (diameter - overlap),
              child: Container(
                width: diameter,
                height: diameter,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.outlineVariant,
                  border: Border.all(color: ring, width: 1.5),
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
  const _MemberAvatar({
    required this.member,
    required this.radius,
    required this.borderColor,
  });

  final ListMember member;
  final double radius;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final initial = initialFor(member.displayName);
    return UserAvatar(
      seed: member.userId.value,
      initial: initial,
      photoUrl: member.avatarPhotoUrl,
      color: member.avatarColor,
      radius: radius,
      border: Border.all(color: borderColor, width: 1.5),
    );
  }
}
