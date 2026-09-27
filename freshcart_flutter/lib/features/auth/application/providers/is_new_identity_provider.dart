import 'package:freshcart_flutter/features/auth/data/sources/auth_bootstrap_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'is_new_identity_provider.g.dart';

/// Resolves once sign-in has finished: true for a brand-new identity (send
/// them through onboarding), false for a restored one.
///
/// Splash only needs this one answer, not the bootstrap's whole result --
/// and not to know that the bootstrap lives in the data layer.
@riverpod
Future<bool> isNewIdentity(Ref ref) async =>
    (await ref.watch(authBootstrapProvider.future)).isNewIdentity;
