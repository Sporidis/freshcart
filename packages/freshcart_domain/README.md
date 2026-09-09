# freshcart_domain

The pure Dart domain layer for FreshCart: entities, value objects, the
`Result`/`Failure` union, repository ports and use cases.

**This package must never import Flutter, Serverpod, Firebase or
`freshcart_client`.** That is golden rule 1 in `../../CLAUDE.md`; the purity
check lives in `../../docs/build-plan.md` (Phase 1) and in CI.

See `../../docs/architecture.md` for the layering it anchors.
