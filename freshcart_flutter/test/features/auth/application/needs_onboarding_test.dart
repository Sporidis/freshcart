import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/auth/application/auth/auth_providers.dart';

import '../../../fakes/fake_auth_repository.dart';

void main() {
  Future<bool> needsOnboardingAfter(Result<SignIn> signIn) {
    final container = ProviderContainer(
      overrides: [signInResultProvider.overrideWith((ref) async => signIn)],
    );
    addTearDown(container.dispose);
    return container.read(needsOnboardingProvider.future);
  }

  test('a user without a profile needs onboarding', () async {
    expect(await needsOnboardingAfter(Ok(aSignIn(hasProfile: false))), isTrue);
  });

  test('a user with a profile goes to their lists', () async {
    expect(await needsOnboardingAfter(Ok(aSignIn())), isFalse);
  });

  // Mostly a returning user opening the app offline: their saved session is
  // fine, only `me()` failed. Their lists (cached, or a retry) beat Welcome.
  test('a failed sign-in goes to the lists, not onboarding', () async {
    expect(
      await needsOnboardingAfter(const Err(Failure.network())),
      isFalse,
    );
  });
}
