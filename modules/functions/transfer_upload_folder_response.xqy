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

let $filenames := request:get-uploaded-file-name('document[]')
let $filesizes := request:get-uploaded-file-size('document[]')
let $documents := request:get-uploaded-file-data('document[]')

let $ct-home-web := request:get-attribute('home-web-gui')
let $ct-home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute('year')
let $transfer-collection := $ct-home-data||'/'||$tenant||'/'||$year||'/transfer'
return

<html xmlns="http://www.w3.org/1999/xhtml" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:ev="http://www.w3.org/2001/xml-events">
	<head>
		<title>Verzeichnis hochladen - Rückmeldung</title>
		<meta http-equiv="refresh" content="10; URL='{$ct-home-web}/{$tenant}/{$year}/transfer/index.html'"/>
	</head>
	<body>
		Die folgenden Dateien wurden hochgeladen:
		<ul>
		{
			for $filenameOrig at $pos in $filenames
				let $filenameParts := subsequence(analyze-string($filenameOrig, '(.*)(\.pdf|\.tif|.tiff|\.png|\.gif|\.txt|\.csv|\.xml)$')//fn:group, 1)
				let $fileName := replace(translate($filenameParts[1],' ','_'),'[^A-Za-z0-9+$_-]+','-')
				let $fileExt := lower-case($filenameParts[2])

				let $storename := 
					if (doc-available($transfer-collection||'/'||$fileName||$fileExt)) then
						for $i in 1 to 1000000 
				  		return 
							if (doc-available($transfer-collection||'/'||$fileName||$fileExt)) then
								''
							else
								$fileName || $fileExt || $i
				  	else
						$fileName || $fileExt
				let $store := xmldb:store($transfer-collection, $storename, $documents[$pos])
				return 
            			<li>
					<a href="$ct-home-web/{$tenant}/{$year}/transfer/{$storename}">"{$storename}"</a> 
					({$filesizes[$pos]} bytes)
				</li>
		}
		</ul>

		<br/>
		<a href="{$ct-home-web}/{$tenant}/{$year}/transfer/index.html">Zurück zum Transfer-Ordner</a>

	</body>
</html>
