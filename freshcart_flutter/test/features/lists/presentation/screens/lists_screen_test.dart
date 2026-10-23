import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/app/app.dart';
import 'package:freshcart_flutter/app/offline_replay_providers.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/offline/status/sync_providers.dart';
import 'package:freshcart_flutter/features/auth/data/sources/anonymous_session_bootstrap.dart';
import 'package:freshcart_flutter/features/auth/data/sources/current_user_provider.dart';
import 'package:freshcart_flutter/features/items/application/items/items_controller.dart';
import 'package:freshcart_flutter/features/items/data/repositories/offline_item_repository.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/quick_add/quick_add_bar.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/offline_list_repository.dart';
import 'package:freshcart_flutter/features/lists/presentation/screens/household_screen.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/editable_list_title.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/member_avatar_stack.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/new_list_sheet.dart';
import 'package:freshcart_flutter/features/shops/data/repositories/shop_repository_impl.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/shop_picker.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../fakes/fake_item_repository.dart';
import '../../../../fakes/fake_list_repository.dart';
import '../../../../fakes/fake_shop_repository.dart';

void main() {
  setUpAll(configurePluralResolvers);

  late FakeListRepository repository;
  late FakeItemRepository itemRepository;
  late FakeShopRepository shopRepository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = FakeListRepository();
    // The detail screen renders the items section, so navigating there needs an
    // item repository even when the test is about the lists screen.
    itemRepository = FakeItemRepository();
    // The detail screen also renders the shop filter bar.
    shopRepository = FakeShopRepository();
  });

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    // Only the delete-confirmation test needs a resolved identity (to land
    // on the owner branch of the list menu); everything else leaves this
    // null and gets the default "assume membership until it resolves"
    // behavior the menu itself documents.
    String? currentUserId,
    // Set to make sign-in itself throw.
    Error? signInError,
  }) async {
    final container = ProviderContainer(
      overrides: [
        listRepositoryProvider.overrideWithValue(repository),
        itemRepositoryProvider.overrideWithValue(itemRepository),
        shopRepositoryProvider.overrideWithValue(shopRepository),
        syncProvider.overrideWith((ref) => Stream.value(SyncStatus.online)),
        // Screen tests, not sync tests: nothing replays the offline queue.
        queueDrainCoordinatorProvider.overrideWith((ref) {}),
        // These tests are about ListsScreen itself, not the onboarding gate —
        // a restored (non-new) identity so the router starts on /lists.
        authBootstrapProvider.overrideWith(
          (ref) async => signInError == null
              ? (authenticated: true, isNewIdentity: false)
              : throw signInError,
        ),
        if (currentUserId != null)
          currentUserIdProvider.overrideWith(
            (ref) async => Ok(UserId(currentUserId)),
          ),
      ],
    );
    addTearDown(container.dispose);
    container.read(localeControllerProvider.notifier).select(AppLocale.en);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const FreshCartApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('ListsScreen rendering', () {
    testWidgets('shows the empty state when there are no lists', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('No lists yet'), findsOneWidget);
      expect(
        find.text(
          'Start one for your household, or join a list someone shared with you.',
        ),
        findsOneWidget,
      );
      // The empty state carries both exits, so the FAB would be a duplicate.
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('a sign-in that throws still opens the app', (tester) async {
      await pump(tester, signInError: StateError('secure storage broke'));
      expect(find.text('No lists yet'), findsOneWidget);
    });

    testWidgets(
      'redirects straight into the first list, never showing a browser',
      (tester) async {
        final groceries = buildList(
          name: 'Groceries',
          members: [buildMember()],
        );
        final hardware = buildList(
          id: '00000000-0000-4000-8000-000000000002',
          name: 'Hardware',
          members: [
            buildMember(),
            buildMember(userId: 'user-2'),
          ],
        );
        repository.myListsResult = Ok([groceries, hardware]);
        repository.byIdResult = Ok(groceries);

        await pump(tester);

        // Landed on Groceries' own detail screen directly -- there is no
        // separate "all lists" screen to have tapped through first, and
        // Hardware's own name never renders anywhere on screen.
        expect(find.widgetWithText(AppBar, 'Groceries'), findsOneWidget);
        expect(find.text('Hardware'), findsNothing);
      },
    );

    testWidgets('shows a localized message when the fetch fails', (
      tester,
    ) async {
      repository.myListsResult = const Err(Failure.network('offline'));

      await pump(tester);

      expect(find.text('Could not reach the server.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('creating a list', () {
    testWidgets('sends the name and refreshes the collection', (tester) async {
      repository.createResult = Ok(buildList(name: 'Weekend'));
      await pump(tester);
      final callsBefore = repository.myListsCallCount;

      await tester.tap(find.text('New list'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Weekend');
      // Create list enables on the frame after typing.
      await tester.pump();
      await tester.tap(find.text('Create list'));
      await tester.pumpAndSettle();

      expect(repository.createCalls.single, 'Weekend');
      expect(find.byType(NewListSheet), findsNothing);
      expect(
        repository.myListsCallCount,
        greaterThan(callsBefore),
        reason: 'a successful create must refresh the list',
      );
    });

    testWidgets(
      'keeps the dialog open and shows the message when the name is blank',
      (tester) async {
        await pump(tester);

        await tester.tap(find.text('New list'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '   ');
        // Create list enables on the frame after typing.
        await tester.pump();
        await tester.tap(find.text('Create list'));
        await tester.pumpAndSettle();

        // The domain rejected it before any network call.
        // The sheet won't send a blank name: Create list stays disabled,
        // and the sheet stays open for a real one.
        expect(repository.createCalls, isEmpty);
        expect(find.byType(NewListSheet), findsOneWidget);
      },
    );
    testWidgets('opens the new list, and remembers it as last opened', (
      tester,
    ) async {
      final weekend = buildList(
        id: '00000000-0000-4000-8000-0000000000aa',
        name: 'Weekend',
      );
      repository
        ..createResult = Ok(weekend)
        ..byIdResult = Ok(weekend);
      await pump(tester);

      await tester.tap(find.text('New list'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Weekend');
      // Create list enables on the frame after typing.
      await tester.pump();
      await tester.tap(find.text('Create list'));
      await tester.pumpAndSettle();

      // On the new list's detail screen, not left on the lists screen.
      expect(
        find.descendant(
          of: find.byType(EditableListTitle),
          matching: find.text('Weekend'),
        ),
        findsOneWidget,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_opened_list_id'), weekend.id.value);
    });
  });

  group('joining by code', () {
    testWidgets('accepts a valid code, normalizing case', (tester) async {
      repository.joinResult = Ok(buildList(name: 'Shared'));
      await pump(tester);

      await tester.tap(find.byIcon(Icons.group_add_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'abc23');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repository.joinCalls.single.value, 'ABC23');
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('opens the joined list, and remembers it as last opened', (
      tester,
    ) async {
      final shared = buildList(
        id: '00000000-0000-4000-8000-0000000000bb',
        name: 'Shared',
      );
      repository
        ..joinResult = Ok(shared)
        ..byIdResult = Ok(shared);
      await pump(tester);

      await tester.tap(find.byIcon(Icons.group_add_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'abc23');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(EditableListTitle),
          matching: find.text('Shared'),
        ),
        findsOneWidget,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_opened_list_id'), shared.id.value);
    });

    testWidgets('rejects a malformed code without a round trip', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.byIcon(Icons.group_add_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'nope');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        repository.joinCalls,
        isEmpty,
        reason: 'JoinList parses the code before spending a request',
      );
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('A join code is 5 characters'), findsOneWidget);
    });

    testWidgets('surfaces a code that matches no list', (tester) async {
      repository.joinResult = const Err(Failure.notFound());
      await pump(tester);

      await tester.tap(find.byIcon(Icons.group_add_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ZZZ99');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repository.joinCalls.single.value, 'ZZZ99');
      expect(find.text('Not found.'), findsOneWidget);
    });
  });

  group('renaming in place', () {
    testWidgets('tapping the title opens a field and saves on submit', (
      tester,
    ) async {
      final list = buildList(name: 'Groceries', members: [buildMember()]);
      repository.myListsResult = Ok([list]);
      repository.byIdResult = Ok(list);

      // Renaming is owner-only (§15) -- buildMember()'s own default id is
      // the owner buildList() defaults to, so this is "me, renaming my own
      // list," not a permissions edge case.
      await pump(tester, currentUserId: 'user-1');

      // The header title itself became the field -- no sheet, no dialog.
      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();
      final titleField = find.descendant(
        of: find.byType(EditableListTitle),
        matching: find.byType(TextField),
      );
      expect(titleField, findsOneWidget);

      await tester.enterText(titleField, 'Weekly Groceries');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(repository.renameCalls.single.name, 'Weekly Groceries');
    });

    testWidgets('a rejected name keeps the field open to be corrected', (
      tester,
    ) async {
      final list = buildList(name: 'Groceries', members: [buildMember()]);
      repository.myListsResult = Ok([list]);
      repository.byIdResult = Ok(list);
      repository.renameResult = const Err(
        Failure.validation('name', 'That name is too long'),
      );

      // Same reason as the test above: rename is owner-only (§15).
      await pump(tester, currentUserId: 'user-1');

      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();
      final titleField = find.descendant(
        of: find.byType(EditableListTitle),
        matching: find.byType(TextField),
      );
      await tester.enterText(titleField, 'Something');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Still editable, still holding what they typed.
      expect(titleField, findsOneWidget);
      expect(
        tester.widget<TextField>(titleField).controller?.text,
        'Something',
      );
    });
  });

  group('deleting a list', () {
    testWidgets('the confirmation names both the members and the products', (
      tester,
    ) async {
      final list = buildList(
        name: 'Groceries',
        members: [
          buildMember(),
          buildMember(userId: 'user-2'),
        ],
      );
      repository.myListsResult = Ok([list]);
      repository.byIdResult = Ok(list);
      itemRepository.byListResult = Ok([
        buildItem(name: 'Milk'),
        buildItem(id: '00000000-0000-4000-8000-0000000000a2', name: 'Bread'),
        buildItem(id: '00000000-0000-4000-8000-0000000000a3', name: 'Eggs'),
      ]);

      await pump(tester, currentUserId: 'user-1');

      // Design v3: the list's own actions live in List settings, behind
      // the header's avatars.
      await tester.tap(find.byType(MemberAvatarStack));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Delete for everyone'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Delete for everyone'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Groceries?'), findsOneWidget);
      expect(
        find.text(
          'This removes the list and its 3 products for all 2 members. '
          'It cannot be undone.',
        ),
        findsOneWidget,
        reason: 'the count is why a bare "everything on it" is not enough',
      );

      // A real backend's own post-delete refresh would no longer return
      // this list -- update the fake to match, since ListsController.delete
      // refreshes its own state as part of a successful delete.
      repository.myListsResult = const Ok([]);
      // The dialog's confirm button; the settings row behind it has the
      // same label.
      await tester.tap(find.text('Delete for everyone').last);
      await tester.pumpAndSettle();

      expect(repository.deleteCalls.single, list.id);
      // Nothing left to redirect to -- the real empty state, not a screen
      // that no longer exists.
      expect(find.text('No lists yet'), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets("the household's avatars open List settings", (
      tester,
    ) async {
      final list = buildList(name: 'Groceries', members: [buildMember()]);
      repository.myListsResult = Ok([list]);
      repository.byIdResult = Ok(list);

      await pump(tester, currentUserId: 'user-1');

      expect(find.text('Groceries'), findsOneWidget);

      // Design v3: the avatars are the door to List settings, where the
      // household, shops and the list's own actions live.
      await tester.tap(find.byType(MemberAvatarStack));
      await tester.pumpAndSettle();
      expect(find.text('List settings'), findsOneWidget);
    });

    testWidgets('the hamburger opens a switcher to the other lists', (
      tester,
    ) async {
      final groceries = buildList(name: 'Groceries', members: [buildMember()]);
      final hardware = buildList(
        id: '00000000-0000-4000-8000-000000000002',
        name: 'Hardware',
        members: [
          buildMember(),
          buildMember(userId: 'user-2'),
        ],
      );
      repository.myListsResult = Ok([groceries, hardware]);
      repository.byIdResult = Ok(groceries);

      await pump(tester);

      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();

      // Both lists, the open one distinguishable from the other.
      expect(find.text('Groceries'), findsWidgets);
      expect(find.text('Hardware'), findsOneWidget);
      expect(find.text('2 members'), findsOneWidget);

      repository.byIdResult = Ok(hardware);
      await tester.tap(find.text('Hardware'));
      await tester.pumpAndSettle();

      // The drawer closed itself and the app bar now shows the other list.
      expect(find.byType(Drawer), findsNothing);
      expect(find.widgetWithText(AppBar, 'Hardware'), findsOneWidget);
    });

    testWidgets('picking a list in the drawer flies its name into the header', (
      tester,
    ) async {
      final groceries = buildList(name: 'Groceries', members: [buildMember()]);
      final hardware = buildList(
        id: '00000000-0000-4000-8000-000000000002',
        name: 'Hardware',
        members: [buildMember()],
      );
      repository.myListsResult = Ok([groceries, hardware]);
      repository.byIdResult = Ok(groceries);

      await pump(tester);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();

      repository.byIdResult = Ok(hardware);
      await tester.tap(find.text('Hardware'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      // The header's own title, which waits while the copy flies in.
      double headerTitleOpacity(String name) => tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.descendant(
                    of: find.byType(AppBar),
                    matching: find.text(name),
                  ),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity;

      expect(headerTitleOpacity('Hardware'), 0);

      await tester.pumpAndSettle();
      expect(headerTitleOpacity('Hardware'), 1);
      // Landed: only the header's title is left.
      expect(find.text('Hardware'), findsOneWidget);

      // And again, back the other way. Every list used to share one page,
      // so from the second switch on the old screen was reused, its title
      // had already flown, and nothing moved.
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      repository.byIdResult = Ok(groceries);
      await tester.tap(find.text('Groceries'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      expect(headerTitleOpacity('Groceries'), 0);
      await tester.pumpAndSettle();
      expect(headerTitleOpacity('Groceries'), 1);
    });

    testWidgets('the drawer\'s Settings entry navigates to Settings', (
      tester,
    ) async {
      final list = buildList(name: 'Groceries', members: [buildMember()]);
      repository.myListsResult = Ok([list]);
      repository.byIdResult = Ok(list);

      await pump(tester);

      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsNothing);
      expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
    });

    testWidgets('a list the user cannot see reports no access', (tester) async {
      final list = buildList(name: 'Groceries');
      repository.myListsResult = Ok([list]);
      repository.byIdResult = const Err(Failure.unauthorized());

      await pump(tester);

      // The screen tier, not a message in the body: without the list there is
      // no screen left to render, so it is replaced outright.
      expect(find.text('You no longer have access'), findsOneWidget);
      // One action, no dead end.
      expect(find.text('Back to your lists'), findsOneWidget);
    });

    testWidgets('a deleted list says so, and offers the way out', (
      tester,
    ) async {
      final list = buildList(name: 'Groceries');
      repository.myListsResult = Ok([list]);
      repository.byIdResult = const Err(Failure.notFound());

      await pump(tester);

      expect(find.text('This list was deleted'), findsOneWidget);

      // A real backend's refresh (onExit refreshes before navigating, see
      // list_detail_screen.dart) would no longer return a list that was
      // just reported deleted -- update the fake to match.
      repository.myListsResult = const Ok([]);
      await tester.tap(find.text('Back to your lists'));
      await tester.pumpAndSettle();

      // Nothing left to redirect to -- the real empty state, not stranded
      // on a screen that no longer exists.
      expect(find.text('No lists yet'), findsOneWidget);
    });

    testWidgets(
      'a collaborator joining while Household is open updates it live',
      (tester) async {
        final list = buildList(name: 'Groceries', members: [buildMember()]);
        repository.myListsResult = Ok([list]);
        repository.byIdResult = Ok(list);
        addTearDown(repository.dispose);

        await pump(tester, currentUserId: 'user-1');
        await tester.tap(find.byType(MemberAvatarStack));
        await tester.pumpAndSettle();
        // List settings shows each member; a member row opens Household.
        await tester.tap(find.text('Nikolaos'));
        await tester.pumpAndSettle();
        expect(find.byType(HouseholdScreen), findsOneWidget);
        expect(find.text('Mom'), findsNothing);

        // Someone else joins the list on another device — no user action here,
        // just the server pushing the updated state down the live stream that
        // listByIdProvider shares with the screen underneath Household.
        repository.live.add(
          Ok(
            buildList(
              name: 'Groceries',
              members: [
                buildMember(),
                buildMember(userId: 'user-2', displayName: 'Mom'),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mom'), findsOneWidget);
      },
    );
  });

  group('swipe to delete', () {
    Future<void> openGroceries(WidgetTester tester) async {
      final list = buildList(name: 'Groceries', members: [buildMember()]);
      repository.myListsResult = Ok([list]);
      repository.byIdResult = Ok(list);
      itemRepository.byListResult = Ok([
        buildItem(name: 'Milk'),
        buildItem(id: '00000000-0000-4000-8000-0000000000a2', name: 'Bread'),
      ]);
      await pump(tester);
    }

    // Right-to-left, well past the 40% threshold.
    Future<void> swipeAway(WidgetTester tester, String name) async {
      await tester.drag(find.text(name), const Offset(-600, 0));
      await tester.pumpAndSettle();
    }

    testWidgets('a swiped row goes at once, with an Undo that brings it back '
        'and deletes nothing', (tester) async {
      await openGroceries(tester);
      await swipeAway(tester, 'Milk');

      expect(find.text('Milk'), findsNothing);
      expect(find.text('Milk removed'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      // Past the whole undo window: the cancelled delete never lands.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsOneWidget);
      expect(itemRepository.removedIds, isEmpty);
    });

    testWidgets('left alone, the delete lands once the undo window ends', (
      tester,
    ) async {
      await openGroceries(tester);
      await swipeAway(tester, 'Milk');
      expect(itemRepository.removedIds, isEmpty, reason: 'held, not sent');

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(itemRepository.removedIds, hasLength(1));
    });

    testWidgets('a short swipe springs back and deletes nothing', (
      tester,
    ) async {
      await openGroceries(tester);
      await tester.drag(find.text('Milk'), const Offset(-120, 0));
      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Milk removed'), findsNothing);
    });
  });

  group('multi-select', () {
    Future<void> openGroceries(WidgetTester tester) async {
      final list = buildList(name: 'Groceries', members: [buildMember()]);
      repository.myListsResult = Ok([list]);
      repository.byIdResult = Ok(list);
      itemRepository.byListResult = Ok([
        buildItem(name: 'Milk'),
        buildItem(id: '00000000-0000-4000-8000-0000000000a2', name: 'Bread'),
      ]);

      await pump(tester);
    }

    // Selection is entered from a row's hold-menu ("Select more…"), not by
    // long-press directly -- that gesture opens the menu. Held in small
    // steps: the hold's 450ms threshold timer only fires reliably against
    // the fake clock when it elapses in several pumps.
    Future<void> enterSelection(WidgetTester tester, String name) async {
      final gesture = await tester.startGesture(
        tester.getCenter(find.text(name)),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select more…'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      "a row's Select more… enters selection and shows the contextual bar",
      (tester) async {
        await openGroceries(tester);

        await enterSelection(tester, 'Milk');

        expect(find.text('1 selected'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
        // The quick-add bar has no place mid-selection.
        expect(find.byType(TextField), findsNothing);
      },
    );

    testWidgets('tapping another row adds it to the selection', (
      tester,
    ) async {
      await openGroceries(tester);

      await enterSelection(tester, 'Milk');
      await tester.tap(find.text('Bread'));
      await tester.pumpAndSettle();

      expect(find.text('2 selected'), findsOneWidget);
    });

    testWidgets('tapping a selected row again removes it, exiting once empty', (
      tester,
    ) async {
      await openGroceries(tester);

      await enterSelection(tester, 'Milk');
      expect(find.text('1 selected'), findsOneWidget);

      await tester.tap(find.text('Milk'));
      await tester.pumpAndSettle();

      // Nothing left selected -- the mode is over, the ordinary header is
      // back, and the row underneath is untouched.
      expect(find.text('1 selected'), findsNothing);
      expect(find.text('Milk'), findsOneWidget);
    });

    testWidgets('rows do not swipe while selecting -- taps own them', (
      tester,
    ) async {
      await openGroceries(tester);
      await enterSelection(tester, 'Milk');

      await tester.drag(find.text('Bread'), const Offset(-600, 0));
      await tester.pumpAndSettle();

      expect(find.text('Bread'), findsOneWidget);
      expect(find.text('Bread removed'), findsNothing);
    });

    testWidgets('Delete removes the selected rows and exits the mode', (
      tester,
    ) async {
      await openGroceries(tester);

      await enterSelection(tester, 'Milk');
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Gone from the list at once; deleted once Undo has had its chance.
      expect(find.text('Milk'), findsNothing);
      expect(itemRepository.removeManyCalls, isEmpty);
      await tester.pump(ItemsController.swipeUndoWindow);
      expect(
        itemRepository.removeManyCalls.single.single,
        ItemId('00000000-0000-4000-8000-0000000000aa'),
      );
      expect(find.text('Milk'), findsNothing);
      expect(find.text('Bread'), findsOneWidget);
      // Back to the ordinary header, not left on an empty selection.
      expect(find.text('1 selected'), findsNothing);
    });

    testWidgets('the close button exits without deleting anything', (
      tester,
    ) async {
      await openGroceries(tester);

      await enterSelection(tester, 'Milk');
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(itemRepository.removeManyCalls, isEmpty);
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
    });

    testWidgets('Move re-tags the selected rows and exits the mode', (
      tester,
    ) async {
      final bakery = buildShop(
        id: '00000000-0000-4000-8000-0000000000c1',
        name: 'Bakery',
        color: '#C62828',
      );
      shopRepository.byListResult = Ok([bakery]);
      await openGroceries(tester);

      await enterSelection(tester, 'Milk');
      await tester.tap(find.text('Move'));
      await tester.pumpAndSettle();

      expect(find.text('Move to'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(ShopPicker),
          matching: find.text('Bakery'),
        ),
      );
      await tester.pumpAndSettle();

      expect(itemRepository.moveManyCalls.single.shopId, bakery.id);
      expect(
        itemRepository.moveManyCalls.single.ids.single,
        ItemId('00000000-0000-4000-8000-0000000000aa'),
      );
      // Back to the ordinary header, not left on an empty selection.
      expect(find.text('1 selected'), findsNothing);
    });

    testWidgets(
      'a rejected Move keeps the selection, rather than losing the pick',
      (tester) async {
        final bakery = buildShop(
          id: '00000000-0000-4000-8000-0000000000c1',
          name: 'Bakery',
          color: '#C62828',
        );
        shopRepository.byListResult = Ok([bakery]);
        itemRepository.moveManyResult = const Err(Failure.network('offline'));
        await openGroceries(tester);

        await enterSelection(tester, 'Milk');
        await tester.tap(find.text('Move'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(ShopPicker),
            matching: find.text('Bakery'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('1 selected'), findsOneWidget);
      },
    );

    testWidgets('cancelling the Move sheet leaves the selection untouched', (
      tester,
    ) async {
      final bakery = buildShop(
        id: '00000000-0000-4000-8000-0000000000c1',
        name: 'Bakery',
        color: '#C62828',
      );
      shopRepository.byListResult = Ok([bakery]);
      await openGroceries(tester);

      await enterSelection(tester, 'Milk');
      await tester.tap(find.text('Move'));
      await tester.pumpAndSettle();
      // Tap outside the sheet to dismiss it without choosing.
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(itemRepository.moveManyCalls, isEmpty);
      expect(find.text('1 selected'), findsOneWidget);
    });
  });

  group('search', () {
    Future<void> openGroceries(WidgetTester tester) async {
      final list = buildList(name: 'Groceries', members: [buildMember()]);
      repository.myListsResult = Ok([list]);
      repository.byIdResult = Ok(list);
      itemRepository.byListResult = Ok([
        buildItem(id: 'a', name: 'Milk'),
        buildItem(id: 'b', name: 'Bread'),
      ]);

      await pump(tester);
    }

    testWidgets(
      'tapping the search icon expands the field and hides the quick-add bar',
      (tester) async {
        await openGroceries(tester);

        expect(find.byKey(const ValueKey('search')), findsNothing);

        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('search')), findsOneWidget);
        // The reference's own search header: the bordered field plus a
        // trailing "Cancel" text action, no separate leading back-arrow.
        expect(find.text('Cancel'), findsOneWidget);
        // The quick-add field is the only other TextField this screen has.
        expect(find.byType(TextField), findsOneWidget);
        // Scaled out, not removed (v3): still built, but can't be tapped.
        expect(find.byType(QuickAddBar).hitTestable(), findsNothing);
      },
    );

    testWidgets('typing filters to matching products only', (tester) async {
      await openGroceries(tester);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('search')), 'mil');
      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Bread'), findsNothing);
    });

    testWidgets(
      'no matches offers to add the search text, which actually adds it',
      (tester) async {
        itemRepository.addResult = Ok(buildItem(name: 'Eggs'));
        await openGroceries(tester);

        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const ValueKey('search')), 'eggs');
        await tester.pumpAndSettle();

        expect(find.text('No products match ‘eggs’'), findsOneWidget);

        await tester.tap(find.text('Add "eggs" to this list'));
        await tester.pumpAndSettle();

        // The addition lands in the same search: "Eggs" now matches the
        // query still typed, so the dead end resolves into a real result.
        expect(find.text('No products match ‘eggs’'), findsNothing);
        expect(find.text('Eggs'), findsOneWidget);
      },
    );

    testWidgets('Cancel closes search and restores the tab strip', (
      tester,
    ) async {
      await openGroceries(tester);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('search')), 'mil');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('search')), findsNothing);
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
    });
  });
}
