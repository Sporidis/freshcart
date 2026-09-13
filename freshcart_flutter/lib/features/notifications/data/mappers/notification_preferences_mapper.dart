import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';

/// Maps a [dto.NotificationPreferences] wire object to the domain entity.
extension NotificationPreferencesDtoX on dto.NotificationPreferences {
  /// Converts to the domain [NotificationPreferences].
  NotificationPreferences toDomain() => NotificationPreferences(
    itemAdded: itemAdded,
    memberJoined: memberJoined,
    listFinished: listFinished,
  );
}
