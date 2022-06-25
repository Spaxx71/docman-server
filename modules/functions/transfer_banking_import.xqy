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
http://localhost:8080/exist/rest/db/apps/docman/bin/transfer/transfer_banking_import.xqy
:)

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace banking="http://bintellix.com/docman/banking" at "/db/apps/docman/modules/module_banking.xqm";
import module namespace tenant="http://bintellix.com/docman/tenant" at "/db/apps/docman/modules/module_tenant.xqm";


let $home-web-gui := request:get-attribute('home-web-gui')
let $home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute('year')
let $filename := request:get-attribute('resource-id')
let $bank-account := request:get-parameter('bank-account','')
let $import := request:get-parameter('import','no')

let $transfer-collection := $home-data||'/'||$tenant||'/'||$year||'/transfer'

let $from := if (request:get-parameter('from',()) castable as xs:date) then xs:date(request:get-parameter('from',())) else ()
let $till := if (request:get-parameter('till',()) castable as xs:date) then xs:date(request:get-parameter('till',())) else current-date()

let $csv-file := $transfer-collection||'/'||$filename
let $csv-binary := util:binary-doc($csv-file)
let $csv := util:binary-to-string($csv-binary)

let $banking := banking:importStatementCSV($home-data, $tenant, $csv, $from, $till, $bank-account, $import!='no') (: for preview empy date filter can be used :)


let $years-info :=  tenant:listYears($main:home-data, $tenant)
let $minBinderDate := min($years-info/Years/Year) || '-01-01'
let $maxBinderDate := max($years-info/Years/Year) || '-12-31'

let $fromDate := min($banking//Accounting/ValueDate/xs:date(.))
let $tillDate := max($banking//Accounting/ValueDate/xs:date(.))

return
	<result>
		<Parameter>
			<MinBinderDate>{$minBinderDate}</MinBinderDate>
			<MaxBinderDate>{$maxBinderDate}</MaxBinderDate>
			<From>{$fromDate}</From>
			<Till>{$tillDate}</Till>
		</Parameter>
		{banking:listBankAccounts($home-data,$tenant,format-date($till,'[Y0000]'))}
		<Preview>
		{$banking} 
		</Preview>
	</result>
