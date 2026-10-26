import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/ui/feedback/failure_state.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// [FailureState] for anything that belongs to one list (the list, its
/// items, its shops): "not found" means the list was deleted, "no access"
/// means you're no longer on it.
class ListFailureState extends StatelessWidget {
  /// Creates the state for [failure] on a list's screen.
  const ListFailureState({
    required this.failure,
    required this.t,
    required this.action,
    super.key,
  });

  final Failure failure;
  final Translations t;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return FailureState(
      t: t,
      failure: failure,
      action: action,
      noAccess: (
        title: t.errors.noAccessTitle,
        body: t.errors.noAccessBody,
      ),
      notFound: (
        title: t.errors.listDeletedTitle,
        body: t.errors.listDeletedBody,
      ),
    );
  }
}
