import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';

/// The app's home: every list the signed-in user belongs to.
///
/// Empty for now by design — phase 5 wires it to `ListsController`. What it
/// does prove today is that the shell works end to end: routed, themed from the
/// active seed colour, and translated.
class ListsScreen extends ConsumerWidget {
  /// Creates the lists screen.
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.lists.title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_basket_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                t.lists.empty,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        // Wired in phase 5.
        onPressed: null,
        icon: const Icon(Icons.add),
        label: Text(t.lists.create),
      ),
    );
  }
}
