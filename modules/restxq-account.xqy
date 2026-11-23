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

(: /rest/db/apps/docman/modules/restxq-account.xqy :)
(: Registrierung über /rest/db/apps/docman/initialize.xqy :)
xquery version "3.1";

module namespace dmaccounts="http://exist-db.org/apps/restxq/docman-accounts";

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace account="http://bintellix.com/docman/account" at "/db/apps/docman/modules/module_account.xqm";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http="http://expath.org/ns/http-client";
declare namespace rerr= "http://exquery.org/ns/restxq/error";

declare option exist:serialize "json-ignore-whitespace-text-nodes=yes";

declare function local:accountAsJson($node as node(), $pos as xs:integer) {
    map {
        "id": $node/@id/data(),
        "kto": number($node/@kto/data()),
        "type": $node/@type/data(),
        "classes": $node/@classes/data(),
        "Name": $node/Name/text(),
        "Notes": $node/Notes/text(),
        "Service": $node/Service/text(),
        "Company": map {
            "Name": $node/Company/Name/text()
        },
        "Person": map {
            "Vorname": $node/Person/Vorname/text(),
            "Nachname": $node/Person/Nachname/text()
        },
        "Contact": map {
            "Vorname": $node/contacts/contact[@type = 'person'][1]/Vorname/text(),
            "Nachname": $node/contacts/contact[@type = 'person'][1]/Nachname/text(),
            "Email": string-join(account:channel-values($node, 'email'), '; '),
            "Website": account:channel-values($node, 'website')[1],
            "Telefon": account:channel-values($node, 'phone')[1]
        },
        "CustomerID": $node/CustomerID/text(),
        "BankAccounts": (
            if (exists($node/BankAccounts/BankAccount)) then
                array {
                    for $bankAccount in $node/BankAccounts/BankAccount
                    return
                        map {
                            "name": $bankAccount/@name/data(),
                            "iban": $bankAccount/@iban/data(),
                            "notes": $bankAccount/@notes/data()
                        }
                }
            else
                array {}
        ),
        "ProcessTemplates":  [],
        "PeriodicPayments": (
            if (exists($node/PeriodicPayments/PeriodicPayment)) then
                array {
                    for $period in $node/PeriodicPayments/PeriodicPayment
                    return
                        map {
                            "Name": $node/PeriodicPayments/PeriodicPayment/Name/text(),
                            "Period": map {
                                "interval": $period/Period/@interval/data(),
                                "min": xs:integer($period/Period/@min),
                                "max": xs:integer($period/Period/@max),
                                "amount-min": string(($period/Period/@amount-min, "")[1]),
                                "amount-max": string(($period/Period/@amount-max, "")[1]),
                                "valid-from": $period/Period/@valid-from/data(),
                                "valid-till": $period/Period/@valid-till/data()
                            }
                        }
                }
            else
                array {}
        ),
        "BudgetCategories": [],
        "Accounting": map {
            "openingBalance": $node/Accounting/@openingBalance/data(),
            "closingBalance": $node/Accounting/@closingBalance/data(),
            "debitSum": $node/Accounting/@debitSum/data(),
            "creditSum": $node/Accounting/@creditSum/data()
        }
    }
};


(: 
    GET 	http://localhost:8080/exist/restxq/docman/test/accounts
    GET     /exist/restxq/tenants/test/years/2020/accounts 
    GET     /api/(xml|json)/tenants/test/years/2020/accounts 
:)
declare
    %rest:GET 
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/accounts") 
    %output:media-type("application/xml")
    %output:method("xml")

    %rest:query-param("user", "{$user}", "Guest")

function dmaccounts:listAccountsXML($user as xs:string*, $tenant as xs:string, $year as xs:integer) {
	account:listAccounts($main:home-data, $tenant, $year)
};

(: Kontorahmen und Nummernkreise des Jahres. Ersetzt keine Buchungskonten. :)
declare
    %rest:PUT("{$body}")
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/accounts")
    %rest:consumes("application/xml")
    %rest:consumes("text/xml")
    %output:media-type("application/xml")
    %output:method("xml")
    %rest:query-param("user", "{$user}", "Guest")
function dmaccounts:putNumbering($user as xs:string*, $tenant as xs:string, $year as xs:integer, $body) {
	account:store-numbering($main:home-data, $tenant, $year, $body)
};

declare
    %rest:GET 
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/accounts") 
    %output:media-type("application/json")
    %output:method("json")

    %rest:query-param("user", "{$user}", "Guest")

function dmaccounts:listAccountsJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer) {
	dmaccounts:listAccountsXML($user, $tenant, $year)
};


(: 
    GET 	http://localhost:8080/exist/restxq/docman/test/accounts/{$accountId}
    GET     /api/(xml|json)/tenants/test/years/2020/accounts/4711
:)
declare
    %rest:GET
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/accounts/{$accountId}")
    %output:media-type("application/xml")
    %output:method("xml")

    %rest:query-param("user", "{$user}", "Guest")

function dmaccounts:getAccountXML($user as xs:string*, $tenant as xs:string, $year as xs:integer, $accountId as xs:string) {
	account:getAccount($main:home-data, $tenant, $year, $accountId)
};

declare
    %rest:GET
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/accounts/{$accountId}")
    %output:media-type("application/json")
    %output:method("json")

    %rest:query-param("user", "{$user}", "Guest")

function dmaccounts:getAccountJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer, $accountId as xs:string) {
	account:getAccount($main:home-data, $tenant, $year, $accountId)
};


(: 
PUT	http://localhost:8080/exist/restxq/docman/test/accounts/{$accountId}
:)
declare
    %rest:PUT("{$body}")
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/accounts/{$accountId}")

    %rest:query-param("user", "{$user}", "Guest")

function dmaccounts:putAccount($user as xs:string*, $tenant as xs:string, $year as xs:integer, $accountId as xs:string, $body) {
	account:storeAccount($main:home-data, $tenant, $year, $accountId, $body)
};


(: 
DELETE 	http://localhost:8080/exist/restxq/docman/test/accounts/{$accountId}
:)
declare
    %rest:DELETE
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/accounts/{$accountId}")

    %rest:query-param("user", "{$user}", "Guest")

function dmaccounts:deleteAccount($user as xs:string*, $tenant as xs:string, $year as xs:integer, $accountId as xs:string) {
	account:deleteAccount($main:home-data, $tenant, $year, $accountId)

};

declare
    %rest:PUT("{$body}")
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/accounts/{$accountId}")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:consumes("application/json")
    %output:method("json")
    %output:media-type("application/json")
function dmaccounts:putAccountJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer, $accountId as xs:string, $body) {
	dmaccounts:putAccount($user, $tenant, $year, $accountId, $body)
};

declare
    %rest:DELETE
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/accounts/{$accountId}")
    %rest:query-param("user", "{$user}", "Guest")
    %output:method("json")
    %output:media-type("application/json")
function dmaccounts:deleteAccountJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer, $accountId as xs:string) {
	dmaccounts:deleteAccount($user, $tenant, $year, $accountId)
};

