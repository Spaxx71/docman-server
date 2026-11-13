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

module namespace email = "http://bintellix.com/docman/email";


declare function local:replaceAttributeValue($node as item(), $attributeName as xs:string, $attributeOldValue as xs:string, $attributeNewValue as xs:string) {

	if ($node instance of document-node()) then
		local:replaceAttributeValue($node/*, $attributeName, $attributeOldValue, $attributeNewValue)
	else if ($node instance of element()) then
		element {$node/name()} {
			for $attribute in $node/@*
			return
				if ($attribute/name()=$attributeName and $attribute/data() = $attributeOldValue) then
					attribute {$attributeName} {$attributeNewValue}
				else
					$attribute
			,
			for $subnode in $node/node()
			return
				local:replaceAttributeValue($subnode, $attributeName, $attributeOldValue, $attributeNewValue)
		}
	else if($node instance of comment()) then 
		comment { ' ' }
	else if($node instance of text()) then 
		$node
	else
		$node
};


declare function local:cleanupNamespace($n as node()) as node() {
	if($n instance of element()) then (
		element { if (namespace-uri($n) = '') then local-name($n) else node-name($n) } 
		{
			for $attribute in $n/@*
			return 
				attribute { if (namespace-uri($attribute) = '') then replace(local-name($attribute),'[^A-Za-z0-9+]','-') else replace(node-name($attribute),'[^A-Za-z0-9+]','-') } { $attribute/data() }
			,
			for $node in $n/node()
			return
				local:cleanupNamespace($node)
		}
	) else if($n instance of document-node()) then (
		document { local:cleanupNamespace($n/node()) }
	) else if($n instance of comment()) then (
		comment { ' ' }
	) else if($n instance of text()) then (
		$n
    ) else (
		$n
	)
};

declare function email:read-emails($tenant as xs:string) as item() {

	(: Crypto - created by util:base64-encode("abc"):)
	let $CryptoValue := "dTNqS0x1M2ozaDNmbjJqbjNKa2wx"
	

	(: https://javaee.github.io/javamail/docs/api/com/sun/mail/smtp/package-summary.html :)
	(: https://www.tutorialspoint.com/javamail_api/javamail_api_imap_servers.htm :)


	let $MailProperties :=
  		if ($tenant = 'bintellix' or $tenant = 'intersecurity') then
	   		<properties>
				<property name="mail.debug" value="false"/>
				<property name="mail.imaps.host" value="imap.bintellix.com"/>
				<property name="mail.imaps.user" value="accounting@bintellix.com"/>
				<property name="mail.imaps.password" value="{util:base64-decode($CryptoValue)}"/>
				<property name="mail.store.protocol" value="imaps"/>
				<property name="mail.imaps.ssl.enable" value="true"/>

		<!--
		<property name="mail.imap.port" value="993"/>
		<property name="mail.imap.ssl.enable" value="true"/>
		<property name="mail.imap.ssl.checkserveridentity" value="true"/>
		<property name="mail.imap.socketFactory.class" value="javax.net.ssl.SSLSocketFactory"/>
		<property name="mail.imap.socketFactory.fallback" value="993"/>
		<property name="mail.imap.socketFactory.port" value="false"/>
		<property name="mail.imaps.ssl.enable" value="true"/>
		<property name="mail.imaps.ssl.checkserveridentity" value="true"/>
		props.setProperty("mail.imap.connectiontimeout", "5000");
		props.setProperty("mail.imap.timeout", "5000");
		-->
	   		</properties>
		else 
			()
        
	let $lMailSessionHandle := mail:get-mail-session($MailProperties)

	let $lMailStoreHandle := mail:get-mail-store($lMailSessionHandle)

	let $lMailFolderHandle := mail:get-mail-folder($lMailStoreHandle, 'INBOX') 

	let $lMessageListHandle := mail:get-message-list($lMailFolderHandle)

	let $MessageList := mail:get-message-list-as-xml($lMessageListHandle, false())

	return 
	(: 
		mail:search-message-list()
	:)
		<result>	
			{$MessageList}

			{mail:close-message-list($lMessageListHandle)}
			{mail:close-mail-folder($lMailFolderHandle, false())}
			{mail:close-mail-store($lMailStoreHandle)}
		</result>	
};

declare function local:sent-by-servers($folder as xs:long, $message as element()?) as xs:string* {
	let $sent := normalize-space(string($message/*:sent[1]))
	let $number := string($message/@number)
	where $message and $sent and $number
	return
		try {
			let $search := <searchTerm type="sent" comparison="eq" format="yyyy-MM-dd" date="{substring($sent, 1, 10)}"/>
			let $handle := mail:search-message-list($folder, $search)
			let $listed := mail:get-message-list-as-xml($handle, true())
			let $hosts :=
				for $header in $listed//*:message[string(@number) = $number]/*:headers/*:header[lower-case(string(@name)) = 'received']
				let $after := tokenize(concat(' ', string($header/@value)), '\sby\s+')[2]
				let $host := replace(tokenize(normalize-space($after), '[^A-Za-z0-9.\-]+')[1], '^\.+|\.+$', '')
				where $host and matches($host, '[A-Za-z]')
				return $host
			let $unique := fold-left($hosts, (), function($found, $host) {
				if ($host = $found) then $found else ($found, $host)
			})
			return (mail:close-message-list($handle), $unique)
		} catch * {
			()
		}
};

declare function local:with-sent-by($node as node(), $servers as xs:string*) as node() {
	if (empty($servers)) then
		$node
	else if ($node instance of document-node()) then
		document {
			for $child in $node/node()
			return local:with-sent-by($child, $servers)
		}
	else if ($node instance of element() and local-name($node) = 'message') then
		element { node-name($node) } {
			$node/@*,
			$node/node(),
			element { QName(namespace-uri($node), 'received-by') } {
				for $server in $servers
				return element { QName(namespace-uri($node), 'server') } { $server }
			}
		}
	else if ($node instance of element()) then
		element { node-name($node) } {
			$node/@*,
			for $child in $node/node()
			return local:with-sent-by($child, $servers)
		}
	else
		$node
};

declare function email:read-message($tenant as xs:string, $id as xs:integer) as item() {

	(: Crypto - created by util:base64-encode("abc"):)
	let $CryptoValue := "dTNqS0x1M2ozaDNmbjJqbjNKa2wx"

	(: https://javaee.github.io/javamail/docs/api/com/sun/mail/smtp/package-summary.html :)
	(: https://www.tutorialspoint.com/javamail_api/javamail_api_imap_servers.htm :)
	let $MailProperties :=
  		if ($tenant = 'bintellix' or $tenant = 'intersecurity') then
	   		<properties>
				<property name="mail.debug" value="false"/>
				<property name="mail.imaps.host" value="imap.bintellix.com"/>
				<property name="mail.imaps.user" value="accounting@bintellix.com"/>
				<property name="mail.imaps.password" value="{util:base64-decode($CryptoValue)}"/>
				<property name="mail.store.protocol" value="imaps"/>
				<property name="mail.imaps.ssl.enable" value="true"/>
	   		</properties>
		else 
			()

        
	let $lMailSessionHandle := mail:get-mail-session($MailProperties)

	let $lMailStoreHandle := mail:get-mail-store($lMailSessionHandle)

	let $lMailFolderHandle := mail:get-mail-folder($lMailStoreHandle, 'INBOX') 

	let $lMessageListHandle := mail:get-message-list($lMailFolderHandle)

	let $cleaned := local:replaceAttributeValue(local:cleanupNamespace(mail:get-messages($lMailFolderHandle, ($id))), 'mime-type', 'application/octet-stream', 'application/pdf')
	let $message := if ($cleaned instance of document-node()) then $cleaned//*:message[1] else $cleaned//*:message[1]
	let $servers := local:sent-by-servers($lMailFolderHandle, $message)

	return 
		<result i="{$id}">	
			{local:with-sent-by($cleaned, $servers)}

			{mail:close-message-list($lMessageListHandle)}
			{mail:close-mail-folder($lMailFolderHandle, false())}
			{mail:close-mail-store($lMailStoreHandle)}
		</result>	
};


declare function email:read-attachment($tenant as xs:string, $mail-id as xs:integer, $att-number as xs:integer) as item() {

	(: Crypto - created by util:base64-encode("abc"):)
	let $CryptoValue := "dTNqS0x1M2ozaDNmbjJqbjNKa2wx"

	(: https://javaee.github.io/javamail/docs/api/com/sun/mail/smtp/package-summary.html :)
	(: https://www.tutorialspoint.com/javamail_api/javamail_api_imap_servers.htm :)
	let $MailProperties :=
  		if ($tenant = 'bintellix' or $tenant = 'intersecurity') then
	   		<properties>
				<property name="mail.debug" value="false"/>
				<property name="mail.imaps.host" value="imap.bintellix.com"/>
				<property name="mail.imaps.user" value="accounting@bintellix.com"/>
				<property name="mail.imaps.password" value="{util:base64-decode($CryptoValue)}"/>
				<property name="mail.store.protocol" value="imaps"/>
				<property name="mail.imaps.ssl.enable" value="true"/>
	   		</properties>
		else 
			()

        
	let $lMailSessionHandle := mail:get-mail-session($MailProperties)

	let $lMailStoreHandle := mail:get-mail-store($lMailSessionHandle)

	let $lMailFolderHandle := mail:get-mail-folder($lMailStoreHandle, 'INBOX') 

	let $lMessageListHandle := mail:get-message-list($lMailFolderHandle)

	let $Messages := local:cleanupNamespace(mail:get-messages($lMailFolderHandle, ($mail-id)))

	return 
		<result id="{$mail-id}" att-number="{$att-number}">
			{local:replaceAttributeValue($Messages/mail:message/mail:attachment[$att-number], 'mime-type', 'application/octet-stream', 'application/pdf')}

			{mail:close-message-list($lMessageListHandle)}
			{mail:close-mail-folder($lMailFolderHandle, false())}
			{mail:close-mail-store($lMailStoreHandle)}
		</result>	
};


