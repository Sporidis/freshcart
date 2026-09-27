import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/auth/data/sources/current_user_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'signed_in_user_provider.g.dart';

/// Who the signed-in user is, or null until that's known (or if it failed).
///
/// The application layer's one doorway to [currentUserIdProvider], which
/// stays in `data/` because repositories need it too. Screens ask this --
/// or better, a question built on it like `isListOwner` -- instead of
/// reaching into the data layer themselves.
@riverpod
UserId? signedInUserId(Ref ref) => ref.watch(currentUserIdProvider).dataOrNull;
