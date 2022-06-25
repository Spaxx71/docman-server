xquery version "3.0";


(:

https://dev.bintellix.com/exist-backend/rest/db/apps/docman/modules/banking/bankings_index.xqy

:)

import module namespace banking="http://bintellix.com/docman/banking" at "/db/apps/docman/modules/module_banking.xqm";
import module namespace hbci4java="http://exist-db.org/hbci4java/existdb" at "java:hbci4java.existdb.OnlineBankingModule"; 

let $home-web-gui := request:get-attribute('home-web-gui')
let $home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute('year')
let $bank-account := request:get-attribute('resource-id')

return
	<result src="banking_edit.xqy" bank-account="{$bank-account}">
		<BankAccount kto="{$bank-account}" year="{$year}">
			{banking:getBankAccount($home-data, $tenant, $bank-account, $year)/BankAccountDetail}
			{banking:listAccountings($home-data, $tenant, $bank-account, $year)/Accountings}
		</BankAccount>
	</result>
