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

module namespace dmaccounts="http://exist-db.org/apps/restxq/docman-accounts";

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace account="http://bintellix.com/docman/account" at "/db/apps/docman/modules/module_account.xqm";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http="http://expath.org/ns/http-client";
declare namespace rerr= "http://exquery.org/ns/restxq/error";


(: 
GET     https://docman.com/api/test/accounts 
GET 	http://localhost:8080/exist/restxq/docman/test/accounts
:)
declare
    %rest:GET 
    %rest:path("/docman/{$tenant}/{$year}/accounts") 
    %output:media-type("application/xml")
    %output:method("xml")

    %rest:query-param("user", "{$user}", "Guest")

function dmaccounts:listAccounts($user as xs:string*, $tenant as xs:string, $year as xs:integer) {
	account:listAccounts($main:home-data, $tenant, $year)
};


(: 
GET 	http://localhost:8080/exist/restxq/docman/test/accounts/{$resource-id}
:)
declare
    %rest:GET
    %rest:path("/docman/{$tenant}/{$year}/accounts/{$resource-id}")
    %output:media-type("application/xml")
    %output:method("xml")

    %rest:query-param("user", "{$user}", "Guest")

function dmaccounts:getAccount($user as xs:string*, $tenant as xs:string, $year as xs:integer, $resource-id) {
	account:getAccount($main:home-data, $tenant, $year, $resource-id)
};


(: 
PUT	http://localhost:8080/exist/restxq/docman/test/accounts/{$resource-id}
:)
declare
    %rest:PUT("{$body}")
    %rest:path("/docman/{$tenant}/{$year}/accounts/{$resource-id}")

    %rest:query-param("user", "{$user}", "Guest")

function dmaccounts:putAccount($user as xs:string*, $tenant as xs:string, $year as xs:integer, $resource-id, $body) {
	account:storeAccount($main:home-data, $tenant, $year, $resource-id, $body)
};


(: 
DELETE 	http://localhost:8080/exist/restxq/docman/test/accounts/{$resource-id}
:)
declare
    %rest:DELETE
    %rest:path("/docman/{$tenant}/{$year}/accounts/{$resource-id}")

    %rest:query-param("user", "{$user}", "Guest")

function dmaccounts:deleteAccount($user as xs:string*, $tenant as xs:string, $year as xs:integer, $resource-id) {
	account:deleteAccount($main:home-data, $tenant, $year, $resource-id)

};

