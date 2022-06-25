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
/rest/db/apps/docman/modules/functions/bookings_index.xqy
:)

import module namespace bookings="http://bintellix.com/docman/bookings" at "/db/apps/docman/modules/module_bookings.xqm";

let $home-web-gui := request:get-attribute('home-web-gui')
let $home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute('year')
let $owner := request:get-parameter('owner',())

return
	(: the order is quite important, as listAccounts creates the numbers :)
	<result>
	{
		bookings:refreshAccounts($home-data, $tenant, $year)
	}
	{
		bookings:getAccoutSheet($home-data, $tenant, $year)
	}
	</result>

(:
:)