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

(: /rest/db/apps/docman/modules/restxq-bank.xqy :)
xquery version "3.1";

module namespace dmbank="http://exist-db.org/apps/restxq/docman-bank";

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace banking="http://bintellix.com/docman/banking" at "/db/apps/docman/modules/module_banking.xqm";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http="http://expath.org/ns/http-client";
declare namespace rerr= "http://exquery.org/ns/restxq/error";

declare function local:bankAccountAsJson($node as node(), $pos as xs:integer) {
    map {
        "id": $node/@id/data(),
        "origin": $node/@origin/data(),
        "saldoTimestamp": substring($node/@saldoTimestamp/data(),1,19),
        "saldoAmount": xs:decimal($node/@saldoAmount/data()),
        "isStorno": xs:boolean($node/@isStorno/data()),
        "isSepa": xs:boolean($node/@isSepa/data()),
        "isCamt": xs:boolean($node/@isCamt/data()),
        "budgetCategory": $node/@budgetCategory/data(),
        "SalesType": map {
            "key": $node/SalesType/@key/data(),
            "#text": $node/SalesType/text()
        },
        "BookingDate": substring($node/BookingDate/data(),1,10),
        "ValueDate": substring($node/ValueDate/data(),1,10),
        "Recipient": $node/Recipient/text(),
        "DivergentRecepient": (
            if ($node/DivergentRecepient) then
                map {
                    "type": $node/DivergentRecepient/@type/data(),
                    "#text": $node/DivergentRecepient/text()
                }
            else 
                ()
        ),
        "PaymentDetail": $node/PaymentDetail/text(),
        "Usage": $node/Usage/text(),
        "IBAN":  $node/IBAN/text(),
        "BIC":  $node/BIC/text(),
        "MandantRef": $node/MandantRef/text(),
        "CustomerRef": $node/CustomerRef/text(),
        "EndToEndRef": $node/EndToEndRef/text(),
        "CreditorID": $node/CreditorID/text(),
        "Primanota": $node/Primanota/text(),
        "Amount": map {
            "type": $node/Amount/@type/data(),
            "value": xs:decimal($node/Amount/text())
        },
        "OriginalAmount": $node/OriginalAmount/text(),
        "CurrencyUnit": $node/CurrencyUnit/text(),
        "ExternalCosts": $node/ExternalCosts/text()
    }

(:
    map {
        "id": $node/id/data(),
        "definition": (
            map {
                "baseType": $node/definition/baseType/string(),
                "subType": $node/definition/subType/string(),
                "category": $node/definition/category/string(),
                "name": $node/definition/name/string(),
                "label": $node/definition/label/string(),
                "description": $node/definition/description/string()
            }
        ),
        "ownerIdRef": (
            if (exists($node/ownerIdRef/text())) then
                $node/ownerIdRef/string()
            else 
                ()
        ),
        "connectors": (
            if (exists($node/connectors/connector)) then
                array {
                    for $link in $node/connectors/connector
                        return
                            map {
                                "id": $link/id/string(),
                                "operationModus": $link/operationModus/string(),
                                "name": $link/name/string(),
                                "label": $link/label/string(),
                                "protocol": $link/protocol/string(),
                                "status": $link/activity/string()
                            }
                }
            else
                array {}
        ),
                "attachments": (
            array {}
        ),
        "properties": map {
            "responsibles": (
                if (exists($node/properties/responsibles/node())) then 
                    array {
                        for $item in $node/properties/responsibles/responsible
                        return
                            map {
                                "givenName": $item/givenName/string(),
                                "familyName": $item/familyName/string(),
                                "email": $item/email/string(),
                                "phone": $item/phone/string()
                            }
                    }
                else 
                    array {}
            ),
            "notations": (
                if (exists($node/properties/notations/notation)) then
                    array {
                        for $link in $node/properties/notations/notation
                            return
                                map {
                                    "note": $link/note/string(),
                                    "user": $link/user/string(),
                                    "timestamp": $link/timestamp/string()
                                }
                    }
                else
                    array {}
            ),
            "style": (
                map {
                    "bgColor": $node/properties/style/bgColor/string(),
                    "graph": map {
                        "layout": $node/properties/style/graph/layout/string()
                    }
                }
            )
        }
    }
:)
};

