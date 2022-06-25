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

https://dev.bintellix.com/exist-backend/rest/db/apps/docman/modules/banking/bankings_index.xqy

:)

import module namespace banking="http://bintellix.com/docman/banking" at "/db/apps/docman/modules/module_banking.xqm";

let $home-web-gui := request:get-attribute('home-web-gui')
let $home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $bank-account := request:get-attribute("bank-account")
let $year := request:get-attribute("year")

let $import := request:get-parameter("import","no")

let $from := request:get-parameter("from",format-date(current-dateTime()-xs:dayTimeDuration('P90D'),'[Y0000]-[M00]-[D00]'))
let $till := request:get-parameter("till",format-date(current-dateTime()-xs:dayTimeDuration('P1D'),'[Y0000]-[M00]-[D00]'))

let $bank := banking:getBankAccount($home-data, $tenant, $bank-account, $year)

let $bank-statement := banking:updateViaFinTS($home-data, $tenant, $bank-account, $year, $from, $till, $import!='no')

return
	<result src="banking_update.xqy">
		<Parameter>
			<From>{$from}</From>
			<Till>{$till}</Till>
			<BankAccount>{$bank-account}</BankAccount>
			{banking:listAccountingIDs($home-data, $tenant, $bank-account, $year)}
		</Parameter>
		{$bank}
		<FinTS>{$bank-statement}</FinTS>
		

	</result>
