xquery version "3.0";

(:
https://dev.bintellix.com/exist-backend/rest/db/apps/docman/modules/functions/attach/bank-transfer.xqy
:)

import module namespace banking="http://bintellix.com/docman/banking" at "/db/apps/docman/modules/module_banking.xqm";


let $home-web-gui := request:get-attribute('home-web-gui') 
let $home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute('year')
let $binder := request:get-attribute('binder')
let $resource-id := request:get-attribute('resource-id')
let $username := request:get-attribute('username')

let $ref := request:get-parameter('ref','')

return
	<result resource-type="bank-transfer">
	</result>