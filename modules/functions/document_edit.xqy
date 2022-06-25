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

https://dev.bintellix.com/exist-backend/rest/db/apps/docman/modules/functions/root_index.xqy

:)

import module namespace account="http://bintellix.com/docman/account" at "/db/apps/docman/modules/module_account.xqm";

import module namespace binder="http://bintellix.com/docman/binder" at "/db/apps/docman/modules/module_binder.xqm";


let $home-web-gui := request:get-attribute('home-web-gui')
let $home-web-api := request:get-attribute('home-web-api')
let $home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute('year')
let $binder := request:get-attribute('binder')
let $resource-type := request:get-attribute('resource-type')
let $resource-id := request:get-attribute('resource-id')
let $file-id := request:get-attribute('file-id')

let $booking := doc($home-data||'/'||$tenant||'/'||$year||'/'||$binder||'/'||'/'||$resource-id||'.dm.xml')/Document[@type=('invoice_in','invoice_in_cancel','invoice_out','invoice_out_cancel')]
return
	<result>
		<Templates>
			<Accounting created="{current-dateTime()}" date="{$booking/@created}" type="S">
				<From kto="1371"/>
				<To kto="70000"/>
				<Amount value="0.00" unit="EUR"/>
				<Tax key="0" value="0.00" unit="EUR"/>
				<RefID/>
				<Description/>
			</Accounting>
		</Templates>
		{$booking}
		{doc($home-data||'/'||$tenant||'/accounts.dm.xml')}
	</result>