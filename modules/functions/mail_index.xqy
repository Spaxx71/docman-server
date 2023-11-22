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

import module namespace email="http://bintellix.com/docman/email" at "/db/apps/docman/modules/module_email.xqm";

declare namespace mail = "http://exist-db.org/xquery/mail";

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



let $tenant := request:get-attribute('tenant')
return
email:read-emails($tenant)