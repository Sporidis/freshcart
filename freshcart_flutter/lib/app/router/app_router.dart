import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/features/lists/presentation/screens/household_screen.dart';
import 'package:freshcart_flutter/features/lists/presentation/screens/list_detail_screen.dart';
import 'package:freshcart_flutter/features/lists/presentation/screens/list_settings_screen.dart';
import 'package:freshcart_flutter/features/lists/presentation/screens/lists_screen.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/list_title_flight.dart';
import 'package:freshcart_flutter/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/screens/join_flow_screen.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:freshcart_flutter/features/settings/presentation/screens/settings_screen.dart';
import 'package:freshcart_flutter/features/shops/presentation/screens/manage_shops_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// All route paths, so no screen has to type a URL string itself.
///
/// A `...Pattern` is the piece used when defining the route below.
/// The method with the same name builds the full URL to navigate to.
abstract final class Routes {
  /// The user's lists. This is the home screen.
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

  /// App-wide settings (not for one specific list).
  static const String settings = '/settings';

  /// The path pattern for the Notifications screen, nested under settings.
  static const String notificationsPattern = 'notifications';

  /// The concrete path to Notifications.
  static const String notifications = '$settings/$notificationsPattern';

  /// The splash screen. The app always starts here. It stays up while the
  /// user is being signed in, then moves on to the right screen.
  static const String splash = '/splash';

  /// The welcome screen.
  static const String welcome = '/welcome';

  /// The onboarding flow.
  static const String onboarding = '/onboarding';

  /// Joining a list with an invite code, for a new user who hasn't done
  /// onboarding. This is the second button on the Welcome screen.
  static const String join = '/join';
}

/// Tells [ListsScreen] when the user comes back to it, for example by
/// pressing back or swiping back from a list. See `didPopNext` in
/// [ListsScreen].
///
/// A provider, not a global: an observer can only watch one navigator, and
/// the web demo runs two apps (two routers) in one engine (decisions.md
/// #112). `keepAlive`, like the router that uses it.
@Riverpod(keepAlive: true)
RouteObserver<PageRoute<void>> listsRouteObserver(Ref ref) =>
    RouteObserver<PageRoute<void>>();

/// The app's [GoRouter].
///
/// `keepAlive` because the router holds the navigation history. If it were
/// rebuilt, the user would be sent back to the first screen.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) => GoRouter(
  observers: [ref.watch(listsRouteObserverProvider)],
  // Always start on the splash screen. It decides where to go next:
  // new users go to Welcome, returning users go straight to their lists.
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
          pageBuilder: (context, state) {
            // A bad link with an empty id goes back to the lists screen,
            // instead of crashing inside ListId.
            final raw = state.pathParameters['listId'];
            final flight = state.extra is ListTitleFlight
                ? state.extra! as ListTitleFlight
                : null;
            final screen = raw == null || raw.isEmpty
                ? const ListsScreen()
                : ListDetailScreen(listId: ListId(raw), titleFlight: flight);
            // One page key per list. go_router's own key is the route
            // pattern ('/lists/:listId'), the same for every list, so the
            // Navigator treated a switch as "same page, new data" and
            // reused the old screen: its state (search text, the title's
            // played flight) carried over to the next list.
            final key = ValueKey<String>('list-detail-$raw');
            // Switching lists from the drawer happens in place (design
            // v3): a quick fade, no sideways push, while the name flies
            // into the header. Any other way in keeps the usual push.
            if (flight == null) {
              return MaterialPage<void>(key: key, child: screen);
            }
            return CustomTransitionPage<void>(
              key: key,
              child: screen,
              transitionDuration: AppMotion.listSwitch,
              reverseTransitionDuration: AppMotion.listSwitch,
              transitionsBuilder: (context, animation, _, child) =>
                  FadeTransition(opacity: animation, child: child),
            );
          },
        ),
      ],
    ),
  ],
  // No redirects for now. The server already checks if you're a member of a
  // list, and the detail screen shows "no access" if not. Checking again here
  // would mean two places deciding the same thing.
  redirect: (context, state) => null,
);
