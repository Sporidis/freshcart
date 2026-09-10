import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';

class AddShopSheet extends StatefulWidget {
  const AddShopSheet({required this.onAdd, super.key});

  final void Function(String name, HexColor color) onAdd;

  @override
  State<AddShopSheet> createState() => _AddShopSheetState();
}

class _AddShopSheetState extends State<AddShopSheet> {
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
            Text('Add a shop', style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.gapSmall),
            Text(
              'Give it a name and choose a colour for its tab.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.gap),
            Text('Shop name', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.gapSmall),
            TextField(
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: canSubmit ? (_) => _submit() : null,
              decoration: const InputDecoration(hintText: 'e.g. Local Market'),
            ),
            const SizedBox(height: AppSpacing.gap),
            Text('Tab colour', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.gapSmall),
            Wrap(
              spacing: AppSpacing.gap,
              runSpacing: AppSpacing.gapSmall,
              children: AppColors.presetShopColors
                  .map(
                    (color) => ColorChoice(
                      color: color,
                      selected: color == _selectedColor,
                      onTap: () => setState(() => _selectedColor = color),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.sheetH),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canSubmit ? _submit : null,
                icon: const Icon(Icons.add),
                label: const Text('Add shop'),
              ),
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
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Tab colour',
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
