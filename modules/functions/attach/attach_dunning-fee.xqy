xquery version "3.0";

(:

https://dev.bintellix.com/exist-backend/rest/db/apps/docman/modules/banking/banking_index.xqy

:)

import module namespace account="http://bintellix.com/docman/account" at "/db/apps/docman/modules/module_account.xqm";
import module namespace binder="http://bintellix.com/docman/binder" at "/db/apps/docman/modules/module_binder.xqm";
import module namespace document="http://bintellix.com/docman/document" at "/db/apps/docman/modules/module_document.xqm";

let $home-web-gui := request:get-attribute('home-web-gui')
let $home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute('year')
let $binder := request:get-attribute('binder')
let $document := request:get-attribute('resource-id')
let $file := request:get-attribute('ref')
let $path := request:get-attribute('path')
let $username := request:get-attribute('username')

let $file-name := tokenize($file,'/')[last()]
let $file-path := substring-before($file, $file-name)
let $src := concat($file-path, $file-name)
let $hash := document:hashcode($home-data, $src)

(: Note: the template in process_edit_html.xsl has to be updated the same :)
return
	<result resource-type="dunning-fee">
		<DunningFeeTask type="dunning-fee" id="ACC{util:uuid()}" date="" created="{current-dateTime()}" isMaster="false" user="{$username}">
			<Notes/>
			<Files>
				<File src="{$src}" uploadSrc="{$src}" fileName="{substring-before($file-name,'.')}" fileExtension=".{lower-case(substring-after($file-name,'.'))}" uploadName="{$file-name}" mimeType="{xmldb:get-mime-type(xs:anyURI(concat($home-data, $file-path,$file-name)))}" type="doc-dunning-fee" doctype="undefined" archived="false">
					{ if ($hash) then attribute hashcode { $hash } else () }
				</File>
			</Files>
			<Bookings>
				<Booking date="" quality="3" amountValue="" amountUnit="EUR" credit="" debit="6855" taxKey="1" taxAmount="0.0" refID="" description=""/>			
			</Bookings>
			<Amount value="-0.0" unit="EUR"/>
			<RefID/>
			<Description/>
		</DunningFeeTask>
	</result>
