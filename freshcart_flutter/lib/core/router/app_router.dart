import 'package:flutter/widgets.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/auth/presentation/edit_profile_screen.dart';
import 'package:freshcart_flutter/features/auth/presentation/settings_screen.dart';
import 'package:freshcart_flutter/features/lists/presentation/household_screen.dart';
import 'package:freshcart_flutter/features/lists/presentation/list_detail_screen.dart';
import 'package:freshcart_flutter/features/lists/presentation/list_settings_screen.dart';
import 'package:freshcart_flutter/features/lists/presentation/lists_screen.dart';
import 'package:freshcart_flutter/features/notifications/presentation/notifications_screen.dart';
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

  /// The path pattern for one list's own settings screen.
  static const String listSettingsPattern = 'settings';

  /// The concrete path for [listId]'s settings.
  static String listSettings(ListId listId) =>
      '/lists/${listId.value}/settings';

  /// Account-level settings, not scoped to any one list.
  static const String settings = '/settings';

  /// The path pattern for the Edit profile screen, nested under settings.
  ///
  /// Temporary: its real home is a profile row on the restructured Settings
  /// screen (`docs/design-gap-plan.md` §5), which does not exist yet — see
  /// [EditProfileScreen]'s own doc comment.
  static const String editProfilePattern = 'profile';

  /// The concrete path to Edit profile.
  static const String editProfile = '$settings/$editProfilePattern';

  /// The path pattern for the Notifications screen, nested under settings.
  static const String notificationsPattern = 'notifications';

  /// The concrete path to Notifications.
  static const String notifications = '$settings/$notificationsPattern';

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

/// Notifies [ListsScreen] when it is revealed again because the route above
/// it (list detail, or one of its own sub-routes) was popped -- including by
/// the OS back-swipe gesture, which is otherwise invisible to a plain
/// [ModalRoute.isCurrent] check. See [ListsScreen]'s own `didPopNext`.
final listsRouteObserver = RouteObserver<PageRoute<void>>();

/// The app's [GoRouter].
///
/// `keepAlive` because the router owns navigation history; rebuilding it would
/// throw the user back to the start.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) => GoRouter(
  observers: [listsRouteObserver],
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
      routes: <RouteBase>[
        GoRoute(
          path: Routes.editProfilePattern,
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: Routes.notificationsPattern,
          builder: (context, state) => const NotificationsScreen(),
        ),
      ],
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
            GoRoute(
              path: Routes.listSettingsPattern,
              builder: (context, state) {
                final raw = state.pathParameters['listId'];
                if (raw == null || raw.isEmpty) return const ListsScreen();
                return ListSettingsScreen(listId: ListId(raw));
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
