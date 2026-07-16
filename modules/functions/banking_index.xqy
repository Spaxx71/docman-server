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

return
	<result src="banking_index.xqy">
		<Analysis type="linegraph">
			{banking:getAccountBalanceList($home-data, $tenant, $year, $bank-account)}
		</Analysis>
		{banking:listAccountings($home-data, $tenant, $bank-account, $year)}
		{account:listAccountsSimplified($home-data, $tenant, $year)}
	</result>