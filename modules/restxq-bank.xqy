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

module namespace dmbank="http://exist-db.org/apps/restxq/docman-bank";

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace banking="http://bintellix.com/docman/banking" at "/db/apps/docman/modules/module_banking.xqm";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http="http://expath.org/ns/http-client";
declare namespace rerr= "http://exquery.org/ns/restxq/error";

(:
GET http://localhost:8080/exist/restxq/docman/bix/bank
:)
declare
    %rest:GET
    %rest:path("/docman/{$tenant}/banks")
    %output:media-type("text/xml")

    %rest:query-param("user", "{$user}", "Guest")

function dmbank:listBankAccounts($user as xs:string*, $tenant as xs:string) {
	banking:listBankAccounts($main:home-data, $tenant, ())
};


(:
GET http://localhost:8080/exist/restxq/docman/bix/bank/12345678/2020
GET /api/bix/banks/12345678/2020
:)
declare
    %rest:GET
    %rest:path("/docman/{$tenant}/banks/{$bank-account}/{$year}")
    %output:media-type("text/xml")

    %rest:query-param("user", "{$user}", "Guest")

function dmbank:listAccountings($user as xs:string*, $tenant as xs:string, $year as xs:integer, $bank-account as xs:string) {
	banking:listAccountings($main:home-data, $tenant, $bank-account, $year)
};


(: 
PUT	http://localhost:8080/exist/restxq/docman/test/bank/{$resource-id}
:)
declare
    %rest:PUT("{$body}")
    %rest:path("/docman/{$tenant}/banks/{$bank-account}/{$year}")

    %rest:query-param("user", "{$user}", "Guest")

function dmbank:putAccountings($user as xs:string*, $tenant as xs:string, $year as xs:integer, $bank-account as xs:string, $body) {
    try {
		if ($body/Accountings) then
	    	banking:storeAccountings($main:home-data, $tenant, $year, $bank-account, $body)
		else
			banking:storeBankAccount($main:home-data, $tenant, $year, $bank-account, $body)
	}
	catch * {
		<rest:response>
			<http:response status="400" message="Invalid syntax for data">
				<http:header name="Content-Language" value="en"/>
				<http:header name="Content-Type" value="text/html; charset=utf-8"/>
			</http:response>
		</rest:response>
		,
		<error>{$err:code, $err:value, $err:description, " module: ", $err:module, "(", $err:line-number, ",", $err:column-number, ")"}</error>
	}
}; 
