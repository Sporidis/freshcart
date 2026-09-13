import 'package:freshcart_server/src/generated/protocol.dart';

/// Turns a burst of buffered changes into one notification.
///
/// A pure function on purpose: the phrasing rules are the part worth pinning
/// with tests, and they have nothing to do with databases or Firebase.
abstract final class NotificationDigest {
  /// Summarises [pending], all for the same list.
  ///
  /// Returns null when there is nothing worth sending — an empty batch, or one
  /// that contains only removals, which are not worth waking a phone for.
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

    // One person, one item: name the item, because that is the useful bit.
    if (additions.length == 1) {
      return (
        title: listName,
        body:
            '${additions.single.actorName} added ${additions.single.itemName}',
      );
    }

    // One person, several items: aggregate rather than send a push per item.
    if (actors.length == 1) {
      return (
        title: listName,
        body: '${actors.single} added ${additions.length} items',
      );
    }

    // Several people: naming them all would not fit a notification.
    return (
      title: listName,
      body: '${additions.length} items added to your list',
    );
  }

  /// "Someone joins a list" -- always exactly one join, so there is nothing
  /// to batch the way item adds are (decisions #80, phase 2).
  static ({String title, String body}) memberJoined(
    String listName,
    String memberName,
  ) => (title: listName, body: '$memberName joined $listName');

  /// "A list is finished" -- fires once, the instant the last open item is
  /// checked; `ItemService.save`'s own `becameChecked` flag decides when
  /// this is even called (decisions #80, phase 2).
  static ({String title, String body}) listFinished(
    String listName,
    int itemCount,
  ) => (
    title: listName,
    body: 'All done — $itemCount ${itemCount == 1 ? 'item' : 'items'}',
  );
}
