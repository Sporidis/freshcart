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

GitHub Actions builds it: pushing a `v*` tag runs `.github/workflows/release.yml`, which
publishes one release with the signed APK (`freshcart-<version>.apk`) and the portfolio's
web demo (`freshcart-demo-web.zip`).

```bash
# 1. Raise the version in freshcart_flutter/pubspec.yaml, e.g. 1.0.3+4 → 1.0.4+5.
#    Both parts: the tag must equal the name (1.0.4), and Android only updates
#    when the build number (+N) goes up. The workflow refuses a mismatch.

# 2. Commit, push, tag
git commit -am "chore(release): 1.0.4" && git push origin main
git tag v1.0.4 && git push origin v1.0.4

# 3. Watch it (about 10 minutes), then check the release has both files
gh run watch "$(gh run list --workflow release.yml --limit 1 --json databaseId --jq '.[0].databaseId')"
gh release view v1.0.4
```

The workflow fails instead of publishing when the APK isn't signed with the release key
(SHA-256 `a4d50e53…`, checked in full). It also needs these repository secrets, set from
the Mac with `gh secret set`:

| Secret | From |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -i ~/.android/freshcart-release.jks` |
| `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS` | `freshcart_flutter/android/key.properties` |
| `GOOGLE_SERVICES_JSON` | `freshcart_flutter/android/app/google-services.json` |
| `FIREBASE_OPTIONS_DART` | `freshcart_flutter/lib/firebase_options.dart` |

The key itself still lives **outside the repo** on the Mac: `~/.android/freshcart-release.jks`,
password in `freshcart_flutter/android/key.properties` (gitignored). **Back both up.** GitHub
secrets can't be read back, so they are no backup. Without the key no new build can install
over the old one, and every phone has to uninstall and start over.

Releases up to 1.0.3 were built by hand on the Mac and tagged `android-x.y.z`. To build one
locally (for a test on a phone):

```bash
cd freshcart_flutter
flutter build apk --release --dart-define=SERVER_URL=https://freshcart-nikos.duckdns.org/
# version, INTERNET permission, app name
$(ls -d ~/Library/Android/sdk/build-tools/*/aapt2 | sort -V | tail -1) \
  dump badging build/app/outputs/flutter-apk/app-release.apk | grep -E "^package:|INTERNET|application-label:"
```

Release builds differ from debug builds: test the release APK on a phone once before handing
it out. (1.0.0 lacked the INTERNET permission — Flutter's template only declares it for
debug and profile — and couldn't reach the server at all.)

## Releasing the web app (iPhones)

iPhones use the web app: `https://freshcart-nikos.duckdns.org/app/`, opened in Safari and
added to the home screen (Share → Add to Home Screen). No push notifications there.

The VM has no Flutter, so the web app is built on the Mac and copied over. Serverpod's web
server (port 8082) serves `freshcart_server/web/app` under `/app`; that folder is gitignored,
so a `git reset --hard` on the VM leaves it alone.

```bash
# On the Mac: build for the live server, under /app
cd freshcart_flutter
flutter build web --release --base-href /app/ \
  --dart-define=SERVER_URL=https://freshcart-nikos.duckdns.org/

# Copy it into the server's web/app folder (the trailing slashes matter)
rsync -az --delete -e "ssh -i ~/.ssh/oracle_freshcart" \
  build/web/ ubuntu@134.98.159.244:freshcart/freshcart_server/web/app/
```

On the VM, only the first time: Caddy must send `/app` to the web server, everything else
to the API, and the server must restart once to notice the new folder.

```bash
# /etc/caddy/Caddyfile
freshcart-nikos.duckdns.org {
    handle /app* {
        reverse_proxy localhost:8082
    }
    handle {
        reverse_proxy localhost:8080
    }
}
```

```bash
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
sudo systemctl restart freshcart-server
```

The offline database runs in the browser on `web/sqlite3.wasm` and `web/drift_worker.js`.
They must match the drift and sqlite3 versions in `pubspec.lock`: after upgrading either
package, download them again from the matching GitHub releases
(`simolus3/sqlite3.dart` → `sqlite3-<version>/sqlite3.wasm`,
`simolus3/drift` → `drift-<version>/drift_worker.js`).

## Moving to a new server

How the server moved from Ubuntu 20.04 / Postgres 12 to a fresh Ubuntu 24.04 / Postgres 16
VM, and how to do it again. The old VM keeps running until the new one works; the switch
is moving the **reserved public IP**, so DuckDNS, the certificate's domain and the apps
don't change.

1. **Create the VM** (Oracle Cloud console → Compute → Instances → Create). Image: *Canonical
   Ubuntu 24.04* (aarch64). Shape: `VM.Standard.A1.Flex` — Always Free allows 4 OCPUs and
   24 GB in total across your instances, so give it what the old VM leaves free (1 OCPU /
   6 GB is plenty). Same VCN and subnet as the old VM. Public IP: a temporary (ephemeral)
   one for now. SSH key: upload `~/.ssh/oracle_freshcart.pub`.
2. **Run the setup script** (from the Mac, with the new VM's temporary IP):
   ```bash
   scp -i ~/.ssh/oracle_freshcart deploy/setup-vm.sh ubuntu@<NEW_IP>:
   ssh -i ~/.ssh/oracle_freshcart ubuntu@<NEW_IP> 'bash setup-vm.sh'
   ```
   It asks for the database password (the `database` value under `production:` in the old
   VM's `passwords.yaml`) and for adding a deploy key on GitHub.
3. **Copy the secrets and the VM's config**, old VM → Mac → new VM, then delete the copies:
   ```bash
   mkdir -p /tmp/fc && cd /tmp/fc
   scp -i ~/.ssh/oracle_freshcart ubuntu@134.98.159.244:freshcart/freshcart_server/config/{passwords,production}.yaml .
   scp -i ~/.ssh/oracle_freshcart passwords.yaml production.yaml ubuntu@<NEW_IP>:freshcart/freshcart_server/config/
   rm -rf /tmp/fc
   ```
4. **Build on the new VM** (steps 2–3 of "Updating the server"):
   ```bash
   cd ~/freshcart && sed -i '/- freshcart_flutter/d' pubspec.yaml && dart pub get
   cd packages/freshcart_domain && dart run build_runner build && cd ../../freshcart_server
   ```
5. **Copy the web app** from the Mac: the `rsync` of "Releasing the web app", to `<NEW_IP>`.
6. **Move the data** — the old server stops here, so nothing written meanwhile is lost:
   ```bash
   # old VM
   sudo systemctl stop freshcart-server
   sudo -u postgres pg_dump -Fc freshcart > ~/freshcart.dump
   # Mac: old → new
   scp -i ~/.ssh/oracle_freshcart ubuntu@134.98.159.244:freshcart.dump /tmp/
   scp -i ~/.ssh/oracle_freshcart /tmp/freshcart.dump ubuntu@<NEW_IP>: && rm /tmp/freshcart.dump
   # new VM: restore into the empty database, then apply any newer migrations (usually none)
   sudo -u postgres pg_restore --no-owner --role=freshcart -d freshcart ~/freshcart.dump
   cd ~/freshcart/freshcart_server
   dart run bin/main.dart --mode production --role maintenance --apply-migrations
   sudo systemctl start freshcart-server
   curl -s localhost:8080/          # OK <time>
   ```
7. **Move the reserved IP** (console): old instance → Attached VNICs → its VNIC → IPv4
   addresses → Edit → *No public IP* (this frees the reserved IP). Then new instance → its
   VNIC → IPv4 addresses → Edit → *Reserved public IP* → pick `134.98.159.244`. Caddy gets a
   certificate for the domain by itself within a minute.
8. **Check from the Mac:** `ssh-keygen -R 134.98.159.244` (the address now has a new host
   key), then `curl https://freshcart-nikos.duckdns.org/` and open the app.
9. **Keep the old VM stopped for a week**, then terminate it (and its boot volume, so it
   doesn't count against the free storage).

## Known gaps

Tracked in the security plan; listed here so an update doesn't come as a surprise.

- **No database backups.** A lost disk loses every list.
- **Ubuntu 20.04 and Postgres 12** no longer get standard security updates (until the move
  in "Moving to a new server" is done).
- **Every request looks like it comes from `localhost`** to the server (Caddy forwards it), so
  the per-IP limits (failed joins, new accounts) are shared by all users together.
- Ports 8080–8082 listen on all interfaces; only the firewall keeps them private.
