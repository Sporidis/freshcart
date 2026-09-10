import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_flutter/core/ui/empty_state.dart';
import 'package:freshcart_flutter/core/ui/error_screen.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/done_divider.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/editable_list_title.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/onboarding_screen.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/welcome_screen.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/add_shop/add_shop_sheet.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/add_shop/shop_option.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/add_shop_step.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/create_list_step.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/display_name_step.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_continue_button.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_step_indicator.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/delete_shop_sheet.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/edit_shop_sheet.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Renders every `@Preview` in the app.
///
/// A preview that throws is worse than no preview: it is discovered by
/// whoever opens the previewer, mid-task, and looks like their change broke
/// it. This suite is what keeps them honest — it catches the usual causes
/// (a missing Material or Directionality ancestor, a provider that reaches
/// for the network, a required argument that moved) in CI instead.
///
/// Adding a preview means adding it here. That is deliberate: the previewer
/// discovers them by annotation, so nothing else would notice a broken one.
void main() {
  setUpAll(configurePluralResolvers);

  final previews = <String, Widget Function()>{
    'welcome': welcomeScreenPreview,
    'onboarding shell': onboardingScreenPreview,
    'step 1 · name': displayNameStepPreview,
    'step 2 · list': createListStepPreview,
    'step 3 · shops': addShopStepPreview,
    'step indicator': onboardingStepIndicatorPreview,
    'continue button': onboardingContinueButtonPreview,
    'shop option': shopOptionPreview,
    'add-a-shop sheet': addShopSheetPreview,
    'item row': itemTilePreview,
    'empty · new list': emptyNewListPreview,
    'empty · shop tab': emptyShopTabPreview,
    'empty · no lists': emptyNoListsPreview,
    'error · deleted': errorScreenDeletedPreview,
    'error · no access': errorScreenNoAccessPreview,
    'error · unexpected': errorScreenUnexpectedPreview,
    'done divider': doneDividerPreview,
    'editable title': editableListTitlePreview,
    'edit shop sheet': editShopSheetPreview,
    'edit shop · clash': editShopSheetClashPreview,
    'delete shop · holds': deleteShopSheetPreview,
    'delete shop · empty': deleteShopSheetEmptyPreview,
  };

  for (final MapEntry(key: name, value: build) in previews.entries) {
    testWidgets('$name preview renders', (tester) async {
      await tester.pumpWidget(build());

      // A single pump, not pumpAndSettle: several of these run intro or
      // looping animations that would never settle.
      await tester.pump(const Duration(milliseconds: 16));

      expect(tester.takeException(), isNull);
    });
  }
}
