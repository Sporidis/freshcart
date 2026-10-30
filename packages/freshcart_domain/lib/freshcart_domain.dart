/// The core of FreshCart, in plain Dart.
///
/// Contains the entities, value objects, [Result]/[Failure], repository
/// interfaces (ports) and use cases.
///
/// This package uses NO Flutter, Serverpod, Firebase or generated client.
/// Because it's a separate package, the compiler enforces that (see
/// `docs/architecture.md`).
///
/// Import this file, never files from `src/` directly.
library;

// Auth
export 'src/auth/entities/auth_user.dart';
export 'src/auth/entities/sign_in.dart';
export 'src/auth/ports/auth_repository.dart';
export 'src/auth/ports/local_data_repository.dart';
export 'src/auth/use_cases/delete_account.dart';
export 'src/auth/use_cases/link_email.dart';
export 'src/auth/use_cases/set_avatar_photo.dart';
export 'src/auth/use_cases/set_display_name.dart';
export 'src/auth/use_cases/set_up_profile.dart';
export 'src/auth/use_cases/sign_out.dart';
export 'src/auth/use_cases/start_link_email.dart';
export 'src/auth/value_objects/user_id.dart';
// Core
export 'src/core/clock.dart';
export 'src/core/failure.dart';
export 'src/core/result.dart';
export 'src/core/validation_issue.dart';
export 'src/core/validation_issue_wire.dart';
// Items
export 'src/items/entities/name_history_entry.dart';
export 'src/items/entities/note.dart';
export 'src/items/entities/shopping_item.dart';
export 'src/items/ports/item_repository.dart';
export 'src/items/use_cases/add_item.dart';
export 'src/items/use_cases/edit_item.dart';
export 'src/items/use_cases/reorder_item.dart';
export 'src/items/use_cases/toggle_item_checked.dart';
export 'src/items/value_objects/item_id.dart';
// Lists
export 'src/lists/entities/list_member.dart';
export 'src/lists/entities/list_summary.dart';
export 'src/lists/entities/member_role.dart';
export 'src/lists/entities/shopping_list.dart';
export 'src/lists/ports/list_repository.dart';
export 'src/lists/use_cases/create_list.dart';
export 'src/lists/use_cases/join_list.dart';
export 'src/lists/use_cases/rename_list.dart';
export 'src/lists/value_objects/join_code.dart';
export 'src/lists/value_objects/list_id.dart';
export 'src/lists/value_objects/list_invite.dart';
// Notifications
export 'src/notifications/entities/notification_preferences.dart';
export 'src/notifications/ports/notification_repository.dart';
// Shops
export 'src/shops/entities/shop.dart';
export 'src/shops/entities/shop_item_disposition.dart';
export 'src/shops/ports/shop_repository.dart';
export 'src/shops/use_cases/create_shop.dart';
export 'src/shops/use_cases/edit_shop.dart';
export 'src/shops/use_cases/toggle_shop_active.dart';
export 'src/shops/value_objects/hex_color.dart';
export 'src/shops/value_objects/shop_id.dart';
