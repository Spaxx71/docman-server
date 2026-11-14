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

(: /rest/db/apps/docman/modules/restxq-tenant.xqy :)
xquery version "3.1";

module namespace dmyear="http://exist-db.org/apps/restxq/docman-year";

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace tenant="http://bintellix.com/docman/tenant" at "/db/apps/docman/modules/module_tenant.xqm";
import module namespace year="http://bintellix.com/docman/year" at "/db/apps/docman/modules/module_year.xqm";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http="http://expath.org/ns/http-client";
declare namespace rerr= "http://exquery.org/ns/restxq/error";


(: 
    GET http://localhost:8080/exist/restxq/tenants/test/years
    GET /api/(xml|json)/tenants/test/years
:) 
declare
    %rest:GET
    %rest:path("/docman/xml/tenants/{$tenant-id}/years")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("text/xml")
    %output:method("xml")

function dmyear:listYearsXML($user as xs:string*, $tenant-id as xs:string) {
    if (not(tenant:existsTenant($main:home-data, $tenant-id))) then
        (
            <rest:response>
                <http:response status="404" message="Invalid data - tenant ID"/>
            </rest:response>
            ,
            <error>Invalid tenant id '{$tenant-id}'</error>
        )
    else    
	    year:listYears($main:home-data, $tenant-id)
};

declare
    %rest:GET
    %rest:path("/docman/json/tenants/{$tenant-id}/years")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("application/json")
    %output:method("json")

function dmyear:listYearsJSON($user as xs:string*, $tenant-id as xs:string) {
    if (not(tenant:existsTenant($main:home-data, $tenant-id))) then
        (
            <rest:response>
                <http:response status="404" message="Invalid data - tenant ID"/>
            </rest:response>
            ,
            <error>Invalid tenant id '{$tenant-id}'</error>
        )     
    else
    	year:listYears($main:home-data, $tenant-id)
};


(: 
    GET http://localhost:8080/exist/restxq/tenants/test/years/2000
    GET /api/tenants/test/years/2000
:) 
declare
    %rest:GET
    %rest:path("/docman/xml/tenants/{$tenant-id}/years/{$year}")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("text/xml")
    %output:method("xml")

function dmyear:getYearXML($user as xs:string*, $tenant-id as xs:string, $year as xs:integer) {
    if (not(tenant:existsTenant($main:home-data, $tenant-id))) then
        (
            <rest:response>
                <http:response status="404" message="Invalid data - tenant ID"/>
            </rest:response>
            ,
            <error>Invalid tenant id '{$tenant-id}'</error>
        )
    else if (not(year:existsYear($main:home-data, $tenant-id, $year))) then
        (
            <rest:response>
                <http:response status="404" message="Invalid data - tenant ID"/>
            </rest:response>
            ,
            <error>Invalid tenant id '{$tenant-id}'</error>
        )
    else
   	    year:getYear($main:home-data, $tenant-id, $year)

};

declare
    %rest:GET
    %rest:path("/docman/json/tenants/{$tenant-id}/years/{$year}")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("application/json")
    %output:method("json")

function dmyear:getYearJSON($user as xs:string*, $tenant-id as xs:string, $year as xs:integer) {
    if (not(tenant:existsTenant($main:home-data, $tenant-id))) then
        (
            <rest:response>
                <http:response status="404" message="Invalid data - tenant ID"/>
            </rest:response>
            ,
            <error>Invalid tenant id '{$tenant-id}'</error>
        )
    else if (not(year:existsYear($main:home-data, $tenant-id, $year))) then
        (
            <rest:response>
                <http:response status="404" message="Invalid data - tenant ID"/>
            </rest:response>
            ,
            <error>Invalid tenant id '{$tenant-id}'</error>
        )
    else
   	    year:getYear($main:home-data, $tenant-id, $year)
};

declare
    %rest:GET
    %rest:path("/docman/xml/tenants/{$tenant-id}/years/{$year}/dashboard")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("text/xml")
    %output:method("xml")

function dmyear:dashboardXML($user as xs:string*, $tenant-id as xs:string, $year as xs:integer) {
    if (not(tenant:existsTenant($main:home-data, $tenant-id))) then
        (
            <rest:response>
                <http:response status="404" message="Invalid data - tenant ID"/>
            </rest:response>
            ,
            <error>Invalid tenant id '{$tenant-id}'</error>
        )
    else if (not(exists(index-of(xmldb:get-child-collections(xs:anyURI(concat($main:home-data, '/', $tenant-id))), string($year))))) then
        (
            <rest:response>
                <http:response status="404" message="Invalid data - year"/>
            </rest:response>
            ,
            <error>Invalid year '{$year}'</error>
        )
    else
        year:dashboard($main:home-data, $tenant-id, $year)
};

declare
    %rest:GET
    %rest:path("/docman/json/tenants/{$tenant-id}/years/{$year}/dashboard")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("application/json")
    %output:method("json")
function dmyear:dashboardJSON($user as xs:string*, $tenant-id as xs:string, $year as xs:integer) {
	dmyear:dashboardXML($user, $tenant-id, $year)
};
