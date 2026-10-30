import 'package:freshcart_server/src/generated/protocol.dart';

import '../test_tools/serverpod_test_tools.dart';

/// Opens invites the way a member would before sharing one.
extension InviteCode on TestEndpoints {
  /// The join code [inviter], a member of [list], would share right now.
  Future<String> inviteCode(
    TestSessionBuilder inviter,
    ShoppingList list,
  ) async => (await this.list.openInvite(inviter, list.id!)).joinCode!;
}
