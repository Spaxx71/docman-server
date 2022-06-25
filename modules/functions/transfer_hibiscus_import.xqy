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
import module namespace binder="http://bintellix.com/docman/binder" at "/db/apps/docman/modules/module_binder.xqm";
import module namespace banking="http://bintellix.com/docman/banking" at "/db/apps/docman/modules/module_banking.xqm";


let $home-web-gui := request:get-attribute('home-web-gui')
let $home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute('year')
let $filename := request:get-attribute('resource-id')
let $transfer-collection := $home-data||'/'||$tenant||'/'||$year||'/transfer'

let $bank-account := request:get-parameter('bank-account','')
let $hibiscus-account := request:get-parameter('hibiscus-account','')
let $import := request:get-parameter('import','no')

let $from := if (request:get-parameter('from',()) castable as xs:date) then xs:date(request:get-parameter('from',())) else ()
let $till := if (request:get-parameter('till',()) castable as xs:date) then xs:date(request:get-parameter('till',())) else format-date(current-date(),'[Y0000]-[M00]-[D00]')

let $binder-info :=  binder:listBinders($main:home-data, $tenant, format-date(current-date(),'[Y0000]'))

let $minDate := if ($binder-info/Years/Year) then min($binder-info/Years/Year) || '-01-01' else format-date(current-date(),'[Y0000]') || '-01-01'
let $maxDate := if ($binder-info/Years/Year) then max($binder-info/Years/Year) || '-12-31' else format-date(current-date(),'[Y0000]') || '-12-31'

let $xmlHibiscus := doc(concat($home-data,'/',$tenant,'/',$year,'/transfer/',$filename))
let $xslt := doc('banking_import_hibiscus.xsl')

let $banking := banking:importHibiscus($home-data, $tenant, $xmlHibiscus, $from, $till, $hibiscus-account, $bank-account, $import!='no')

return
	<result>
		<Parameter>
			<Filename>{$filename}</Filename>
			<BankAccount>{$bank-account}</BankAccount>
			<HibiscusAccount>{$hibiscus-account}</HibiscusAccount>
			<MinBinderDate>{$minDate}</MinBinderDate>
			<MaxBinderDate>{$maxDate}</MaxBinderDate>
			<From>{$from}</From>
			<Till>{$till}</Till>
			{$binder-info}
		</Parameter>
		{banking:listBankAccounts($home-data,$tenant,format-date($till,'[Y0000]'))}
		<Hibiscus>
			<BankingStatements>
				{$banking}		
			</BankingStatements>
		</Hibiscus>
	</result>