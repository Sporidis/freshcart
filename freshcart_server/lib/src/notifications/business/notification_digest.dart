import 'package:freshcart_server/src/generated/protocol.dart';

/// Turns several changes into one notification text.
///
/// No database or Firebase here, so the wording rules are easy to test.
abstract final class NotificationDigest {
  /// Makes one notification for [pending] (all for the same list).
  ///
  /// Returns null if there's nothing worth sending: no changes, or only
  /// deletions (not worth waking up a phone for).
  static ({String title, String body})? summarise(
    String listName,
    List<PendingItemNotification> pending,
  ) {
    final additions = [
      for (final entry in pending)
        if (entry.kind == ItemChangeKind.upserted) entry,
    ];
    if (additions.isEmpty) return null;

    final actors = additions.map((e) => e.actorName).toSet();

    // One person, one item: say which item.
    if (additions.length == 1) {
      return (
        title: listName,
        body:
            '${additions.single.actorName} added ${additions.single.itemName}',
      );
    }

    // One person, several items: one notification with the count.
    if (actors.length == 1) {
      return (
        title: listName,
        body: '${actors.single} added ${additions.length} items',
      );
    }

    // Several people: too many names to fit, so just the count.
    return (
      title: listName,
      body: '${additions.length} items added to your list',
    );
  }

  /// "Someone joins a list". Always one person, so no grouping needed
  /// (decisions.md #80).
  static ({String title, String body}) memberJoined(
    String listName,
    String memberName,
  ) => (title: listName, body: '$memberName joined $listName');

  /// "A list is finished". Sent once, when the last item is checked
  /// (`ItemService.save` decides when) (decisions.md #80).
  static ({String title, String body}) listFinished(
    String listName,
    int itemCount,
  ) => (
    title: listName,
    body: 'All done — $itemCount ${itemCount == 1 ? 'item' : 'items'}',
  );
}
