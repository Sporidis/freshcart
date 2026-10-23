import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/color_swatch_picker.dart';
import 'package:freshcart_flutter/core/ui/sheet/app_sheet.dart';
import 'package:freshcart_flutter/features/shops/application/shop_color_preview/shop_color_preview_controller.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Edits a shop's name and colour, or creates a new shop if [shop] is null.
///
/// When editing, tapping a colour changes the shop's colour behind the
/// sheet right away, so the user sees how it really looks. When creating,
/// there's nothing behind the sheet to recolour yet, so no preview.
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

  /// The other shops on this list, to warn about similar colours.
  final List<Shop> siblings;

  /// Saves the shop. If it returns an error message, the sheet stays open.
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

  /// The first preset colour no other shop is using. If all are used, just
  /// the first one. The user can change it anyway.
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
      ref.read(shopColorPreviewControllerProvider.notifier).preview(id, color);
    }
  }

  /// Another shop with a similar colour, or null.
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
    if (!_isCreate) {
      ref.read(shopColorPreviewControllerProvider.notifier).clear();
    }
    if (mounted) Navigator.of(context).pop();
  }

  /// Preset colours that another shop already uses (or is close to), with
  /// that shop's name. They get a mark in the picker, so the user knows
  /// before picking.
  Map<int, String> _takenSwatches(Translations t) => {
    for (final preset in AppColors.presetShopColors)
      for (final other in widget.siblings)
        if (other.id != widget.shop?.id &&
            HexColor.fromArgb(preset.toARGB32()).isCloseTo(other.color))
          preset.toARGB32(): t.shops.usedBy(name: other.name),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider);
    final clash = _clashesWith;

    // AppSheetScaffold scrolls, because with the keyboard open it doesn't
    // all fit on a small phone.
    return AppSheetScaffold(
      title: _isCreate ? t.shops.add : t.shops.edit,
      children: [
        Text(t.shops.nameLabel, style: theme.textTheme.bodySmall),
        const SizedBox(height: AppSpacing.gapSmall),
        TextField(
          controller: _name,
          enabled: !_saving,
          // New shop: open the keyboard for the name straight away.
          // Existing shop: don't, so the keyboard doesn't hide the colours.
          autofocus: _isCreate,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _saving ? null : _save(),
          decoration: InputDecoration(errorText: _error),
        ),
        const SizedBox(height: AppSpacing.screen),
        Text(t.shops.colorLabel, style: theme.textTheme.bodySmall),
        const SizedBox(height: AppSpacing.gapSmall),
        ColorSwatchPicker(
          colors: AppColors.presetShopColors,
          selected: Color(_color.argb),
          semanticLabel: t.shops.colorLabel,
          marked: _takenSwatches(t),
          onSelected: (color) => _pick(HexColor.fromArgb(color.toARGB32())),
        ),
        // Only a warning: similar colours are allowed, just not a great
        // idea.
        AnimatedSize(
          duration: AppMotion.durationFor(context, AppMotion.quick),
          alignment: Alignment.topLeft,
          child: clash == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.gapSmall),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: AppSizes.quantityIcon,
                        color: theme.colorScheme.onSurface,
                      ),
                      const SizedBox(width: AppSpacing.gapSmall),
                      Expanded(
                        child: Text(
                          t.shops.closeTo(name: clash.name),
                          style: AppTextStyles.captionStrong.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.screen),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: Text(_isCreate ? t.shops.add : t.shops.saveChanges),
        ),
      ],
    );
  }
}
