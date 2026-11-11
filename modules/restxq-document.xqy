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

(: /rest/db/apps/docman/modules/restxq-document.xqy :)
xquery version "3.1";

module namespace dmdocument="http://exist-db.org/apps/restxq/docman-document";

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace document="http://bintellix.com/docman/document" at "/db/apps/docman/modules/module_document.xqm";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http="http://expath.org/ns/http-client";
declare namespace rerr= "http://exquery.org/ns/restxq/error";
declare namespace docman = "http://docman.bintellix.com";

(: https://docman.com/exist-backend/rest/db/apps/docman/modules/module_document.xqm :)

(:
	GET http://localhost:8080/exist/restxq/docman/tenants/test/years/2020/binders/01/documents
	GET /api/tenants/test/years/2020/binders/01/documents
:)
declare
    %rest:GET
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/binders/{$binder}/documents")
    %output:media-type("text/xml")

    %rest:query-param("user", "{$user}", "Guest")
    %rest:query-param("scope", "{$scope}", "")

function dmdocument:listDocuments($user as xs:string*, $tenant as xs:string, $year as xs:integer, $binder as xs:string, $scope as xs:string*) {
	if ($scope = "folder") then
		document:listDocumentsForBinder($main:home-data, $tenant, $year, $binder)
	else
		document:listDocuments($main:home-data, $tenant, $year, $binder)
}; 


(: 
	GET http://localhost:8080/exist/restxq/docman/tenants/test/years/2020/binders/01/documents/xyz
	GET /api/tenants/test/years/2020/binders/01/documents/xyz
:)
declare
    %rest:GET
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/binders/{$binder}/documents/{$document-id}")
    %output:media-type("application/xml")

    %rest:query-param("user", "{$user}", "Guest")

function dmdocument:getDocument($user as xs:string*, $tenant as xs:string, $year as xs:integer, $binder as xs:string, $document-id as xs:string) {
	document:getDocument($main:home-data,$tenant,$year,$binder,$document-id)
};


(: 
	PUT	http://localhost:8080/exist/restxq/docman/tenants/test/years/2020/binders/01/documents/xyz
	PUT /api/tenants/test/years/2020/binders/01/documents/xyz	
:)
declare
    %rest:PUT("{$body}")
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/binders/{$binder}/documents/{$document-id}")

    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("application/xml")
function dmdocument:putDocument($user as xs:string*, $tenant as xs:string, $year as xs:integer, $binder as xs:string, $document-id as xs:string, $body) {
	try {
		let $result := 
			if (matches($document-id,'^PRO[0-9a-f\-]+$')) then
				document:updateDocument($main:home-data,$tenant,$year,$binder,$document-id,$body)
			else
				document:createDocument($main:home-data,$tenant,$year,$binder,$document-id,$body)
		return 
			if ($result/name()='error') then
				(
					<rest:response>
						<http:response status="501" message="An unexpected error occured at putDocument">
							<http:header name="Content-Language" value="en"/>
							<http:header name="Content-Type" value="text/html; charset=utf-8"/>
						</http:response>
					</rest:response>
					,
					<error>{$result}</error>
				)
			else
				<div>
					<ul class="Nav">
						<li><a href="/app/{$tenant}/{$year}/binders/{$binder}/{$document-id}/edit/{replace(name($body/Process/Tasks/*[1]),'Task$','')}.html">Dokument ansehen</a></li>
						<li><a href="/app/{$tenant}/{$year}/mail/index.html">Zurück zum Email Posteingang</a></li>
						<li><a href="/app/{$tenant}/{$year}/transfer/index.html">Zurück zum Transfer Ordner</a></li>
					</ul>
					<result>{$result}</result>
				</div>
	}
	catch * { 
		(
			<rest:response>
				<http:response status="501" message="An unexpected error occured at putDocument">
					<http:header name="Content-Language" value="en"/>
					<http:header name="Content-Type" value="text/html; charset=utf-8"/>
				</http:response>
			</rest:response>
			,
			<error>{$err:code, $err:value, $err:description, " module: ", $err:module, "(", $err:line-number, ",", $err:column-number, ")"}</error>
		)
	}
};


(: 
	POST	http://localhost:8080/exist/restxq/docman/tenants/test/years/2020/binders/documents/xyz
	POST /api/tenants/test/years/2020/binders/01/documents/xyz
:)
declare
    %rest:POST("{$body}")
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/binders/{$binder}/documents/{$document-id}")

    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("application/xml")
function dmdocument:postDocument($user as xs:string*, $tenant as xs:string, $year as xs:integer, $binder as xs:string, $document-id as xs:string, $body) {
	try {
		if ($body/Task/@type) then
			let $result := document:insertTask($main:home-data, $tenant, $year, $binder, $document-id, $body)
			return 
				if ($result/name()='error') then
					(
					<rest:response>
						<http:response status="501" message="An unexpected error occured at patchDocument">
							<http:header name="Content-Language" value="en"/>
							<http:header name="Content-Type" value="text/html; charset=utf-8"/>
						</http:response>
					</rest:response>
					,
					<error>{$result}</error>
					)
				else
					<ul class="Nav">
						<li><a href="/app/docman/{$tenant}/{$year}/binders/{$binder}/{$document-id}/search.html">Dokument bearbeiten</a></li>
						<li><a href="/app/{$tenant}/{$year}/transfer/index.html">Zurück zum Transfer Ordner</a></li>
					</ul>
		else
			(
				<rest:response>
					<http:response status="400" message="Invalid syntax for data">
						<http:header name="Content-Language" value="en"/>
						<http:header name="Content-Type" value="text/html; charset=utf-8"/>
					</http:response>
				</rest:response>
				,
				<error>No valid body data for task. {$body//text()} document:insertTask({$main:home-data}, {$tenant}, {$year}, {$document-id}, {$body})</error>
			)
	}
	catch * {
		<rest:response>
			<http:response status="501" message="An unexpected error occured at patchDocument">
				<http:header name="Content-Language" value="en"/>
				<http:header name="Content-Type" value="text/html; charset=utf-8"/>
			</http:response>
		</rest:response>
		,
		<error>{$err:code, $err:value, $err:description, " module: ", $err:module, "(", $err:line-number, ",", $err:column-number, ")"}</error>
	}
};


(: 
	DELETE http://localhost:8080/exist/restxq/docman/tenants/test/years/2020/binders/01/documents/xyz
	DELETE /api/tenants/test/years/2020/binders/01/documents/xyz	
:)
declare
    %rest:DELETE
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/binders/{$binder}/documents/{$document-id}")

    %rest:query-param("user", "{$user}", "Guest")

function dmdocument:deleteDocument($user as xs:string*, $tenant as xs:string, $year as xs:integer, $binder as xs:string, $document-id as xs:string) {
	document:deleteDocument($main:home-data,$tenant,$year,$binder,$document-id)
};
