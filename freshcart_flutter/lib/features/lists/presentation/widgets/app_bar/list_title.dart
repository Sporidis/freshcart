import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/features/lists/application/list_detail_screen/list_detail_screen_controller.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/editable_list_title.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/list_title_flight.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The list name; tap to rename (owner only).
class ListTitle extends ConsumerStatefulWidget {
  const ListTitle({
    required this.list,
    required this.t,
    required this.style,
    super.key,
  });

  final ShoppingList list;
  final Translations t;
  final TextStyle style;

  @override
  ConsumerState<ListTitle> createState() => _ListTitleState();
}

/// Plays the drawer's title flight, if this screen was opened by one: the
/// title stays hidden while a copy of the name flies into its place, then
/// shows. Once per screen.
class _ListTitleState extends ConsumerState<ListTitle> {
  bool _flying = false;
  bool _checked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checked) return;
    _checked = true;
    final flight = ListTitleFlight.of(context);
    if (flight == null || AppMotion.reduced(context)) return;
    _flying = true;
    // Where the title will be is only known after layout.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Checked before touching `context`: if the title is gone by now,
      // reading its render object would throw, and in an async callback
      // that's an unhandled error (the debugger stops on it).
      if (!mounted) return;
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.hasSize) {
        setState(() => _flying = false);
        return;
      }
      await flyListTitle(
        context,
        text: widget.list.name,
        style: widget.style,
        from: flight.from,
        to: box.localToGlobal(Offset.zero) & box.size,
      );
      if (mounted) setState(() => _flying = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.list;
    // Only the owner can rename.
    final isOwner = ref.watch(
      listDetailScreenControllerProvider(list.id).select((s) => s.isOwner),
    );
    return Opacity(
      opacity: _flying ? 0 : 1,
      child: EditableListTitle(
        name: list.name,
        enabled: isOwner,
        style: widget.style,
        onRename: (name) async {
          final failure = await ref
              .read(listDetailScreenControllerProvider(list.id).notifier)
              .rename(name);
          return failure?.toMessage(widget.t);
        },
      ),
    );
  }
}
