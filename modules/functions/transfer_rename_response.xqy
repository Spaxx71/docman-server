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

let $ct-home-web := request:get-attribute('home-web-gui')
let $ct-home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute('year')
let $file := request:get-attribute('resource-id')
let $name := request:get-parameter('name','')

let $transfer-collection := $ct-home-data||'/'||$tenant||'/'||$year||'/transfer'
let $pattern := '[A-Za-z0-9_\-\.]+\.(pdf|tif|tiff|png|gif|txt|csv)'

return

if (not(matches($name,$pattern))) then
	<error>Filename "{$name}" is not a valid file name. Must be {$pattern}.</error>

else if (index-of(xmldb:get-child-resources($transfer-collection),$name) > 0) then
	<error>Filename "{$name}" already exists.</error>

else 
	let $rename := xmldb:rename($transfer-collection, $file, $name)
	return
		<result from="{$file}" to="{$name}" status="{$rename}"/>
