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
let $document := request:get-attribute('resource-id')
let $transfer-collection := $home-data||'/'||$tenant||'/'||$year||'/transfer'
return

<html>
    <head>
		<title>Rename file</title>
    </head>
    <body>
		<ul class="Nav">
			<li><a href="{$home-web-gui}/{$tenant}/{$year}/transfer/{$document}/delete.html">Löschen…</a></li>
			<li><a href="{$home-web-gui}/{$tenant}/{$year}/transfer/{$document}">Download…</a></li>
		</ul>
		<div>
			<h4>Dateigröße: {xmldb:size($transfer-collection, $document)}</h4>
			<!-- http://localhost:8080/exist/rest/db/apps/docman/bin/transfer/transfer_upload_file_response.xqy -->
			<!-- {home-web-gui}/{$tenant}/{$year}/transfer/upload_file_response.html -->
			<form action="{$home-web-gui}/{$tenant}/{$year}/transfer/{$document}/rename_response.html" enctype="multipart/form-data" method="post">
				<fieldset>
					<legend>Dokument Name</legend>
					<label>Neuer Name: </label>
					<input type="text" name="name" size="50" value="{$document}" minlength="5" maxlength="254" pattern="[A-Za-z0-9_\-\.]+\.(pdf|tif|tiff|png|gif|txt|csv)" required="required"/>
					<input type="submit" value="Umbenennen"/>
				</fieldset>
			</form>
			<object data="{$home-web-gui}/{$tenant}/{$year}/transfer/{$document}" style="width:100%; height:80%" title="Preview of {$document}">
				<a href="{$home-web-gui}/{$tenant}/{$year}/transfer/{$document}">{$document}</a>
			</object>
			<a href="{$home-web-gui}/{$tenant}/{$year}/transfer/{$document}">{$document}</a>
		</div>
    </body>
</html>