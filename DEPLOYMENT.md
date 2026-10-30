# Deployment

How the live FreshCart server runs, how to update it, and how to ship an Android build.
FreshCart runs for a household, not for the public; the setup is deliberately small and
free. No secrets are in this file: they live only in `freshcart_server/config/passwords.yaml`
on the VM (never in git) and in the Android key files on the developer's Mac.

## The server at a glance

- **Provider:** Oracle Cloud Infrastructure, "Always Free" tier ($0, no time limit).
- **Machine:** `VM.Standard.A1.Flex` — Ampere ARM (**arm64**), region `eu-amsterdam-1`.
- **OS:** Ubuntu 20.04, with **Postgres 12** installed locally (both past standard support;
  see "Known gaps").
- **Address:** `134.98.159.244` (a *reserved* IP, it survives reboots) and the DuckDNS name
  `freshcart-nikos.duckdns.org` pointing at it.
- **SSH:** `ssh -i ~/.ssh/oracle_freshcart ubuntu@134.98.159.244`
- **Code:** `~/freshcart`, a clone of the private repo, pulled with a read-only deploy key.
- **HTTPS:** Caddy (`/etc/caddy/Caddyfile`) with an automatic Let's Encrypt certificate. It
  forwards **only the API**: `freshcart-nikos.duckdns.org → localhost:8080`.
- **Server process:** systemd unit `freshcart-server` running
  `dart run bin/main.dart --mode production` as `ubuntu`, `Restart=on-failure`.
- **Database:** Postgres on the VM, database and role both `freshcart`, listening on
  `127.0.0.1` only.
- **Ports:** 8080 (API), 8081 (Insights) and 8082 (web server) are not reachable from
  outside; only 22, 80 and 443 are.
- **Email:** Brevo, for login verification codes.

### Files on the VM that are not in git

| File | What | If it's missing |
|---|---|---|
| `freshcart_server/config/passwords.yaml` | database password, JWT secrets, Brevo key and sender — under **`production:`** | the server can't start |
| `freshcart_server/config/production.yaml` | tracked, but edited on the VM with its real hostnames | the server talks to placeholders |

The server reads **only the section of its run mode**. A key that exists under
`development:` but not under `production:` doesn't exist for the live server.

Because the VM keeps its own `production.yaml`, a change to that file in the repo does
**not** reach the VM by itself: compare after updating
(`diff ~/production.yaml.vm freshcart_server/config/production.yaml` before copying it back)
and carry such changes over by hand. Example: `maxRequestSize` went from 512 KB to 2 MB
(2097152) on 30 October 2026, so avatar photos up to 1 MB fit.

## Updating the server

Run on the VM. Each step says how to see that it worked: a command that runs without an
error is not proof that the right code runs.

```bash
cd ~/freshcart

# 1. Keep the VM's production config, then become exactly what's on GitHub.
#    Not `git pull`: the VM edits tracked files (pubspec, production.yaml), which
#    blocks a pull, and the repo's history has been rewritten once, which a pull
#    can't follow. NEVER `git clean`: it deletes passwords.yaml.
cp freshcart_server/config/production.yaml ~/production.yaml.vm
git fetch origin
git reset --hard origin/main
git log --oneline -1                 # must match `git log --oneline -1 origin/main` on the Mac
cp ~/production.yaml.vm freshcart_server/config/production.yaml

# 2. The VM has no Flutter: drop the app from the workspace, then fetch packages.
sed -i '/- freshcart_flutter/d' pubspec.yaml
dart pub get

# 3. Generate the domain's freezed code (generated files aren't committed).
#    After a change to the domain this writes outputs; "0 outputs" means nothing new.
cd packages/freshcart_domain && dart run build_runner build && cd ../../freshcart_server

# 4. Stop, migrate, start. Migrations first: the server touches its tables at start.
sudo systemctl stop freshcart-server
dart run bin/main.dart --mode production --role maintenance --apply-migrations
sudo systemctl start freshcart-server

# 5. Check it stays up (systemd restarts a crashing server, so "active" alone proves little).
sleep 10
sudo systemctl status freshcart-server --no-pager
journalctl -u freshcart-server --since "1 minute ago" --no-pager | tail -20
```

