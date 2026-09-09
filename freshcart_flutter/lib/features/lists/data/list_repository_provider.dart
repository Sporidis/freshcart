import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/di/serverpod_client_provider.dart';
import 'package:freshcart_flutter/features/lists/data/list_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'list_repository_provider.g.dart';

/// Supplies the [ListRepository] port.
///
/// The provider's type is the *domain port*, not the implementation, so
/// everything above it depends on the interface and a test can override this
/// with a fake without the app noticing.
@Riverpod(keepAlive: true)
ListRepository listRepository(Ref ref) =>
    ListRepositoryImpl(ref.watch(serverpodClientProvider));
