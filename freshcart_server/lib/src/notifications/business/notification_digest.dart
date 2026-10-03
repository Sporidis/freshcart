import 'package:freshcart_server/src/generated/protocol.dart';

/// Turns several changes into one notification text.
///
/// No database or Firebase here, so the wording rules are easy to test.
abstract final class NotificationDigest {
  /// Makes one notification for [pending] (items added to the same list),
  /// or null when there's nothing to say.
  ///
  /// Names the items, because "what was added" is the point: one person,
  /// "Sam added Milk, Eggs and Bread", or "Sam added Milk, Eggs and 3 more";
  /// two people, "Sam and Alex added Milk and Eggs"; more, "3 people added
  /// 7 items". An item added twice in the batch is named once.
  static ({String title, String body})? summarise(
    String listName,
    List<PendingItemNotification> pending,
  ) {
    if (pending.isEmpty) return null;

    final actors = <String>{for (final entry in pending) entry.actorName};
    // Same name, case aside, counts once ("Milk" then "milk"), spelled as
    // it was first added.
    final byKey = <String, String>{};
    for (final entry in pending) {
      final name = entry.itemName.trim();
      byKey.putIfAbsent(name.toLowerCase(), () => name);
    }
    final items = byKey.values.toList();

    final who = switch (actors.length) {
      1 => actors.single,
      2 => '${actors.first} and ${actors.last}',
      _ => '${actors.length} people',
    };
    final what = actors.length > 2 ? '${items.length} items' : _named(items);
    return (title: listName, body: '$who added $what');
  }

  /// "Milk", "Milk and Eggs", "Milk, Eggs and Bread", or the first two and
  /// "N more" past three, so the text fits a notification line.
  static String _named(List<String> items) {
    if (items.length == 1) return items.single;
    if (items.length <= 3) {
      return '${items.sublist(0, items.length - 1).join(', ')} '
          'and ${items.last}';
    }
    return '${items[0]}, ${items[1]} and ${items.length - 2} more';
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
