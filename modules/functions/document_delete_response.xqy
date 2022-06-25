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


import module namespace document="http://bintellix.com/docman/document" at "/db/apps/docman/modules/module_document.xqm";


let $home-web-gui := request:get-attribute('home-web-gui')
let $home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute('year')
let $binder := request:get-attribute('binder')
let $resource-type := request:get-attribute('resource-type')
let $resource-id := request:get-attribute('resource-id')

return
	<result tenant="{$tenant}" resource="{$resource-type}" resource-id="{$resource-id}">
		{document:deleteDocument($home-data, $tenant, $year, $binder, $resource-id)}
	</result>