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

(: /rest/db/apps/docman/modules/restxq-categories.xqy :)
xquery version "3.1";

module namespace dmcategories="http://exist-db.org/apps/restxq/docman-categories";

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace categories="http://bintellix.com/docman/categories" at "/db/apps/docman/modules/module_categories.xqm";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http="http://expath.org/ns/http-client";
declare namespace rerr= "http://exquery.org/ns/restxq/error";


(: 
    GET 	http://localhost:8080/exist/restxq/docman/tenants/test/years/2000/categories
    GET     /api/(xml|json)/tenants/test/years/2000/categories 
:)
declare
    %rest:GET 
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/categories") 
    %output:media-type("application/xml")
    %output:method("xml")

    %rest:query-param("user", "{$user}", "Guest")

function dmcategories:listCategoriesXML($user as xs:string*, $tenant as xs:string, $year as xs:integer) {
    categories:listCategories($main:home-data, $tenant, $year)
};

declare
    %rest:GET 
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/categories") 
    %output:media-type("application/json")
    %output:method("json")

    %rest:query-param("user", "{$user}", "Guest")

function dmcategories:listCategoriesJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer) {
    categories:listCategories($main:home-data, $tenant, $year)
};


(: 
    PUT 	http://localhost:8080/exist/restxq/docman/tenants/test/years/2000/categories
    PUT     /api/tenants/test/years/2000/categories 
:)
declare
    %rest:PUT("{$body}")
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/categories")
    %rest:query-param("user", "{$user}", "Guest")

function dmcategories:putCategories($user as xs:string*, $tenant as xs:string, $year as xs:integer, $body) {
    try {
	    categories:storeCategories($main:home-data, $tenant, $year, $body)
    } catch * {
        <rest:response>
            <http:response status="400" message="Invalid data"/>
        </rest:response>,
        <error>Description: {$err:code} {$err:value} {$err:description}</error>
    }
};

declare
    %rest:PUT("{$body}")
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/categories")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:consumes("application/json")
    %output:method("json")
    %output:media-type("application/json")
function dmcategories:putCategoriesJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer, $body) {
	dmcategories:putCategories($user, $tenant, $year, $body)
};


