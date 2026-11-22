#!/bin/sh
# Holt das Test-Image und startet es mit einem gemounteten Datenverzeichnis.
set -eu

IMAGE=${DOCMAN_IMAGE:-ghcr.io/spaxx71/docman:0.6}
NAME=${DOCMAN_NAME:-docman}
DATA=${DOCMAN_DATA:-$HOME/.docman/data}
PORT=${DOCMAN_PORT:-8080}
PASS=${EXIST_PASSWORD:-docman}

if [ -n "${DOCMAN_CONTAINER:-}" ]; then
	CLI=$DOCMAN_CONTAINER
elif command -v docker >/dev/null 2>&1; then
	CLI=docker
elif command -v podman >/dev/null 2>&1; then
	CLI=podman
else
	echo "Weder Docker noch Podman gefunden. DOCMAN_CONTAINER kann ein Werkzeug mit denselben pull- und run-Argumenten nennen. Es wird nichts installiert." >&2
	exit 1
fi

mkdir -p "$DATA"
"$CLI" pull "$IMAGE"
"$CLI" rm -f "$NAME" >/dev/null 2>&1 || true
"$CLI" run -d --name "$NAME" \
	-p "$PORT:8080" \
	-e "EXIST_PASSWORD=$PASS" \
	-v "$DATA:/exist/data" \
	"$IMAGE"

echo "http://localhost:$PORT/exist/apps/docman/webapp/"
echo "Login: admin / $PASS"
