#!/bin/sh
# Exports the web build into build/web/ with the scoreboard key in it.
#
#   SCOREBOARD_KEY=... tools/export_web.sh
#
# The key is written to secrets/scoreboard.cfg (ignored by git), which the
# Web preset packs into the build. Without SCOREBOARD_KEY the file from an
# earlier export is used. The same key is SCOREBOARD_HMAC_KEY on the server
# (secret scoreboard-secrets in the fredsoe-io namespace).
set -eu
cd "$(dirname "$0")/.."

if [ -n "${SCOREBOARD_KEY:-}" ]; then
    mkdir -p secrets
    printf '[scoreboard]\n\nkey="%s"\n' "$SCOREBOARD_KEY" > secrets/scoreboard.cfg
fi
if [ ! -f secrets/scoreboard.cfg ]; then
    echo "No scoreboard key: set SCOREBOARD_KEY (scores would be rejected)." >&2
    exit 1
fi

mkdir -p build/web
godot --headless --export-release "Web" build/web/index.html
