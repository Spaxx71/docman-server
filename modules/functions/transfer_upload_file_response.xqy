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

import module namespace di="http://bintellix.com/docman/document-intelligence" at "/db/apps/docman/modules/module_document-intelligence.xqm";

(: http://localhost:8080/exist/rest/db/apps/docman/bin/transfer/transfer_upload_file_response.xqy :)

let $ct-home-web := request:get-attribute('home-web-gui')
let $ct-home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute('year')
let $transfer-collection := $ct-home-data||'/'||$tenant||'/'||$year||'/transfer'

let $filenameOrig := replace(request:get-uploaded-file-name('file'),'.*/','')

let $filenameParts := subsequence(analyze-string($filenameOrig, '(.*)(\.pdf|\.tif|.tiff|\.png|\.gif|\.txt|\.csv|\.xml)$')//fn:group, 1)
let $fileName := replace(translate($filenameParts[1],' ','_'),'[^A-Za-z0-9_+$-]+','-')
let $fileExt := lower-case($filenameParts[2])
let $stored-name := $fileName || $fileExt
let $store := xmldb:store($transfer-collection, $stored-name, request:get-uploaded-file-data('file'))
let $intel := di:ensure($ct-home-data, $tenant, $year, $stored-name, '', '')
return
<html>
	<head>
		<title>Datei hochladen - Rückmeldung</title>
		<meta http-equiv="refresh" content="10; URL='{$ct-home-web}/{$tenant}/{$year}/transfer/index.html'"/>
	</head>
	<body>
		<div>Date "{$fileName}{$fileExt}" wurde gespeichert "{concat('/',$tenant,'/',$year,'/transfer')}".</div>
		<br/>
		<a href="{$ct-home-web}/{$tenant}/{$year}/transfer/index.html">Zurück zum Transfer-Ordner</a>
	</body>
</html>