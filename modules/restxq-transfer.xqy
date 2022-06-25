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

xquery version "3.0";

module namespace dmtransfer="http://exist-db.org/apps/restxq/docman-transfer";

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace transfer="http://bintellix.com/docman/transfer" at "/db/apps/docman/modules/module_transfer.xqm";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http="http://expath.org/ns/http-client";
declare namespace rerr= "http://exquery.org/ns/restxq/error";


(: 
GET https://docman.com/api/bintellix/2021/transfer/
GET http://localhost:8080/exist/restxq/docman/bix/2021/transfer
GET http://localhost:8080/exist/restxq/docman/bix/2021/transfer?display=html
:)
declare
    %rest:GET
    %rest:path("/docman/{$tenant}/{$year}/transfer")
    %output:media-type("text/xml")

    %rest:query-param("user", "{$user}", "Guest")
    %rest:query-param("display", "{$display}", "")
function dmtransfer:index($user as xs:string*, $display, $tenant as xs:string, $year as xs:integer) {
	if ($display="html") then
	(
		<rest:response xmlns:rest="http://exquery.org/ns/restxq">
			<http:response xmlns:http="http://expath.org/ns/http-client">
				<http:header name="Content-Language" value="en"/>
				<http:header name="Content-Type" value="text/html; charset=utf-8"/>
			</http:response>
		</rest:response>,
	
			let $xml := transfer:index($main:home-data,$tenant,$year)
			let $param := 	<parameters>
							<param name="home-web-gui" value="{$main:home-web-gui}"/>
							<param name="home-web-api" value="{$main:home-web-api}"/>
							<param name="home-data" value="{$main:home-data}"/>
							<param name="home-views" value="{$main:home-views}"/>
							<param name="tenant" value="{$tenant}"/>
							<param name="year" value="{$year}"/>
							<param name="path" value="/$tenant/$year/transfer"/>
						</parameters>
			let $data := transform:transform($xml, xs:anyURI("xmldb:exist://"||$main:home-views||"/transfer_index_html.xsl"), $param)
			let $result := transform:transform($data, xs:anyURI("xmldb:exist://"||$main:home-views||"/frame.xsl"), $param)
			return
				$result
	)
	else
		transfer:index($main:home-data,$tenant,$year)
};


(: 
GET http://localhost:8080/exist/restxq/docman/bix/2021/transfer/uploadSingleFile
GET http://localhost:8080/exist/restxq/docman/bix/2021/transfer/uploadSingleFile?display=html
:)
declare
    %rest:GET
    %rest:path("/docman/{$tenant}/{$year}/transfer/uploadSingleFile")
    %output:media-type("text/xml")

    %rest:query-param("user", "{$user}", "Guest")
    %rest:query-param("display", "{$display}", "")

function dmtransfer:uploadSingleFile($user as xs:string*, $display, $tenant as xs:string, $year as xs:string, $document) {
	transfer:uploadSingleFile($main:home-web, $main:home-data, $tenant, $year)
};


(: 
GET http://localhost:8080/exist/restxq/docman/bix/2021/transfer/uploadFolder
GET http://localhost:8080/exist/restxq/docman/bix/2021/transfer/uploadFolder?display=html
:)
declare
    %rest:GET
    %rest:path("/docman/{$tenant}/{$year}/transfer/uploadFolder")
    %output:media-type("text/xml")

    %rest:query-param("user", "{$user}", "Guest")
    %rest:query-param("display", "{$display}", "")

function dmtransfer:uploadFolder($user as xs:string*, $display, $tenant as xs:string, $year as xs:string, $document) {
	transfer:uploadFolder($main:home-web, $main:home-data, $tenant, $year)
};


(: 
GET http://localhost:8080/exist/restxq/docman/bix/2021/transfer/xyz
GET http://localhost:8080/exist/restxq/docman/bix/2021/transfer/xyz?display=html
:)
declare
    %rest:GET
    %rest:path("/docman/{$tenant}/{$year}/transfer/{$document}")
    %output:method("binary")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:query-param("display", "{$display}", "")
function dmtransfer:transfer($user as xs:string*, $display, $tenant as xs:string, $year as xs:string, $document) {
	let $filename := xs:anyURI($main:home-data||'/'||$tenant||'/'||$year||'/transfer/'||$document)
	return
	(
	<rest:response xmlns:rest="http://exquery.org/ns/restxq">
		<output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
			<output:method value="binary"/>
			<output:media-type value="xmldb:get-mime-type($filename)"/>
		</output:serialization-parameters>
	</rest:response>
	,
	util:binary-doc($filename) 
	)
	
	(: unparsed-text($filename) :)
	(: binary-doc($filename) :)
	(: util:string-to-binary(unparsed-text($filename)) :)
};


(: 
POST http://localhost:8080/exist/restxq/docman/bix/2021/transfer
POST http://localhost:8080/exist/restxq/docman/bix/2021/transfer?display=html
:)
declare
    %rest:POST("{$body}")
    %rest:path("/docman/{$tenant}/{$year}/transfer")
    %output:media-type("text/xml")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:query-param("display", "{$display}", "")

%rest:form-param("file", "{$file}", "()")

%rest:header-param("Content-Type", "{$Content-Type}", "()")
%rest:header-param("UP-FILENAME", "{$filename}", "()")
%rest:header-param("UP-SIZE", "{$size}", "()")
%rest:header-param("UP-TYPE", "{$type}", "()")

function dmtransfer:upload($user, $display, $tenant, $year, $body, $file, $Content-Type, $filename, $size, $type) {

	if (false()) then 
		let $filename := request:get-uploaded-file-name('file')
		let $transfer-collection := $main:home-data||'/'||$tenant||'/'||$year||'/transfer'
		let $store := xmldb:store($transfer-collection, $filename, request:get-uploaded-file-data('file'))
		return
		if ($display="html") then
			<html>
				<head>
					<title>Datei hochladen - Rückmeldung</title>
					<meta http-equiv="refresh" content="10; URL='{$main:home-web}/{$tenant}/{$year}/transfer?display=html'"/>
				</head>
				<body>
					<div>File "{$filename}" has been stored at collection={$transfer-collection}.</div>
					<br/>
					<a href="{$main:home-web-api}/{$tenant}/{$year}/transfer?display=html">Zurück zum Transfer-Ordner</a>
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
					<a href="{$main:home-web-api}/{$tenant}/{$year}/transfer/?display=html">Zurück zum Transfer-Ordner</a>
			
				</body>
			</html>
		:)
	else
		<error>No file neither files have been sent file="{$file}" Content-Type="{$Content-Type}" filename="{$filename}" size="{$size}" type="{$type}"</error>

};


(: 
DELETE http://localhost:8080/exist/restxq/docman/bix/2021/transfer/xyz
DELETE http://localhost:8080/exist/restxq/docman/bix/2021/transfer/xyz?display=html
:)
declare
    %rest:DELETE
    %rest:path("/docman/{$tenant}/{$year}/transfer/{$document}")
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
