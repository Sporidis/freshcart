import 'dart:ui' show Color;

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding/onboarding_shop_draft.dart';

/// The shops offered on the "Where do you shop?" step.
///
/// The first two are selected by default. The user can also add their own.
final List<OnboardingShopDraft> presetShops = [
  _preset('Albert Heijn', AppColors.swatchTeal),
  _preset('Colruyt', AppColors.swatchOrange),
  _preset('Delhaize', AppColors.swatchRed),
];

OnboardingShopDraft _preset(String name, Color color) =>
    OnboardingShopDraft(name: name, color: HexColor.fromArgb(color.toARGB32()));
