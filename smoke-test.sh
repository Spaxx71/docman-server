#!/bin/sh
# Prüft eine laufende Test-Instanz: UI, Mandant mycompany, Initialisierung.
set -eu

BASE=${1:-http://localhost:8080}
USER=${EXIST_USER:-admin}
PASS=${EXIST_PASSWORD:-docman}

fetch() {
	curl -fsS -u "$USER:$PASS" "$1"
}

code=000
i=0
while [ "$i" -lt 90 ]; do
	code=$(curl -s -o /dev/null -w '%{http_code}' -u "$USER:$PASS" "$BASE/exist/apps/docman/webapp/index.html" || true)
	if [ "$code" = "200" ]; then
		break
	fi
	i=$((i + 1))
	sleep 5
done
if [ "$code" != "200" ]; then
	echo "smoke: index.html nicht erreichbar, letzter Status $code" >&2
	exit 1
fi

html=$(fetch "$BASE/exist/apps/docman/webapp/index.html")
echo "$html" | grep -q '/exist/apps/docman/webapp/static/' || {
	echo "smoke: static-Pfad fehlt in index.html" >&2
	exit 1
}

tenants=$(fetch "$BASE/exist/restxq/docman/xml/tenants")
echo "$tenants" | grep -q 'mycompany' || {
	echo "smoke: mycompany fehlt" >&2
	exit 1
}
echo "$tenants" | grep -q 'MyCompany' || {
	echo "smoke: MyCompany fehlt" >&2
	exit 1
}

tenant=$(fetch "$BASE/exist/rest/db/apps/docman/data/test/tenant.dm.xml")
echo "$tenant" | grep -q 'id="mycompany"' || {
	echo "smoke: tenant.dm.xml ist nicht der Testmandant" >&2
	exit 1
}

query=$(curl -fsS -u "$USER:$PASS" --get \
	--data-urlencode "_query=concat(if (sm:group-exists('docman')) then 'docman ' else '', if (sm:group-exists('test')) then 'test ' else '', if (sm:list-users() = 'bix-accounting') then 'bix-accounting' else '')" \
	"$BASE/exist/rest/db")
echo "$query" | grep -q 'docman test bix-accounting' || {
	echo "smoke: Initialisierung unvollständig: $query" >&2
	exit 1
}

echo "smoke: ok"
