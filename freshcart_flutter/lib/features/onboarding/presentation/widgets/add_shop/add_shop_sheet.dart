import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';

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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final canSubmit = _nameController.text.trim().isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.gapSmall,
          AppSpacing.screen,
          bottomInset + AppSpacing.screen,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.shops.add, style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.gapSmall),
            Text(
              t.onboarding.shopSheetBody,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.gap),
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
            Wrap(
              spacing: AppSpacing.gap,
              runSpacing: AppSpacing.gapSmall,
              children: [
                for (final (index, color) in AppColors.presetShopColors.indexed)
                  ColorChoice(
                    color: color,
                    // Numbered, so a screen reader can tell eight otherwise
                    // identically-announced swatches apart.
                    label: '${t.shops.colorLabel} ${index + 1}',
                    selected: color == _selectedColor,
                    onTap: () => setState(() => _selectedColor = color),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sheetH),
            // The app's themed primary (ink, full width), the same button
            // every other Getting-in screen uses for its main action.
            ElevatedButton.icon(
              onPressed: canSubmit ? _submit : null,
              icon: const Icon(Icons.add),
              label: Text(t.shops.add),
            ),
          ],
        ),
      ),
    );
  }
}

class ColorChoice extends StatelessWidget {
  const ColorChoice({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Color color;

  /// What a screen reader announces for this swatch.
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Center(
            child: AnimatedContainer(
              duration: AppMotion.quick,
              curve: AppMotion.pop,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: color,
                child: AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: AppMotion.quick,
                  curve: AppMotion.pop,
                  child: const Icon(Icons.check, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@Preview(group: 'Onboarding', name: 'Add-a-shop sheet', size: Size(393, 520))
Widget addShopSheetPreview() =>
    previewApp(Scaffold(body: AddShopSheet(onAdd: (_, _) {})));
