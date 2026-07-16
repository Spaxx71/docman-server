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

(:

https://dev.bintellix.com/exist-backend/rest/db/apps/docman/modules/functions/banking_transfer.xqy

:)

import module namespace banking="http://bintellix.com/docman/banking" at "/db/apps/docman/modules/module_banking.xqm";

let $home-web-gui := request:get-attribute('home-web-gui')
let $home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute("year")
let $bank-account := request:get-attribute("bank-account")

let $request-data := util:base64-decode(request:get-data())

let $request-data as document-node() := request:get-data()
let $request := parse-xml($request-data)
 
(:
<TranasferRequest>
	<RecipientCountry></RecipientCountry>
	<RecipientBIC></RecipientBIC>
	<RecipientIBAN></RecipientIBAN>
	<RecipientName></RecipientName>
	<RecipientDate></RecipientDate>
	<RecipientAmount></RecipientAmount>
	<RecipientUnit></RecipientUnit>
	<RecipientUnit></RecipientUnit>
	<UsageText></UsageText>
</TransferReqeuest>
:)

let $recipientCountry := $request/RecipientCountry
let $recipientBic := $request/RecipientBIC
let $recipientIban := $request/RecipientIBAN
let $recipientName := $request/RecipientName
let $date := format-date($request/RecipientDate,'[Y0000]-[M00]-[D00]')
let $currencyAmount := $request/RecipientAmount
let $currencyUnit := $request/RecipientUnit
let $usageText := $request/UsageText

let $bank := banking:getBankAccount($home-data, $tenant, $bank-account, $year)
let $bank-transfer := banking:transferViaFinTS($home-data, $tenant, $year, $bank-account, $recipientCountry, $recipientBic, $recipientIban, $recipientName, $date, $currencyAmount, $currencyUnit, $usageText)
return
	<result src="banking_transfer.xqy">
		<Parameter>
			<Year>{$year}</Year>
			<BankAccount>{$bank-account}</BankAccount>
			<RecipientCountry>{$recipientCountry}</RecipientCountry>
			<RecipientBIC>{$recipientBic}</RecipientBIC>
			<RecipientIBAN>{$recipientIban}</RecipientIBAN>
			<RecipientName>{$recipientName}</RecipientName>
			<RecipientDate>{$date}</RecipientDate>
			<RecipientAmount>{$currencyAmount}</RecipientAmount>
			<RecipientUnit>{$currencyUnit}</RecipientUnit>
			<RecipientUnit>{$usageText}</RecipientUnit>
			<UsageText>{$usageText}</UsageText>
			<!-- {banking:listAccountingIDs($home-data, $tenant, $bank-account, $year)} -->
		</Parameter>
		{$bank}
		<FinTS>{$bank-transfer}</FinTS>
	</result>
