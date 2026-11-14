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

module namespace dmhbci="http://exist-db.org/apps/restxq/docman-hbci";

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace tenant="http://bintellix.com/docman/tenant" at "/db/apps/docman/modules/module_tenant.xqm";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http="http://expath.org/ns/http-client";
declare namespace rerr= "http://exquery.org/ns/restxq/error";




(: 
RECEIVE Messages (at the HBCI/FinTS Module) from Docman
GET http://localhost:8080/exist/restxq/docman/test/hbci/1234567/receive.xml
GET /api/bix/hbci/12345678/receive.xml
Check if there is an Message element, if so delete it and send the value, if not wait 1 second.
:)
declare
    %rest:GET
    %rest:path("/docman/{$tenant}/hbci/{$bank-account}/receive")
    %output:media-type("text/xml")
    %rest:query-param("user", "{$user}", "Guest")
	%output:method("text")
	%output:media-type("text/plain") 
function dmhbci:getMessage($user as xs:string*, $tenant as xs:string, $bank-account as xs:string) {

	let $filename := concat('hbci_',$bank-account,'_send.dm.xml')
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
Send Messages (from the HBCI/FinTS Module) to Docman
PUT	http://localhost:8080/exist/restxq/docman/test/hbci/1234567/send.xml
:)
declare
    %rest:PUT("{$body}")
    %rest:path("/docman/{$tenant}/hbci/{$bank-account}/send")
	%rest:form-param("input","{$body}", "")
    %rest:query-param("user", "{$user}", "Guest")
	%output:method("text")
	%output:media-type("text/plain") 
function dmhbci:putMessage($user as xs:string*, $tenant as xs:string, $bank-account as xs:string, $body) {

	let $doc := doc(concat($main:home-data,'/','hbci_',$bank-account,'_receive.dm.xml'))
	let $add := update insert <Message timestamp="{current-dateTime()}">{$body}</Message> into $doc/Messages
	return
		"Message accepted"
};


(: 
Read Messages at the docman (send by the HBCI/FinTS Module)
GET http://localhost:8080/exist/restxq/docman/test/hbci/1234567/get-messages-from-hbci.json
GET /api/bix/hbci/12345678/get-messages-from-hbci.json
:)
declare
    %rest:GET
    %rest:path("/docman/{$tenant}/hbci/{$bank-account}/get-messages-from-hbci.json")
    %output:media-type("text/xml")
    %rest:query-param("user", "{$user}", "Guest")
	%output:method("json")
	%output:media-type("application/json") 
function dmhbci:getMessageFromHbci($user as xs:string*, $tenant as xs:string, $bank-account as xs:string) {

	let $data := doc(concat($main:home-data,'/hbci_',$bank-account,'_receive.dm.xml'))
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
				"text": $message/text()
			}
};


(: 
Send Message from Docman (to the HBCI/FinTS module)
PUT	http://localhost:8080/exist/restxq/docman/test/hbci/1234567/send-message-to-hbci.json
GET /api/bix/hbci/12345678/send-message-to-hbci.json
:)
declare
    %rest:POST
    %rest:path("/docman/{$tenant}/hbci/{$bank-account}/send-message-to-hbci.json")
    %rest:query-param("input", "{$input}", "")
	%rest:query-param("user", "{$user}", "Guest")
	%output:method("json")
	%output:media-type("application/json") 
function dmhbci:sendMessageToHbci($user as xs:string*, $tenant as xs:string, $bank-account as xs:string, $input) {
	let $filename := concat('hbci_',$bank-account,'_send.dm.xml')
	let $data := <Message>{$input}</Message>
	let $write := xmldb:store($main:home-data, $filename, $data)
	return
		<result>
		{"Send message '"|| string($input) ||"' to HBCI/FinTS module."}
		</result>
};

declare
    %rest:GET
    %rest:path("/docman/xml/tenants/{$tenant}/hbci/{$bank-account}/messages")
    %output:method("xml")
    %output:media-type("text/xml")
    %rest:query-param("user", "{$user}", "Guest")
function dmhbci:getMessageFromHbciXML($user as xs:string*, $tenant as xs:string, $bank-account as xs:string) {
	let $data := doc(concat($main:home-data,'/hbci_',$bank-account,'_receive.dm.xml'))
	return
		<Messages>{
			for $message at $id in $data/Messages/Message
			where $message/@timestamp > current-dateTime() - xs:dayTimeDuration("P1D")
			return
				<Message nr="{$id}" timestamp="{substring($message/@timestamp/data(),1,19)}">{$message/text()}</Message>
		}</Messages>
};

declare
    %rest:POST
    %rest:path("/docman/xml/tenants/{$tenant}/hbci/{$bank-account}/messages")
    %rest:query-param("input", "{$input}", "")
	%rest:query-param("user", "{$user}", "Guest")
	%output:method("xml")
	%output:media-type("application/xml")
function dmhbci:sendMessageToHbciXML($user as xs:string*, $tenant as xs:string, $bank-account as xs:string, $input) {
	dmhbci:sendMessageToHbci($user, $tenant, $bank-account, $input)
};
