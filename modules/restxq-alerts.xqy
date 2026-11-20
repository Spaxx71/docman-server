(:
GET/PUT /xml/tenants/{tenant}/years/{year}/alerts
:)

xquery version "3.1";

module namespace dmalerts="http://exist-db.org/apps/restxq/docman-alerts";

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace alerts="http://bintellix.com/docman/alerts" at "/db/apps/docman/modules/module_alerts.xqm";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http="http://expath.org/ns/http-client";

declare
	%rest:GET
	%rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/alerts")
	%rest:query-param("user", "{$user}", "Guest")
	%output:media-type("application/xml")
	%output:method("xml")
function dmalerts:list($user as xs:string*, $tenant as xs:string, $year as xs:integer) {
	alerts:list($main:home-data, $tenant, $year)
};

declare
	%rest:PUT("{$body}")
	%rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/alerts")
	%rest:query-param("user", "{$user}", "Guest")
	%rest:consumes("application/xml")
	%rest:consumes("text/xml")
	%output:media-type("application/xml")
	%output:method("xml")
function dmalerts:store($user as xs:string*, $tenant as xs:string, $year as xs:integer, $body) {
	try {
		alerts:store($main:home-data, $tenant, $year, $body)
	} catch * {
		(
			<rest:response>
				<http:response status="400" message="Alerts rejected"/>
			</rest:response>,
			<error>{$err:description}</error>
		)
	}
};
