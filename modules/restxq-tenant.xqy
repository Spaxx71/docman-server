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

xquery version "3.0";

module namespace dmtenant="http://exist-db.org/apps/restxq/docman-tenant";

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace tenant="http://bintellix.com/docman/tenant" at "/db/apps/docman/modules/module_tenant.xqm";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http="http://expath.org/ns/http-client";
declare namespace rerr= "http://exquery.org/ns/restxq/error";


(: 
https://docman.com/api
http://localhost:8080/exist/restxq/docman
:) 
declare
    %rest:GET
    %rest:path("/docman")
    %output:media-type("text/xml")
    %rest:query-param("user", "{$user}", "Guest")

function dmtenant:listTenants($user as xs:string*) {
	tenant:listTenants($main:home-data)
};


(: 
https://docman.com/api/test
http://localhost:8080/exist/restxq/docman/test
:) 
declare
    %rest:GET
    %rest:path("/docman/{$tenant}")
    %output:media-type("text/xml")
    %rest:query-param("user", "{$user}", "Guest")

function dmtenant:getTenant($user as xs:string*, $tenant as xs:string) {
	tenant:getTenant($main:home-data, $tenant)
};


declare
    %rest:DELETE
    %rest:path("/docman/{$tenant}")
    %rest:query-param("user", "{$user}", "Guest")

function dmtenant:deleteTenant($user as xs:string*, $display, $tenant as xs:string) {
	()
	(: delete node fn:collection("/db/widgets")//widget[@id = $id] :)
};

