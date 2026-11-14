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


(:

https://dev.bintellix.com/exist-backend/rest/db/apps/docman/modules/mail/mail_record.xqy

:)

declare namespace mail = "http://exist-db.org/xquery/mail";

import module namespace email="http://bintellix.com/docman/email" at "/db/apps/docman/modules/module_email.xqm";
import module namespace di="http://bintellix.com/docman/document-intelligence" at "/db/apps/docman/modules/module_document-intelligence.xqm";
	




let $ct-home-web := request:get-attribute('home-web-gui')
let $ct-home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute('year')
let $id := request:get-attribute('resource-id')
let $number := xs:integer(request:get-attribute('attachment'))

let $transfer-collection := $ct-home-data||'/'||$tenant||'/'||$year||'/transfer'

let $attachment := email:read-attachment($tenant, $id, $number)/*:attachment
let $filename :=  replace(translate(replace(replace($attachment/@filename,'\.PDF','.pdf'),'utf\-8',''),' ','_'),'[^A-Za-z0-9_#\.\-]','')
return
	if (index-of(xmldb:get-child-resources($transfer-collection), $filename) > 0) then
		<error>Filename "{$filename}" already exists.</error>
	else if (string-length($attachment/text()) = 0) then
		<error>No Attachment found.</error>
	else
		let $write := xmldb:store($transfer-collection, $filename, xs:base64Binary($attachment/text()), $attachment/@mime-type)
		let $message := email:read-message($tenant, $id)
		let $from := string(($message//*:from)[1])
		let $subject := string(($message//*:subject)[1])
		let $intel := di:ensure($ct-home-data, $tenant, $year, $filename, $from, $subject)
		(: let $write := xmldb:store-as-binary($transfer-collection, $filename, xs:base64Binary$attachment/text())) :)
		return
			<result>
				<transfer document="{$filename}" mime-type="{$attachment/@mime-type}" status=""/>
			</result>
