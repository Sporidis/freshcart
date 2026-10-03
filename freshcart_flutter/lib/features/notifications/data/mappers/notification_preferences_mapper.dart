import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';

/// Converts a Serverpod [dto.NotificationPreferences] into our domain
/// [NotificationPreferences].
extension NotificationPreferencesDtoX on dto.NotificationPreferences {
  /// Converts to the domain [NotificationPreferences].
  NotificationPreferences toDomain() => NotificationPreferences(
    itemAdded: itemAdded,
    memberJoined: memberJoined,
    listFinished: listFinished,
  );
}
