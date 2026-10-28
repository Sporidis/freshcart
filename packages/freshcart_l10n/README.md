# freshcart_l10n

Shared [slang](https://pub.dev/packages/slang) translations for FreshCart, used by both
the Flutter app and the Jaspr site.

| Locale | Language |
| --- | --- |
| `nl` | Dutch (default and fallback) |
| `en` | English |
| `fr` | French |
| `ru` | Russian |
| `tl` | Tagalog |

Strings live in `lib/i18n/<locale>.i18n.json`. The package is plain Dart, so Jaspr can use
it too. `freshcart_flutter` adds the Flutter-specific bindings.

## Generating

```bash
dart run slang     # NOT build_runner
```

`slang_build_runner` ignores `slang.yaml` and falls back to slang's defaults: an English
base locale, Flutter integration (which breaks Jaspr) and a different output file. Use
the CLI.

## Plurals

Dutch and Tagalog need custom plural resolvers. Apps call `configurePluralResolvers()`
at startup. The tests in `test/` check them.

```bash
dart test
```
