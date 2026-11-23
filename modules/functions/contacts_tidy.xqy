xquery version "3.1";

(:
	Entfernt type, classes und Numbers aus contacts.dm.xml.
	Die Jahresdateien bleiben unverändert.
:)

import module namespace main = "http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace account = "http://bintellix.com/docman/account" at "/db/apps/docman/modules/module_account.xqm";
import module namespace request = "http://exist-db.org/xquery/request";

declare variable $tenant := request:get-parameter('tenant', '');

if (normalize-space($tenant) = '') then
	<Tidy status="missing-tenant"/>
else
	account:tidy-contacts($main:home-data, $tenant)
