import 'package:jaspr/dom.dart';

// As your CSS styles are defined using just Dart, you can simply
// use global variables or methods for common things like colors.
const primaryColor = Color('#01589B');

// Defines the global CSS styles for this project.
//
// By using the @css annotation, these will be rendered automatically to CSS and included in your page.
@css
List<StyleRule> get styles => [
  // Each style rule takes a valid css selector and a set of styles.
  // Styles are defined using type-safe css bindings and can be freely chained and nested.
  css('html, body').styles(
    width: 100.percent,
    minHeight: 100.vh,
    padding: .zero,
    margin: .zero,
    // The visitor's own system font: nothing is fetched from a font CDN, so
    // opening the site doesn't send their IP address to Google.
    fontFamily: const .list([FontFamilies.systemUi, FontFamilies.sansSerif]),
  ),
  css('h1').styles(
    margin: .unset,
    fontSize: 4.rem,
  ),
];