declare function local:bankBalancesAsJson($node as node(), $pos as xs:integer) {
    map {
        "date": substring($node/@date/data(),1,10),
        "day": xs:integer($node/@day/data()),
        "amount": xs:double($node/@amount/data()),
        "saldo": xs:double($node/@saldo/data()),
        "Transactions": (
            if (exists($node/Transaction)) then
                array {
                    for $item in $node/Transaction
                    return
                        map {
                            "id": $item/@id/data(),
                            "amount": xs:double($item/@amount/data()),
                            "paymentDetail": $item/@paymentDetail/data(),
                            "Bookings": $item/Bookings/text()
                        }
                }
            else 
                []
        )
    }
};

(:
GET http://localhost:8080/exist/restxq/docman/tenants/test/years/2000/banks
GET /api/(xml|json)/tenants/test/years/2000/banks
:)
declare
    %rest:GET
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/banks")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("text/xml")
    %output:method("xml")

function dmbank:listBankAccountsXML($user as xs:string*, $tenant as xs:string, $year as xs:integer) {
	banking:listBankAccounts($main:home-data, $tenant, $year)
};

declare
    %rest:GET
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/banks")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("application/json")
    %output:method("json")	

function dmbank:listBankAccountsJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer) {
	banking:listBankAccounts($main:home-data, $tenant, $year)
};


(:
GET http://localhost:8080/exist/restxq/docman/tenants/test/years/2000/banks/12345678
GET /api/(xml|json)/tenants/test/years/2000/12345678
:)
declare
    %rest:GET
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/banks/{$bank-account}")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("text/xml")
    %output:method("xml")

function dmbank:listBankDetailXML($user as xs:string*, $tenant as xs:string, $year as xs:integer, $bank-account as xs:string) {
	banking:getBankAccount ($main:home-data, $tenant, $bank-account, $year)
};

declare
    %rest:GET
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/banks/{$bank-account}")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("application/json")
    %output:method("json")

function dmbank:listBankDetailJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer, $bank-account as xs:string) {
	let $bankAccount := banking:getBankAccount ($main:home-data, $tenant, $bank-account, $year)
    return
        map {
            "version": "1.0",
            "tenant": $tenant,
            "year": $year,
            "kto":  $bank-account,
            "hasOnlineBanking": xs:boolean($bankAccount/@hasOnlineBanking/data()),
            "Accountings": map {
                "saldoInitAmount": xs:decimal($bankAccount/Accountings/@saldoAmount/data()),
                "Accounting": 
                    for $bankAccount at $pos in $bankAccount/Accountings/Accounting
                    return
                        local:bankAccountAsJson($bankAccount, $pos)
            }
        }    
};


(:
GET http://localhost:8080/exist/restxq/docman/tenants/test/years/2000/banks/12345678/detail
GET /api/(xml|json)/tenants/test/years/2000/12345678/detail
:)
declare
    %rest:GET
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/banks/{$bank-account}/detail")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("text/xml")
    %output:method("xml")

function dmbank:listBankAccountDetailXML($user as xs:string*, $tenant as xs:string, $year as xs:integer, $bank-account as xs:string) {
	banking:getBankAccountDetail ($main:home-data, $tenant, $bank-account, $year)
};

declare
    %rest:GET
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/banks/{$bank-account}/detail")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("application/json")
    %output:method("json")

function dmbank:listBankAccountDetailJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer, $bank-account as xs:string) {
	banking:getBankAccountDetail ($main:home-data, $tenant, $bank-account, $year)
};


