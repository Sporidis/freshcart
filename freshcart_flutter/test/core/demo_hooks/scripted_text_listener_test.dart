import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_flutter/core/demo_hooks/scripted_field.dart';
import 'package:freshcart_flutter/core/demo_hooks/scripted_text_controller.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/join_code_input.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/name_with_avatar_field.dart';

/// The web demo's text hook (decisions.md #109): a field given a
/// [ScriptedField] shows what the demo types, as if a person typed it; a
/// field without one is untouched.
void main() {
  Widget host(Widget field) => MaterialApp(home: Scaffold(body: field));

  testWidgets('typed text appears in the field and reaches onChanged', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final changes = <String>[];

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: host(
          NameWithAvatarField(
            initialValue: '',
            hintText: 'Name',
            onChanged: changes.add,
            autofocus: false,
            scriptedField: ScriptedField.onboardingName,
          ),
        ),
      ),
    );

    final scripted = container.read(scriptedTextControllerProvider.notifier);
    for (final prefix in ['A', 'An', 'Anna']) {
      scripted.type(ScriptedField.onboardingName, prefix);
      await tester.pump();
    }

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'Anna');
    expect(field.controller!.selection.baseOffset, 4); // cursor at the end
    expect(changes, ['A', 'An', 'Anna']);
  });

  testWidgets('the code boxes show scripted text too', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: host(
          JoinCodeInput(
            value: '',
            onChanged: (_) {},
            scriptedField: ScriptedField.joinCode,
          ),
        ),
      ),
    );
    container
        .read(scriptedTextControllerProvider.notifier)
        .type(ScriptedField.joinCode, 'AB');
    await tester.pump();

    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('a field without a ScriptedField needs no ProviderScope', (
    tester,
  ) async {
    // No ProviderScope at all: if the field listened anyway, this throws.
    await tester.pumpWidget(
      host(
        NameWithAvatarField(
          initialValue: 'Alex',
          hintText: 'Name',
          onChanged: (_) {},
          autofocus: false,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Alex'), findsOneWidget);
  });
}
