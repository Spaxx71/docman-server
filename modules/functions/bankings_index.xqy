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
(: import module namespace binder="http://bintellix.com/docman/binder" at "/db/apps/docman/modules/module_binder.xqm"; :)
import module namespace hbci4java="http://exist-db.org/hbci4java/existdb" at "java:hbci4java.existdb.OnlineBankingModule"; 

let $home-web-gui := request:get-attribute('home-web-gui')
let $home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute('year')

let $bank-account := request:get-parameter("bank-account", "")

return
	<result src="bankings_index.xqy">
			<Analysis type="linegraph">
			{ banking:getAccountBalanceList($home-data, $tenant, '0', $year) }
			<!-- { binder:getBinderBalanceList($home-data, $tenant, $year)} -->
			{
				for $bank-account-id in banking:listBankAccounts($home-data, $tenant, $year)/BankAccount/@kto
				return
					banking:getAccountBalanceList($home-data, $tenant, $bank-account-id, $year)
			}
		</Analysis>
		{banking:listBankAccounts ($home-data, $tenant, $year)}
	</result>
