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

https://dev.bintellix.com/exist-backend/rest/db/apps/docman/modules/banking/banking_index.xqy

:)

import module namespace account="http://bintellix.com/docman/account" at "/db/apps/docman/modules/module_account.xqm";

import module namespace banking="http://bintellix.com/docman/banking" at "/db/apps/docman/modules/module_banking.xqm";


let $home-web-gui := request:get-attribute('home-web-gui')
let $home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $bank-account := request:get-attribute('resource-id')
let $year := request:get-attribute('year')

let $owner := request:get-parameter('owner','')


return
	<result owner="{$owner}">
	{
		if ($owner != '') then
			let $account := account:getAccount ($home-data, $tenant, $year, $owner)
			return
				banking:getAccountingByIban($home-data, $tenant, $year, $account/@iban)/BankAccount
		else
			()
	}
	</result>