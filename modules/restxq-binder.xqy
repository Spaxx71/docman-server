(:
========================================================================
LICENSE AGREEMENT:
This software is distributed WITHOUT ANY WARRANTY and without even the
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
========================================================================
This copy of Docman (a Document managgement an accounting system) 
is licensed under the Server Side Public License (SSPL), v 1 ("the License").

See the License for details about distribution rights, 
modification and transformation of it.

========================================================================
All rights reserved by bintellix GmbH, Germany
========================================================================
@Author: Eduard Huber
@Version: 1.0
======================================================================== 
:)

(: /rest/db/apps/docman/modules/restxq-binder.xqy :)
(: Registrierung über /rest/db/apps/docman/initialize.xqy :)
xquery version "3.1";

module namespace dmbinder="http://exist-db.org/apps/restxq/docman-binder";

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace binder="http://bintellix.com/docman/binder" at "/db/apps/docman/modules/module_binder.xqm";
import module namespace document="http://bintellix.com/docman/document" at "/db/apps/docman/modules/module_document.xqm";
import module namespace user="http://bintellix.com/docman/user" at "/db/apps/docman/modules/module_user.xqm";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http="http://expath.org/ns/http-client";
declare namespace rerr= "http://exquery.org/ns/restxq/error";


(:
    GET http://localhost:8080/exist/restxq/docman/tenant/test/years/2020/binders
    GET /restxq/docman/tenants/test/years/2020/binders
    GET /api/(xml|json)/docman/test/2020/binders
:)
declare
    %rest:GET
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/binders")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("text/xml")
    %output:method("xml")    

function dmbinder:listBindersXML($user as xs:string*, $tenant as xs:string, $year as xs:integer) {
	binder:listBinders($main:home-data,$tenant,$year)
};

declare
    %rest:GET
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/binders")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("application/json")
    %output:method("json")

function dmbinder:listBindersJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer) {
	binder:listBinders($main:home-data,$tenant,$year)
};

declare
    %rest:GET
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/binders/{$binder}")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("text/xml")
    %output:method("xml")
function dmbinder:getBinderXML($user as xs:string*, $tenant as xs:string, $year as xs:integer, $binder as xs:string) {
	document:listDocumentsForBinder($main:home-data, $tenant, $year, $binder)
};

declare
    %rest:GET
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/binders/{$binder}")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("application/json")
    %output:method("json")
function dmbinder:getBinderJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer, $binder as xs:string) {
	dmbinder:getBinderXML($user, $tenant, $year, $binder)
};

(:
POST /xml/tenants/{tenant}/years/{year}/binders
Body: <Binder name="Vertraege" type="ARCHIVE"/>
:)
declare
    %rest:POST("{$body}")
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/binders")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:consumes("application/xml")
    %rest:consumes("text/xml")
    %output:media-type("text/xml")
    %output:method("xml")
function dmbinder:createBinderXML($user as xs:string*, $tenant as xs:string, $year as xs:integer, $body) {
	try {
		let $_ := user:requirePermission($main:home-data, $tenant, 'year_settings', (), 'ADD')
		let $name :=
			if ($body/self::Binder) then string($body/@name)
			else if ($body/Binder) then string($body/Binder/@name)
			else string($body)
		return binder:createArchive($main:home-data, $tenant, string($year), $name)
	}
	catch * {
		(
			<rest:response>
				<http:response status="400" message="Binder create failed"/>
			</rest:response>
			,
			<error>{$err:code, $err:description}</error>
		)
	}
};

(:
PUT /xml/tenants/{tenant}/years/{year}/binders/{binder}?name=Neu
:)
declare
    %rest:PUT
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/binders/{$binder}")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:query-param("name", "{$name}", "")
    %output:media-type("text/xml")
    %output:method("xml")
function dmbinder:renameBinderXML($user as xs:string*, $tenant as xs:string, $year as xs:integer, $binder as xs:string, $name as xs:string*) {
	try {
		let $_ := user:requirePermission($main:home-data, $tenant, 'year_settings', (), 'CHANGE')
		return binder:renameArchive($main:home-data, $tenant, string($year), $binder, string(($name[1], $binder)[1]))
	}
	catch * {
		(
			<rest:response>
				<http:response status="400" message="Binder rename failed"/>
			</rest:response>
			,
			<error>{$err:code, $err:description}</error>
		)
	}
};

(:
DELETE /xml/tenants/{tenant}/years/{year}/binders/{binder}
:)
declare
    %rest:DELETE
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/binders/{$binder}")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("text/xml")
    %output:method("xml")
function dmbinder:deleteBinderXML($user as xs:string*, $tenant as xs:string, $year as xs:integer, $binder as xs:string) {
	try {
		let $_ := user:requirePermission($main:home-data, $tenant, 'year_settings', (), 'DELETE')
		return binder:deleteArchive($main:home-data, $tenant, string($year), $binder)
	}
	catch * {
		(
			<rest:response>
				<http:response status="400" message="Binder delete failed"/>
			</rest:response>
			,
			<error>{$err:code, $err:description}</error>
		)
	}
};

