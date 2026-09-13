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

import 'package:serverpod_client/serverpod_client.dart' as _i1;

/// A list's item counts -- the drawer's "6 left" / "All done" row (Flow 10,
/// §4). Not persisted: computed on demand from ShoppingItem, the same way
/// ShopService.itemCount already computes a count rather than storing one.
///
/// Deliberately not fields on ShoppingList itself: items are fetched
/// separately from lists precisely because the two change at very different
/// rates (see ShoppingList's own doc comment) -- folding a count onto every
/// list load would mean paying for it even on screens that never show it.
abstract class ListSummary implements _i1.SerializableModel {
  ListSummary._({
    required this.listId,
    required this.total,
    required this.checkedCount,
  });

  factory ListSummary({
    required _i1.UuidValue listId,
    required int total,
    required int checkedCount,
  }) = _ListSummaryImpl;

  factory ListSummary.fromJson(Map<String, dynamic> jsonSerialization) {
    return ListSummary(
      listId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['listId']),
      total: jsonSerialization['total'] as int,
      checkedCount: jsonSerialization['checkedCount'] as int,
    );
  }

  _i1.UuidValue listId;

  /// Every item on the list, checked or not.
  int total;

  /// How many of [total] are checked off. Named `checkedCount`, not
  /// `checked`: `package:meta` declares a top-level `checked` constant (the
  /// old, deprecated `@checked` annotation), and the domain entity this
  /// maps to could not compile against a field of that exact name. Named
  /// the same way here for one consistent name across the DTO/domain
  /// boundary rather than translating it at the mapper for no reason.
  int checkedCount;

  /// Returns a shallow copy of this [ListSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ListSummary copyWith({
    _i1.UuidValue? listId,
    int? total,
    int? checkedCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ListSummary',
      'listId': listId.toJson(),
      'total': total,
      'checkedCount': checkedCount,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ListSummaryImpl extends ListSummary {
  _ListSummaryImpl({
    required _i1.UuidValue listId,
    required int total,
    required int checkedCount,
  }) : super._(
         listId: listId,
         total: total,
         checkedCount: checkedCount,
       );

  /// Returns a shallow copy of this [ListSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ListSummary copyWith({
    _i1.UuidValue? listId,
    int? total,
    int? checkedCount,
  }) {
    return ListSummary(
      listId: listId ?? this.listId,
      total: total ?? this.total,
      checkedCount: checkedCount ?? this.checkedCount,
    );
  }
}
