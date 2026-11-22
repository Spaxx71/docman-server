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
(: Registrierung über /rest/db/apps/docman/initialize.xqy :)
xquery version "3.1";

module namespace dmdocument="http://exist-db.org/apps/restxq/docman-document";

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace document="http://bintellix.com/docman/document" at "/db/apps/docman/modules/module_document.xqm";
import module namespace match="http://bintellix.com/docman/match" at "/db/apps/docman/modules/module_match.xqm";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http="http://expath.org/ns/http-client";
declare namespace rerr= "http://exquery.org/ns/restxq/error";
declare namespace docman = "http://docman.bintellix.com";

declare function local:match-days($value, $default as xs:integer) as xs:integer {
	let $text := normalize-space(string($value))
	return if ($text castable as xs:integer) then abs(xs:integer($text)) else $default
};

declare function local:match-money($value, $default as xs:decimal) as xs:decimal {
	let $text := translate(normalize-space(string($value)), ',', '.')
	return if ($text castable as xs:decimal) then abs(xs:decimal($text)) else $default
};

(: Ausgangspunkt ist der Vorgang. :)
declare function local:payment-suggestions($tenant as xs:string, $year as xs:integer, $document-id as xs:string, $days-before, $days-after, $tolerance) {
	match:suggestions($main:home-data, $tenant, $year, (), (), $document-id, local:match-days($days-before, 14), local:match-days($days-after, 21), local:match-money($tolerance, 0.01))
};

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

(:
	POST /api/xml/tenants/{tenant}/years/{year}/binders/{binder}/documents/{document-id}/notes
	Body: <Notes>...</Notes>
:)
declare
    %rest:POST("{$body}")
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/binders/{$binder}/documents/{$document-id}/notes")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:consumes("application/xml")
    %rest:consumes("text/xml")
    %output:media-type("application/xml")
function dmdocument:notes($user as xs:string*, $tenant as xs:string, $year as xs:integer, $binder as xs:string, $document-id as xs:string, $body as item()*) {
	let $text :=
		if ($body instance of element(Notes)) then
			string($body)
		else
			string(($body/Notes, $body//Notes)[1])
	return document:updateNotes($main:home-data, $tenant, $year, $binder, $document-id, $text)
};

declare
    %rest:GET
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/binders/{$binder}/documents")
    %output:media-type("application/json")
    %output:method("json")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:query-param("scope", "{$scope}", "")
function dmdocument:listDocumentsJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer, $binder as xs:string, $scope as xs:string*) {
	dmdocument:listDocuments($user, $tenant, $year, $binder, $scope)
};

declare
    %rest:GET
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/binders/{$binder}/documents/{$document-id}")
    %output:media-type("application/json")
    %output:method("json")
    %rest:query-param("user", "{$user}", "Guest")
function dmdocument:getDocumentJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer, $binder as xs:string, $document-id as xs:string) {
	dmdocument:getDocument($user, $tenant, $year, $binder, $document-id)
};

declare
    %rest:PUT("{$body}")
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/binders/{$binder}/documents/{$document-id}")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:consumes("application/json")
    %output:media-type("application/json")
    %output:method("json")
function dmdocument:putDocumentJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer, $binder as xs:string, $document-id as xs:string, $body) {
	dmdocument:putDocument($user, $tenant, $year, $binder, $document-id, $body)
};

declare
    %rest:POST("{$body}")
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/binders/{$binder}/documents/{$document-id}")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:consumes("application/json")
    %output:media-type("application/json")
    %output:method("json")
function dmdocument:postDocumentJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer, $binder as xs:string, $document-id as xs:string, $body) {
	dmdocument:postDocument($user, $tenant, $year, $binder, $document-id, $body)
};

declare
    %rest:DELETE
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/binders/{$binder}/documents/{$document-id}")
    %rest:query-param("user", "{$user}", "Guest")
    %output:media-type("application/json")
    %output:method("json")
function dmdocument:deleteDocumentJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer, $binder as xs:string, $document-id as xs:string) {
	dmdocument:deleteDocument($user, $tenant, $year, $binder, $document-id)
};

(: After-save SEPA transfer for SepaTransferTask :)
declare
    %rest:POST
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/binders/{$binder}/documents/{$document-id}/sepa-transfer")
    %rest:query-param("user", "{$user}", "Guest")
    %output:method("xml")
    %output:media-type("application/xml")
function dmdocument:sepaTransfer($user as xs:string*, $tenant as xs:string, $year as xs:integer, $binder as xs:string, $document-id as xs:string) {
	let $_ := request:set-attribute('home-data', $main:home-data)
	let $_ := request:set-attribute('tenant', $tenant)
	let $_ := request:set-attribute('year', string($year))
	let $_ := request:set-attribute('binder', $binder)
	let $_ := request:set-attribute('process-id', $document-id)
	let $_ := request:set-attribute('username', ($user, 'Guest')[1])
	return
		util:eval(xs:anyURI('/db/apps/docman/modules/functions/banking_sepa_transfer_process.xqy'))
};

