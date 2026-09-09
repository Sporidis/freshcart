import 'package:freshcart_flutter/features/lists/presentation/lists_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// Route paths, in one place so no screen hard-codes a string.
abstract final class Routes {
  /// The signed-in user's lists — the app's home.
  static const String lists = '/lists';
}

/// The app's [GoRouter].
///
/// `keepAlive` because the router owns navigation history; rebuilding it would
/// throw the user back to the start.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) => GoRouter(
  initialLocation: Routes.lists,
  routes: <RouteBase>[
    GoRoute(
      path: Routes.lists,
      builder: (context, state) => const ListsScreen(),
    ),
  ],
  // Auth and list-membership guards attach here. Deliberately empty for now:
  // sign-in lands in phase 5 and the membership guard in phase 5's list detail
  // route. A guard that silently allowed everything would be worse than an
  // obvious gap, so this stays a visible placeholder rather than a stub that
  // looks finished.
  redirect: (context, state) => null,
);
