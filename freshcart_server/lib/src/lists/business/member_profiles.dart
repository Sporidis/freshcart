import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/profile/business/profile_service.dart';
import 'package:serverpod/serverpod.dart';

/// Fills a list's members with their current profile.
abstract final class MemberProfiles {
  /// [list] with its members, each with their current name, colour and
  /// photo (from `MemberProfile`).
  ///
  /// Every list read and broadcast goes through here, so people always show
  /// with their current profile (decisions.md #98). Two queries per list,
  /// not one per member.
  static Future<ShoppingList> attachTo(
    Session session,
    ShoppingList list,
  ) async {
    final members = await ListMember.db.find(
      session,
      where: (t) => t.listId.equals(list.id!),
      orderBy: (t) => t.joinedAt,
    );
    final profiles = await ProfileService.profilesFor(session, {
      for (final m in members) m.userId,
    });
    return list.copyWith(
      members: [
        for (final m in members)
          m.copyWith(
            displayName:
                profiles[m.userId]?.displayName ??
                ProfileService.fallbackDisplayName,
            avatarColorArgb: profiles[m.userId]?.avatarColorArgb,
            avatarPhotoUrl: await ProfileService.photoUrlFor(
              session,
              profiles[m.userId]?.avatarPhotoPath,
            ),
          ),
      ],
    );
  }
}
