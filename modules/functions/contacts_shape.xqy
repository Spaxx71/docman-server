xquery version "3.1";

(:
	Contact wird zu contacts/contact.
	Firma und Person bleiben nur als eine von beiden stehen.
:)

import module namespace main = "http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace account = "http://bintellix.com/docman/account" at "/db/apps/docman/modules/module_account.xqm";
import module namespace request = "http://exist-db.org/xquery/request";

declare variable $tenant := request:get-parameter('tenant', '');

if (normalize-space($tenant) = '') then
	<Reshape status="missing-tenant"/>
else
	account:reshape-contacts($main:home-data, $tenant)
