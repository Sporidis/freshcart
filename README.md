# FreshCart

A collaborative shopping-list app, built as three surfaces from one Dart monorepo:
a Flutter app (iOS, Android, installable web PWA), a Jaspr marketing site, and a
Serverpod backend.

Deliberately over-engineered as a portfolio piece — every non-obvious choice has a
written justification in [`docs/decisions.md`](docs/decisions.md).

## Layout

| Path | What |
| --- | --- |
| `packages/freshcart_domain` | Pure Dart domain: entities, ports, use cases. Imports **nothing** but Dart. |
| `packages/freshcart_l10n` | Shared slang translations (`nl` default, `en`, `fr`). |
| `freshcart_server` | Serverpod server — endpoints, DB models, migrations. |
| `freshcart_client` | Serverpod-generated client. **Never hand-edit.** |
| `freshcart_flutter` | The Flutter app. Feature-first; `data/` maps client DTOs → domain. |
| `freshcart_web` | Jaspr marketing site (SSG). Resolves independently — see below. |

Read [`docs/architecture.md`](docs/architecture.md) before touching `packages/` or any
feature's `data/` layer, and [`docs/build-plan.md`](docs/build-plan.md) for build order.

## First-time setup

```bash
# 1. Secrets — passwords.yaml is gitignored
cp freshcart_server/config/passwords.example.yaml freshcart_server/config/passwords.yaml

# 2. Resolve. Two commands, on purpose (see below).
flutter pub get                        # the 5-member workspace
cd freshcart_web && dart pub get && cd ..

# 3. Generated code. build_runner output is NOT committed.
cd packages/freshcart_domain && dart run build_runner build --delete-conflicting-outputs && cd ../..

# 4. Database
cd freshcart_server && docker compose up --build --detach
dart bin/main.dart --apply-migrations
```

> **Why two `pub get`s?** `freshcart_web` is not a pub workspace member. `jaspr_builder`
> pins `analyzer ^12` while `freezed` 4.x and `riverpod_generator` 4.x need `analyzer >=13`,
> and a workspace has a single resolution. Full reasoning: `docs/decisions.md` #13.

## Checks

```bash
dart analyze                    # whole tree, strict lints, must be clean
dart format --set-exit-if-changed .
dart test                       # pure Dart tests
cd freshcart_flutter && flutter test
```

## CI

`.github/workflows/ci.yml` runs on every push and pull request:

| Job | What it proves |
| --- | --- |
| `analyze` | `dart analyze` and `dart format` clean across the tree, **plus** the two golden rules asserted directly: the domain imports nothing but pure Dart, and `freshcart_client` never appears above `data/`. |
| `test-dart` | Domain use-case and value-object tests; translation and pluralisation tests. |
| `test-server` | Endpoint tests against a real Postgres — they exist to verify migrations, foreign keys and transactions, none of which a fake would exercise. |
| `test-app` | Repository, mapper, controller and widget tests. |
| `build-web` | The marketing site builds, and its `<title>`, description, Open Graph, canonical and JSON-LD survived the build. |

Every job regenerates `build_runner` and slang output first, because that output
is deliberately not committed (`docs/decisions.md` #14).

## Conventions

Golden rules, layering and commit format live in [`CLAUDE.md`](CLAUDE.md). The short
version: **the dependency rule points inward**, Serverpod types stop at `data/`, and code
is organised feature-first.
