import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/error_tier.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_radii.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';
import 'package:freshcart_flutter/core/ui/feedback/shake_on_error.dart';
import 'package:freshcart_flutter/core/ui/sheet/app_sheet.dart';
import 'package:freshcart_flutter/core/ui/tap_target.dart';

/// The "New list" sheet (design v3): a name field, a few starting names to
/// tap, and Create list.
///
/// [onSubmit] runs the create. If it fails, the error shows under the field
/// (and the field shakes when it's something the user can fix), and the
/// sheet stays open with the name, as the old dialog did. On success the
/// sheet closes with `true`.
class NewListSheet extends ConsumerStatefulWidget {
  const NewListSheet({required this.onSubmit, super.key});

  final Future<Result<void>> Function(String name) onSubmit;

  @override
  ConsumerState<NewListSheet> createState() => _NewListSheetState();
}

class _NewListSheetState extends ConsumerState<NewListSheet> {
  final TextEditingController _name = TextEditingController();
  String? _errorText;
  bool _busy = false;
  bool _shake = true;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || _name.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _errorText = null;
    });
    final result = await widget.onSubmit(_name.text);
    if (!mounted) return;
    switch (result) {
      case Ok<void>():
        Navigator.of(context).pop(true);
      case Err<void>(:final failure):
        setState(() {
          _busy = false;
          _errorText = failure.toMessage(ref.read(translationsProvider));
          _shake = shakesOn(failure);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final scheme = Theme.of(context).colorScheme;
    final canSubmit = _name.text.trim().isNotEmpty && !_busy;

    return AppSheetScaffold(
      title: t.lists.create,
      children: [
        Text(
          t.lists.nameLabel,
          style: AppTextStyles.secondaryStrong.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ShakeOnError(
          errorText: _errorText,
          shake: _shake,
          child: TextField(
            controller: _name,
            autofocus: true,
            enabled: !_busy,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: t.lists.nameExample,
              errorText: _errorText,
            ),
            // The error goes as soon as they type again.
            onChanged: (_) {
              if (_errorText != null) setState(() => _errorText = null);
            },
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final suggestion in t.lists.nameSuggestions)
              _NameChip(
                label: suggestion,
                onTap: () => _name.text = suggestion,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          onPressed: canSubmit ? _submit : null,
          child: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(t.lists.createButton),
        ),
      ],
    );
  }
}

/// A starting name: a 36px outlined pill that fills the field.
class _NameChip extends StatelessWidget {
  const _NameChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      child: TapTarget(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              fontSize: 14,
              color: scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
