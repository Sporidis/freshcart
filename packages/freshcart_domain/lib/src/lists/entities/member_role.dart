/// A member's role on a list, which decides what they can do.
enum MemberRole {
  /// Made the list (or got ownership). Can rename and delete it, and
  /// remove members.
  owner,

  /// Joined with a [JoinCode]. Can add, edit, check and delete items.
  member,
}
