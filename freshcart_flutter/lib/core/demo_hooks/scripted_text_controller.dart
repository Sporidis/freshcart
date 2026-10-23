import 'package:freshcart_flutter/core/demo_hooks/scripted_field.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'scripted_text_controller.g.dart';

/// Text the web demo "types" into a [ScriptedField] (decisions.md #109).
///
/// Only the demo's director writes to this. In the real app it stays empty
/// forever, so the fields listening to it never change.
@Riverpod(keepAlive: true)
class ScriptedTextController extends _$ScriptedTextController {
  @override
  Map<ScriptedField, String> build() => const {};

  /// Sets [field]'s whole text to [text]. Typing is calling this once per
  /// character with a growing prefix.
  void type(ScriptedField field, String text) =>
      state = {...state, field: text};
}
