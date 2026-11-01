#!/usr/bin/env bash
# Builds the FreshCart web demo (lib/main_demo.dart, docs/web-demo-plan.md).
#
#   ./tool/build_demo.sh           build, then copy into the portfolio at
#                                  $PORTFOLIO/web/demo/freshcart/
#   ./tool/build_demo.sh --serve   build, add the dev host page, and serve it
#                                  at http://localhost:${PORT:-8090}/demo.html
#
# PORTFOLIO defaults to Nikolaos' checkout of the portfolio site.
set -euo pipefail

cd "$(dirname "$0")/.." # freshcart_flutter/
PORTFOLIO="${PORTFOLIO:-$HOME/Documents/Portfolio/Website/nikolaos_sporidis_portfolio}"
PORT="${PORT:-8090}"
# Not build/web: that is the real app's, which the server serves at /app/.
# --output must be absolute.
build="$PWD/build/demo"

case "${1:-}" in
  "" | --serve) ;;
  *)
    echo "usage: $0 [--serve]" >&2
    exit 64
    ;;
esac

flutter build web --release -t lib/main_demo.dart --output "$build"

if [[ "${1:-}" == "--serve" ]]; then
  cp tool/demo/demo.html "$build/demo.html"
  echo "Serving http://localhost:$PORT/demo.html (Ctrl-C to stop)"
  cd "$build"
  exec python3 -m http.server "$PORT"
fi

if [[ ! -d "$PORTFOLIO/web" ]]; then
  echo "No portfolio found at $PORTFOLIO (set PORTFOLIO=/path/to/it)" >&2
  exit 1
fi

out="$PORTFOLIO/web/demo/freshcart"
# Start clean, so files from an older build never linger.
rm -rf "$out"
mkdir -p "$out"
cp -R "$build/." "$out/"

# The portfolio's page hosts the demo, so the PWA's own page, manifest and
# service worker don't belong there (nor the dev host page, if a --serve
# run left it in build/demo).
rm -f "$out/index.html" "$out/demo.html" "$out/manifest.json" \
  "$out/flutter_service_worker.js"

# Drop renderer files the demo never fetches (checked in flutter.js's
# loader): they would only make the release zip and the deployed portfolio
# bigger. This is a dart2js build with the canvaskit renderer: it loads
# canvaskit/chromium/ in Chromium browsers and canvaskit/canvaskit.*
# elsewhere. skwasm*, wimp* (skwasm renderer) and webparagraph/ (only with
# preferWebParagraph) are unused, and *.symbols are only for symbolising
# stack traces. Revisit if the build moves to --wasm.
rm -rf "$out/canvaskit/webparagraph"
rm -f "$out"/canvaskit/skwasm* "$out"/canvaskit/wimp.*
find "$out/canvaskit" -name '*.symbols' -delete

echo "Demo copied to $out"
