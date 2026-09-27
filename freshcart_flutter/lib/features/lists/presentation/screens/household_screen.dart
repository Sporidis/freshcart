import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/error_screen.dart';
import 'package:freshcart_flutter/core/ui/failure_snack_bar.dart';
import 'package:freshcart_flutter/features/auth/application/providers/signed_in_user_provider.dart';
import 'package:freshcart_flutter/features/lists/application/controllers/lists_controller.dart';
import 'package:freshcart_flutter/features/lists/application/providers/list_membership_provider.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/invite_card.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

/// Who is on a list, and how to add someone.
///
/// Deliberately shallow, per the design: two roles and no admin console. A
/// shopping list does not need an org chart.
class HouseholdScreen extends ConsumerWidget {
  /// Creates the screen for [listId].
  const HouseholdScreen({required this.listId, super.key});

  /// The list whose household this is.
  final ListId listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final list = ref.watch(listByIdProvider(listId));

    final failure = list.loadFailure;
    if (failure != null) {
      return ErrorScreen(
        failure: failure,
        t: t,
        // See list_detail_screen.dart's identical onExit for why this
        // refreshes first: /lists now redirects straight into whichever
        // list comes first in the cached collection, so a stale cache
        // still holding this now-gone list would just bounce back here.
        onExit: () {
          unawaited(ref.read(listsControllerProvider.notifier).refresh());
          context.go(Routes.lists);
        },
      );
    }

    final loaded = list.dataOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(t.household.title)),
      body: loaded == null
          ? const Center(child: CircularProgressIndicator())
          : _Household(list: loaded, t: t),
    );
  }
}

class _Household extends ConsumerWidget {
  const _Household({required this.list, required this.t});

  final ShoppingList list;
  final Translations t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final me = ref.watch(signedInUserIdProvider);
    final iAmOwner = ref.watch(isListOwnerProvider(list));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        for (final member in list.members)
          _MemberRow(
            member: member,
            list: list,
            t: t,
            isMe: member.userId == me,
            // Only the owner is offered the destructive verbs, and never
            // against themselves — the server enforces both, this only keeps
            // the UI from offering what it knows will be refused.
            canManage: iAmOwner && member.userId != me,
          ),
        const SizedBox(height: 24),
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

class _MemberRow extends ConsumerWidget {
  const _MemberRow({
    required this.member,
    required this.list,
    required this.t,
    required this.isMe,
    required this.canManage,
  });

  final ListMember member;
  final ShoppingList list;
  final Translations t;
  final bool isMe;
  final bool canManage;

  /// A stable colour per member, so the same person is the same colour
  /// everywhere without storing one.
  Color get _avatarColor {
    const palette = AppColors.presetShopColors;
    return palette[member.userId.value.hashCode.abs() % palette.length];
  }

  String get _tag => switch ((isMe, member.isOwner)) {
    (true, true) => t.household.youOwner,
    (true, false) => t.household.you,
    (false, true) => t.household.owner,
    (false, false) => '',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final initial = member.displayName.trim().isEmpty
        ? '?'
        : member.displayName.trim()[0].toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.rowVertical),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isMe ? AppColors.ink : _avatarColor,
            child: Text(
              initial,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
              ),
            ),
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
                  onTap: () => _confirmTransfer(context, ref),
                  child: Text(t.household.makeOwner),
                ),
                PopupMenuItem<void>(
                  onTap: () => _confirmRemove(context, ref),
                  child: Text(t.household.removeMember),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final ok = await _confirm(
      context,
      title: t.household.removeTitle(name: member.displayName),
      body: t.household.removeBody,
      confirmLabel: t.household.removeMember,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final result = await ref
        .read(listsControllerProvider.notifier)
        .removeMember(list.id, member.userId);
    if (!context.mounted) return;
    if (result case Err<void>(:final failure)) {
      showFailureSnackBar(context, failure: failure, t: t);
    }
  }

  Future<void> _confirmTransfer(BuildContext context, WidgetRef ref) async {
    // Spelled out rather than confirmed with a bare "OK": handing over
    // ownership also takes it away from you, which the title alone does not
    // say.
    final ok = await _confirm(
      context,
      title: t.household.transferTitle(name: member.displayName),
      body: t.household.transferBody,
      confirmLabel: t.household.transfer,
      destructive: false,
    );
    if (!ok || !context.mounted) return;
    final result = await ref
        .read(listsControllerProvider.notifier)
        .transferOwnership(list.id, member.userId);
    if (!context.mounted) return;
    if (result case Err<ShoppingList>(:final failure)) {
      showFailureSnackBar(context, failure: failure, t: t);
    }
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
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: AppColors.destructive,
                      foregroundColor: Colors.white,
                    )
                  : null,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ) ??
      false;
}
