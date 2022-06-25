xquery version "3.0";

(:
https://dev.bintellix.com/exist-backend/rest/db/apps/docman/modules/functions/attach/attachment.xqy

/app/bintelix/2019/binders/PRO1f97e590-64fd-479c-97e5-9064fd279c88/attach/attachment.xml?ref=PAY0f6a8823-38e3-4994-aa88-2338e35994dd
:)

import module namespace account="http://bintellix.com/docman/account" at "/db/apps/docman/modules/module_account.xqm";
import module namespace banking="http://bintellix.com/docman/banking" at "/db/apps/docman/modules/module_banking.xqm";
import module namespace document="http://bintellix.com/docman/document" at "/db/apps/docman/modules/module_document.xqm";


let $home-web-gui := request:get-attribute('home-web-gui') 
let $home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute('year')
let $document := request:get-attribute('resource-id')
let $file := request:get-attribute('ref')
let $path := request:get-attribute('path')
let $username := request:get-attribute('username')

let $file-name := tokenize($file,'/')[last()]
let $file-path := substring-before($file, $file-name)

return
	<result resource-type="attachment">
		<AttachmentTask type="doc-undefined" id="ACC{util:uuid()}" date="{substring(xs:string(current-date()),1,10)}" created="{current-dateTime()}" isMaster="false" user="{$username}" isStorno="false">
			<Notes/>
			<Files>
				<File src="{concat($file-path,$file-name)}" uploadSrc="{concat($file-path,$file-name)}" fileName="{substring-before($file-name,'.')}" fileExtension=".{lower-case(substring-after($file-name,'.'))}" uploadName="{$file-name}" mimeType="{xmldb:get-mime-type(xs:anyURI(concat($home-data, $file-path,$file-name)))}" type="delivery-note" doctype="doc-undefined" archived="false"/>			
			</Files>
			<Bookings/>
			<Amount value="0" unit="EUR"/>
			<DocName/>
			<RefID/>
			<Description/>
		</AttachmentTask>
	</result>