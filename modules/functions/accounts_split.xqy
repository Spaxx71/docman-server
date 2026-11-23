xquery version "3.1";

(:
	Einmal je Mandant: erweiterte Kontodaten nach contacts.dm.xml übernehmen
	und jede Jahresdatei auf die schlanke Account-Zeile bringen. Die bisherige
	Datei bleibt als accounts.dm.xml.bak. Ein zweiter Lauf schreibt sie nicht erneut.
:)

import module namespace main = "http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace account = "http://bintellix.com/docman/account" at "/db/apps/docman/modules/module_account.xqm";
import module namespace request = "http://exist-db.org/xquery/request";

declare variable $tenant := request:get-parameter('tenant', '');

if (normalize-space($tenant) = '') then
	<Split status="missing-tenant"/>
else
	account:split($main:home-data, $tenant)
