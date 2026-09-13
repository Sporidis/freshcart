/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:serverpod/serverpod.dart' as _i1;
import 'package:serverpod/protocol.dart' as _i2;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i3;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i4;
import 'auth/models/linked_provider.dart' as _i5;
import 'common/models/account_already_linked_exception.dart' as _i6;
import 'common/models/avatar_photo_too_large_exception.dart' as _i7;
import 'common/models/edit_conflict_exception.dart' as _i8;
import 'common/models/email_already_in_use_exception.dart' as _i9;
import 'common/models/invalid_join_code_exception.dart' as _i10;
import 'common/models/item_not_found_exception.dart' as _i11;
import 'common/models/list_not_found_exception.dart' as _i12;
import 'common/models/not_a_member_exception.dart' as _i13;
import 'common/models/shop_not_found_exception.dart' as _i14;
import 'items/models/item_change.dart' as _i15;
import 'items/models/item_change_kind.dart' as _i16;
import 'items/models/item_name_history.dart' as _i17;
import 'items/models/note.dart' as _i18;
import 'items/models/shopping_item.dart' as _i19;
import 'lists/models/list_member.dart' as _i20;
import 'lists/models/member_role.dart' as _i21;
import 'lists/models/shopping_list.dart' as _i22;
import 'notifications/models/device_platform.dart' as _i23;
import 'notifications/models/device_token.dart' as _i24;
import 'notifications/models/list_mute.dart' as _i25;
import 'notifications/models/list_reference.dart' as _i26;
import 'notifications/models/pending_item_notification.dart' as _i27;
import 'shops/models/shop.dart' as _i28;
import 'shops/models/shop_item_disposition.dart' as _i29;
import 'users/models/current_user.dart' as _i30;
import 'users/models/member_profile.dart' as _i31;
import 'package:freshcart_server/src/generated/auth/models/linked_provider.dart'
    as _i32;
import 'package:freshcart_server/src/generated/items/models/shopping_item.dart'
    as _i33;
import 'package:freshcart_server/src/generated/items/models/item_name_history.dart'
    as _i34;
import 'package:freshcart_server/src/generated/lists/models/shopping_list.dart'
    as _i35;
import 'package:freshcart_server/src/generated/shops/models/shop.dart' as _i36;
export 'auth/models/linked_provider.dart';
export 'common/models/account_already_linked_exception.dart';
export 'common/models/avatar_photo_too_large_exception.dart';
export 'common/models/edit_conflict_exception.dart';
export 'common/models/email_already_in_use_exception.dart';
export 'common/models/invalid_join_code_exception.dart';
export 'common/models/item_not_found_exception.dart';
export 'common/models/list_not_found_exception.dart';
export 'common/models/not_a_member_exception.dart';
export 'common/models/shop_not_found_exception.dart';
export 'items/models/item_change.dart';
export 'items/models/item_change_kind.dart';
export 'items/models/item_name_history.dart';
export 'items/models/note.dart';
export 'items/models/shopping_item.dart';
export 'lists/models/list_member.dart';
export 'lists/models/member_role.dart';
export 'lists/models/shopping_list.dart';
export 'notifications/models/device_platform.dart';
export 'notifications/models/device_token.dart';
export 'notifications/models/list_mute.dart';
export 'notifications/models/list_reference.dart';
export 'notifications/models/pending_item_notification.dart';
export 'shops/models/shop.dart';
export 'shops/models/shop_item_disposition.dart';
export 'users/models/current_user.dart';
export 'users/models/member_profile.dart';