(: 
PUT	http://localhost:8080/exist/restxq/docman/test/2000/banks/12345678/detail
PUT /api/(xml|json)/tenants/test/years/2000/12345678/detail
:)
declare
    %rest:PUT("{$body}")
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/banks/{$bank-account}/detail")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:consumes("application/xml")
    %rest:consumes("text/xml")     

function dmbank:putBankAccountDetail($user as xs:string*, $tenant as xs:string, $year as xs:integer, $bank-account as xs:string, $body) {
    try {
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


(:
GET http://localhost:8080/exist/restxq/docman/tenants/test/years/2000/banks/12345678/accountings
GET /api/(xml|json)/tenants/test/years/2000/12345678/accountings
:)
declare
    %rest:GET
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/banks/{$bank-account}/accountings")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("text/xml")
    %output:method("xml")

function dmbank:listAccountingsXML($user as xs:string*, $tenant as xs:string, $year as xs:integer, $bank-account as xs:string) {
	banking:listAccountings($main:home-data, $tenant, $bank-account, $year)
};

declare
    %rest:GET
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/banks/{$bank-account}/accountings")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("application/json")
    %output:method("json")

function dmbank:listAccountingsJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer, $bank-account as xs:string) {
	let $BankAccount := banking:listAccountings($main:home-data, $tenant, $bank-account, $year)
    return
        map {
            "version": "1.0",
            "tenantId": $tenant,
            "yearId": $year,
            "accountId":  $bank-account,
            "name": "",
            "hasOnlineBanking": "true",
            "Accountings": map {
                "saldoInitAmount": 2365.31,
                "Accounting": 
                    for $Accounting at $pos in $BankAccount/Accountings/Accounting
                    return
                        local:bankAccountAsJson($Accounting, $pos)
            }
        }  
};


(: 
PUT	http://localhost:8080/exist/restxq/docman/tenants/test/years/2000/banks/12345678/accountings
PUT /api/(xml|json)/tenants/test/years/200012345678/accountings
:)
declare
    %rest:PUT("{$body}")
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/banks/{$bank-account}/accountings")

    %rest:query-param("user", "{$user}", "Guest")

function dmbank:putAccountings($user as xs:string*, $tenant as xs:string, $year as xs:integer, $bank-account as xs:string, $body) {
    try {
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

(: 
GET	http://localhost:8080/exist/restxq/docman/tenants/test/years/2000/banks/12345678/balancelist
GET /api/(xml|json)/tenants/test/years/0/banks/234/balancelist  - for a summary of all bank accounts
GET /api/(xml|json)/tenants/test/years/200012345678/banks/234/balancelist
:)
declare
    %rest:GET
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/banks/{$bank-account}/balancelist")
    %rest:query-param("user", "{$user}", "Guest")

function dmbank:getAccountBalanceListXML($user as xs:string*, $tenant as xs:string, $year as xs:integer, $bank-account as xs:string) {
    banking:getAccountBalanceList($main:home-data, $tenant, $year, $bank-account)
};

declare
    %rest:GET
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/banks/{$bank-account}/balancelist")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("application/json")
    %output:method("json")

function dmbank:getAccountBalanceListJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer, $bank-account as xs:string) {
    let $AccountBalanceList := banking:getAccountBalanceList($main:home-data, $tenant, $year, $bank-account)
    return
        map {
            "version": "1.0",
            "tenantId": $AccountBalanceList/@tenantId,
            "yearId": $AccountBalanceList/@yearId,
            "bankAccountId":  $AccountBalanceList/@bankAccountId,
            "bankName": $AccountBalanceList/@tenantId/@bankName,
            "unit": $AccountBalanceList/@unit,
            "saldoInitAmount": $AccountBalanceList/@saldoInitAmount,
            "numberOfPaymentTasks": $AccountBalanceList/@numberOfPaymentTasks,
            "Balances": (
                for $Balance at $pos in $AccountBalanceList/Balance
                return
                    local:bankBalancesAsJson($Balance, $pos)
            )
        }
};
