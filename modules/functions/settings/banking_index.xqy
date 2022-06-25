xquery version "3.0";


(:

https://dev.bintellix.com/exist-backend/rest/db/apps/docman/modules/banking/bankings_index.xqy

:)

import module namespace banking="http://bintellix.com/docman/banking" at "/db/apps/docman/modules/module_banking.xqm";
import module namespace years="http://bintellix.com/docman/years" at "/db/apps/docman/modules/module_years.xqm";


let $home-web-gui := request:get-attribute('home-web-gui')
let $home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $years := years:listYears($home-data, $tenant)

return
	<result src="bankings_index.xqy">
		{
			for $year in $years//Year/text()
		 	return
				banking:listBankAccounts ($home-data, $tenant, $year)
		}
	</result>
