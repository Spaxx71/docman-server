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
xquery version "3.1";

module namespace dmbinder="http://exist-db.org/apps/restxq/docman-binder";

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace binder="http://bintellix.com/docman/binder" at "/db/apps/docman/modules/module_binder.xqm";

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

