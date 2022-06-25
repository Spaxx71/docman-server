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

let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute('year')
let $ct-home-web := request:get-attribute('home-web-gui')
let $ct-home-data := request:get-attribute('home-data')
let $transfer-collection := $ct-home-data||'/'||$tenant||'/'||$year||'/transfer'
return

<html>
    <head>
		<title>Upload file</title>
    </head>
    <body>
		<div>
			<!-- http://localhost:8080/exist/rest/db/apps/docman/bin/transfer/transfer_upload_file_response.xqy -->
			<!-- {$ct-home-web}/{$tenant}/{$year}/transfer/upload_file_response.html -->
			<form action="{$ct-home-web}/{$tenant}/{$year}/transfer/upload_file_response.html" enctype="multipart/form-data" method="post">
				<fieldset>
					<legend>Datei hochladen:</legend>
					<div class="fileUpload">
						<input type="file" name="file" accept=".pdf,.tif,.tiff,.png,.gif,.txt,.csv,.xml" class="upload"/>
						<input type="submit" value="Upload"/>
					</div>
				</fieldset>
			</form>
		</div>
    </body>
</html>