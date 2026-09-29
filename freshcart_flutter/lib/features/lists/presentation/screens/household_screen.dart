import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/error_screen.dart';
import 'package:freshcart_flutter/core/ui/failure_snack_bar.dart';
import 'package:freshcart_flutter/features/lists/application/household_screen_controller.dart';
import 'package:freshcart_flutter/features/lists/application/household_screen_state.dart';
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
    final s = ref.watch(householdScreenControllerProvider(listId));
    final vm = ref.read(householdScreenControllerProvider(listId).notifier);

    final failure = s.loadFailure;
    if (failure != null) {
      return ErrorScreen(
        failure: failure,
        t: t,
        // See list_detail_screen.dart's identical onExit for why this
        // refreshes first: /lists now redirects straight into whichever
        // list comes first in the cached collection, so a stale cache
        // still holding this now-gone list would just bounce back here.
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
  Widget build(BuildContext context) {
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
