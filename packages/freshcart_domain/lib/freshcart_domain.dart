/// The pure Dart heart of FreshCart.
///
/// Entities, value objects, the [Result]/[Failure] union, repository ports and
/// use cases. This library depends on nothing but pure Dart — no Flutter, no
/// Serverpod, no Firebase, no generated client — which is what makes the
/// dependency rule in `docs/architecture.md` enforceable by the compiler rather
/// than by convention.
///
/// Consumers import this barrel, never `src/` directly.
library;

// Auth
export 'src/auth/entities/auth_user.dart';
export 'src/auth/ports/auth_port.dart';
export 'src/auth/use_cases/set_display_name.dart';
export 'src/auth/value_objects/user_id.dart';
// Core
export 'src/core/clock.dart';
export 'src/core/failure.dart';
export 'src/core/result.dart';
// Items
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
export 'src/lists/entities/member_role.dart';
export 'src/lists/entities/shopping_list.dart';
export 'src/lists/ports/list_repository.dart';
export 'src/lists/use_cases/create_list.dart';
export 'src/lists/use_cases/join_list.dart';
export 'src/lists/use_cases/rename_list.dart';
export 'src/lists/value_objects/join_code.dart';
export 'src/lists/value_objects/list_id.dart';
// Notifications
export 'src/notifications/ports/push_port.dart';
// Shops
export 'src/shops/entities/shop.dart';
export 'src/shops/entities/shop_item_disposition.dart';
export 'src/shops/ports/shop_repository.dart';
export 'src/shops/use_cases/create_shop.dart';
export 'src/shops/use_cases/edit_shop.dart';
export 'src/shops/value_objects/hex_color.dart';
export 'src/shops/value_objects/shop_id.dart';
