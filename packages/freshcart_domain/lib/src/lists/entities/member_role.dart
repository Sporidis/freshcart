/// What a member may do to a shopping list.
enum MemberRole {
  /// Created the list. May rename and delete it, and remove other members.
  owner,

  /// Joined via a [JoinCode]. May add, edit, check and remove items.
  member,
}
