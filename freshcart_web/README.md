# freshcart_web

FreshCart's marketing site, built with [Jaspr](https://docs.jaspr.site) as a statically
generated site. It is the SEO surface: real HTML with a title, meta description, Open
Graph tags, a canonical URL and JSON-LD. CI checks that all of them survive the build.
Everything behind sign-in is the Flutter app.

It uses the same translations as the app (`packages/freshcart_l10n`).

## Not a workspace member

This package resolves on its own, with its own lockfile. `jaspr_builder` pins
`analyzer ^12`, while `freezed` 4 and `riverpod_generator` 4 need `analyzer >=13`, and a
pub workspace has only one resolution.

```bash
dart pub get                       # here, separately from the root `flutter pub get`
dart pub global activate jaspr_cli # once
```

## Commands

```bash
jaspr serve    # dev server at http://localhost:8080
jaspr build    # static output in build/jaspr/
```

## Layout

| Path | What |
| --- | --- |
| `lib/pages/` | Pages (`home.dart`) |
| `lib/components/` | Header, footer, feature cards |
| `lib/constants/` | Site metadata and theme |
