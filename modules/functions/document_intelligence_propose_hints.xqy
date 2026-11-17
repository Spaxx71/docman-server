xquery version "3.1";

(:
Einmalig Hint-Vorschläge für Kreditoren erzeugen.
Schreibt {year}/accounts.hint-proposals.xml — ändert accounts.dm.xml nicht.

Aufruf in eXist (Beispiel):
  let $tenant := 'bintellix'
  let $year := 2020
  return ...
Oder Parameter unten anpassen und Script ausführen.
:)

import module namespace di = "http://bintellix.com/docman/document-intelligence" at "/db/apps/docman/modules/module_document-intelligence.xqm";

let $home := '/db/apps/docman/data'
let $tenant := 'bintellix'
let $year := 2020
return di:propose-creditor-hints($home, $tenant, $year)
