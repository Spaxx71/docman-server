xquery version "3.1";

(:
	Ersetzt sprechende Kontakt-Ids durch UUIDs und setzt contactsRef in allen Jahresdateien.
	Ohne tenant-Parameter: alle Mandanten unter home-data.
	Mit ?tenant=…: nur dieser Mandant.
:)

import module namespace main = "http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace account = "http://bintellix.com/docman/account" at "/db/apps/docman/modules/module_account.xqm";
import module namespace request = "http://exist-db.org/xquery/request";

declare variable $tenant := normalize-space(request:get-parameter('tenant', ''));

if ($tenant = '') then
	account:uuid-contacts-all($main:home-data)
else
	account:uuid-contacts($main:home-data, $tenant)
