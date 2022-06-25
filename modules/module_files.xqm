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

module namespace files = "http://bintellix.com/docman/files";

(: import module namespace crypto = "http://expath.org/ns/crypto"; 
import module "http://expath.org/ns/crypto";
:)

declare function files:index ($home-data as xs:string, $tenant as xs:string, $folder as xs:string) {
	let $collection-transfer := $home-data||'/'||$tenant||'/'||$folder||'/'
	let $documents := xmldb:get-child-resources($collection-transfer)
	return
	<CompanyPaperFiles version="1.0" tenantId="{$tenant}">
		<Files>
		{ 
		for $document in $documents
		order by $document 
		return
			<File name="{$document}" 
				size="{xmldb:size($home-data||'/'||$tenant||'/'||$folder||'/',$document)}"
				created="{xmldb:created($home-data||'/'||$tenant||'/'||$folder||'/',$document)}"
				/>
				(: hash-sha1="{crypto:hash(util:binary-doc($collection-transfer ||'/'||$document),'SHA1')}" :)
		}
		</Files>
	</CompanyPaperFiles>
};


declare function files:delete ($home-data as xs:string, $tenant as xs:string, $folder as xs:string, $document) {
	xmldb:remove($home-data||'/'||$tenant||'/'||$folder||'/', $document)
};


declare function files:uploadSingleFile($home-web as xs:string, $home-data as xs:string, $tenant as xs:string, $folder as xs:string) {
	let $transfer-collection := $home-data||'/'||$tenant||'/'||$folder||'/'
	return
	<html xmlns="http://www.w3.org/1999/xhtml">
		<head>
			<title>Upload single file</title>
		</head>
		<body>
			<div>
				<!-- http://localhost:8080/exist/rest/db/apps/docman/bin/transfer/transfer_upload_file_response.xqy -->
				<form action="{$home-web}/{$tenant}/{$folder}" enctype="multipart/form-data" method="post">
					<fieldset>
						<legend>Datei hochladen:</legend>
						<input type="file" name="file"/>
						<br/>
						<button type="submit" name="upload" value="file">Senden</button>
					</fieldset>
				</form>
			</div>
		</body>
	</html>
};

declare function files:uploadFolder($home-web as xs:string, $home-data as xs:string, $tenant as xs:string, $folder as xs:string) {
	let $transfer-collection := $home-data||'/'||$tenant||'/'||$folder||'/'
	return
	<html xmlns="http://www.w3.org/1999/xhtml" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:ev="http://www.w3.org/2001/xml-events">
	    <head>
			<title>Upload document</title>
	    </head>
	    <body>
	        <form action="{$home-web}/{$tenant}/{$folder}/" method="post" enctype="multipart/form-data">
	            <legend>Verzeichnis hochladen:</legend>
	            <input type="file" name="files[]" size="40" maxlength="100000" multiple="multiple" webkitdirectory="" directory="" mozdirectory=""/>
	            <br/>
	            <button type="submit" name="upload" value="folder">Senden</button>
	        </form>
	    </body>
	</html>
};
