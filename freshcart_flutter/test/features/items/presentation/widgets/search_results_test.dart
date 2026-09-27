import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/features/auth/data/current_user_provider.dart';
import 'package:freshcart_flutter/features/items/application/items_controller.dart';
import 'package:freshcart_flutter/features/items/data/item_repository_provider.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/search/search_results.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../fakes/fake_item_repository.dart';
import '../../../../fakes/fake_list_repository.dart';

void main() {
  setUpAll(configurePluralResolvers);

  final listId = ListId('00000000-0000-4000-8000-000000000001');
  final me = UserId('user-me');

  late FakeItemRepository repository;

  setUp(() {
    repository = FakeItemRepository();
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => repository.dispose());

  Future<void> pump(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        itemRepositoryProvider.overrideWithValue(repository),
        currentUserIdProvider.overrideWith((ref) async => Ok(me)),
      ],
    );
    addTearDown(container.dispose);
    container.read(localeControllerProvider.notifier).select(AppLocale.en);
    // itemsControllerProvider is autoDispose; holding a listener keeps it
    // alive across the tap below, the same way an open screen would (see
    // items_controller_test.dart's identical pattern).
    final subscription = container.listen(
      itemsControllerProvider(listId),
      (_, _) {},
    );
    addTearDown(subscription.close);
    final controller = container.read(itemsControllerProvider(listId).notifier);
    final t = container.read(translationsProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SearchResults(
              list: buildList(id: listId.value),
              allItems: const [],
              query: 'Nutella',
              t: t,
              controller: controller,
              report: (_, {onRetry}) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('SearchResults no-results "Add to this list"', () {
    testWidgets('tapping it adds the typed name', (tester) async {
      repository.byListResult = const Ok(<ShoppingItem>[]);
      repository.addResult = Ok(buildItem(name: 'Nutella'));
      await pump(tester);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(repository.addCalls.single.name, 'Nutella');
    });

    testWidgets('a rapid second tap does not start a second add', (
      tester,
    ) async {
      repository.byListResult = const Ok(<ShoppingItem>[]);
      repository.addResult = Ok(buildItem(name: 'Nutella'));
      final pause = Completer<void>();
      repository.addPause = pause.future;
      await pump(tester);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(repository.addCalls, hasLength(1));

      pause.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('tapping it fires a haptic', (tester) async {
      repository.byListResult = const Ok(<ShoppingItem>[]);
      repository.addResult = Ok(buildItem(name: 'Nutella'));
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            calls.add(call);
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await pump(tester);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(
        calls,
        contains(
          isMethodCall(
            'HapticFeedback.vibrate',
            arguments: 'HapticFeedbackType.lightImpact',
          ),
        ),
      );
    });
  });
}
