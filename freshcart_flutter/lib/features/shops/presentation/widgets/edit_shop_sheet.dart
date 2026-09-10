import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/features/shops/application/shop_color_preview.dart';

/// Renames and recolours a shop, or creates a new one when [shop] is null.
///
/// Every swatch tap previews immediately behind the sheet rather than waiting
/// for Save, because the whole question a shop colour answers is "will I spot
/// this in an aisle?" — and that cannot be judged from a swatch in a modal.
/// There is nothing to retint behind the sheet for a shop that does not exist
/// yet, so the live preview only fires in edit mode.
class EditShopSheet extends ConsumerStatefulWidget {
  /// Creates the sheet. Pass `shop: null` to create a new shop instead of
  /// editing an existing one.
  const EditShopSheet({
    required this.shop,
    required this.siblings,
    required this.onSave,
    super.key,
  });

  /// The shop being edited, or null when creating a new one.
  final Shop? shop;

  /// The other shops on this list, for the colour-clash warning.
  final List<Shop> siblings;

  /// Commits the add/edit. An error message keeps the sheet open.
  final Future<String?> Function({
    required String name,
    required HexColor color,
  })
  onSave;

  @override
  ConsumerState<EditShopSheet> createState() => _EditShopSheetState();
}

class _EditShopSheetState extends ConsumerState<EditShopSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.shop?.name ?? '',
  );
  late HexColor _color = widget.shop?.color ?? _firstUnusedPreset();
  String? _error;
  bool _saving = false;

  bool get _isCreate => widget.shop == null;

  /// The first preset that does not clash with a sibling's colour, or the
  /// first preset outright if every one of them does — a starting point, not
  /// a guarantee, since the user can always repick.
  HexColor _firstUnusedPreset() {
    for (final preset in AppColors.presetShopColors) {
      final candidate = HexColor.fromArgb(preset.toARGB32());
      if (widget.siblings.every((s) => !candidate.isCloseTo(s.color))) {
        return candidate;
      }
    }
    return HexColor.fromArgb(AppColors.presetShopColors.first.toARGB32());
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _pick(HexColor color) {
    setState(() => _color = color);
    final id = widget.shop?.id;
    if (id != null) {
      ref.read(shopColorPreviewProvider.notifier).preview(id, color);
    }
  }

  /// The shop this colour could be confused with, if any.
  Shop? get _clashesWith {
    for (final other in widget.siblings) {
      if (other.id == widget.shop?.id) continue;
      if (_color.isCloseTo(other.color)) return other;
    }
    return null;
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSave(name: _name.text, color: _color);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }
    if (!_isCreate) ref.read(shopColorPreviewProvider.notifier).clear();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider);
    final clash = _clashesWith;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sheetH,
        8,
        AppSpacing.sheetH,
        MediaQuery.viewInsetsOf(context).bottom + 30,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isCreate ? t.shops.add : t.shops.edit,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.gap),
          Text(t.shops.nameLabel, style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          TextField(
            controller: _name,
            enabled: !_saving,
            decoration: InputDecoration(errorText: _error),
          ),
          const SizedBox(height: 16),
          Text(t.shops.colorLabel, style: theme.textTheme.bodySmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final swatch in AppColors.presetShopColors)
                _Swatch(
                  // Keyed by its colour so a test can tap a specific swatch
                  // rather than guessing at an index.
                  key: ValueKey('swatch-${swatch.toARGB32()}'),
                  color: swatch,
                  selected: _color.argb == swatch.toARGB32(),
                  onTap: () => _pick(HexColor.fromArgb(swatch.toARGB32())),
                ),
            ],
          ),
          // A warning, never a block: two similar colours are a bad idea, not
          // an invalid one, and the household may have its own reasons.
          AnimatedSize(
            duration: AppMotion.durationFor(context, AppMotion.quick),
            alignment: Alignment.topLeft,
            child: clash == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      t.shops.closeTo(name: clash.name),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_isCreate ? t.shops.add : t.shops.saveChanges),
            ),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: AppMotion.durationFor(context, AppMotion.micro),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: selected ? Border.all(color: ink, width: 2.5) : null,
          ),
          child: selected
              ? const Center(
                  child: SizedBox(
                    width: 10,
                    height: 10,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

@Preview(group: 'Shops', name: 'Edit shop sheet', size: Size(393, 560))
Widget editShopSheetPreview() {
  Shop shop(String id, String name, int argb) => Shop(
    id: ShopId(id),
    listId: ListId('list-1'),
    name: name,
    color: HexColor.fromArgb(argb),
  );

  return previewApp(
    Scaffold(
      body: EditShopSheet(
        shop: shop('s1', 'Colruyt', 0xFFE8791A),
        siblings: [
          shop('s1', 'Colruyt', 0xFFE8791A),
          shop('s2', 'Albert Heijn', 0xFF2456A6),
        ],
        onSave: ({required name, required color}) async => null,
      ),
    ),
  );
}

/// The clash warning, which only shows for a confusable pair.
@Preview(group: 'Shops', name: 'Edit shop · colour clash', size: Size(393, 560))
Widget editShopSheetClashPreview() {
  Shop shop(String id, String name, int argb) => Shop(
    id: ShopId(id),
    listId: ListId('list-1'),
    name: name,
    color: HexColor.fromArgb(argb),
  );

  return previewApp(
    Scaffold(
      body: EditShopSheet(
        // Two blues: easy to tell apart here, not in an aisle.
        shop: shop('s2', 'Delhaize', 0xFF2A5AAA),
        siblings: [
          shop('s1', 'Albert Heijn', 0xFF2456A6),
          shop('s2', 'Delhaize', 0xFF2A5AAA),
        ],
        onSave: ({required name, required color}) async => null,
      ),
    ),
  );
}

/// Create mode: no shop, an empty name, and a starting colour chosen to
/// avoid the siblings already on the list.
@Preview(group: 'Shops', name: 'Add shop', size: Size(393, 560))
Widget editShopSheetCreatePreview() {
  Shop shop(String id, String name, int argb) => Shop(
    id: ShopId(id),
    listId: ListId('list-1'),
    name: name,
    color: HexColor.fromArgb(argb),
  );

  return previewApp(
    Scaffold(
      body: EditShopSheet(
        shop: null,
        siblings: [
          shop('s1', 'Colruyt', 0xFFE8791A),
          shop('s2', 'Albert Heijn', 0xFF2456A6),
        ],
        onSave: ({required name, required color}) async => null,
      ),
    ),
  );
}
