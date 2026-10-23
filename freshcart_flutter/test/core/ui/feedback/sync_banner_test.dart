import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/offline/status/offline_status_providers.dart';
import 'package:freshcart_flutter/core/offline/status/sync_conflicts_controller.dart';
import 'package:freshcart_flutter/core/ui/feedback/sync_banner.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline-sync plan, Phase E: go offline, make a change, see it waiting;
/// come back online, watch it sync and clear.
void main() {
  setUpAll(configurePluralResolvers);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late StreamController<ConnectivityStatus> status;
  late StreamController<int> pending;
  late ProviderContainer container;

  Future<void> pumpBanner(WidgetTester tester) async {
    status = StreamController<ConnectivityStatus>();
    pending = StreamController<int>();
    addTearDown(status.close);
    addTearDown(pending.close);
    container = ProviderContainer(
      overrides: [
        connectivityStatusProvider.overrideWith((ref) => status.stream),
        pendingWriteCountProvider.overrideWith((ref) => pending.stream),
      ],
    );
    addTearDown(container.dispose);
    container.read(localeControllerProvider.notifier).select(AppLocale.en);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: Column(children: [SyncBanner()])),
        ),
      ),
    );
  }

  Future<void> set(
    WidgetTester tester, {
    required ConnectivityStatus to,
    required int waiting,
  }) async {
    status.add(to);
    pending.add(waiting);
    await tester.pumpAndSettle();
  }

  testWidgets('offline, then a change, then back online and synced', (
    tester,
  ) async {
    await pumpBanner(tester);

    await set(tester, to: ConnectivityStatus.offline, waiting: 0);
    expect(find.text('Offline – changes will sync'), findsOneWidget);

    // A change made offline waits in the queue.
    await set(tester, to: ConnectivityStatus.offline, waiting: 1);
    expect(find.text('Offline – 1 change will sync'), findsOneWidget);

    // Back online: it's being sent, with the moving line under the text.
    status.add(ConnectivityStatus.online);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Syncing 1 change…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    // Sent: "Up to date" for a moment, then nothing.
    pending.add(0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Up to date'), findsOneWidget);

    await tester.pump(SyncBanner.upToDateHold);
    await tester.pumpAndSettle();
    expect(find.text('Up to date'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets(
    'changes turned down while syncing are explained in a toast',
    (tester) async {
      await pumpBanner(tester);
      await set(tester, to: ConnectivityStatus.online, waiting: 0);

      container.read(syncConflictsControllerProvider.notifier).add(1);
      await tester.pumpAndSettle();

      expect(
        find.text("1 change couldn't be applied – someone changed it first"),
        findsOneWidget,
      );
    },
  );

  testWidgets('a quiet launch, online with nothing queued, shows no bar', (
    tester,
  ) async {
    await pumpBanner(tester);
    await set(tester, to: ConnectivityStatus.online, waiting: 0);

    expect(find.text('Up to date'), findsNothing);
    expect(find.textContaining('Offline'), findsNothing);
  });
}
