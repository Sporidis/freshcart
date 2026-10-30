import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/lists/application/invite_section/invite_section_controller.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/offline_list_repository.dart';

import '../../../fakes/fake_list_repository.dart';

void main() {
  final listId = ListId('00000000-0000-4000-8000-000000000001');

  late FakeListRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeListRepository();
    container = ProviderContainer(
      overrides: [listRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  InviteSectionControllerProvider provider() =>
      inviteSectionControllerProvider(listId);

  /// Keeps the auto-dispose controller alive, like a widget showing it.
  void listen() {
    final sub = container.listen(provider(), (_, _) {});
    addTearDown(sub.close);
  }

  test('asks for nothing until a member taps Invite', () {
    listen();

    expect(container.read(provider()), isNull);
    expect(repository.openInviteCalls, isEmpty);
  });

  test('open stores the invite the repository returns', () async {
    listen();
    final invite = buildInvite(code: 'K7M2Q');
    repository.openInviteResult = Ok(invite);

    await container.read(provider().notifier).open();

    expect(repository.openInviteCalls, [listId]);
    expect(
      container.read(provider()),
      AsyncData<Result<ListInvite>>(Ok(invite)),
    );
  });

  test('a failure is kept as data, for the section to show', () async {
    listen();
    repository.openInviteResult = const Err(Failure.network());

    await container.read(provider().notifier).open();

    expect(
      container.read(provider()),
      const AsyncData<Result<ListInvite>>(Err(Failure.network())),
    );
  });

  test('is loading while the repository answers', () async {
    final answer = Completer<Result<ListInvite>>();
    final slow = _SlowListRepository(answer.future);
    final slowContainer = ProviderContainer(
      overrides: [listRepositoryProvider.overrideWithValue(slow)],
    );
    addTearDown(slowContainer.dispose);
    final sub = slowContainer.listen(provider(), (_, _) {});
    addTearDown(sub.close);

    final opening = slowContainer.read(provider().notifier).open();
    expect(slowContainer.read(provider()), isA<AsyncLoading<Object?>>());

    answer.complete(Ok(buildInvite()));
    await opening;
    expect(slowContainer.read(provider())?.value, isA<Ok<ListInvite>>());
  });

  test('an answer after the section is gone is dropped, not thrown', () async {
    final answer = Completer<Result<ListInvite>>();
    final slow = _SlowListRepository(answer.future);
    final slowContainer = ProviderContainer(
      overrides: [listRepositoryProvider.overrideWithValue(slow)],
    );
    addTearDown(slowContainer.dispose);
    final sub = slowContainer.listen(provider(), (_, _) {});

    final opening = slowContainer.read(provider().notifier).open();
    // The member leaves the screen: nothing listens, so it's disposed.
    sub.close();
    await pumpEventQueue();

    answer.complete(Ok(buildInvite()));
    await expectLater(opening, completes);
  });
}

/// A [FakeListRepository] whose [openInvite] waits for [_answer].
class _SlowListRepository extends FakeListRepository {
  _SlowListRepository(this._answer);

  final Future<Result<ListInvite>> _answer;

  @override
  Future<Result<ListInvite>> openInvite(ListId id) => _answer;
}
