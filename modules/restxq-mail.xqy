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
xquery version "3.1";

module namespace dmmail="http://exist-db.org/apps/restxq/docman-mail";

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace email="http://bintellix.com/docman/email" at "/db/apps/docman/modules/module_email.xqm";

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
function dmmail:transferXML($user as xs:string*, $tenant as xs:string, $year as xs:integer, $id as xs:integer, $index as xs:integer) {
	let $transfer-collection := $main:home-data || "/" || $tenant || "/" || $year || "/transfer"
	let $attachment := email:read-attachment($tenant, $id, $index)/*:attachment
	let $filename := replace(translate(replace(replace($attachment/@filename, "\.PDF", ".pdf"), "utf\-8", ""), " ", "_"), "[^A-Za-z0-9_#\.\-]", "")
	return
		if (index-of(xmldb:get-child-resources($transfer-collection), $filename) > 0) then
			<error>Filename "{$filename}" already exists.</error>
		else if (string-length($attachment/text()) = 0) then
			<error>No Attachment found.</error>
		else
			let $write := xmldb:store($transfer-collection, $filename, xs:base64Binary($attachment/text()), $attachment/@mime-type)
			return
				<result>
					<transfer document="{$filename}" mime-type="{$attachment/@mime-type}" status=""/>
				</result>
};
