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

https://dev.bintellix.com/exist-backend/rest/db/apps/docman/modules/functions/binder_index.xqy

:)

import module namespace account="http://bintellix.com/docman/account" at "/db/apps/docman/modules/module_account.xqm";
import module namespace binder="http://bintellix.com/docman/binder" at "/db/apps/docman/modules/module_binder.xqm";
import module namespace document="http://bintellix.com/docman/document" at "/db/apps/docman/modules/module_document.xqm";

let $home-web-gui := request:get-attribute('home-web-gui')
let $home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute('year')
let $resource-id := request:get-attribute('resource-id')

let $owner := request:get-parameter('owner','')
let $attach := request:get-parameter('attach','')
let $ref := request:get-parameter('ref','')

return
	<result owner="{$owner}" attach="{$attach}" ref="{$ref}">
		{document:getDocument($home-data, $tenant, $year, (), $resource-id)}
		{
			if ($attach != '') then
				document:listDocuments($home-data, $tenant, $year, ())
			else if ($owner != '') then
				document:listDocuments($home-data, $tenant, $year, $owner)
			else
				binder:listBinders($home-data, $tenant, $year)
		}
		{account:listAccountsSimplified($home-data, $tenant, $year)}
	</result>