# freshcart_server

The [Serverpod](https://docs.serverpod.dev) backend for FreshCart: endpoints, live list
streams, push notifications and the Postgres schema. For the big picture, see the
[root README](../README.md).

## Structure

```text
lib/src/
├── auth/  lists/  items/  shops/  profile/  notifications/
│   ├── <feature>_endpoint.dart   ← thin: authenticate, call a service, return
│   ├── business/                 ← services, ListAccess guards, ListBroadcast
│   └── models/                   ← *.spy.yaml protocol and table definitions
├── common/                        ← shared server helpers
└── generated/                     ← Serverpod output (committed, do not edit)
```

- **Rules run twice, on purpose.** The server depends on `freshcart_domain`, so it enforces
  the same validation the app shows, and the server stays the source of truth.
- **Membership is checked here only.** `ListAccess` decides who may read or change a list.
- **Live updates are deltas.** `ListBroadcast` streams changes to every member, and the
  client merges them into its list.
- **Push is batched.** Additions are buffered and summarised into one notification per list.

## Running locally

```bash
cp config/passwords.example.yaml config/passwords.yaml   # once
docker compose up --build --detach                       # Postgres + Redis (dev and test)
dart bin/main.dart --apply-migrations
```

Stop with `Ctrl-C`, then `docker compose stop`.

## After changing models or endpoints

```bash
serverpod generate            # regenerates lib/src/generated and ../freshcart_client
serverpod create-migration    # only if a table definition changed
```

## Tests

```bash
dart test
```

Endpoint tests run against the real test Postgres from `docker compose`, because the
point is to exercise migrations, foreign keys and transactions.
