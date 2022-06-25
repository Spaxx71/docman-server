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
	

declare function email:read-message($tenant as xs:string, $id as xs:integer) as item() {

	(: Crypto :)
	let $CryptoValue := "NmloODM2c2tqYjM5emk5"

	(: https://javaee.github.io/javamail/docs/api/com/sun/mail/smtp/package-summary.html :)
	(: https://www.tutorialspoint.com/javamail_api/javamail_api_imap_servers.htm :)
	let $MailProperties :=
  		if ($tenant = 'bintellix') then
	   		<properties>
				<property name="mail.debug" value="false"/>
				<property name="mail.imaps.host" value="imap.bintellix.com"/>
				<property name="mail.imaps.user" value="accounting@bintellix.com"/>
				<property name="mail.imaps.password" value="{util:base64-decode($CryptoValue)}"/>
				<property name="mail.store.protocol" value="imaps"/>
				<property name="mail.imaps.ssl.enable" value="true"/>
	   		</properties>
		else if ($tenant = 'intersecurity') then
	   		<properties>
				<property name="mail.debug" value="false"/>
				<property name="mail.imaps.host" value="imap.intersecurity.net"/>
				<property name="mail.imaps.user" value="accounting@intersecurity.net"/>
				<property name="mail.imaps.password" value="{util:base64-decode('NmloODM2c2tqYjM5emk5bDllNw==')}"/>
				<property name="mail.store.protocol" value="imaps"/>
				<property name="mail.imaps.ssl.enable" value="true"/>
	   		</properties>
		else 
			()

        
	let $lMailSessionHandle := mail:get-mail-session($MailProperties)

	let $lMailStoreHandle := mail:get-mail-store($lMailSessionHandle)

	let $lMailFolderHandle := mail:get-mail-folder($lMailStoreHandle, 'INBOX') 

	let $lMessageListHandle := mail:get-message-list($lMailFolderHandle)

	return 
		<result i="{$id}">	
			{local:replaceAttributeValue( local:cleanupNamespace(mail:get-messages($lMailFolderHandle, ($id))) , 'mime-type', 'application/octet-stream', 'application/pdf')}

			{mail:close-message-list($lMessageListHandle)}
			{mail:close-mail-folder($lMailFolderHandle, false())}
			{mail:close-mail-store($lMailStoreHandle)}
		</result>	
};


declare function email:read-attachment($tenant as xs:string, $mail-id as xs:integer, $att-number as xs:integer) as item() {

	(: Crypto :)
	let $CryptoValue := "NmloODM2c2tqYjM5emk5"

	(: https://javaee.github.io/javamail/docs/api/com/sun/mail/smtp/package-summary.html :)
	(: https://www.tutorialspoint.com/javamail_api/javamail_api_imap_servers.htm :)
	let $MailProperties :=
  		if ($tenant = 'bintellix') then
	   		<properties>
				<property name="mail.debug" value="false"/>
				<property name="mail.imaps.host" value="imap.bintellix.com"/>
				<property name="mail.imaps.user" value="accounting@bintellix.com"/>
				<property name="mail.imaps.password" value="{util:base64-decode($CryptoValue)}"/>
				<property name="mail.store.protocol" value="imaps"/>
				<property name="mail.imaps.ssl.enable" value="true"/>
	   		</properties>
		else if ($tenant = 'intersecurity') then
	   		<properties>
				<property name="mail.debug" value="false"/>
				<property name="mail.imaps.host" value="imap.intersecurity.net"/>
				<property name="mail.imaps.user" value="accounting@intersecurity.net"/>
				<property name="mail.imaps.password" value="{util:base64-decode('NmloODM2c2tqYjM5emk5bDllNw==')}"/>
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


