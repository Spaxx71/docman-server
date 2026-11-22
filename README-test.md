# Docman-Testumgebung

Dieses Paket enthält nur den Mandanten `test`. Unter `data/` darf nichts anderes liegen. Der Build bricht ab, wenn dort ein weiterer Ordner oder eine weitere Datei steht. `__contents__.xml` und `.DS_Store` zählen nicht als Inhalt und kommen nicht ins Paket.

## Dateien

- `data/test/tenant.dm.xml`, Mandant `mycompany`, Name `MyCompany (test)`, Gruppe `test`, User `admin`
- `data/test/2022/year.dm.xml`
- `data/test/2022/accounts.dm.xml`
- leere Monats- und Fachordner unter `data/test/2022/` und `data/test/business-paper/` mit einer Marker-Datei `.keep`, damit die Collections nach der Installation bleiben

Produktionsnamen wie `bintellix`, `intersecurity`, `ehuber` und Dateien `hbci_*.dm.xml` dürfen in `data/` nicht vorkommen.

## Start

Docker oder Podman muss schon installiert sein. Das Skript installiert nichts.

```bash
curl -fsSL https://raw.githubusercontent.com/Spaxx71/docman-server/main/docman.sh | sh
```

Das Skript zieht `ghcr.io/spaxx71/docman:0.6`, legt die Datenbank nach `~/.docman/data` und öffnet Port 8080.

- React: http://localhost:8080/exist/apps/docman/webapp/
- API: http://localhost:8080/exist/restxq/docman
- Klassische Oberfläche: http://localhost:8080/exist/apps/docman/index.html
- Login: `admin` / `docman`
- Zusätzlicher User aus der Initialisierung: `bix-accounting` / `bix-acc`

Dieselbe Datei `docman-0.6.xar` liegt am GitHub-Release `v0.6`, für eine eXist-Instanz, die schon läuft.

## Bauen

`./build-xar.sh` prüft `data/`, baut die UI und schreibt `dist/docman-0.6.xar`. Die UI-Quellen liegen daneben in `../docman-ui` oder in `DOCMAN_UI`.

Ohne `deployment.xml` bleiben die Proxy-Pfade `/app` und `/api/xml`. Nur das XAR enthält `deployment.xml` mit `/exist/apps/docman` und `/exist/restxq/docman`. Die React-Quellen behalten als Default `https:/docman.bintellix.com/api`. Das Paket setzt beim UI-Build `REACT_APP_API_ROOT=/exist/restxq/docman`.

Veröffentlichung von Image und XAR: Workflow `release` in GitHub Actions von Hand starten. Der Workflow prüft vorher UI, Mandant `mycompany` und die Gruppen `docman` und `test` samt User `bix-accounting`.
