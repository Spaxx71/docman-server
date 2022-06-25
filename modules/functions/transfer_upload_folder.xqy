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

let $home-web := request:get-attribute('home-web-gui')
let $home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute('year')
let $transfer-collection := $home-data||'/'||$tenant||'/'||$year||'/transfer'
return

<html>
    <head>
		<title>Upload document</title>
    </head>
    <body>
        <form action="{$home-web}/{$tenant}/{$year}/transfer/upload_folder_response.html" method="post" enctype="multipart/form-data">
            <fieldset>
				<legend>Verzeichnis hochladen:</legend>
                <input type="file" name="document[]" size="40" maxlength="1000" multiple="multiple" accept=".pdf,.tif,.tiff,.png,.gif,.txt,.csv,.xml"/>
            <!-- webkitdirectory="" directory="" mozdirectory="" -->
                <input type="submit" value="Upload"/>
            </fieldset>
        </form>
    </body>
</html>