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

(: /rest/db/apps/docman/modules/restxq-transfer.xqy :)
(: Registrierung über /rest/db/apps/docman/initialize.xqy :)
xquery version "3.1";

module namespace dmtransfer="http://exist-db.org/apps/restxq/docman-transfer";

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace transfer="http://bintellix.com/docman/transfer" at "/db/apps/docman/modules/module_transfer.xqm";
import module namespace di="http://bintellix.com/docman/document-intelligence" at "/db/apps/docman/modules/module_document-intelligence.xqm";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http="http://expath.org/ns/http-client";
declare namespace rerr= "http://exquery.org/ns/restxq/error";

(: 
	GET http://localhost:8080/exist/restxq/docman/tenants/test/years/2020/transfer
	GET http://localhost:8080/exist/restxq/docman/tenants/test/years/2020/transfer?display=html
	GET /api/(xml|json)/tenants/test/years/2020/transfer
:)
declare
    %rest:GET
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/transfer")
    %output:media-type("text/xml")
	%output:method("xml")
    %rest:query-param("user", "{$user}", "Guest")
function dmtransfer:listTransferXML($user as xs:string*, $tenant as xs:string, $year as xs:integer) {
	transfer:index($main:home-data,$tenant,$year)
};

declare
    %rest:GET
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/transfer")
    %output:media-type("application/json")
	%output:method("json")
    %rest:query-param("user", "{$user}", "Guest")
function dmtransfer:listTransferJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer) {
	dmtransfer:listTransferXML($user, $tenant, $year)
};

(: 
GET http://localhost:8080/exist/restxq/docman/tenants/test/years/2020/transfer/xyz
GET http://localhost:8080/exist/restxq/docman/tenants/test/years/2020/transfer/xyz?display=html
:)
declare
    %rest:GET
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/transfer/{$document}")
    %output:method("binary")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:query-param("display", "{$display}", "")
function dmtransfer:transferFile($user as xs:string*, $display, $tenant as xs:string, $year as xs:string, $document) {
	let $filename := xs:anyURI($main:home-data||'/'||$tenant||'/'||$year||'/transfer/'||$document)
	let $lower := lower-case(string($document))
	let $mime :=
		if (ends-with($lower, '.pdf')) then 'application/pdf'
		else if (ends-with($lower, '.png')) then 'image/png'
		else if (ends-with($lower, '.gif')) then 'image/gif'
		else if (ends-with($lower, '.jpg') or ends-with($lower, '.jpeg')) then 'image/jpeg'
		else if (ends-with($lower, '.tif') or ends-with($lower, '.tiff')) then 'image/tiff'
		else xmldb:get-mime-type($filename)
	return
	(
		<rest:response xmlns:rest="http://exquery.org/ns/restxq">
			<output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
				<output:method value="binary"/>
				<output:media-type value="{$mime}"/>
			</output:serialization-parameters>
			<http:response status="200">
				<http:header name="Content-Type" value="{$mime}"/>
				<http:header name="Content-Disposition" value="inline"/>
			</http:response>
		</rest:response>
		,
		util:binary-doc($filename) 
	)
	
	(: unparsed-text($filename) :)
	(: binary-doc($filename) :)
	(: util:string-to-binary(unparsed-text($filename)) :)
};

(: 
POST http://localhost:8080/exist/restxq/docman/tenants/test/years/2020/transfer
POST http://localhost:8080/exist/restxq/docman/tenants/test/years/2020/transfer?display=html
:)
declare
    %rest:POST
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/transfer0")
	%rest:form-param("files", "{$files}", "no files")
	%rest:form-param("files[]", "{$filesArray}", "no files[]") 
	%rest:consumes("multipart/form-data")
    %output:media-type("text/xml")
    %rest:query-param("user", "{$user}", "Guest")
(: 
%rest:consumes("multipart/form-data")
%rest:form-param("files", "{$files}", "no file") 
:)
function dmtransfer:upload0($user, $tenant, $year, $files, $filesArray) {
	<files>
	{ 
		if ($files != "no files") then
			<yyy count="{count($files)}" keys="{map:keys($files)}">
			{  
				$files
			}
			</yyy>
		else
			<noFiles>{$files}</noFiles>
	}
	{ 
		if ($filesArray != "no files[]") then
			<yyy count="{count($filesArray)}" keys="{map:keys($filesArray)}">
			{  
				$filesArray
			}
			</yyy>
		else
			<noFilesArray>{$filesArray}</noFilesArray>
	}
  	</files>
};


declare
    %rest:POST("{$body}")
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/transfer")
	%rest:header-param("Content-Type","{$content-type}")
	%rest:header-param("Content-Length","{$content-length}")
	%rest:consumes("multipart/form-data")
    %output:media-type("text/xml")
    %rest:query-param("user", "{$user}", "Guest")
