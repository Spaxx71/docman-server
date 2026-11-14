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

(: /rest/db/apps/docman/modules/restxq-email.xqy :)
(: Registrierung über /rest/db/apps/docman/initialize.xqy :)
xquery version "3.1";

module namespace dmemail="http://exist-db.org/apps/restxq/docman-email";

import module namespace email="http://bintellix.com/docman/email" at "/db/apps/docman/modules/module_email.xqm";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http="http://expath.org/ns/http-client";
declare namespace rerr= "http://exquery.org/ns/restxq/error";
declare namespace mail = "http://exist-db.org/xquery/mail";


(:
	GET http://localhost:8080/exist/restxq/docman/xml/tenants/test/emails
	GET /api/xml/tenants/test/emails
:)
declare
	%rest:GET
	%rest:path("/docman/xml/tenants/{$tenant}/emails")
	%rest:query-param("user", "{$user}", "Guest")
	%rest:query-param("folder", "{$folder}", "INBOX")
	%output:media-type("text/xml")
	%output:method("xml")
function dmemail:listEmailsXML($user as xs:string*, $tenant as xs:string, $folder as xs:string*) {
	try { email:read-emails($tenant, ($folder, 'INBOX')[1]) } catch * { <error>{$err:description}</error> }
};

declare
	%rest:GET
	%rest:path("/docman/json/tenants/{$tenant}/emails")
	%rest:query-param("user", "{$user}", "Guest")
	%rest:query-param("folder", "{$folder}", "INBOX")
	%output:media-type("application/json")
	%output:method("json")
function dmemail:listEmailsJSON($user as xs:string*, $tenant as xs:string, $folder as xs:string*) {
	dmemail:listEmailsXML($user, $tenant, $folder)
};


(:
	GET http://localhost:8080/exist/restxq/docman/xml/tenants/test/emails/1
	GET /api/xml/tenants/test/emails/1
:)
declare
	%rest:GET
	%rest:path("/docman/xml/tenants/{$tenant}/emails/{$message-id}")
	%rest:query-param("user", "{$user}", "Guest")
	%rest:query-param("folder", "{$folder}", "INBOX")
	%output:media-type("text/xml")
	%output:method("xml")
function dmemail:getEmailXML($user as xs:string*, $tenant as xs:string, $message-id as xs:integer, $folder as xs:string*) {
	try { email:read-message($tenant, $message-id, ($folder, 'INBOX')[1]) } catch * { <error>{$err:description}</error> }
};

declare
	%rest:GET
	%rest:path("/docman/json/tenants/{$tenant}/emails/{$message-id}")
	%rest:query-param("user", "{$user}", "Guest")
	%rest:query-param("folder", "{$folder}", "INBOX")
	%output:media-type("application/json")
	%output:method("json")
function dmemail:getEmailJSON($user as xs:string*, $tenant as xs:string, $message-id as xs:integer, $folder as xs:string*) {
	dmemail:getEmailXML($user, $tenant, $message-id, $folder)
};


(:
	GET http://localhost:8080/exist/restxq/docman/tenants/test/emails/1/attachments/1
	GET /api/tenants/test/emails/1/attachments/1
:)
declare
	%rest:GET
	%rest:path("/docman/xml/tenants/{$tenant}/emails/{$message-id}/attachments/{$attachment}")
	%output:media-type("text/xml")
	%output:method("xml")
	%rest:query-param("user", "{$user}", "Guest")
	%rest:query-param("folder", "{$folder}", "INBOX")
function dmemail:getEmailAttachmentXML($user as xs:string*, $tenant as xs:string, $message-id as xs:integer, $attachment as xs:integer, $folder as xs:string*) {
	try { email:read-attachment($tenant, $message-id, $attachment, ($folder, 'INBOX')[1]) } catch * { <error>{$err:description}</error> }
};

declare
	%rest:GET
	%rest:path("/docman/json/tenants/{$tenant}/emails/{$message-id}/attachments/{$attachment}")
	%output:media-type("application/json")
	%output:method("json")
	%rest:query-param("user", "{$user}", "Guest")
	%rest:query-param("folder", "{$folder}", "INBOX")
function dmemail:getEmailAttachmentJSON($user as xs:string*, $tenant as xs:string, $message-id as xs:integer, $attachment as xs:integer, $folder as xs:string*) {
	dmemail:getEmailAttachmentXML($user, $tenant, $message-id, $attachment, $folder)
};


