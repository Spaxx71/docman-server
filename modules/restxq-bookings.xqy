(:
========================================================================
LICENSE AGREEMENT:
This software is distributed WITHOUT ANY WARRANTY and without even the
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
========================================================================
This copy of Docman (a Document managgement an accounting system)
is licensed under the Server Side Public License (SSPL), v 1 ("the License").

    10|See the License for details about distribution rights,
modification and transformation of it.

========================================================================
All rights reserved by bintellix GmbH, Germany
========================================================================
@Author: Eduard Huber
@Version: 1.0
========================================================================
:)

xquery version "3.1";

module namespace dmbookings="http://exist-db.org/apps/restxq/docman-bookings";

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace tenant="http://bintellix.com/docman/tenant" at "/db/apps/docman/modules/module_tenant.xqm";
import module namespace bookings="http://bintellix.com/docman/bookings" at "/db/apps/docman/modules/module_bookings.xqm";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http="http://expath.org/ns/http-client";

declare function local:guard($tenant-id as xs:string, $year as xs:integer) {
	if (not(tenant:existsTenant($main:home-data, $tenant-id))) then
		(
			<rest:response>
				<http:response status="404" message="Invalid data - tenant ID"/>
			</rest:response>
			,
			<error code="TENANT_MISSING">Invalid tenant id '{$tenant-id}'</error>
		)
	else if (not(xmldb:collection-available($main:home-data || "/" || $tenant-id || "/" || $year))) then
		(
			<rest:response>
				<http:response status="404" message="Invalid data - year"/>
			</rest:response>
			,
			<error code="YEAR_MISSING">Invalid year '{$year}'</error>
		)
	else
		()
};

(:
	GET /api/xml/tenants/{tenant}/years/{year}/bookings/accounts
:)
declare
	%rest:GET
	%rest:path("/docman/xml/tenants/{$tenant-id}/years/{$year}/bookings/accounts")
	%rest:query-param("user", "{$user}", "Guest")
	%rest:query-param("owner", "{$owner}", "")
	%output:media-type("text/xml")
	%output:method("xml")
function dmbookings:accountsXML($user as xs:string*, $tenant-id as xs:string, $year as xs:integer, $owner as xs:string*) {
	let $guard := local:guard($tenant-id, $year)
	return
		if (exists($guard)) then $guard
		else
			let $kto := normalize-space(string(($owner[1], "")[1]))
			return
				bookings:listAccounts($main:home-data, $tenant-id, $year, if ($kto = "") then () else $kto)
};

(:
	GET /api/xml/tenants/{tenant}/years/{year}/bookings/sheet
:)
declare
	%rest:GET
	%rest:path("/docman/xml/tenants/{$tenant-id}/years/{$year}/bookings/sheet")
	%rest:query-param("user", "{$user}", "Guest")
	%output:media-type("text/xml")
	%output:method("xml")
function dmbookings:sheetXML($user as xs:string*, $tenant-id as xs:string, $year as xs:integer) {
	let $guard := local:guard($tenant-id, $year)
	return
		if (exists($guard)) then $guard
		else
			let $_ := bookings:refreshAccounts($main:home-data, $tenant-id, $year)
			return
				bookings:getAccoutSheet($main:home-data, $tenant-id, $year)
};

(:
	POST /api/xml/tenants/{tenant}/years/{year}/bookings/refresh
:)
declare
	%rest:POST
	%rest:path("/docman/xml/tenants/{$tenant-id}/years/{$year}/bookings/refresh")
	%rest:query-param("user", "{$user}", "Guest")
	%output:media-type("text/xml")
	%output:method("xml")
function dmbookings:refreshXML($user as xs:string*, $tenant-id as xs:string, $year as xs:integer) {
	let $guard := local:guard($tenant-id, $year)
	return
		if (exists($guard)) then $guard
		else
			bookings:refreshAccounts($main:home-data, $tenant-id, $year)
};
