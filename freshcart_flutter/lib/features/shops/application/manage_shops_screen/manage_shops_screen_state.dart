import 'package:freshcart_domain/freshcart_domain.dart';

/// The data `ManageShopsScreen` shows.
///
/// Plain Dart (no Flutter), so it can be tested without widgets.
class ManageShopsScreenState {
  const ManageShopsScreenState({
    required this.shops,
    this.isLoading = false,
    this.loadFailure,
  });

  /// The list's shops, or null until loaded. While reloading, the old ones
  /// stay, so the screen doesn't flash to a spinner after an edit.
  final List<Shop>? shops;

  /// Still loading (not the same as failed).
  final bool isLoading;

  /// The shops failed to load at all.
  final Failure? loadFailure;

  /// Loaded, but there are no shops. The empty state has its own "add"
  /// button.
  bool get isEmpty => shops?.isEmpty ?? false;
}
