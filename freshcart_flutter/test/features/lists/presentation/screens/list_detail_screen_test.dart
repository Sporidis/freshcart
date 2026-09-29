import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/app.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/features/auth/data/sources/anonymous_session_bootstrap.dart';
import 'package:freshcart_flutter/features/auth/data/sources/current_user_provider.dart';
import 'package:freshcart_flutter/features/items/data/repositories/item_repository_impl.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_section.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/list_repository_impl.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/lists_drawer.dart';
import 'package:freshcart_flutter/features/shops/data/repositories/shop_repository_impl.dart';
import 'package:freshcart_flutter/features/sync/application/sync/sync_providers.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../fakes/fake_item_repository.dart';
import '../../../../fakes/fake_list_repository.dart';
import '../../../../fakes/fake_shop_repository.dart';

/// Covers the scoping Priority 0 item #2 of `docs/upgrade-design-guide.md`
/// asks for: a shop's colour reaches the list-detail subtree it belongs to,
/// and nothing outside it -- not the drawer, not the app bar's own chrome.
/// `app_shell_test.dart`'s "theming" group used to cover the *old*,
/// app-wide mechanism this replaced; this file is its replacement.
void main() {
  setUpAll(configurePluralResolvers);

  late FakeListRepository listRepository;
  late FakeItemRepository itemRepository;
  late FakeShopRepository shopRepository;

  final colruyt = buildShop(name: 'Colruyt', color: '#C0392B');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    listRepository = FakeListRepository();
    itemRepository = FakeItemRepository();
    shopRepository = FakeShopRepository();
  });

  Future<ProviderContainer> pump(WidgetTester tester) async {
    final list = buildList(name: 'Groceries', members: [buildMember()]);
    listRepository.myListsResult = Ok([list]);
    listRepository.byIdResult = Ok(list);
    shopRepository.byListResult = Ok([colruyt]);

    final container = ProviderContainer(
      overrides: [
        listRepositoryProvider.overrideWithValue(listRepository),
        itemRepositoryProvider.overrideWithValue(itemRepository),
        shopRepositoryProvider.overrideWithValue(shopRepository),
        // Real connectivity_plus has no platform to answer in a widget test
        // and never resolves — pumpAndSettle hangs forever without this.
        syncProvider.overrideWith((ref) => Stream.value(SyncStatus.online)),
        authBootstrapProvider.overrideWith(
          (ref) async => (authenticated: true, isNewIdentity: false),
        ),
        currentUserIdProvider.overrideWith(
          (ref) async => Ok(UserId('user-1')),
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

  /// [Theme.of] resolved from inside the list body -- descends from the
  /// screen's own scoped colour-reveal theme, not the app root.
  ThemeData bodyTheme(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(ItemsSection)));

  group('theming', () {
    testWidgets('the body starts neutral, same as the rest of the app', (
      tester,
    ) async {
      await pump(tester);
      expect(bodyTheme(tester).colorScheme.primary, AppColors.ink);
    });

    testWidgets('selecting a shop tints the body with its own colour', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.textContaining('Colruyt'));
      await tester.pumpAndSettle();

      expect(
        bodyTheme(tester).colorScheme.primary,
        colruyt.color.toColor(),
      );
    });

    testWidgets(
      'the drawer stays neutral while the body is tinted -- the tint does '
      'not leak sideways',
      (tester) async {
        await pump(tester);
        await tester.tap(find.textContaining('Colruyt'));
        await tester.pumpAndSettle();
        expect(bodyTheme(tester).colorScheme.primary, isNot(AppColors.ink));

        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();

        final drawerTheme = Theme.of(
          tester.element(find.byType(ListsDrawer)),
        );
        expect(drawerTheme.colorScheme.primary, AppColors.ink);
      },
    );

    testWidgets('returning to "All" returns the body to neutral', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.textContaining('Colruyt'));
      await tester.pumpAndSettle();
      expect(bodyTheme(tester).colorScheme.primary, isNot(AppColors.ink));

      await tester.tap(find.text('All shops'));
      await tester.pumpAndSettle();

      expect(bodyTheme(tester).colorScheme.primary, AppColors.ink);
    });
  });
}
