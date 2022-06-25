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

xquery version '3.1';

(:
https://dev.bintellix.com/exist-backend/rest/db/apps/docman/modules/account/users_change-password_response.xqy
:)

import module namespace user="http://bintellix.com/docman/user" at "/db/apps/docman/modules/module_user.xqm";

let $home-web-gui := request:get-attribute('home-web-gui')
let $home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')

let $username := sm:id()/sm:id/sm:real/sm:username
let $groups := sm:id()/sm:id/sm:real/sm:groups/sm:group

return
	<result>
	{
		if (request:get-parameter("password","") = request:get-parameter("password2","none")) then
			user:setPassword($home-data, $tenant, $username, request:get-parameter("password",""))
		else
			<error>Invalid Password</error>
	} 
	</result>