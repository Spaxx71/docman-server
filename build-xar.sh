#!/bin/sh
# Baut dist/docman-0.6.xar. data/ darf nur den Mandanten test enthalten.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
UI=${DOCMAN_UI:-$ROOT/../docman-ui}
VERSION=0.6
DIST=$ROOT/dist
STAGE=$(mktemp -d "${TMPDIR:-/tmp}/docman-xar.XXXXXX")
trap 'rm -rf "$STAGE"' EXIT

fail() {
	echo "build-xar: $1" >&2
	exit 1
}

require_file() {
	if [ ! -f "$1" ]; then
		fail "Pflicht-Datei fehlt: $1"
	fi
}

only_test() {
	dir=$1
	found=0
	for entry in "$dir"/* "$dir"/.[!.]* "$dir"/..?*; do
		if [ ! -e "$entry" ]; then
			continue
		fi
		name=$(basename "$entry")
		case "$name" in
			test|__contents__.xml|.DS_Store) ;;
			*) fail "$dir darf nur test enthalten, gefunden: $name" ;;
		esac
		if [ "$name" = "test" ]; then
			found=1
		fi
	done
	if [ "$found" -ne 1 ]; then
		fail "$dir enthält kein test"
	fi
}

only_test "$ROOT/data"
require_file "$ROOT/data/test/tenant.dm.xml"
require_file "$ROOT/data/test/2022/year.dm.xml"
require_file "$ROOT/data/test/2022/accounts.dm.xml"
if ! grep -q 'id="mycompany"' "$ROOT/data/test/tenant.dm.xml"; then
	fail 'tenant.dm.xml hat nicht id="mycompany"'
fi

if [ ! -d "$UI" ]; then
	fail "docman-ui nicht gefunden: $UI"
fi
if [ ! -d "$UI/node_modules" ]; then
	(cd "$UI" && npm ci)
fi
(
	cd "$UI"
	PUBLIC_URL=/exist/apps/docman/webapp \
	REACT_APP_API_ROOT=/exist/restxq/docman \
	npm run build
)
require_file "$UI/build/index.html"
if ! grep -q '/exist/apps/docman/webapp/static/' "$UI/build/index.html"; then
	fail "UI-Build verweist nicht auf /exist/apps/docman/webapp/static/"
fi

copy_tree() {
	mkdir -p "$2"
	rsync -a --exclude '__contents__.xml' --exclude '.DS_Store' "$1"/ "$2"/
}

cp "$ROOT/controller.xql" "$ROOT/initialize.xqy" "$ROOT/install.xqy" "$ROOT/cleanup.xqy" \
	"$ROOT/update_module_hbci.xqy" "$ROOT/repo.xml" "$ROOT/expath-pkg.xml" "$STAGE/"
copy_tree "$ROOT/modules" "$STAGE/modules"
copy_tree "$ROOT/views" "$STAGE/views"
mkdir -p "$STAGE/resources"
rsync -a \
	--exclude '__contents__.xml' \
	--exclude '.DS_Store' \
	--exclude 'hbci4java-0.5.xar' \
	--exclude '_hbci4java-0.5.xar' \
	"$ROOT/resources/" "$STAGE/resources/"
mkdir -p "$STAGE/data"
rsync -a --exclude '__contents__.xml' --exclude '.DS_Store' "$ROOT/data/test/" "$STAGE/data/test/"
rm -rf "$STAGE/webapp"
cp -R "$UI/build/." "$STAGE/webapp/"

find "$STAGE/data/test" -type d | while read -r dir; do
	if [ -z "$(find "$dir" -mindepth 1 -maxdepth 1 ! -type d | head -n 1)" ]; then
		printf '\n' > "$dir/.keep"
	fi
done

cat > "$STAGE/deployment.xml" <<'EOF'
<config>
  <gui>/exist/apps/docman</gui>
  <api>/exist/restxq/docman</api>
</config>
EOF

only_test "$STAGE/data"
require_file "$STAGE/data/test/tenant.dm.xml"
require_file "$STAGE/data/test/2022/year.dm.xml"
require_file "$STAGE/data/test/2022/accounts.dm.xml"
if find "$STAGE/data" -print | grep -E -q '(^|/)(bintellix|intersecurity|ehuber)(/|$)|hbci_[^/]*\.dm\.xml'; then
	fail "data im Paket enthält Produktionsnamen"
fi

mkdir -p "$DIST"
OUT="$DIST/docman-$VERSION.xar"
rm -f "$OUT"
(cd "$STAGE" && zip -qr "$OUT" . -x '*.DS_Store')
if ! unzip -l "$OUT" | awk '{ print $4 }' | grep -qx 'expath-pkg.xml'; then
	fail "expath-pkg.xml liegt nicht in der Wurzel des Archivs"
fi
if unzip -l "$OUT" | awk '{ print $4 }' | grep -E -q '(^|/)(bintellix|intersecurity|ehuber)(/|$)|hbci_[^/]*\.dm\.xml|__contents__\.xml'; then
	fail "Archiv enthält ausgeschlossene Daten"
fi

echo "$OUT"
