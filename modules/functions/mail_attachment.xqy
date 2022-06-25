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

https://dev.bintellix.com/exist-backend/rest/db/apps/docman/modules/mail/mail.xqy

:)

import module namespace email="http://bintellix.com/docman/email" at "/db/apps/docman/modules/module_email.xqm";


(: module namespace bixmail="http://www.bintellix.com/mail"; :)
	


let $tenant := request:get-attribute('tenant')
let $mail-id := request:get-attribute('resource-id')
let $att-number := request:get-attribute('attachment')
let $attachment := email:read-attachment($tenant, $mail-id, $att-number)/mail:attachment
return
	response:stream-binary($attachment/text(), $attachment/@mime-type, $attachment/@filename)


			(: <attachment name="{$message/mail:messages/mail:message/mail:attachment/@name}"
			     mime-type="{$message/messages/mail:message/mail:attachment/@mime-type}">
				{$message/mail:messages/mail:message/mail:attachment/text()}
			</attachment>
			:)


