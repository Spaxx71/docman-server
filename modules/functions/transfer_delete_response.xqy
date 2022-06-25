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

xquery version "3.1";

let $home-web-gui := request:get-attribute('home-web-gui')
let $home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute('year')
let $file := request:get-attribute('resource-id')
let $transfer-collection := $home-data||'/'||$tenant||'/'||$year||'/transfer'
let $trash-collection := $home-data||'/'||$tenant||'/trash'

return
	try {
		let $move := xmldb:move($transfer-collection, $trash-collection,$file)
		return
			<result file="{$file}" status="{$move}"/>
	}
	catch * {
		<error>Datei '{$file}' konnte nicht gelöscht werden.</error>
	}
	