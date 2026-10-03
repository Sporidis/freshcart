import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/destructive_button.dart';
import 'package:freshcart_flutter/core/ui/error_screen.dart';
import 'package:freshcart_flutter/core/ui/failure_snack_bar.dart';
import 'package:freshcart_flutter/core/ui/initial_for.dart';
import 'package:freshcart_flutter/core/ui/user_avatar.dart';
import 'package:freshcart_flutter/features/lists/application/household_screen/household_screen_controller.dart';
import 'package:freshcart_flutter/features/lists/application/household_screen/household_screen_state.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/invite_card.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

/// Who's on a list, and how to invite someone.
///
/// Kept simple on purpose: only two roles (owner and member).
class HouseholdScreen extends ConsumerWidget {
  /// Creates the screen for [listId].
  const HouseholdScreen({required this.listId, super.key});

  /// The list whose household this is.
  final ListId listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final s = ref.watch(householdScreenControllerProvider(listId));
    final vm = ref.read(householdScreenControllerProvider(listId).notifier);

    final failure = s.loadFailure;
    if (failure != null) {
      return ErrorScreen(
        failure: failure,
        t: t,
        // Reload the lists first. Otherwise /lists could send the user
        // straight back to this list that's gone.
        onExit: () {
          unawaited(vm.refreshLists());
          context.go(Routes.lists);
        },
      );
    }

    final list = s.list;

    return Scaffold(
      appBar: AppBar(title: Text(t.household.title)),
      body: list == null
          ? const Center(child: CircularProgressIndicator())
          : _Household(list: list, s: s, vm: vm, t: t),
    );
  }
}

class _Household extends StatelessWidget {
  const _Household({
    required this.list,
    required this.s,
    required this.vm,
    required this.t,
  });

  final ShoppingList list;
  final HouseholdScreenState s;
  final HouseholdScreenController vm;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        for (final member in list.members)
          _MemberRow(
            member: member,
            t: t,
            isMe: s.isMe(member),
            canManage: s.canManage(member),
            vm: vm,
          ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          t.household.invite.toUpperCase(),
          style: AppTextStyles.eyebrow.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.gapSmall),
        InviteCard(joinCode: list.joinCode.value, t: t),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.t,
    required this.isMe,
    required this.canManage,
    required this.vm,
  });

  final ListMember member;
  final Translations t;
  final bool isMe;
  final bool canManage;
  final HouseholdScreenController vm;

  String get _tag => switch ((isMe, member.isOwner)) {
    (true, true) => t.household.youOwner,
    (true, false) => t.household.you,
    (false, true) => t.household.owner,
    (false, false) => '',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = initialFor(member.displayName);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.rowVertical),
      child: Row(
        children: [
          // Same avatar widget as everywhere else (decisions.md #65).
          UserAvatar(
            seed: member.userId.value,
            initial: initial,
            photoUrl: member.avatarPhotoUrl,
            color: member.avatarColor,
            radius: 20,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              member.displayName,
              style: theme.textTheme.titleMedium,
            ),
          ),
          if (_tag.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Text(_tag, style: theme.textTheme.bodySmall),
            ),
          if (canManage)
            PopupMenuButton<void>(
              itemBuilder: (context) => [
                PopupMenuItem<void>(
                  onTap: () => _confirmTransfer(context),
                  child: Text(t.household.makeOwner),
                ),
                PopupMenuItem<void>(
                  onTap: () => _confirmRemove(context),
                  child: Text(t.household.removeMember),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final ok = await _confirm(
      context,
      title: t.household.removeTitle(name: member.displayName),
      body: t.household.removeBody,
      confirmLabel: t.household.removeMember,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final failure = await vm.removeMember(member);
    if (failure == null || !context.mounted) return;
    showFailureSnackBar(context, failure: failure, t: t);
  }

  Future<void> _confirmTransfer(BuildContext context) async {
    // The dialog says clearly that you stop being the owner. The title
    // alone doesn't make that clear.
    final ok = await _confirm(
      context,
      title: t.household.transferTitle(name: member.displayName),
      body: t.household.transferBody,
      confirmLabel: t.household.transfer,
      destructive: false,
    );
    if (!ok || !context.mounted) return;
    final failure = await vm.transferOwnership(member);
    if (failure == null || !context.mounted) return;
    showFailureSnackBar(context, failure: failure, t: t);
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    required bool destructive,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t.common.cancel),
            ),
            if (destructive)
              DestructiveButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirmLabel),
              )
            else
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirmLabel),
              ),
          ],
        ),
      ) ??
      false;
}
