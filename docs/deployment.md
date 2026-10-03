# Deployment

The staging/production home for `freshcart_server` is one Oracle Cloud "Always Free" VM —
**$0/month, no time limit, no credit-card trap** (see the reasoning in `docs/decisions.md`
if it's added there; if not, the short version is: Render/Fly/Railway all either sleep after
idle, meter by the second, or killed their free tier outright in 2025–26, and none of them
offer a Postgres that doesn't expire on its own free tier — this VM sidesteps all three).

Read this before touching anything server-side in production, and definitely before asking
"how do I get my change live."

## Infrastructure at a glance

- **Provider:** Oracle Cloud Infrastructure, Always Free tier.
- **Shape:** `VM.Standard.A1.Flex` (Ampere ARM, **arm64** — not x86).
- **OS:** Ubuntu 20.04 LTS.
- **Region:** `eu-amsterdam-1` (Netherlands Northwest).
- **Public IP:** `134.98.159.244` — **Reserved**, not ephemeral, so it survives stop/reboot.
- **Domain:** `freshcart-nikos.duckdns.org` (DuckDNS, free) → the reserved IP above. Since
  the IP is reserved, this was set **once** and never needs a dynamic-update script — that's
  only needed for IPs that change.
- **SSH access:** `ssh -i ~/.ssh/oracle_freshcart ubuntu@134.98.159.244`.
- **Code on the VM:** `~/freshcart` — a `git clone` of the private repo, pulled via a
  **deploy key** (`~/.ssh/github_deploy` on the VM, registered read-only under the GitHub
  repo's Settings → Deploy keys — not your personal GitHub login).
- **Reverse proxy + TLS:** Caddy, config at `/etc/caddy/Caddyfile`, automatic Let's Encrypt
  cert for the domain above.
- **Server process:** `systemd` unit `freshcart-server.service`, runs
  `dart run bin/main.dart --mode production` as user `ubuntu`, `Restart=on-failure`.
- **Database:** Postgres, installed locally on the same VM (not a separate managed
  service). Role + database both named `freshcart`. Password lives only in
  `config/passwords.yaml` on the VM, which is gitignored and was never committed anywhere.
- **Secrets file:** `~/freshcart/freshcart_server/config/passwords.yaml` — created by hand
  on the VM from `config/passwords.example.yaml`, never via git.
- **Push notifications key:** `~/freshcart/freshcart_server/config/firebase-service-account.json`
  — a Firebase service-account key for the **`freshcart-portfolio`** project (Firebase console →
  Project settings → Service accounts → Generate new private key), copied up by hand and never
  committed (it's gitignored):
  ```bash
  scp -i ~/.ssh/oracle_freshcart <downloaded-key>.json \
    ubuntu@134.98.159.244:~/freshcart/freshcart_server/config/firebase-service-account.json
  ssh -i ~/.ssh/oracle_freshcart ubuntu@134.98.159.244 \
    'chmod 600 ~/freshcart/freshcart_server/config/firebase-service-account.json && sudo systemctl restart freshcart-server'
  ```
  Without it the server still runs, but only **logs** notifications (`[push] …` in the journal)
  instead of sending them (decisions.md #7). On macOS, copy the key out of Downloads first if
  your terminal isn't allowed to read that folder. Delete the local copy afterwards.

## Updating the deployed server

This is the thing you'll actually do repeatedly. Every step below runs **on the VM**
(`ssh -i ~/.ssh/oracle_freshcart ubuntu@134.98.159.244` first).

```bash
# 1. Pull the latest code
cd ~/freshcart
git pull

# 2. Re-apply the server-only workspace tweak (see "Why no Flutter on this VM" below —
#    this line is NOT tracked, git pull silently restores it every time)
sed -i '/- freshcart_flutter/d' pubspec.yaml

# 3. Re-resolve dependencies for the trimmed workspace
dart pub get

# 4. Regenerate freezed code for the domain package — *.freezed.dart is gitignored,
#    so a fresh pull never has it
cd packages/freshcart_domain
dart run build_runner build
cd ../../freshcart_server

# 5. Stop the running service before touching the database
sudo systemctl stop freshcart-server

# 6. Apply any new migrations. Safe to run even when there's nothing new — it's a no-op
#    then. --role maintenance runs this one job and exits, rather than starting a full
#    server you'd have to Ctrl+C.
dart run bin/main.dart --mode production --role maintenance --apply-migrations

# 7. Bring the real service back up
sudo systemctl start freshcart-server

# 8. Confirm it's actually healthy, not just "started"
sleep 5
sudo systemctl status freshcart-server --no-pager
journalctl -u freshcart-server --since "20 seconds ago" --no-pager
```

**Migrations do not lose data.** `serverpod create-migration` (run on your Mac when you
change a database model) writes a diff — `ALTER TABLE`/`CREATE TABLE`, not a drop-and-
recreate — as a new folder under `freshcart_server/migrations/`. Unlike `*.freezed.dart`,
**migration folders are committed to git**, so step 1 above already brings new ones along;
step 6 is what actually applies them, additively, against the real data already in the
`freshcart` database.

## Why no Flutter on this VM

`dart pub get` at the workspace root fails outright if `freshcart_flutter` stays a member,
because Flutter's official Linux SDK builds are **x86 only** — there is no first-party
Flutter SDK for Linux ARM64 to satisfy that member's `sdk: flutter` constraint. Installing
a community/unofficial ARM64 Flutter build on a production server, just to satisfy a
resolution technicality for an app that never runs here, wasn't worth it. Instead, the
server-only copy of the root `pubspec.yaml` has `freshcart_flutter` removed from its
`workspace:` list (see step 2 above) — the four members Serverpod actually needs
(`freshcart_domain`, `freshcart_l10n`, `freshcart_client`, `freshcart_server`) are all pure
Dart or server-side, and resolve fine without it.

This edit is **local to the VM only.** Never commit it — the real, tracked `pubspec.yaml`
needs `freshcart_flutter` as a member for your Mac and CI to build the app at all.

## The two firewalls

Every inbound port needs opening in **two** places, or it silently doesn't work:

1. **OCI Security List** (cloud-level) — Networking → Virtual Cloud Networks →
   `freshcart-vcn` → Security Lists → Default Security List → Ingress Rules.
2. **The VM's own `iptables`** (OS-level, ships pre-configured and restrictive on Oracle's
   Ubuntu image) — `sudo iptables -I INPUT 1 -p tcp --dport <port> -j ACCEPT`, then
   `sudo netfilter-persistent save` so it survives a reboot.

Only **80** and **443** are open on either firewall. Port **8080** (where Serverpod
actually listens) is deliberately not opened anywhere — Caddy reaches it over `localhost`
only, so the app server itself is never directly internet-facing.

## Architecture-specific gotchas (arm64, not the usual x86 tutorials)

- **Dart's apt repo line hardcodes `arch=amd64`.** On this VM it must say
  `arch=arm64` instead, or you silently get told to install the wrong architecture's
  binaries. (Every generic "install Dart on Ubuntu" tutorial gets this wrong for this box.)
- Postgres and Caddy are architecture-agnostic via their own apt repos — no special
  handling needed there.

## `config/production.yaml`, as actually set

Differences from the repo's checked-in template (`examplepod.com` placeholder domains):

- `apiServer` / `insightsServer` / `webServer` `publicHost` → all point at
  `freshcart-nikos.duckdns.org`.
- `database.host` → `localhost` (Postgres runs on this same VM, not a separate host).
- `database.name` / `database.user` → `freshcart` (a dedicated least-privilege role, not
  the `postgres` superuser).
- `database.requireSsl` → `false`. Deliberate: this setting encrypts the network hop _to_
  Postgres, and that hop never leaves the machine (`localhost`), so there's nothing on the
  wire for TLS to protect — enabling it would only add certificate setup for zero benefit.

## Troubleshooting seen so far

- **`28P01: password authentication failed`** — the value in `config/passwords.yaml`'s
  `production.database` doesn't match the `freshcart` Postgres role's actual password.
  Fastest fix: generate a new password and set both ends (`ALTER ROLE ... PASSWORD`, then
  edit the yaml) in the same VM session, rather than debugging which of two copies is stale.
- **`relation "serverpod_future_call" does not exist"` / "have you applied the database
  migration?"** — migrations were never actually applied to this database. Run step 6 of
  the update workflow above.
- **`Error when reading '....freezed.dart': No such file or directory`** right after a
  fresh clone — expected, see "Why no Flutter on this VM" above for the gitignore reasoning;
  fix is `dart run build_runner build` in `packages/freshcart_domain`.

## Known, accepted gaps

- **Ubuntu 20.04's Expanded Security Maintenance (ESM) is not enabled** — the VM is missing
  security patches that are gated behind a free Ubuntu Pro signup (separate from this
  account). `sudo apt update && sudo apt upgrade -y` still applies everything available
  without it. Enabling ESM properly is a reasonable follow-up, not yet done.
- **Client-side:** point a local run at this server with
  `flutter run --dart-define=SERVER_URL=https://freshcart-nikos.duckdns.org/`, or make it
  the permanent default by editing `freshcart_flutter/assets/config.json`'s `apiUrl` (not
  recommended while you're still actively testing against both local and live).