(:
	GET /api/xml/tenants/{Mandant}/emails/folders
:)
declare
	%rest:GET
	%rest:path("/docman/xml/tenants/{$tenant}/emails/folders")
	%rest:query-param("user", "{$user}", "Guest")
	%output:media-type("text/xml")
	%output:method("xml")
function dmemail:listFoldersXML($user as xs:string*, $tenant as xs:string) {
	try { email:list-folders($tenant) } catch * { <error>{$err:description}</error> }
};

declare
	%rest:GET
	%rest:path("/docman/json/tenants/{$tenant}/emails/folders")
	%rest:query-param("user", "{$user}", "Guest")
	%output:media-type("application/json")
	%output:method("json")
function dmemail:listFoldersJSON($user as xs:string*, $tenant as xs:string) {
	dmemail:listFoldersXML($user, $tenant)
};


(:
	PUT /api/xml/tenants/{Mandant}/emails/{nr}?folder=INBOX&amp;seen=true&amp;flagged=false&amp;erledigt=true
	Leere Flags bleiben unverändert. Mindestens eines muss gesetzt sein.
:)
declare
	%rest:PUT
	%rest:path("/docman/xml/tenants/{$tenant}/emails/{$nr}")
	%rest:query-param("user", "{$user}", "Guest")
	%rest:query-param("folder", "{$folder}", "INBOX")
	%rest:query-param("seen", "{$seen}", "")
	%rest:query-param("flagged", "{$flagged}", "")
	%rest:query-param("erledigt", "{$erledigt}", "")
	%output:media-type("text/xml")
	%output:method("xml")
function dmemail:setFlagsXML($user as xs:string*, $tenant as xs:string, $nr as xs:integer, $folder as xs:string*, $seen as xs:string*, $flagged as xs:string*, $erledigt as xs:string*) {
	try { email:set-flags($tenant, ($folder, 'INBOX')[1], $nr, ($seen, '')[1], ($flagged, '')[1], ($erledigt, '')[1]) } catch * { <error>{$err:description}</error> }
};

declare
	%rest:PUT
	%rest:path("/docman/json/tenants/{$tenant}/emails/{$nr}")
	%rest:query-param("user", "{$user}", "Guest")
	%rest:query-param("folder", "{$folder}", "INBOX")
	%rest:query-param("seen", "{$seen}", "")
	%rest:query-param("flagged", "{$flagged}", "")
	%rest:query-param("erledigt", "{$erledigt}", "")
	%output:media-type("application/json")
	%output:method("json")
function dmemail:setFlagsJSON($user as xs:string*, $tenant as xs:string, $nr as xs:integer, $folder as xs:string*, $seen as xs:string*, $flagged as xs:string*, $erledigt as xs:string*) {
	dmemail:setFlagsXML($user, $tenant, $nr, $folder, $seen, $flagged, $erledigt)
};


(:
	POST /api/xml/tenants/{Mandant}/emails/{nr}/move?folder=INBOX&amp;to=archiv-2022
:)
declare
	%rest:POST
	%rest:path("/docman/xml/tenants/{$tenant}/emails/{$nr}/move")
	%rest:query-param("user", "{$user}", "Guest")
	%rest:query-param("folder", "{$folder}", "INBOX")
	%rest:query-param("to", "{$to}", "")
	%output:media-type("text/xml")
	%output:method("xml")
function dmemail:moveEmailXML($user as xs:string*, $tenant as xs:string, $nr as xs:integer, $folder as xs:string*, $to as xs:string*) {
	if (normalize-space(string($to)) = '') then
		<error>Zielordner to fehlt.</error>
	else
		try { email:move-message($tenant, ($folder, 'INBOX')[1], $nr, string($to)) } catch * { <error>{$err:description}</error> }
};

declare
	%rest:POST
	%rest:path("/docman/json/tenants/{$tenant}/emails/{$nr}/move")
	%rest:query-param("user", "{$user}", "Guest")
	%rest:query-param("folder", "{$folder}", "INBOX")
	%rest:query-param("to", "{$to}", "")
	%output:media-type("application/json")
	%output:method("json")
function dmemail:moveEmailJSON($user as xs:string*, $tenant as xs:string, $nr as xs:integer, $folder as xs:string*, $to as xs:string*) {
	dmemail:moveEmailXML($user, $tenant, $nr, $folder, $to)
};
