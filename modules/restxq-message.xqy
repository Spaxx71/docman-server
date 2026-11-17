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

(: /rest/db/apps/docman/modules/restxq-message.xqy :)
(: Registrierung über /rest/db/apps/docman/initialize.xqy :)
xquery version "3.1";

module namespace dmmessage="http://exist-db.org/apps/restxq/docman-message";

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace tenant="http://bintellix.com/docman/tenant" at "/db/apps/docman/modules/module_tenant.xqm";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http="http://expath.org/ns/http-client";
declare namespace rerr= "http://exquery.org/ns/restxq/error";


(: 
RECEIVE Messages (at the HBCI/FinTS Module) from Docman
	GET http://localhost:8080/exist/restxq/docman/tenants/test/messages/1234567/receive
	GET /api/tenants/test/messages/12345678/receive
Check if there is an Message element, if so delete it and send the value, if not wait 1 second.
:)
declare
    %rest:GET
    %rest:path("/docman/text/tenants/{$tenant}/messages/{$message-id}/receive")
    %output:media-type("text/xml")
    %rest:query-param("user", "{$user}", "Guest")
	%output:method("text")
	%output:media-type("text/plain") 
function dmmessage:getMessage($user as xs:string*, $tenant as xs:string, $message-id as xs:string) {

	let $filename := concat('hbci_',$message-id,'_send.dm.xml')
	let $data := doc(concat($main:home-data,'/',$filename))

	let $timeout := for $i in (1 to 60)
		let $data := doc(concat($main:home-data,'/',$filename))
		let $timeout := if (exists($data/Message)) then
				()
			else 
				util:wait(1000)
		return
			()
			
	let $data := "" || doc(concat($main:home-data,'/',$filename))/Message/text()
	return 
		if ($data != '') then
			let $reset := xmldb:store($main:home-data, $filename, <null_resource/>)
			return
				$data
		else
			""
};


(: 
Send Message to Docman (like a PIN for the HBCI/FinTS module)
POST http://localhost:8080/exist/restxq/docman/text/tenants/test/messages/1234567/receive
POST /api/text/tenants/bix/messages/12345678/receive
:)declare
    %rest:POST
    %rest:path("/docman/text/tenants/{$tenant}/messages/{$message-id}/receive")
    %rest:query-param("input", "{$input}", "")
	%rest:query-param("user", "{$user}", "Guest")
	%output:method("json")
	%output:media-type("application/json") 
function dmmessage:sendMessageToDocman($user as xs:string*, $tenant as xs:string, $message-id as xs:string, $input) {
	let $filename := concat('hbci_',$message-id,'_send.dm.xml')
	let $data := <Message>{$input}</Message>
	let $write := xmldb:store($main:home-data, $filename, $data)
	return
		"Send message '"|| string($input) ||"' to HBCI/FinTS module."
};


(: 
Send Messages (from the HBCI/FinTS Module) to Docman
	PUT	http://localhost:8080/exist/restxq/docman/tenants/test/messages/1234567/send
	PUT	/api/tenants/test/messages/1234567/send
:)
declare
    %rest:PUT("{$body}")
    %rest:path("/docman/text/tenants/{$tenant}/messages/{$message-id}/send")
	%rest:form-param("input","{$body}", "")
    %rest:query-param("user", "{$user}", "Guest")
	%output:method("text")
	%output:media-type("text/plain") 
function dmmessage:putMessage($user as xs:string*, $tenant as xs:string, $message-id as xs:string, $body) {

	let $doc := doc(concat($main:home-data,'/','hbci_',$message-id,'_receive.dm.xml'))
	let $text :=
		typeswitch ($body)
			case xs:string return $body
			case node() return serialize($body)
			default return string($body)
	let $type :=
		if (contains($text, '<Challenge type="flicker"')) then 'flicker'
		else if (contains($text, '<Challenge type="qr"')) then 'qr'
		else if (contains($text, '<Challenge type="photo"')) then 'photo'
		else if (contains($text, '<Challenge')) then 'challenge'
		else 'text'
	let $add := update insert <Message timestamp="{current-dateTime()}" type="{$type}">{$text}</Message> into $doc/Messages
	return
		"Message accepted"
};


(: 
Read Messages at the docman (send by the HBCI/FinTS Module)
GET http://localhost:8080/exist/restxq/docman/tenants/test/messages/1234567/get-messages-from-hbci.json
GET /api/json/tenants/test/messages/12345678/get-messages-from-hbci.json
:)
declare
    %rest:GET
    %rest:path("/docman/json/tenants/{$tenant}/messages/{$message-id}/get-messages-from-hbci.json")
    %output:media-type("text/json")
    %rest:query-param("user", "{$user}", "Guest")
	%output:method("json")
	%output:media-type("application/json") 
function dmmessage:getMessageFromHbciJson($user as xs:string*, $tenant as xs:string, $message-id as xs:string) {

	let $data := doc(concat($main:home-data,'/hbci_',$message-id,'_receive.dm.xml'))
	(:
	let $jdata := <json objects="json Message">{$data/Messages/*}</json>
	let $jdatatxt := json:serialize($jdata)
	:)
		for $message at $id in $data/Messages/Message
		where $message/@timestamp > current-dateTime() - xs:dayTimeDuration("P1D")
		return
			map {
				"nr": $id,
				"timestamp": substring($message/@timestamp/data(),1,19),
				"type": string(($message/@type, 'text')[1]),
				"text": string($message)
			}
};

declare
    %rest:GET
    %rest:path("/docman/xml/tenants/{$tenant}/messages/{$message-id}/get-messages-from-hbci")
    %output:method("xml")
    %output:media-type("text/xml")
    %rest:query-param("user", "{$user}", "Guest")
function dmmessage:getMessageFromHbciXml($user as xs:string*, $tenant as xs:string, $message-id as xs:string) {
	let $data := doc(concat($main:home-data,'/hbci_',$message-id,'_receive.dm.xml'))
	return
		<Messages>{
			for $message at $id in $data/Messages/Message
			where $message/@timestamp > current-dateTime() - xs:dayTimeDuration("P1D")
			return
				<Message nr="{$id}" timestamp="{substring($message/@timestamp/data(),1,19)}">{$message/text()}</Message>
		}</Messages>
};


(: 
Send Message from Docman (to the HBCI/FinTS module)
POST http://localhost:8080/exist/restxq/docman/tenants/test/messages/1234567/send-message-to-hbci.json
POST /api/xml/tenants/bix/messages/12345678/send-message-to-hbci.json
:)
(: REPLACED BY /receive (for sending PIN from Web and for receiving that at HBCI module)
declare
    %rest:POST
    %rest:path("/docman/xml/tenants/{$tenant}/messages/{$message-id}/send-message-to-hbci.json")
    %rest:query-param("input", "{$input}", "")
	%rest:query-param("user", "{$user}", "Guest")
	%output:method("xml")
	%output:media-type("application/xml") 
function dmmessage:sendMessageToHbciXml($user as xs:string*, $tenant as xs:string, $message-id as xs:string, $input) {
	let $filename := concat('hbci_',$message-id,'_send.dm.xml')
	let $data := <Message>{$input}</Message>
	let $write := xmldb:store($main:home-data, $filename, $data)
	return
		<result>
			{"Send message '"|| string($input) ||"' to HBCI/FinTS module."}
		</result>
};
:)