From the Mac: `curl https://freshcart-nikos.duckdns.org/` answers `OK <time>`.

## Starting from an empty database

Only when the data doesn't matter (it deletes every account and list). Replaces step 4
above.

```bash
sudo systemctl stop freshcart-server
sudo -u postgres psql -c "DROP DATABASE freshcart;"
sudo -u postgres psql -c "CREATE DATABASE freshcart OWNER freshcart;"
# Postgres 12 has no built-in gen_random_uuid(): it's in pgcrypto, per database.
# Without it every insert fails ("function gen_random_uuid() does not exist").
sudo -u postgres psql freshcart -c "CREATE EXTENSION IF NOT EXISTS pgcrypto;"
dart run bin/main.dart --mode production --role maintenance --apply-migrations
sudo systemctl start freshcart-server
```

Phones that used the old database still hold a session for an account that no longer
exists. Serverpod's client signs such a session out by itself at the next start; if a phone
still shows errors, clear the app's storage once.

## Checking the server

```bash
# Newest migration applied
sudo -u postgres psql freshcart -c "select module, version from serverpod_migrations;"
# The daily retention job (decisions.md #120): exactly one row
sudo -u postgres psql freshcart -c "select name, time, identifier from serverpod_future_call;"
# Recent errors
journalctl -u freshcart-server --since "15 minutes ago" --no-pager | grep -iE -A12 "exception|error"
```

## Releasing the Android app

On the Mac. The APK is signed with the release key, which lives **outside the repo**:
`~/.android/freshcart-release.jks`, password in `freshcart_flutter/android/key.properties`
(gitignored). **Back both up.** Without them no new build can install over the old one,
and every phone has to uninstall and start over.

```bash
# 1. Raise the version: the build number (+N) must go up, or Android won't update.
#    freshcart_flutter/pubspec.yaml → version: 1.0.3+4

# 2. Build against the live server
cd freshcart_flutter
flutter build apk --release --dart-define=SERVER_URL=https://freshcart-nikos.duckdns.org/

# 3. Check before handing it out
#    - signed with the release key (SHA-256 a4d50e53…)
$(ls -d ~/Library/Android/sdk/build-tools/*/apksigner | sort -V | tail -1) \
  verify --print-certs build/app/outputs/flutter-apk/app-release.apk | grep SHA-256
#    - version, INTERNET permission, app name
$(ls -d ~/Library/Android/sdk/build-tools/*/aapt2 | sort -V | tail -1) \
  dump badging build/app/outputs/flutter-apk/app-release.apk | grep -E "^package:|INTERNET|application-label:"

# 4. Commit the version, push, and publish under an android-x.y.z tag.
#    Not v*: that tag triggers release.yml (the web demo) for the same release.
gh release create android-1.0.3 build/app/outputs/flutter-apk/app-release.apk \
  --target "$(git rev-parse HEAD)" --title "FreshCart 1.0.3 (Android)" --notes "…"
```

Release builds differ from debug builds: test the release APK on a phone once before handing
it out. (1.0.0 lacked the INTERNET permission — Flutter's template only declares it for
debug and profile — and couldn't reach the server at all.)

## Known gaps

Tracked in the security plan; listed here so an update doesn't come as a surprise.

- **No database backups.** A lost disk loses every list.
- **Ubuntu 20.04 and Postgres 12** no longer get standard security updates.
- **iPhones can't use FreshCart yet:** Caddy forwards only the API, not the web app.
- **Every request looks like it comes from `localhost`** to the server (Caddy forwards it), so
  the per-IP limits (failed joins, new accounts) are shared by all users together.
- Ports 8080–8082 listen on all interfaces; only the firewall keeps them private.
