xquery version '3.1';

(:

https://dev.bintellix.com/exist-backend/rest/db/apps/docman/modules/functions/enter_index.xqy

:)

import module namespace account="http://bintellix.com/docman/account" at "/db/apps/docman/modules/module_account.xqm";

let $home-web-gui := request:get-attribute('home-web-gui')
let $home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')

return
	<result>
	</result>