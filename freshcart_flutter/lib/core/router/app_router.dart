import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/auth/presentation/settings_screen.dart';
import 'package:freshcart_flutter/features/lists/presentation/household_screen.dart';
import 'package:freshcart_flutter/features/lists/presentation/list_detail_screen.dart';
import 'package:freshcart_flutter/features/lists/presentation/lists_screen.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/join_flow_screen.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/onboarding_screen.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/splash_screen.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/welcome_screen.dart';
import 'package:freshcart_flutter/features/shops/presentation/manage_shops_screen.dart';
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

  /// The path pattern for one list's household screen.
  static const String householdPattern = 'household';

  /// The concrete path for [listId]'s household.
  static String household(ListId listId) => '/lists/${listId.value}/household';

  /// The path pattern for one list's shop management screen.
  static const String manageShopsPattern = 'shops';

  /// The concrete path for [listId]'s shops.
  static String manageShops(ListId listId) => '/lists/${listId.value}/shops';

  /// Account-level settings, not scoped to any one list.
  static const String settings = '/settings';

  /// The splash screen — the app's actual initial route. Shown for exactly
  /// as long as sign-in takes; it redirects itself onward once it knows.
  static const String splash = '/splash';

  /// The welcome screen.
  static const String welcome = '/welcome';

  /// The onboarding flow.
  static const String onboarding = '/onboarding';

  /// Joining an existing list from an invite code, for someone who has not
  /// been through onboarding yet — Welcome's second exit.
  static const String join = '/join';
}

/// The app's [GoRouter].
///
/// `keepAlive` because the router owns navigation history; rebuilding it would
/// throw the user back to the start.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) => GoRouter(
  // Always Splash — it is the one place that knows whether to send a new
  // identity to Welcome or a restored one straight to Lists (whose own empty
  // state already covers "no lists left", a distinct case from "never
  // onboarded"), and it needs to be an actual route, not a pre-`runApp`
  // gate, for its mark to `Hero` into Welcome's instead of just cutting.
  initialLocation: Routes.splash,
  routes: <RouteBase>[
    GoRoute(
      path: Routes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: Routes.welcome,
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: Routes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: Routes.join,
      builder: (context, state) => const JoinFlowScreen(),
    ),
    GoRoute(
      path: Routes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: Routes.lists,
      builder: (context, state) => const ListsScreen(),
      routes: <RouteBase>[
        GoRoute(
          path: ':listId',
          routes: <RouteBase>[
            GoRoute(
              path: Routes.householdPattern,
              builder: (context, state) {
                final raw = state.pathParameters['listId'];
                if (raw == null || raw.isEmpty) return const ListsScreen();
                return HouseholdScreen(listId: ListId(raw));
              },
            ),
            GoRoute(
              path: Routes.manageShopsPattern,
              builder: (context, state) {
                final raw = state.pathParameters['listId'];
                if (raw == null || raw.isEmpty) return const ListsScreen();
                return ManageShopsScreen(listId: ListId(raw));
              },
            ),
          ],
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
