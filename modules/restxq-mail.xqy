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

(: /rest/db/apps/docman/modules/restxq-mail.xqy :)
(: Registrierung über /rest/db/apps/docman/initialize.xqy :)
xquery version "3.1";

module namespace dmmail="http://exist-db.org/apps/restxq/docman-mail";

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace email="http://bintellix.com/docman/email" at "/db/apps/docman/modules/module_email.xqm";
import module namespace di="http://bintellix.com/docman/document-intelligence" at "/db/apps/docman/modules/module_document-intelligence.xqm";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http="http://expath.org/ns/http-client";
declare namespace rerr= "http://exquery.org/ns/restxq/error";

(:
	message-Elemente aufsteigend nach @number anordnen.
	Die React-Liste verwendet die 1-basierte Position als Id, GET und POST die IMAP-Nummer.
:)
declare function local:order-messages($node as node()?) as node()? {
	if (empty($node)) then
		()
	else if ($node instance of document-node()) then
		document { local:order-messages($node/node()) }
	else if ($node instance of element() and local-name($node) = ("result", "messages")) then
		element { node-name($node) } {
			$node/@*,
			for $child in $node/node()
			order by
				if ($child instance of element() and local-name($child) = "message" and $child/@number castable as xs:integer) then
					xs:integer($child/@number)
				else
					-1
			return
				if ($child instance of element() and local-name($child) = "messages") then
					local:order-messages($child)
				else
					$child
		}
	else
		$node
};

declare function local:transfer-collection($tenant as xs:string, $year as xs:integer) as xs:string {
	let $year-col := concat($main:home-data, "/", $tenant, "/", $year)
	let $transfer := concat($year-col, "/transfer")
	return
		if (xmldb:collection-available($transfer)) then
			$transfer
		else if (xmldb:collection-available($year-col)) then
			let $created := xmldb:create-collection($year-col, "transfer")
			return $transfer
		else
			error(xs:QName("dmmail:missing-year"), concat("Jahr fehlt: ", $year))
};

declare function local:attachment-name($attachment as element()?, $id as xs:integer, $index as xs:integer) as xs:string {
	let $filename := normalize-space(string(($attachment/@filename)[1]))
	let $named := normalize-space(string(($attachment/@name)[1]))
	let $raw := if ($filename != "") then $filename else $named
	let $clean := replace(translate(replace(replace($raw, "\.PDF", ".pdf"), "utf\-8", ""), " ", "_"), "[^A-Za-z0-9_#\.\-]", "")
	return
		if ($clean = "" or $clean = ".") then
			concat("anhang-", $id, "-", $index)
		else
			$clean
};

(: Wie Transfer-Upload: bei Namenskollision Suffix -1, -2, … vor der Endung. :)
declare function local:unique-transfer-name($collection as xs:string, $name as xs:string) as xs:string {
	if (empty(index-of(xmldb:get-child-resources($collection), $name))
		and not(doc-available($collection || "/" || $name))
		and not(util:binary-doc-available($collection || "/" || $name))) then
		$name
	else
		let $parts := analyze-string($name, "^(.*?)(\.[^.]+)?$")//fn:group
		let $stem := string(($parts[1], $name)[1])
		let $ext := string(($parts[2], "")[1])
		let $free :=
			for $i in 1 to 10000
			let $candidate := $stem || "-" || $i || $ext
			where empty(index-of(xmldb:get-child-resources($collection), $candidate))
				and not(doc-available($collection || "/" || $candidate))
				and not(util:binary-doc-available($collection || "/" || $candidate))
			return $candidate
		return
			if (exists($free)) then
				$free[1]
			else
				error(xs:QName("dmmail:name-clash"), concat("Kein freier Name für: ", $name))
};

(:
	GET http://localhost:8080/exist/restxq/docman/xml/tenants/test/years/2020/mail
	GET /api/(xml|json)/tenants/test/years/2020/mail
	Das Jahr steht nur im Pfad. email:read-emails wählt die Inbox allein über den Mandanten.
:)
declare
	%rest:GET
	%rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/mail")
	%output:media-type("text/xml")
	%output:method("xml")
	%rest:query-param("user", "{$user}", "Guest")
function dmmail:listXML($user as xs:string*, $tenant as xs:string, $year as xs:integer) {
	local:order-messages(email:read-emails($tenant))
};

