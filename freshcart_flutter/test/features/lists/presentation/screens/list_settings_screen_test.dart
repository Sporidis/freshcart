import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/app/app.dart';
import 'package:freshcart_flutter/app/offline_replay_providers.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/offline/status/sync_providers.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_toggle_option.dart';
import 'package:freshcart_flutter/features/auth/data/sources/anonymous_session_bootstrap.dart';
import 'package:freshcart_flutter/features/auth/data/sources/current_user_provider.dart';
import 'package:freshcart_flutter/features/items/data/repositories/item_repository_impl.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/list_repository_impl.dart';
import 'package:freshcart_flutter/features/lists/presentation/screens/household_screen.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/error_screen.dart';
import 'package:freshcart_flutter/features/shops/data/repositories/shop_repository_impl.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/shop_sheet.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../fakes/fake_item_repository.dart';
import '../../../../fakes/fake_list_repository.dart';
import '../../../../fakes/fake_shop_repository.dart';

/// Reached only through the real journey (drawer -> Settings -> tapping the
/// list's own row under "Your lists"), not by constructing the screen
/// directly -- the point of this screen is that door, and a widget test
/// that skips it could not catch the door going missing.
///
/// There is deliberately no single "Manage lists" row to tap: the
/// `Flow Screens v2.dc.html` re-export replaced it with one row per list,
/// each opening straight into that list's own settings ("Shops and
/// household belong to a list. Pick one to manage it.") -- so the door this
/// suite exercises is a specific list's row, by name.
void main() {
  setUpAll(configurePluralResolvers);

  late FakeListRepository repository;
  late FakeItemRepository itemRepository;
  late FakeShopRepository shopRepository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = FakeListRepository();
    itemRepository = FakeItemRepository();
    shopRepository = FakeShopRepository();
  });

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required ShoppingList list,
    String? currentUserId,
  }) async {
    repository.myListsResult = Ok([list]);
    repository.byIdResult = Ok(list);
    final container = ProviderContainer(
      overrides: [
        listRepositoryProvider.overrideWithValue(repository),
        itemRepositoryProvider.overrideWithValue(itemRepository),
        shopRepositoryProvider.overrideWithValue(shopRepository),
        syncProvider.overrideWith((ref) => Stream.value(SyncStatus.online)),
        // Screen tests, not sync tests: nothing replays the offline queue.
        queueDrainCoordinatorProvider.overrideWith((ref) {}),
        authBootstrapProvider.overrideWith(
          (ref) async => (authenticated: true, isNewIdentity: false),
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

    // The real journey: drawer -> Settings -> the list's own row.
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(list.name));
    await tester.pumpAndSettle();
    return container;
  }

  // Keyed rather than find.byType(TextField), so a future second field on
  // this screen cannot make the finder ambiguous.
  Finder nameField() => find.byKey(const Key('listNameField'));

  testWidgets('opens pre-filled with the list\'s own name', (tester) async {
    await pump(
      tester,
      list: buildList(name: 'Groceries', members: [buildMember()]),
    );

    // v3: a large title in the page, not in the bar.
    expect(find.text('List settings'), findsOneWidget);
    expect(
      tester.widget<TextField>(nameField()).controller?.text,
      'Groceries',
    );
  });

  testWidgets('saving a new name calls through to rename', (tester) async {
    final list = buildList(name: 'Groceries', members: [buildMember()]);
    repository.renameResult = Ok(list.copyWith(name: 'Weekly Groceries'));
    await pump(tester, list: list);

    // There's no Save button — the field saves on submit.
    await tester.enterText(nameField(), 'Weekly Groceries');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(repository.renameCalls.single.name, 'Weekly Groceries');
  });

  testWidgets('a rejected rename shows the error beneath the field', (
    tester,
  ) async {
    final list = buildList(name: 'Groceries', members: [buildMember()]);
    repository.renameResult = const Err(
      Failure.validation('name', 'That name is too long'),
    );
    await pump(tester, list: list);

    await tester.enterText(nameField(), 'x' * 61);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('That name is too long'), findsOneWidget);
  });

  testWidgets(
    'the Clear checked after shopping toggle calls through',
    (tester) async {
      final list = buildList(name: 'Groceries', members: [buildMember()]);
      repository.setClearCheckedAfterShoppingResult = Ok(
        list.copyWith(clearCheckedAfterShopping: true),
      );
      await pump(tester, list: list);

      final tile = find.widgetWithText(
        SettingToggleOption,
        'Clear checked items automatically',
      );
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      expect(tester.widget<SettingToggleOption>(tile).value, isFalse);

      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(
        repository.setClearCheckedAfterShoppingCalls.single.value,
        isTrue,
      );
    },
  );

  testWidgets(
    'a failed Clear checked toggle says so in a snackbar, not silently',
    (tester) async {
      final list = buildList(name: 'Groceries', members: [buildMember()]);
      repository.setClearCheckedAfterShoppingResult = const Err(
        Failure.validation('clearChecked', 'Could not save that'),
      );
      await pump(tester, list: list);

      final tile = find.widgetWithText(
        SettingToggleOption,
        'Clear checked items automatically',
      );
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Could not save that'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'the list disappearing while open replaces the form with the error '
    'screen, rather than spinning forever',
    (tester) async {
      final list = buildList(name: 'Groceries', members: [buildMember()]);
      await pump(tester, list: list);
      expect(nameField(), findsOneWidget);

      // Pushed into the live stream after arriving, not set up front: the
      // journey above passes through the list's own detail screen, which
      // would stop at its own error screen first. This is also the real
      // case -- someone else deletes the list while it's open here.
      repository.live.add(const Err(Failure.notFound()));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorScreen), findsOneWidget);
      expect(nameField(), findsNothing);
    },
  );

  // No "Household" or "Manage shops" row exists in the current
  // ListSettingsScreen (its own doc comment describes them, but nothing
  // implements them yet) — removed rather than testing UI that isn't there.

  testWidgets('Add shop opens the create sheet, with the existing shops', (
    tester,
  ) async {
    final list = buildList(name: 'Groceries', members: [buildMember()]);
    final colruyt = Shop(
      id: ShopId('s1'),
      listId: list.id,
      name: 'Colruyt',
      color: HexColor.fromArgb(0xFFE8791A),
    );
    shopRepository.byListResult = Ok([colruyt]);
    await pump(tester, list: list);

    final addShop = find.text('Add shop');
    await tester.ensureVisible(addShop);
    await tester.tap(addShop);
    await tester.pumpAndSettle();

    final sheet = tester.widget<ShopSheet>(find.byType(ShopSheet));
    expect(sheet.shop, isNull, reason: 'create mode, not editing anything');
    expect(sheet.siblings, [colruyt], reason: 'for the clash warning');
  });

  /// The danger zone sits at the very bottom; ListView only builds what
  /// is on screen, so scroll it in before looking for it.
  Future<void> scrollToEnd(WidgetTester tester) async {
    await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
  }

  testWidgets('an owner sees Delete for everyone, not Leave list', (
    tester,
  ) async {
    await pump(
      tester,
      list: buildList(name: 'Groceries', members: [buildMember()]),
      currentUserId: 'user-1',
    );
    await scrollToEnd(tester);

    expect(find.text('Delete for everyone'), findsOneWidget);
    expect(find.text('Leave list'), findsNothing);
  });

  testWidgets('a member sees Leave list, not Delete for everyone', (
    tester,
  ) async {
    await pump(
      tester,
      list: buildList(
        name: 'Groceries',
        members: [
          buildMember(),
          buildMember(userId: 'user-2'),
        ],
      ),
      currentUserId: 'user-2',
    );
    await scrollToEnd(tester);

    expect(find.text('Leave list'), findsOneWidget);
    expect(find.text('Delete for everyone'), findsNothing);
  });

  testWidgets('leaving asks first, in the destructive red', (tester) async {
    await pump(
      tester,
      list: buildList(
        name: 'Groceries',
        members: [
          buildMember(),
          buildMember(userId: 'user-2'),
        ],
      ),
      currentUserId: 'user-2',
    );
    await scrollToEnd(tester);

    await tester.tap(find.text('Leave list'));
    await tester.pumpAndSettle();

    expect(find.text('Leave this list?'), findsOneWidget);
    final confirm = find.widgetWithText(FilledButton, 'Leave list');
    final style = tester.widget<FilledButton>(confirm).style!;
    expect(style.backgroundColor?.resolve({}), AppColors.destructive);
  });

  testWidgets('a list with no shops still offers Add shop', (tester) async {
    shopRepository.byListResult = const Ok([]);
    await pump(
      tester,
      list: buildList(name: 'Groceries', members: [buildMember()]),
    );

    expect(find.text('Add shop'), findsOneWidget);
  });

  testWidgets('a name typed then left by Back is saved, not dropped', (
    tester,
  ) async {
    final list = buildList(name: 'Groceries', members: [buildMember()]);
    repository.renameResult = Ok(list.copyWith(name: 'Weekly'));
    await pump(tester, list: list);

    await tester.enterText(nameField(), 'Weekly');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(repository.renameCalls.single.name, 'Weekly');
  });

  testWidgets('a member row opens the household screen', (tester) async {
    await pump(
      tester,
      list: buildList(
        name: 'Groceries',
        members: [buildMember(displayName: 'Sam De Vos')],
      ),
    );

    final row = find.text('Sam De Vos');
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(find.byType(HouseholdScreen), findsOneWidget);
  });

  testWidgets('the invite code is shown inline, and a tap copies it', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pump(
      tester,
      list: buildList(name: 'Groceries', members: [buildMember()]),
    );

    final code = find.text('ABC23');
    await tester.ensureVisible(code);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Invite code'));
    await tester.pump();

    expect(copied, 'ABC23');
    expect(find.text('Copied'), findsOneWidget);

    // Back to the code once the confirmation has had its moment.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('ABC23'), findsOneWidget);
  });
}
