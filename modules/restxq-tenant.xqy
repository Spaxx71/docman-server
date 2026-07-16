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

(: /rest/db/apps/docman/modules/restxq-tenant.xqy - needs to send accept :) 
xquery version "3.1";

module namespace dmtenant="http://exist-db.org/apps/restxq/docman-tenant";

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace tenant="http://bintellix.com/docman/tenant" at "/db/apps/docman/modules/module_tenant.xqm";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http="http://expath.org/ns/http-client";
declare namespace rerr= "http://exquery.org/ns/restxq/error";


(: 
    GET http://localhost:8080/exist/restxq/docman/tenants
    GET /api/(xml|json)/tenants
:) 
declare
    %rest:GET
    %rest:path("/docman/xml/tenants")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("text/xml")
    %output:method("xml")

function dmtenant:listTenantsXML($user as xs:string*) {
	tenant:listTenants($main:home-data)
};

declare
    %rest:GET
    %rest:path("/docman/json/tenants")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("application/json")
    %output:method("json")

function dmtenant:listTenantsJSON($user as xs:string*) {
	tenant:listTenants($main:home-data)
};


(: 
    GET http://localhost:8080/exist/restxq/docman/tenants/test
    GET /api/tenants/test
:) 
declare
    %rest:GET
    %rest:path("/docman/xml/tenants/{$tenant-id}")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("text/xml")
    %output:method("xml")

function dmtenant:getTenantXML($user as xs:string*, $tenant-id as xs:string) {
	if (not(tenant:existsTenant($main:home-data, $tenant-id))) then
		(
            <rest:response>
                <http:response status="404" message="Invalid data - tenant ID"/>
            </rest:response>
            ,
            <error>Invalid tenant id '{$tenant-id}'</error>
        )
    else
    	tenant:getTenant($main:home-data, $tenant-id)
};

declare
    %rest:GET
    %rest:path("/docman/json/tenants/{$tenant-id}")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("application/json")
    %output:method("json")

function dmtenant:getTenantJSON($user as xs:string*, $tenant-id as xs:string) {
	if (not(tenant:existsTenant($main:home-data, $tenant-id))) then
		(
            <rest:response>
                <http:response status="404" message="Invalid data - tenant ID"/>
            </rest:response>
            ,
            <error>Invalid tenant id '{$tenant-id}'</error>
        )
    else
    	tenant:getTenant($main:home-data, $tenant-id)
};


(: 
    DELETE http://localhost:8080/exist/restxq/docman/tenants/test
    DELETE /api/tenants/test
:) 
declare
    %rest:DELETE
    %rest:path("/docman/json/tenants/{$tenant-id}")
    %rest:query-param("user", "{$user}", "Guest") 
    %output:media-type("text/xml")
    %output:method("xml")

function dmtenant:deleteTenant($user as xs:string*, $display, $tenant-id as xs:string) {
	()
	(: delete node fn:collection("/db/widgets")//widget[@id = $id] :)
};