class Protocol extends _i1.SerializationManagerServer {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    _i2.TableDefinition(
      name: 'freshcart_device_token',
      dartName: 'DeviceToken',
      schema: 'public',
      module: 'freshcart',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid_v7()',
        ),
        _i2.ColumnDefinition(
          name: 'ownerId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'token',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'platform',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:DevicePlatform',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'freshcart_device_token_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'freshcart_device_token_unique_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'token',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'freshcart_device_token_owner_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'ownerId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'freshcart_item_name_history',
      dartName: 'ItemNameHistory',
      schema: 'public',
      module: 'freshcart',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid_v7()',
        ),
        _i2.ColumnDefinition(
          name: 'listId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'lastUsedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'freshcart_item_name_history_fk_0',
          columns: ['listId'],
          referenceTable: 'freshcart_shopping_list',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'freshcart_item_name_history_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'freshcart_item_name_history_list_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'listId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'lastUsedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'freshcart_item_name_history_unique_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'listId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'name',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'freshcart_list_member',
      dartName: 'ListMember',
      schema: 'public',
      module: 'freshcart',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid_v7()',
        ),
        _i2.ColumnDefinition(
          name: 'listId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'displayName',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'avatarColorArgb',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'avatarPhotoUrl',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'role',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:MemberRole',
        ),
        _i2.ColumnDefinition(
          name: 'joinedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'freshcart_list_member_fk_0',
          columns: ['listId'],
          referenceTable: 'freshcart_shopping_list',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'freshcart_list_member_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'freshcart_list_member_unique_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'listId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'freshcart_list_mute',
      dartName: 'ListMute',
      schema: 'public',
      module: 'freshcart',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid_v7()',
        ),
        _i2.ColumnDefinition(
          name: 'listId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'freshcart_list_mute_fk_0',
          columns: ['listId'],
          referenceTable: 'freshcart_shopping_list',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'freshcart_list_mute_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'freshcart_list_mute_unique_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'listId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'freshcart_member_profile',
      dartName: 'MemberProfile',
      schema: 'public',
      module: 'freshcart',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid_v7()',
        ),
        _i2.ColumnDefinition(
          name: 'authUserId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'displayName',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'avatarColorArgb',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'avatarPhotoPath',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'freshcart_member_profile_fk_0',
          columns: ['authUserId'],
          referenceTable: 'serverpod_auth_core_user',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'freshcart_member_profile_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'freshcart_member_profile_auth_user_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'authUserId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'freshcart_pending_item_notification',
      dartName: 'PendingItemNotification',
      schema: 'public',
      module: 'freshcart',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid_v7()',
        ),
        _i2.ColumnDefinition(
          name: 'listId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'actorId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'actorName',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'itemName',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'kind',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ItemChangeKind',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'freshcart_pending_item_notification_fk_0',
          columns: ['listId'],
          referenceTable: 'freshcart_shopping_list',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'freshcart_pending_item_notification_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'freshcart_pending_item_notification_list_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'listId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'freshcart_shop',
      dartName: 'Shop',
      schema: 'public',
      module: 'freshcart',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid_v7()',
        ),
        _i2.ColumnDefinition(
          name: 'listId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'colorArgb',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'isActive',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'freshcart_shop_fk_0',
          columns: ['listId'],
          referenceTable: 'freshcart_shopping_list',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'freshcart_shop_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'freshcart_shop_list_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'listId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'freshcart_shopping_item',
      dartName: 'ShoppingItem',
      schema: 'public',
      module: 'freshcart',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid_v7()',
        ),
        _i2.ColumnDefinition(
          name: 'listId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'quantity',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'isChecked',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _i2.ColumnDefinition(
          name: 'sortOrder',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
          columnDefault: '0.0',
        ),
        _i2.ColumnDefinition(
          name: 'shopId',
          columnType: _i2.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _i2.ColumnDefinition(
          name: 'note',
          columnType: _i2.ColumnType.json,
          isNullable: true,
          dartType: 'protocol:Note?',
        ),
        _i2.ColumnDefinition(
          name: 'addedBy',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'checkedBy',
          columnType: _i2.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _i2.ColumnDefinition(
          name: 'checkedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'freshcart_shopping_item_fk_0',
          columns: ['listId'],
          referenceTable: 'freshcart_shopping_list',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'freshcart_shopping_item_fk_1',
          columns: ['shopId'],
          referenceTable: 'freshcart_shop',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'freshcart_shopping_item_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'freshcart_shopping_item_list_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'listId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'sortOrder',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'freshcart_shopping_list',
      dartName: 'ShoppingList',
      schema: 'public',
      module: 'freshcart',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'gen_random_uuid_v7()',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'joinCode',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'ownerId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'freshcart_shopping_list_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'freshcart_shopping_list_join_code_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'joinCode',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'freshcart_shopping_list_owner_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'ownerId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._i3.Protocol.targetTableDefinitions,
    ..._i4.Protocol.targetTableDefinitions,
    ..._i2.Protocol.targetTableDefinitions,
  ];

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i5.LinkedProvider) {
      return _i5.LinkedProvider.fromJson(data) as T;
    }
    if (t == _i6.AccountAlreadyLinkedException) {
      return _i6.AccountAlreadyLinkedException.fromJson(data) as T;
    }
    if (t == _i7.AvatarPhotoTooLargeException) {
      return _i7.AvatarPhotoTooLargeException.fromJson(data) as T;
    }
    if (t == _i8.EditConflictException) {
      return _i8.EditConflictException.fromJson(data) as T;
    }
    if (t == _i9.EmailAlreadyInUseException) {
      return _i9.EmailAlreadyInUseException.fromJson(data) as T;
    }
    if (t == _i10.InvalidJoinCodeException) {
      return _i10.InvalidJoinCodeException.fromJson(data) as T;
    }
    if (t == _i11.ItemNotFoundException) {
      return _i11.ItemNotFoundException.fromJson(data) as T;
    }
    if (t == _i12.ListNotFoundException) {
      return _i12.ListNotFoundException.fromJson(data) as T;
    }
    if (t == _i13.NotAMemberException) {
      return _i13.NotAMemberException.fromJson(data) as T;
    }
    if (t == _i14.ShopNotFoundException) {
      return _i14.ShopNotFoundException.fromJson(data) as T;
    }
    if (t == _i15.ItemChange) {
      return _i15.ItemChange.fromJson(data) as T;
    }
    if (t == _i16.ItemChangeKind) {
      return _i16.ItemChangeKind.fromJson(data) as T;
    }
    if (t == _i17.ItemNameHistory) {
      return _i17.ItemNameHistory.fromJson(data) as T;
    }
    if (t == _i18.Note) {
      return _i18.Note.fromJson(data) as T;
    }
    if (t == _i19.ShoppingItem) {
      return _i19.ShoppingItem.fromJson(data) as T;
    }
    if (t == _i20.ListMember) {
      return _i20.ListMember.fromJson(data) as T;
    }
    if (t == _i21.MemberRole) {
      return _i21.MemberRole.fromJson(data) as T;
    }
    if (t == _i22.ShoppingList) {
      return _i22.ShoppingList.fromJson(data) as T;
    }
    if (t == _i23.DevicePlatform) {
      return _i23.DevicePlatform.fromJson(data) as T;
    }
    if (t == _i24.DeviceToken) {
      return _i24.DeviceToken.fromJson(data) as T;
    }
    if (t == _i25.ListMute) {
      return _i25.ListMute.fromJson(data) as T;
    }
    if (t == _i26.ListReference) {
      return _i26.ListReference.fromJson(data) as T;
    }
    if (t == _i27.PendingItemNotification) {
      return _i27.PendingItemNotification.fromJson(data) as T;
    }
    if (t == _i28.Shop) {
      return _i28.Shop.fromJson(data) as T;
    }
    if (t == _i29.ShopItemDisposition) {
      return _i29.ShopItemDisposition.fromJson(data) as T;
    }
    if (t == _i30.CurrentUser) {
      return _i30.CurrentUser.fromJson(data) as T;
    }
    if (t == _i31.MemberProfile) {
      return _i31.MemberProfile.fromJson(data) as T;
    }
    if (t == _i1.getType<_i5.LinkedProvider?>()) {
      return (data != null ? _i5.LinkedProvider.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.AccountAlreadyLinkedException?>()) {
      return (data != null
              ? _i6.AccountAlreadyLinkedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i7.AvatarPhotoTooLargeException?>()) {
      return (data != null
              ? _i7.AvatarPhotoTooLargeException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i8.EditConflictException?>()) {
      return (data != null ? _i8.EditConflictException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i9.EmailAlreadyInUseException?>()) {
      return (data != null
              ? _i9.EmailAlreadyInUseException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i10.InvalidJoinCodeException?>()) {
      return (data != null
              ? _i10.InvalidJoinCodeException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i11.ItemNotFoundException?>()) {
      return (data != null ? _i11.ItemNotFoundException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i12.ListNotFoundException?>()) {
      return (data != null ? _i12.ListNotFoundException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i13.NotAMemberException?>()) {
      return (data != null ? _i13.NotAMemberException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i14.ShopNotFoundException?>()) {
      return (data != null ? _i14.ShopNotFoundException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i15.ItemChange?>()) {
      return (data != null ? _i15.ItemChange.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.ItemChangeKind?>()) {
      return (data != null ? _i16.ItemChangeKind.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.ItemNameHistory?>()) {
      return (data != null ? _i17.ItemNameHistory.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.Note?>()) {
      return (data != null ? _i18.Note.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.ShoppingItem?>()) {
      return (data != null ? _i19.ShoppingItem.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i20.ListMember?>()) {
      return (data != null ? _i20.ListMember.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.MemberRole?>()) {
      return (data != null ? _i21.MemberRole.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.ShoppingList?>()) {
      return (data != null ? _i22.ShoppingList.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i23.DevicePlatform?>()) {
      return (data != null ? _i23.DevicePlatform.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i24.DeviceToken?>()) {
      return (data != null ? _i24.DeviceToken.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i25.ListMute?>()) {
      return (data != null ? _i25.ListMute.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i26.ListReference?>()) {
      return (data != null ? _i26.ListReference.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i27.PendingItemNotification?>()) {
      return (data != null ? _i27.PendingItemNotification.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i28.Shop?>()) {
      return (data != null ? _i28.Shop.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i29.ShopItemDisposition?>()) {
      return (data != null ? _i29.ShopItemDisposition.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i30.CurrentUser?>()) {
      return (data != null ? _i30.CurrentUser.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i31.MemberProfile?>()) {
      return (data != null ? _i31.MemberProfile.fromJson(data) : null) as T;
    }
    if (t == List<_i20.ListMember>) {
      return (data as List).map((e) => deserialize<_i20.ListMember>(e)).toList()
          as T;
    }
    if (t == _i1.getType<List<_i20.ListMember>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i20.ListMember>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i19.ShoppingItem>) {
      return (data as List)
              .map((e) => deserialize<_i19.ShoppingItem>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i19.ShoppingItem>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i19.ShoppingItem>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i28.Shop>) {
      return (data as List).map((e) => deserialize<_i28.Shop>(e)).toList() as T;
    }
    if (t == _i1.getType<List<_i28.Shop>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<_i28.Shop>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i25.ListMute>) {
      return (data as List).map((e) => deserialize<_i25.ListMute>(e)).toList()
          as T;
    }
    if (t == _i1.getType<List<_i25.ListMute>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i25.ListMute>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i27.PendingItemNotification>) {
      return (data as List)
              .map((e) => deserialize<_i27.PendingItemNotification>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i27.PendingItemNotification>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i27.PendingItemNotification>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i17.ItemNameHistory>) {
      return (data as List)
              .map((e) => deserialize<_i17.ItemNameHistory>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i17.ItemNameHistory>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i17.ItemNameHistory>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i32.LinkedProvider>) {
      return (data as List)
              .map((e) => deserialize<_i32.LinkedProvider>(e))
              .toList()
          as T;
    }
    if (t == List<_i33.ShoppingItem>) {
      return (data as List)
              .map((e) => deserialize<_i33.ShoppingItem>(e))
              .toList()
          as T;
    }
    if (t == List<_i1.UuidValue>) {
      return (data as List).map((e) => deserialize<_i1.UuidValue>(e)).toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i34.ItemNameHistory>) {
      return (data as List)
              .map((e) => deserialize<_i34.ItemNameHistory>(e))
              .toList()
          as T;
    }
    if (t == List<_i35.ShoppingList>) {
      return (data as List)
              .map((e) => deserialize<_i35.ShoppingList>(e))
              .toList()
          as T;
    }
    if (t == List<_i36.Shop>) {
      return (data as List).map((e) => deserialize<_i36.Shop>(e)).toList() as T;
    }
    try {
      return _i3.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i4.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i5.LinkedProvider => 'LinkedProvider',
      _i6.AccountAlreadyLinkedException => 'AccountAlreadyLinkedException',
      _i7.AvatarPhotoTooLargeException => 'AvatarPhotoTooLargeException',
      _i8.EditConflictException => 'EditConflictException',
      _i9.EmailAlreadyInUseException => 'EmailAlreadyInUseException',
      _i10.InvalidJoinCodeException => 'InvalidJoinCodeException',
      _i11.ItemNotFoundException => 'ItemNotFoundException',
      _i12.ListNotFoundException => 'ListNotFoundException',
      _i13.NotAMemberException => 'NotAMemberException',
      _i14.ShopNotFoundException => 'ShopNotFoundException',
      _i15.ItemChange => 'ItemChange',
      _i16.ItemChangeKind => 'ItemChangeKind',
      _i17.ItemNameHistory => 'ItemNameHistory',
      _i18.Note => 'Note',
      _i19.ShoppingItem => 'ShoppingItem',
      _i20.ListMember => 'ListMember',
      _i21.MemberRole => 'MemberRole',
      _i22.ShoppingList => 'ShoppingList',
      _i23.DevicePlatform => 'DevicePlatform',
      _i24.DeviceToken => 'DeviceToken',
      _i25.ListMute => 'ListMute',
      _i26.ListReference => 'ListReference',
      _i27.PendingItemNotification => 'PendingItemNotification',
      _i28.Shop => 'Shop',
      _i29.ShopItemDisposition => 'ShopItemDisposition',
      _i30.CurrentUser => 'CurrentUser',
      _i31.MemberProfile => 'MemberProfile',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('freshcart.', '');
    }

    switch (data) {
      case _i5.LinkedProvider():
        return 'LinkedProvider';
      case _i6.AccountAlreadyLinkedException():
        return 'AccountAlreadyLinkedException';
      case _i7.AvatarPhotoTooLargeException():
        return 'AvatarPhotoTooLargeException';
      case _i8.EditConflictException():
        return 'EditConflictException';
      case _i9.EmailAlreadyInUseException():
        return 'EmailAlreadyInUseException';
      case _i10.InvalidJoinCodeException():
        return 'InvalidJoinCodeException';
      case _i11.ItemNotFoundException():
        return 'ItemNotFoundException';
      case _i12.ListNotFoundException():
        return 'ListNotFoundException';
      case _i13.NotAMemberException():
        return 'NotAMemberException';
      case _i14.ShopNotFoundException():
        return 'ShopNotFoundException';
      case _i15.ItemChange():
        return 'ItemChange';
      case _i16.ItemChangeKind():
        return 'ItemChangeKind';
      case _i17.ItemNameHistory():
        return 'ItemNameHistory';
      case _i18.Note():
        return 'Note';
      case _i19.ShoppingItem():
        return 'ShoppingItem';
      case _i20.ListMember():
        return 'ListMember';
      case _i21.MemberRole():
        return 'MemberRole';
      case _i22.ShoppingList():
        return 'ShoppingList';
      case _i23.DevicePlatform():
        return 'DevicePlatform';
      case _i24.DeviceToken():
        return 'DeviceToken';
      case _i25.ListMute():
        return 'ListMute';
      case _i26.ListReference():
        return 'ListReference';
      case _i27.PendingItemNotification():
        return 'PendingItemNotification';
      case _i28.Shop():
        return 'Shop';
      case _i29.ShopItemDisposition():
        return 'ShopItemDisposition';
      case _i30.CurrentUser():
        return 'CurrentUser';
      case _i31.MemberProfile():
        return 'MemberProfile';
    }
    className = _i2.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod.$className';
    }
    className = _i3.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i4.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'LinkedProvider') {
      return deserialize<_i5.LinkedProvider>(data['data']);
    }
    if (dataClassName == 'AccountAlreadyLinkedException') {
      return deserialize<_i6.AccountAlreadyLinkedException>(data['data']);
    }
    if (dataClassName == 'AvatarPhotoTooLargeException') {
      return deserialize<_i7.AvatarPhotoTooLargeException>(data['data']);
    }
    if (dataClassName == 'EditConflictException') {
      return deserialize<_i8.EditConflictException>(data['data']);
    }
    if (dataClassName == 'EmailAlreadyInUseException') {
      return deserialize<_i9.EmailAlreadyInUseException>(data['data']);
    }
    if (dataClassName == 'InvalidJoinCodeException') {
      return deserialize<_i10.InvalidJoinCodeException>(data['data']);
    }
    if (dataClassName == 'ItemNotFoundException') {
      return deserialize<_i11.ItemNotFoundException>(data['data']);
    }
    if (dataClassName == 'ListNotFoundException') {
      return deserialize<_i12.ListNotFoundException>(data['data']);
    }
    if (dataClassName == 'NotAMemberException') {
      return deserialize<_i13.NotAMemberException>(data['data']);
    }
    if (dataClassName == 'ShopNotFoundException') {
      return deserialize<_i14.ShopNotFoundException>(data['data']);
    }
    if (dataClassName == 'ItemChange') {
      return deserialize<_i15.ItemChange>(data['data']);
    }
    if (dataClassName == 'ItemChangeKind') {
      return deserialize<_i16.ItemChangeKind>(data['data']);
    }
    if (dataClassName == 'ItemNameHistory') {
      return deserialize<_i17.ItemNameHistory>(data['data']);
    }
    if (dataClassName == 'Note') {
      return deserialize<_i18.Note>(data['data']);
    }
    if (dataClassName == 'ShoppingItem') {
      return deserialize<_i19.ShoppingItem>(data['data']);
    }
    if (dataClassName == 'ListMember') {
      return deserialize<_i20.ListMember>(data['data']);
    }
    if (dataClassName == 'MemberRole') {
      return deserialize<_i21.MemberRole>(data['data']);
    }
    if (dataClassName == 'ShoppingList') {
      return deserialize<_i22.ShoppingList>(data['data']);
    }
    if (dataClassName == 'DevicePlatform') {
      return deserialize<_i23.DevicePlatform>(data['data']);
    }
    if (dataClassName == 'DeviceToken') {
      return deserialize<_i24.DeviceToken>(data['data']);
    }
    if (dataClassName == 'ListMute') {
      return deserialize<_i25.ListMute>(data['data']);
    }
    if (dataClassName == 'ListReference') {
      return deserialize<_i26.ListReference>(data['data']);
    }
    if (dataClassName == 'PendingItemNotification') {
      return deserialize<_i27.PendingItemNotification>(data['data']);
    }
    if (dataClassName == 'Shop') {
      return deserialize<_i28.Shop>(data['data']);
    }
    if (dataClassName == 'ShopItemDisposition') {
      return deserialize<_i29.ShopItemDisposition>(data['data']);
    }
    if (dataClassName == 'CurrentUser') {
      return deserialize<_i30.CurrentUser>(data['data']);
    }
    if (dataClassName == 'MemberProfile') {
      return deserialize<_i31.MemberProfile>(data['data']);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _i2.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i3.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i4.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  @override
  _i1.Table? getTableForType(Type t) {
    {
      var table = _i3.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i4.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i2.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i17.ItemNameHistory:
        return _i17.ItemNameHistory.t;
      case _i19.ShoppingItem:
        return _i19.ShoppingItem.t;
      case _i20.ListMember:
        return _i20.ListMember.t;
      case _i22.ShoppingList:
        return _i22.ShoppingList.t;
      case _i24.DeviceToken:
        return _i24.DeviceToken.t;
      case _i25.ListMute:
        return _i25.ListMute.t;
      case _i27.PendingItemNotification:
        return _i27.PendingItemNotification.t;
      case _i28.Shop:
        return _i28.Shop.t;
      case _i31.MemberProfile:
        return _i31.MemberProfile.t;
    }
    return null;
  }

  @override
  List<_i2.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'freshcart';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _i3.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i4.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
