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

/exist-backend/rest/db/apps/docman/modules/functions/banking_create-periodics.xqy
?home-data=/db/apps/docman/data/bintellix/2000/
&tenant=bintellix
&year=2000
&bank-account=222971400
&payment-id=PAY21c856b3530171993626a6a8e455c50f

:)

import module namespace banking="http://bintellix.com/docman/banking" at "/db/apps/docman/modules/module_banking.xqm";

let $home-web-gui := request:get-attribute('home-web-gui')
let $home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $bank-account-id := request:get-attribute('bank-account')
let $year := request:get-attribute('year')


let $createPeriodicPayments := banking:createPeriodicPayments ($home-data, $tenant, $year, $bank-account-id)

return
	<result>
		{$createPeriodicPayments}
	</result>