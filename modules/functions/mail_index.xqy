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


(:

https://dev.bintellix.com/exist-backend/rest/db/apps/docman/modules/mail/mail_index.xqy

:)

declare namespace mail = "http://exist-db.org/xquery/mail";

(: module namespace bixmail="http://www.bintellix.com/mail"; :)

declare function local:get-attachement($lMailFolderHandle as xs:long, $number as xs:integer) as item() {
	let $Messages := mail:get-messages($lMailFolderHandle, ($number))
	
	return
		$Messages
		(:
		<attachment xx="" name="{$Messages/mail:message/mail:attachment/@name}"
			     mime-type="{$Messages/mail:message/mail:attachment/@mime-type}">
				{$Messages/mail:message/mail:attachment/text()}
		</attachment>
		:)
};	

declare function local:read-emails($tenant as xs:string) as item() {

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

let $tenant := request:get-attribute('tenant')
return
local:read-emails($tenant)