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
(: Registrierung über /rest/db/apps/docman/initialize.xqy :)
xquery version "3.1";

module namespace dmbank="http://exist-db.org/apps/restxq/docman-bank";

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace banking="http://bintellix.com/docman/banking" at "/db/apps/docman/modules/module_banking.xqm";
import module namespace user="http://bintellix.com/docman/user" at "/db/apps/docman/modules/module_user.xqm";

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
        "Additional": $node/Additional/text(),
        "booked": string($node/@booked),
        "bookedAmount": string($node/@booked-amount),
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
POST /api/xml/tenants/{t}/years/{y}/banks
Body: <BankAccount kto="..."><BankAccountDetail>...</BankAccountDetail></BankAccount>
:)
declare
    %rest:POST("{$body}")
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/banks")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:consumes("application/xml")
    %rest:consumes("text/xml")
    %output:media-type("text/xml")
    %output:method("xml")
function dmbank:createBankAccountXML($user as xs:string*, $tenant as xs:string, $year as xs:integer, $body) {
	try {
		let $_ := user:requirePermission($main:home-data, $tenant, 'year_settings', (), 'ADD')
		return banking:createBankAccount($main:home-data, $tenant, $year, $body)
	}
	catch * {
		(
			<rest:response>
				<http:response status="400" message="Bank create failed"/>
			</rest:response>
			,
			<error>{$err:code, $err:description}</error>
		)
	}
};

(:
DELETE /api/xml/tenants/{t}/years/{y}/banks/{kto}
:)
declare
    %rest:DELETE
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/banks/{$bank-account}")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("text/xml")
    %output:method("xml")
function dmbank:deleteBankAccountXML($user as xs:string*, $tenant as xs:string, $year as xs:integer, $bank-account as xs:string) {
	try {
		let $_ := user:requirePermission($main:home-data, $tenant, 'bankdetails', $bank-account, 'DELETE')
		return banking:deleteBankAccount($main:home-data, $tenant, $year, $bank-account)
	}
	catch * {
		(
			<rest:response>
				<http:response status="400" message="Bank delete failed"/>
			</rest:response>
			,
			<error>{$err:code, $err:description}</error>
		)
	}
};


declare function local:bankAccountings($tenant as xs:string, $year as xs:integer, $bank-account as xs:string) {
	let $bankAccount := banking:getBankAccount($main:home-data, $tenant, $bank-account, $year)
	return
		if ($bankAccount/Accountings) then
			$bankAccount/Accountings
		else
			<Accountings/>
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
	local:bankAccountings($tenant, $year, $bank-account)
};

declare
    %rest:GET
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/banks/{$bank-account}")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("application/json")
    %output:method("json")

function dmbank:listBankDetailJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer, $bank-account as xs:string) {
	local:bankAccountings($tenant, $year, $bank-account)
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
		let $_ := user:requirePermission($main:home-data, $tenant, 'bankdetails', $bank-account, 'CHANGE')
		return banking:storeBankAccount($main:home-data, $tenant, $year, $bank-account, $body)
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
	dmbank:listAccountingsXML($user, $tenant, $year, $bank-account)
};


(:
GET /api/xml/tenants/{tenant}/years/{year}/banks/{kto}/accountings/{PAY-id}.pdf
GET /exist/restxq/docman/xml/tenants/{tenant}/years/{year}/banks/{kto}/accountings/{PAY-id}.pdf
:)
declare
    %rest:GET
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/banks/{$bank-account}/accountings/{$accounting-id}.pdf")
    %rest:query-param("user", "{$user}", "Guest")

