(:
GET  /docman/xml/tenants/{t}/years/{y}/proposals[?kto=]
POST /docman/xml/tenants/{t}/years/{y}/proposals/{id}/accept   Rumpf: bearbeiteter Vorschlag
POST /docman/xml/tenants/{t}/years/{y}/proposals/{id}/reject
Registrierung über /rest/db/apps/docman/initialize.xqy
:)
xquery version "3.1";

module namespace dmproposals="http://exist-db.org/apps/restxq/docman-proposals";

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace proposals="http://bintellix.com/docman/proposals" at "/db/apps/docman/modules/module_proposals.xqm";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http="http://expath.org/ns/http-client";

declare function local:body($body) as element()? {
	if (empty($body)) then ()
	else if ($body instance of element()) then $body
	else $body/*[1]
};

declare
	%rest:GET
	%rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/proposals")
	%rest:query-param("kto", "{$kto}", "")
	%rest:produces("application/xml")
	%output:method("xml")
	%output:media-type("application/xml")
function dmproposals:list($tenant as xs:string, $year as xs:integer, $kto as xs:string*) {
	proposals:list($main:home-data, $tenant, $year, normalize-space(string(($kto, '')[1])))
};

declare
	%rest:POST("{$body}")
	%rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/proposals/{$id}/accept")
	%rest:query-param("user", "{$user}", "Guest")
	%rest:consumes("application/xml")
	%rest:consumes("text/xml")
	%rest:produces("application/xml")
	%output:method("xml")
	%output:media-type("application/xml")
function dmproposals:accept($user as xs:string*, $tenant as xs:string, $year as xs:integer, $id as xs:string, $body) {
	proposals:accept($main:home-data, $tenant, $year, $id, local:body($body), string(($user, 'Guest')[1]))
};

declare
	%rest:POST("{$body}")
	%rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/proposals/{$id}/reject")
	%rest:query-param("user", "{$user}", "Guest")
	%rest:consumes("application/xml")
	%rest:consumes("text/xml")
	%rest:produces("application/xml")
	%output:method("xml")
	%output:media-type("application/xml")
function dmproposals:reject($user as xs:string*, $tenant as xs:string, $year as xs:integer, $id as xs:string, $body) {
	proposals:reject($main:home-data, $tenant, $year, $id, local:body($body), string(($user, 'Guest')[1]))
};