(: 	
%rest:consumes("multipart/mixed")
%rest:consumes("multipart/form-data")
%rest:form-param("files", "{$files}", "unknown")
:)
function dmtransfer:upload1($user, $tenant, $year, $content-type, $content-length, $body as item()*) {
	let $transfer-collection := $main:home-data||"/"||$tenant||"/"||$year||"/transfer"
	(: let $test := xmldb:store-as-binary($transfer-collection, "body.png", $body) :)
	return
		<files content-type="{$content-type}" content-length="{$content-length}">
		{
			let $boundary := replace($content-type, ".* boundary=\-+([^\\r\\n]+).*", "$1")
			let $files := fn:tokenize($body, "\-+(" || $boundary || ")\-*(\r\n)")
			for $file in $files
			where $file != ""
			return
				let $part := tokenize($file, '(\r\n\r\n|\r\r|\n\n)')
				let $headers := $part[1]
				let $data := substring($file, string-length($headers) +1 +4) (: CR+NL :)
				let $filenameOrig := fn:replace($headers, '.*filename="([^"]+)".*', '$1','s') (: Extrahiert den Dateinamen :)
				let $contentType := fn:replace($headers, '.*Content-Type: ([^\r\n]+).*', '$1','s') (: Extrahiert den Content-Type :)
				return
					(:
					<file filename="{$filenameOrig}" contentType="{$contentType}">
						<header>{$headers}</header>
						<body>{subsequence($part, 2)}</body>
					</file>
					:)
					let $filenameParts := subsequence(analyze-string($filenameOrig, '(.*)(\.pdf|\.tif|.tiff|\.png|\.gif|\.jpg|\.txt|\.csv|\.xml)$')//fn:group, 1)
					let $fileName := replace(translate($filenameParts[1],' ','_'),'[^A-Za-z0-9+$_-]+','-')
					let $fileExt := lower-case($filenameParts[2][last()])
					let $suffix := 
						if (doc-available($transfer-collection||'/'||$fileName||$fileExt) 
							or util:binary-doc-available($transfer-collection||'/'||$fileName||$fileExt)) then
							let $available-suffix := 
								for $i in 1 to 10000
								where not(doc-available($transfer-collection||'/'||$fileName||"-"||$i||$fileExt) 
										or util:binary-doc-available($transfer-collection||'/'||$fileName||"-"||$i||$fileExt))
								return "-" || $i
							return if (exists($available-suffix)) then $available-suffix[1] else "-1"
						else
							""
					let $storename := $fileName || $suffix || $fileExt
					return
						if ($storename != '') then
							let $store := xmldb:store($transfer-collection, $storename, $data)
							let $intel := di:ensure($main:home-data, $tenant, $year, $storename, '', '')
							(: let $store := xmldb:store($transfer-collection, $storename, $data, $contentType) :)
							(: let $store := xmldb:store-as-binary($transfer-collection, $storename, $data) :)
							return
								<file 
									filename="{$storename}"
									filenameOrig="{$filenameOrig}" 
									url="/api/tenants/{$tenant}/years/{$year}/transfer/{$storename}"
									contentType="{$contentType}"
									size="{string-length($data)}"
									/>
						else
							<error>File with name '{$filenameOrig}' and type '{$contentType}' could not be stored.</error>
		}
		</files>
};

(: 
POST http://localhost:8080/exist/restxq/docman/tenants/test/years/2020/transfer
POST http://localhost:8080/exist/restxq/docman/tenants/test/years/2020/transfer?display=html
:)
declare
    %rest:POST("{$body}")
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/transferXXX")
    %output:media-type("text/xml")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:query-param("display", "{$display}", "")

%rest:form-param("file", "{$file}", "()")

%rest:header-param("Content-Type", "{$Content-Type}", "()")
%rest:header-param("UP-FILENAME", "{$filename}", "()")
%rest:header-param("UP-SIZE", "{$size}", "()")
%rest:header-param("UP-TYPE", "{$type}", "()")

function dmtransfer:uploadXXX($user, $display, $tenant, $year, $body, $file, $Content-Type, $filename, $size, $type) {

	if (false()) then 
		let $filename := request:get-uploaded-file-name('file')
		let $transfer-collection := $main:home-data||'/'||$tenant||'/'||$year||'/transfer'
		let $store := xmldb:store($transfer-collection, $filename, request:get-uploaded-file-data('file'))
		return
			if ($display="html") then
				<html>
					<head>
						<title>Datei hochladen - Rückmeldung</title>
						<meta http-equiv="refresh" content="10; URL='{$main:home-web-gui}/{$tenant}/{$year}/transfer?display=html'"/>
					</head>
					<body>
						<div>File "{$filename}" has been stored at collection={$transfer-collection}.</div>
						<br/>
						<a href="{$main:home-web-api}/tenants/{$tenant}/years/{$year}/transfer?display=html">Zurück zum Transfer-Ordner</a>
					</body>
				</html>
			else
				<result>fine</result>
	else if (false()) then
(: read more: https://github.com/apb2006/uploadxq/tree/master/src/upload :)
(:
 		let $transfer-collection := $main:home-data||'/'||$tenant||'/'||$year||'/transfer'
		return (
				xmldb:store($transfer-collection, $filename, $content)
			,
    				<file name="{$filename}" size="{$size}"/>
    			)
:)
		<nothing/>
(:
		let $transfer-collection := $main:home-data||'/'||$tenant||'/'||$year||'/transfer'
		return
		if ($display="html") then
			<html xmlns="http://www.w3.org/1999/xhtml" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:ev="http://www.w3.org/2001/xml-events">
				<head>
					<title>Verzeichnis hochladen - Rückmeldung</title>
					<meta http-equiv="refresh" content="10; URL='{$main:home-web}/{$tenant}/{$year}/transfer/?display=html'"/>
				</head>
				<body>
					Die folgenden Dateien wurden hochgeladen:
					<ul>
					{for $filename at $pos in $filenames
			            let $storename := concat(format-dateTime(current-dateTime(),'[Y0001]-[M01]-[D01]'),'_',$filenames[$pos])
			            let $store := xmldb:store($transfer-collection, $storename, $documents[$pos])
			            return 
			            	<li><a href="/exist/apps/docman/{$tenant}/{$year}/transfer/{$storename}">"{$filenames[$pos]}"</a> ({$filesizes[$pos]} bytes)</li>}
					</ul>
			
					<br/>
					<a href="{$main:home-web-api}/tenants/{$tenant}/years/{$year}/transfer/?display=html">Zurück zum Transfer-Ordner</a>
			
				</body>
			</html>
		:)
	else
		<error>No file neither files have been sent file="{$file}" Content-Type="{$Content-Type}" filename="{$filename}" size="{$size}" type="{$type}"</error>

};


(: 
DELETE http://localhost:8080/exist/restxq/docman/tenants/test/years/2020/transfer/xyz
DELETE http://localhost:8080/exist/restxq/docman/tenants/test/years/2020/transfer/xyz?display=html
:)
declare
    %rest:DELETE
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/transfer/{$document}")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:query-param("display", "{$display}", "")
function dmtransfer:delete($user as xs:string*, $display, $tenant as xs:string, $year as xs:string, $document) {
	let $delete := transfer:delete($main:home-data,$tenant,$year,$document)
	return
	if ($display='html') then 
		<html xmlns="http://www.w3.org/1999/xhtml">
			<head>
				<title>Delete file from transfer</title>
			</head>
			<body>
				<div>
					Datei "{$document}" wurde gelöscht.
				</div>
			</body>
		</html>
	else
		"done"
};

declare
    %rest:POST("{$body}")
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/transfer/{$document}/notes")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:consumes("application/xml")
    %rest:consumes("text/xml")
    %output:media-type("application/xml")
function dmtransfer:notes($user as xs:string*, $tenant as xs:string, $year as xs:integer, $document as xs:string, $body as item()*) {
	let $text :=
		if ($body instance of element(Notes)) then
			string($body)
		else
			string(($body/Notes, $body//Notes)[1])
	return di:notes($main:home-data, $tenant, $year, $document, $text)
};

declare
    %rest:GET
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/transfer/intelligence-status")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("application/xml")
    %output:method("xml")
function dmtransfer:intelligenceStatus($user as xs:string*, $tenant as xs:string, $year as xs:integer) {
	let $home := $main:home-data
	let $path := $home || '/document-intelligence-status.xml'
	let $status := if (doc-available($path)) then doc($path)/* else <DocumentIntelligenceStatus state="unknown"/>
	let $queue := di:queue($home)[@tenant = $tenant][@year = string($year)]
	return
		<IntelligenceJob tenant="{$tenant}" year="{$year}">
			{$status}
			<Pending count="{count($queue)}">{
				for $item at $pos in $queue
				return
					<Item position="{$pos}" file="{$item/@source}" companion="{$item/@name}" status="{$item/@status}" updated="{$item/@updated}"/>
			}</Pending>
		</IntelligenceJob>
};

declare
    %rest:GET
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/transfer/{$document}/intelligence")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("application/xml")
    %output:method("xml")
function dmtransfer:intelligence($user as xs:string*, $tenant as xs:string, $year as xs:integer, $document as xs:string) {
	di:load($main:home-data, $tenant, $year, $document)
};

declare
    %rest:POST
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/transfer/{$document}/intelligence")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("application/xml")
    %output:method("xml")
function dmtransfer:refreshIntelligence($user as xs:string*, $tenant as xs:string, $year as xs:integer, $document as xs:string) {
	di:refresh-file($main:home-data, $tenant, $year, $document)
};

declare
    %rest:POST
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/transfer/{$document}/rename")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:query-param("name", "{$name}", "")
    %output:media-type("application/xml")
function dmtransfer:rename($user as xs:string*, $tenant as xs:string, $year as xs:integer, $document as xs:string, $name as xs:string*) {
	transfer:rename($main:home-data, $tenant, $year, $document, $name)
};

declare
    %rest:POST
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/transfer/{$document}/trash")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("application/xml")
function dmtransfer:trash($user as xs:string*, $tenant as xs:string, $year as xs:integer, $document as xs:string) {
	transfer:toTrash($main:home-data, $tenant, $year, $document)
};

(:
POST /xml/tenants/{tenant}/years/{year}/transfer/{document}/move-year?year=2024
Datei in den Transfer eines anderen Jahres verschieben.
:)
declare
    %rest:POST
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/transfer/{$document}/move-year")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:query-param("year", "{$to-year}", "")
    %output:media-type("text/xml")
    %output:method("xml")
function dmtransfer:moveYear($user as xs:string*, $tenant as xs:string, $year as xs:integer, $document as xs:string, $to-year as xs:string*) {
	try {
		let $target := normalize-space(string(($to-year[1], "")[1]))
		return
			if (not($target castable as xs:integer)) then
				error(xs:QName('transfer:YearMissing'), 'Zieljahr fehlt oder ist ungültig.')
			else
				transfer:moveToYear($main:home-data, $tenant, $year, $document, xs:integer($target))
	}
	catch * {
		(
			<rest:response>
				<http:response status="400" message="Move to year failed"/>
			</rest:response>
			,
			<error>{$err:code, $err:description}</error>
		)
	}
};

declare
    %rest:GET
    %rest:path("/docman/xml/tenants/{$tenant}/trash")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("application/xml")
    %output:method("xml")
function dmtransfer:trashIndex($user as xs:string*, $tenant as xs:string) {
	transfer:trashIndex($main:home-data, $tenant)
};

declare
    %rest:GET
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/transfer/{$document}")
    %output:method("binary")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:query-param("display", "{$display}", "")
function dmtransfer:transferFileJSON($user as xs:string*, $display, $tenant as xs:string, $year as xs:string, $document) {
	dmtransfer:transferFile($user, $display, $tenant, $year, $document)
};

declare
    %rest:POST("{$body}")
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/transfer")
    %rest:header-param("Content-Type","{$content-type}")
    %rest:header-param("Content-Length","{$content-length}")
    %rest:consumes("multipart/form-data")
    %output:media-type("application/json")
    %output:method("json")
    %rest:query-param("user", "{$user}", "Guest")
function dmtransfer:uploadJSON($user, $tenant, $year, $content-type, $content-length, $body as item()*) {
	dmtransfer:upload1($user, $tenant, $year, $content-type, $content-length, $body)
};

declare
    %rest:DELETE
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/transfer/{$document}")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:query-param("display", "{$display}", "")
    %output:media-type("application/json")
    %output:method("json")
function dmtransfer:deleteJSON($user as xs:string*, $display, $tenant as xs:string, $year as xs:string, $document) {
	dmtransfer:delete($user, $display, $tenant, $year, $document)
};

declare
    %rest:POST
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/transfer/{$document}/rename")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:query-param("name", "{$name}", "")
    %output:media-type("application/json")
    %output:method("json")
function dmtransfer:renameJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer, $document as xs:string, $name as xs:string*) {
	dmtransfer:rename($user, $tenant, $year, $document, $name)
};

declare
    %rest:POST
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/transfer/{$document}/trash")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("application/json")
    %output:method("json")
function dmtransfer:trashJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer, $document as xs:string) {
	dmtransfer:trash($user, $tenant, $year, $document)
};

declare
    %rest:POST
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/transfer/{$document}/move-year")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:query-param("year", "{$to-year}", "")
    %output:media-type("application/json")
    %output:method("json")
function dmtransfer:moveYearJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer, $document as xs:string, $to-year as xs:string*) {
	dmtransfer:moveYear($user, $tenant, $year, $document, $to-year)
};

declare
    %rest:GET
    %rest:path("/docman/json/tenants/{$tenant}/trash")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("application/json")
    %output:method("json")
function dmtransfer:trashIndexJSON($user as xs:string*, $tenant as xs:string) {
	dmtransfer:trashIndex($user, $tenant)
};