function dmbank:getAccountingPdf(
	$user as xs:string*,
	$tenant as xs:string,
	$year as xs:integer,
	$bank-account as xs:string,
	$accounting-id as xs:string
) {
	try {
		let $found := banking:getAccountingById($main:home-data, $tenant, $bank-account, $year, $accounting-id)
		return
			if (exists($found/self::error) or exists($found/error)) then
				(
					<rest:response>
						<http:response status="404" message="Accounting not found">
							<http:header name="Content-Language" value="en"/>
							<http:header name="Content-Type" value="text/xml; charset=utf-8"/>
						</http:response>
					</rest:response>
					,
					$found
				)
			else
				let $pdf := banking:getAccountingByIdAsPDF(
					$main:home-data,
					$main:home-web-gui,
					$tenant,
					$bank-account,
					$year,
					$accounting-id
				)
				return
					if ($pdf instance of xs:base64Binary) then
						(
							<rest:response>
								<output:serialization-parameters>
									<output:method value="binary"/>
									<output:media-type value="application/pdf"/>
								</output:serialization-parameters>
								<http:response status="200">
									<http:header name="Content-Type" value="application/pdf"/>
									<http:header name="Content-Disposition" value="inline; filename=&quot;{$accounting-id}.pdf&quot;"/>
								</http:response>
							</rest:response>
							,
							$pdf
						)
					else
						(
							<rest:response>
								<http:response status="400" message="PDF generation failed">
									<http:header name="Content-Language" value="en"/>
									<http:header name="Content-Type" value="text/xml; charset=utf-8"/>
								</http:response>
							</rest:response>
							,
							if ($pdf instance of element()) then $pdf
							else <error>PDF generation returned unexpected type</error>
						)
	}
	catch * {
		(
			<rest:response>
				<http:response status="400" message="PDF generation failed">
					<http:header name="Content-Language" value="en"/>
					<http:header name="Content-Type" value="text/xml; charset=utf-8"/>
				</http:response>
			</rest:response>
			,
			<error>{$err:code, $err:value, $err:description, " module: ", $err:module, "(", $err:line-number, ",", $err:column-number, ")"}</error>
		)
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
		let $_ := user:requirePermission($main:home-data, $tenant, 'bankmovements', $bank-account, 'CHANGE')
		(: Schmale Kategorie-Zuordnung: <BudgetCategory id="CAT" accounting="PAY…"/> :)
		let $category :=
			if ($body/self::BudgetCategory) then $body
			else if ($body/BudgetCategory) then $body/BudgetCategory
			else ()
		return
			if (exists($category) and normalize-space(string($category/@accounting)) != '') then
				banking:setAccountingBudgetCategory(
					$main:home-data,
					$tenant,
					$year,
					$bank-account,
					normalize-space(string($category/@accounting)),
					string($category/@id)
				)
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

(:
PUT /api/xml/tenants/{t}/years/{y}/banks/{kto}/budget-category
Body: <BudgetCategory id="CAT" accounting="PAY…"/>  (leere id = Attribut leeren)
:)
declare
    %rest:PUT("{$body}")
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/banks/{$bank-account}/budget-category")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:consumes("application/xml")
    %rest:consumes("text/xml")
    %output:media-type("text/xml")
    %output:method("xml")

function dmbank:putAccountingBudgetCategory(
	$user as xs:string*,
	$tenant as xs:string,
	$year as xs:integer,
	$bank-account as xs:string,
	$body
) {
	try {
		let $category :=
			if ($body/self::BudgetCategory) then $body
			else if ($body/BudgetCategory) then $body/BudgetCategory
			else ()
		let $accounting-id :=
			if (exists($category)) then normalize-space(string($category/@accounting))
			else ""
		let $category-id :=
			if (exists($category)) then string($category/@id)
			else normalize-space(string($body))
		return
			if ($accounting-id = '') then
				error(xs:QName('docman:AccountingMissing'), 'BudgetCategory/@accounting is required.')
			else
				banking:setAccountingBudgetCategory($main:home-data, $tenant, $year, $bank-account, $accounting-id, $category-id)
	}
	catch * {
		<rest:response>
			<http:response status="400" message="Invalid budget category update">
				<http:header name="Content-Language" value="en"/>
				<http:header name="Content-Type" value="text/xml; charset=utf-8"/>
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
	dmbank:getAccountBalanceListXML($user, $tenant, $year, $bank-account)
};


(:
Update Bank transactions via HBCI/FinTS online-banking

GET	http://localhost:8080/exist/restxq/docman/tenants/test/years/2000/banks/12345678/onlineupdate ?from=2000-01-01&till=2000-12-31&import=yes
GET /api/(xml|json)/tenants/test/years/0/banks/234/onlineupdate  - for a summary of all bank accounts
GET /api/(xml|json)/tenants/test/years/200012345678/banks/234/onlineupdate
:)

declare
    %rest:GET
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/banks/{$bank-account}/onlineupdate")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:query-param("from", "{$from-input}", "")
    %rest:query-param("till", "{$till-input}", "")
    %rest:query-param("import", "{$import}", "no")
    %output:method("json")

function dmbank:updateViaFinTSJson($user as xs:string*, $tenant as xs:string, $year as xs:integer, $bank-account as xs:string, $from-input, $till-input, $import)
{
    let $min-date := xs:date(concat($year, '-01-01'))
    let $max-date := xs:date(concat($year, '-12-31'))

    let $from-raw := if ($from-input = "") then format-date(current-dateTime()-xs:dayTimeDuration('P90D'), '[Y0000]-[M00]-[D00]') else $from-input
    let $till-raw := if ($till-input = "") then format-date(current-dateTime()-xs:dayTimeDuration('P1D'), '[Y0000]-[M00]-[D00]') else $till-input

    let $from := max(($min-date, xs:date($from-raw)))
    let $till := min(($max-date, xs:date($till-raw)))

    let $bank-statement := banking:updateViaFinTS($main:home-data, $tenant, $bank-account, $year, $from, $till, $import='yes')

    return
        if (string($year) != substring($from, 1, 4) or string($year) != substring($till, 1, 4)) then
            <result src="updateviafints">
                <error>The provided dates must be within the current year "{$year}". Given dates are from={$from} and till={$till}</error>
            </result>
        else
            <result src="updateviafints">
                <Parameter>
                    <From>{$from}</From>
                    <Till>{$till}</Till>
                    <BankAccount>{$bank-account}</BankAccount>
                    {(: banking:listAccountingIDs($main:home-data, $tenant, $bank-account, $year) :)}
                </Parameter>
                {(: banking:getBankAccount($main:home-data, $tenant, $bank-account, $year) :)}
                <FinTS>{$bank-statement}</FinTS>
            </result>
};

declare
    %rest:GET
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/banks/{$bank-account}/onlineupdate")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:query-param("from", "{$from-input}", "")
    %rest:query-param("till", "{$till-input}", "")
    %rest:query-param("import", "{$import}", "no")
    %output:method("xml")
    %output:media-type("text/xml")
function dmbank:updateViaFinTSXml($user as xs:string*, $tenant as xs:string, $year as xs:integer, $bank-account as xs:string, $from-input, $till-input, $import) {
	dmbank:updateViaFinTSJson($user, $tenant, $year, $bank-account, $from-input, $till-input, $import)
};

declare
    %rest:PUT("{$body}")
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/banks/{$bank-account}/detail")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:consumes("application/json")
    %output:method("json")
    %output:media-type("application/json")
function dmbank:putBankAccountDetailJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer, $bank-account as xs:string, $body) {
	dmbank:putBankAccountDetail($user, $tenant, $year, $bank-account, $body)
};

declare
    %rest:PUT("{$body}")
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/banks/{$bank-account}/accountings")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:consumes("application/json")
    %output:method("json")
    %output:media-type("application/json")
function dmbank:putAccountingsJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer, $bank-account as xs:string, $body) {
	dmbank:putAccountings($user, $tenant, $year, $bank-account, $body)
};
