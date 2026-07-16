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

/exist-backend/rest/db/apps/docman/modules/functions/banking_periodic-payment.xqy
/app/test/2000/banking/222971400/PAY21c856b3530171993626a6a8e455c50f/periodic-payment.html

:)

import module namespace account="http://bintellix.com/docman/account" at "/db/apps/docman/modules/module_account.xqm";

import module namespace banking="http://bintellix.com/docman/banking" at "/db/apps/docman/modules/module_banking.xqm";


let $home-web-gui := request:get-attribute('home-web-gui')
let $home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $bank-account-id := request:get-attribute('bank-account')
let $year := request:get-attribute('year')
let $resource-id := request:get-attribute('resource-id')

let $periodicPayment := banking:getPeriodicPayment($home-data, $tenant, $year, $bank-account-id, $resource-id)
return
	<result resource-id="{$resource-id}">
		{
			if ($periodicPayment != ()) then
				account:getAccount ($home-data, $tenant, $year, $periodicPayment/Tasks/InvoiceInTask/Owner/text())
			else
				<error>No periodic payment '{$resource-id}' exist. {$periodicPayment}</error>
		}
		{banking:getBankAccount ($home-data, $tenant, $bank-account-id, $year)}
		{$periodicPayment}
	</result>