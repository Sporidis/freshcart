import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/lists/presentation/list_detail_screen.dart';
import 'package:freshcart_flutter/features/lists/presentation/lists_screen.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/onboarding_screen.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/welcome_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// Route paths, in one place so no screen hard-codes a string.
abstract final class Routes {
  /// The signed-in user's lists — the app's home.
  static const String lists = '/lists';

  /// The path pattern for one list's detail screen.
  static const String listDetailPattern = '/lists/:listId';

  /// The concrete path for [listId].
  static String listDetail(ListId listId) => '/lists/${listId.value}';

  /// The welcome screen.
  static const String welcome = '/welcome';

  /// The onboarding flow.
  static const String onboarding = '/onboarding';
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
      path: Routes.welcome,
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: Routes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: Routes.lists,
      builder: (context, state) => const ListsScreen(),
      routes: <RouteBase>[
        GoRoute(
          path: ':listId',
          builder: (context, state) {
            // A malformed id in a pasted or stale link is a routing concern,
            // not a domain one, so it is caught here and redirected rather
            // than allowed to throw out of ListId's constructor.
            final raw = state.pathParameters['listId'];
            if (raw == null || raw.isEmpty) return const ListsScreen();
            return ListDetailScreen(listId: ListId(raw));
          },
        ),
      ],
    ),
  ],
  // The auth guard attaches here in phase 10, and list membership is already
  // enforced server-side — ListService.requireMembership answers
  // NotAMemberException, which the detail screen renders as "no access".
  // Duplicating that check client-side would be a second source of truth.
  redirect: (context, state) => null,
);
