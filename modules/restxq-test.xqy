xquery version "3.1";

(: Registrierung über initialize.xqy, Dateiname restxq-*. :)

module namespace dmtest="http://exist-db.org/apps/restxq/docman-test";

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace test-tenant="http://bintellix.com/docman/test-tenant" at "/db/apps/docman/modules/module_test-tenant.xqm";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http="http://expath.org/ns/http-client";

(:
	POST /exist/restxq/docman/xml/tenants/test/years/2022/test-seed
	POST /api/xml/tenants/test/years/2022/test-seed
:)
declare
	%rest:POST
	%rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/test-seed")
	%output:media-type("text/xml")
	%output:method("xml")
function dmtest:seedXML($tenant as xs:string, $year as xs:integer) {
	(
		<rest:response>
			<http:response status="200" message="Test tenant seeded"/>
		</rest:response>
		,
		test-tenant:build($main:home-data, $tenant, $year)
	)
};
