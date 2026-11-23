(:
GET  /docman/xml/tenants/{t}/years/{y}/contacts[?ended=true]
GET  /docman/xml/tenants/{t}/years/{y}/contacts/{id}
PUT  /docman/xml/tenants/{t}/years/{y}/contacts/{id}
DELETE beendet den Kontakt, löscht ihn nicht.
Registrierung über /rest/db/apps/docman/initialize.xqy
:)
xquery version "3.1";

module namespace dmcontacts="http://exist-db.org/apps/restxq/docman-contacts";

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace account="http://bintellix.com/docman/account" at "/db/apps/docman/modules/module_account.xqm";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare function local:body($body) as element()? {
	if (empty($body)) then ()
	else if ($body instance of element()) then $body
	else $body/*[1]
};

declare
	%rest:GET
	%rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/contacts")
	%rest:query-param("ended", "{$ended}", "false")
	%rest:produces("application/xml")
	%output:method("xml")
	%output:media-type("application/xml")
function dmcontacts:list($tenant as xs:string, $year as xs:integer, $ended as xs:string*) {
	<Contacts tenant="{$tenant}" year="{$year}">{
		account:contacts($main:home-data, $tenant, $year, string(($ended, 'false')[1]) = ('true', '1'))
	}</Contacts>
};

declare
	%rest:GET
	%rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/contacts/{$id}")
	%rest:produces("application/xml")
	%output:method("xml")
	%output:media-type("application/xml")
function dmcontacts:get($tenant as xs:string, $year as xs:integer, $id as xs:string) {
	let $contact := account:contact($main:home-data, $tenant, $year, $id)
	return
		if (empty($contact)) then <error>Kein Kontakt vorhanden</error>
		else
			<ContactRecord id="{$id}" year="{$year}">
				{$contact}
				<Accounts>{account:contact-accounts($main:home-data, $tenant, $year, $id)}</Accounts>
				<PastAccounts>{account:contact-past-accounts($main:home-data, $tenant, $year, $id)}</PastAccounts>
			</ContactRecord>
};

declare
	%rest:PUT("{$body}")
	%rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/contacts/{$id}")
	%rest:consumes("application/xml")
	%rest:consumes("text/xml")
	%rest:produces("application/xml")
	%output:method("xml")
	%output:media-type("application/xml")
function dmcontacts:put($tenant as xs:string, $year as xs:integer, $id as xs:string, $body) {
	account:store-contact($main:home-data, $tenant, $year, $id, local:body($body))
};

declare
	%rest:DELETE
	%rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/contacts/{$id}")
	%rest:produces("application/xml")
	%output:method("xml")
	%output:media-type("application/xml")
function dmcontacts:end($tenant as xs:string, $year as xs:integer, $id as xs:string) {
	account:end-contact($main:home-data, $tenant, $year, $id)
};
