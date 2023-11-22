xquery version '3.1';

(:

https://dev.bintellix.com/exist-backend/rest/db/apps/docman/modules/account/tenant_index.xqy

:)

import module namespace user="http://bintellix.com/docman/user" at "/db/apps/docman/modules/module_user.xqm";

let $home-web-gui := request:get-attribute('home-web-gui')
let $home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $username := request:get-attribute('resource-id')

let $real-username := sm:id()/sm:id/sm:real/sm:username
let $groups := sm:id()/sm:id/sm:real/sm:groups/sm:group

(: the list of members for this tenant is been managed at /apps/docman/data/$tenant/tenant.dm.xml and updated by /apps/docman/initialize.xqy :)
return
	<result>
		{user:getUser($home-data, $tenant, $username)}
	</result>