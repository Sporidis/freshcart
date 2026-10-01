import 'package:freshcart_domain/freshcart_domain.dart';

/// Everything `ManageShopsScreen` renders, already derived.
///
/// Pure Dart on purpose, same as the other screen states: domain types only,
/// so it stays unit-testable without a widget tree.
class ManageShopsScreenState {
  const ManageShopsScreenState({
    required this.shops,
    this.isLoading = false,
    this.loadFailure,
  });

  /// The list's shops; null until they have loaded. Kept through a refresh,
  /// so an edit does not blank the screen behind a spinner.
  final List<Shop>? shops;

  /// The shops haven't arrived yet -- distinct from a failed load.
  final bool isLoading;

  /// The shops failed to load at all.
  final Failure? loadFailure;

  /// Loaded, and there are none: the empty state, which offers the one
  /// action itself instead of a FAB.
  bool get isEmpty => shops?.isEmpty ?? false;
}
