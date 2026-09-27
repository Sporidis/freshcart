import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/list_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'list_use_case_providers.g.dart';

/// Supplies [CreateList], wired to the repository port.
///
/// Use cases are constructed here rather than inside controllers so a widget
/// test can override the repository once and have every use case follow.
@riverpod
CreateList createListUseCase(Ref ref) =>
    CreateList(ref.watch(listRepositoryProvider));

/// Supplies [JoinList], wired to the repository port.
@riverpod
JoinList joinListUseCase(Ref ref) =>
    JoinList(ref.watch(listRepositoryProvider));

/// The [RenameList] use case, wired to the list repository.
@riverpod
RenameList renameListUseCase(Ref ref) =>
    RenameList(ref.watch(listRepositoryProvider));
