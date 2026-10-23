import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/demo_hooks/scripted_field.dart';
import 'package:freshcart_flutter/core/demo_hooks/scripted_text_controller.dart';

/// Calls [onText] whenever the demo types new text into [field].
///
/// A field wraps itself in this only when it was given a [ScriptedField].
/// Without one, the field is exactly the widget it was before, and doesn't
/// even need a `ProviderScope` above it (decisions.md #109).
class ScriptedTextListener extends ConsumerWidget {
  const ScriptedTextListener({
    required this.field,
    required this.onText,
    required this.child,
    super.key,
  });

  final ScriptedField field;

  /// Puts the text in the field's controller and reports it as if typed.
  final ValueChanged<String> onText;

  final Widget child;

  /// Sets [controller]'s text to [text] with the cursor at the end, the way
  /// a person typing it would leave it.
  static void apply(TextEditingController controller, String text) =>
      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      scriptedTextControllerProvider.select((texts) => texts[field]),
      (_, text) {
        if (text != null) onText(text);
      },
    );
    return child;
  }
}