(:
GET /api/(xml|json)/tenants/{t}/years/{y}/binders/{binder}/documents/{PRO}/payment-suggestions
Ausgangspunkt ist der Vorgang. Pfad nur hier, nicht zusätzlich in restxq-bank:
dieselbe URL in zwei Modulen verwirft eXist und antwortet mit HTTP 405.
:)
declare
    %rest:GET
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/binders/{$binder}/documents/{$document-id}/payment-suggestions")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:query-param("days-before", "{$days-before}", "")
    %rest:query-param("days-after", "{$days-after}", "")
    %rest:query-param("tolerance", "{$tolerance}", "")
    %rest:produces("application/xml")
    %rest:produces("text/xml")
    %output:method("xml")
    %output:media-type("application/xml")
function dmdocument:paymentSuggestionsXML($user as xs:string*, $tenant as xs:string, $year as xs:integer, $binder as xs:string, $document-id as xs:string, $days-before, $days-after, $tolerance) {
	local:payment-suggestions($tenant, $year, $document-id, $days-before, $days-after, $tolerance)
};

declare
    %rest:GET
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/binders/{$binder}/documents/{$document-id}/payment-suggestions")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:query-param("days-before", "{$days-before}", "")
    %rest:query-param("days-after", "{$days-after}", "")
    %rest:query-param("tolerance", "{$tolerance}", "")
    %rest:produces("application/json")
    %output:method("json")
    %output:media-type("application/json")
function dmdocument:paymentSuggestionsJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer, $binder as xs:string, $document-id as xs:string, $days-before, $days-after, $tolerance) {
	local:payment-suggestions($tenant, $year, $document-id, $days-before, $days-after, $tolerance)
};

declare function local:match-body($body) as element() {
	if ($body instance of element()) then $body else $body/*[1]
};

declare
    %rest:POST("{$body}")
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/binders/{$binder}/documents/{$document-id}/match-check")
    %rest:query-param("days-before", "{$days-before}", "")
    %rest:query-param("days-after", "{$days-after}", "")
    %rest:query-param("tolerance", "{$tolerance}", "")
    %rest:consumes("application/xml")
    %rest:produces("application/xml")
    %output:method("xml")
    %output:media-type("application/xml")
function dmdocument:matchCheckXML($tenant as xs:string, $year as xs:integer, $binder as xs:string, $document-id as xs:string, $days-before, $days-after, $tolerance, $body) {
	match:check($main:home-data, $tenant, $year, string(local:match-body($body)/@payment), local:match-days($days-before, 14), local:match-days($days-after, 21), local:match-money($tolerance, 0.01), local:match-body($body))
};

declare
    %rest:POST("{$body}")
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/binders/{$binder}/documents/{$document-id}/match-check")
    %rest:query-param("days-before", "{$days-before}", "")
    %rest:query-param("days-after", "{$days-after}", "")
    %rest:query-param("tolerance", "{$tolerance}", "")
    %rest:consumes("application/json")
    %rest:produces("application/json")
    %output:method("json")
    %output:media-type("application/json")
function dmdocument:matchCheckJSON($tenant as xs:string, $year as xs:integer, $binder as xs:string, $document-id as xs:string, $days-before, $days-after, $tolerance, $body) {
	match:check($main:home-data, $tenant, $year, string(local:match-body($body)/@payment), local:match-days($days-before, 14), local:match-days($days-after, 21), local:match-money($tolerance, 0.01), local:match-body($body))
};

declare
    %rest:POST("{$body}")
    %rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/binders/{$binder}/documents/{$document-id}/match-commit")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:query-param("tolerance", "{$tolerance}", "")
    %rest:consumes("application/xml")
    %rest:produces("application/xml")
    %output:method("xml")
    %output:media-type("application/xml")
function dmdocument:matchCommitXML($user as xs:string*, $tenant as xs:string, $year as xs:integer, $binder as xs:string, $document-id as xs:string, $tolerance, $body) {
	match:commit($main:home-data, $tenant, $year, string(local:match-body($body)/@payment), local:match-money($tolerance, 0.01), string(($user, 'Guest')[1]), local:match-body($body))
};

declare
    %rest:POST("{$body}")
    %rest:path("/docman/json/tenants/{$tenant}/years/{$year}/binders/{$binder}/documents/{$document-id}/match-commit")
    %rest:query-param("user", "{$user}", "Guest")
    %rest:query-param("tolerance", "{$tolerance}", "")
    %rest:consumes("application/json")
    %rest:produces("application/json")
    %output:method("json")
    %output:media-type("application/json")
function dmdocument:matchCommitJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer, $binder as xs:string, $document-id as xs:string, $tolerance, $body) {
	match:commit($main:home-data, $tenant, $year, string(local:match-body($body)/@payment), local:match-money($tolerance, 0.01), string(($user, 'Guest')[1]), local:match-body($body))
};
