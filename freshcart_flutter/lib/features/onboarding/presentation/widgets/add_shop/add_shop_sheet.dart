import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/color_swatch_picker.dart';
import 'package:freshcart_flutter/core/ui/sheet/app_sheet.dart';

class AddShopSheet extends ConsumerStatefulWidget {
  const AddShopSheet({required this.onAdd, super.key});

  final void Function(String name, HexColor color) onAdd;

  @override
  ConsumerState<AddShopSheet> createState() => _AddShopSheetState();
}

class _AddShopSheetState extends ConsumerState<AddShopSheet> {
  late final TextEditingController _nameController;
  Color _selectedColor = AppColors.swatchGreen;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController()..addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_onNameChanged)
      ..dispose();
    super.dispose();
  }

  void _onNameChanged() => setState(() {});

  void _submit() {
    widget.onAdd(
      _nameController.text,
      HexColor.fromArgb(_selectedColor.toARGB32()),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);
    final canSubmit = _nameController.text.trim().isNotEmpty;

    return AppSheetScaffold(
      title: t.shops.add,
      subtitle: t.onboarding.shopSheetBody,
      children: [
        Text(t.shops.nameLabel, style: theme.textTheme.labelMedium),
        const SizedBox(height: AppSpacing.gapSmall),
        TextField(
          controller: _nameController,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: canSubmit ? (_) => _submit() : null,
          decoration: InputDecoration(
            hintText: t.onboarding.shopPlaceholder,
          ),
        ),
        const SizedBox(height: AppSpacing.gap),
        Text(t.shops.colorLabel, style: theme.textTheme.labelMedium),
        const SizedBox(height: AppSpacing.gapSmall),
        ColorSwatchPicker(
          colors: AppColors.presetShopColors,
          selected: _selectedColor,
          semanticLabel: t.shops.colorLabel,
          onSelected: (color) => setState(() => _selectedColor = color),
        ),
        const SizedBox(height: AppSpacing.sheetH),
        // Our standard full-width main button.
        ElevatedButton.icon(
          onPressed: canSubmit ? _submit : null,
          icon: const Icon(Icons.add),
          label: Text(t.shops.add),
        ),
      ],
    );
  }
}