(:
	GET http://localhost:8080/exist/restxq/docman/xml/tenants/test/years/2020/mail/1
	GET /api/xml/tenants/test/years/2020/mail/1
	$id ist die IMAP-Nachrichtennummer (@number), kein Listenindex.
:)
declare
	%rest:GET
	%rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/mail/{$id}")
	%output:media-type("text/xml")
	%output:method("xml")
	%rest:query-param("user", "{$user}", "Guest")
function dmmail:messageXML($user as xs:string*, $tenant as xs:string, $year as xs:integer, $id as xs:integer) {
	email:read-message($tenant, $id)
};

(:
	POST http://localhost:8080/exist/restxq/docman/xml/tenants/test/years/2020/mail/1/attachment/1/transfer
	POST /api/xml/tenants/test/years/2020/mail/1/attachment/1/transfer
	$index ist 1-basiert, wie mail_attachment.xqy und mail_transfer.xqy.
:)
declare
	%rest:POST
	%rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/mail/{$id}/attachment/{$index}/transfer")
	%output:media-type("text/xml")
	%output:method("xml")
	%rest:query-param("user", "{$user}", "Guest")
	%rest:query-param("folder", "{$folder}", "INBOX")
function dmmail:transferXML($user as xs:string*, $tenant as xs:string, $year as xs:integer, $id as xs:integer, $index as xs:integer, $folder as xs:string*) {
	let $box := ($folder, "INBOX")[1]
	let $transfer-collection := local:transfer-collection($tenant, $year)
	let $attachment := email:read-attachment($tenant, $id, $index, $box)/*:attachment
	let $wanted := local:attachment-name($attachment, $id, $index)
	return
		if (empty($attachment) or string-length(normalize-space(string($attachment))) = 0) then
			<error>Anhang {$index} der Nachricht {$id} wurde im Ordner "{$box}" nicht gefunden.</error>
		else
			let $filename := local:unique-transfer-name($transfer-collection, $wanted)
			let $write := xmldb:store($transfer-collection, $filename, xs:base64Binary($attachment/text()), $attachment/@mime-type)
			let $message := email:read-message($tenant, $id, $box)
			let $from := string(($message//*:from)[1])
			let $subject := string(($message//*:subject)[1])
			let $intel := di:ensure($main:home-data, $tenant, $year, $filename, $from, $subject)
			return
				<result>
					<transfer document="{$filename}" mime-type="{$attachment/@mime-type}" status="stored"/>
				</result>
};

declare
	%rest:GET
	%rest:path("/docman/json/tenants/{$tenant}/years/{$year}/mail")
	%output:media-type("application/json")
	%output:method("json")
	%rest:query-param("user", "{$user}", "Guest")
function dmmail:listJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer) {
	dmmail:listXML($user, $tenant, $year)
};

declare
	%rest:GET
	%rest:path("/docman/json/tenants/{$tenant}/years/{$year}/mail/{$id}")
	%output:media-type("application/json")
	%output:method("json")
	%rest:query-param("user", "{$user}", "Guest")
function dmmail:messageJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer, $id as xs:integer) {
	dmmail:messageXML($user, $tenant, $year, $id)
};

declare
	%rest:GET
	%rest:path("/docman/xml/tenants/{$tenant}/years/{$year}/mail/{$id}/attachment/{$index}")
	%output:media-type("text/xml")
	%output:method("xml")
	%rest:query-param("user", "{$user}", "Guest")
function dmmail:attachmentXML($user as xs:string*, $tenant as xs:string, $year as xs:integer, $id as xs:integer, $index as xs:integer) {
	email:read-attachment($tenant, $id, $index)
};

declare
	%rest:GET
	%rest:path("/docman/json/tenants/{$tenant}/years/{$year}/mail/{$id}/attachment/{$index}")
	%output:media-type("application/json")
	%output:method("json")
	%rest:query-param("user", "{$user}", "Guest")
function dmmail:attachmentJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer, $id as xs:integer, $index as xs:integer) {
	dmmail:attachmentXML($user, $tenant, $year, $id, $index)
};

declare
	%rest:POST
	%rest:path("/docman/json/tenants/{$tenant}/years/{$year}/mail/{$id}/attachment/{$index}/transfer")
	%output:media-type("application/json")
	%output:method("json")
	%rest:query-param("user", "{$user}", "Guest")
	%rest:query-param("folder", "{$folder}", "INBOX")
function dmmail:transferJSON($user as xs:string*, $tenant as xs:string, $year as xs:integer, $id as xs:integer, $index as xs:integer, $folder as xs:string*) {
	dmmail:transferXML($user, $tenant, $year, $id, $index, $folder)
};
