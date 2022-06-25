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

xquery version '3.1';

(:
https://dev.bintellix.com/exist-backend/rest/db/apps/docman/modules/account/tenant_index.xqy
:)

import module namespace banking="http://bintellix.com/docman/banking" at "/db/apps/docman/modules/module_banking.xqm";
import module namespace binder="http://bintellix.com/docman/binder" at "/db/apps/docman/modules/module_binder.xqm";

let $home-web-gui := request:get-attribute('home-web-gui')
let $home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute('year')

let $Collection := concat($home-data,'/',$tenant,'/',$year)
return
	<result>
		<Analysis type="linegraph">
			<!-- { banking:getAccountBalanceList($home-data, $tenant, '0', $year) } -->
			{ binder:getBinderBalanceList($home-data, $tenant, $year)}
			<!--
			{
				for $bank-account-id in banking:listBankAccounts($home-data, $tenant, $year)/BankAccount/@kto
				return
					banking:getAccountBalanceList($home-data, $tenant, $bank-account-id, $year)
			}
			-->
		</Analysis>
		{binder:listBinders($home-data, $tenant, $year)} 
		{banking:listBankAccounts($home-data, $tenant, $year)}
		<Dashboard>
		{
			let $Documents := collection($Collection)/Process[not(Tasks/DocumentTask) and not(Tasks/SimpleTask)]
			let $DocumentsCount := count($Documents)
			let $Mapped := count($Documents[.//PaymentTask])
			let $BankingsCount := count(collection($Collection)/BankAccount//Accounting)
			let $Transfer := count(xmldb:get-child-resources($Collection||'/transfer'))
			let $Email := 0
			let $Max := $Mapped + ($DocumentsCount - $Mapped) + ($BankingsCount - $Mapped) + $Transfer + $Email
			return
				<OverallCount count="{$Max}">
					<Mapped>{$Mapped}</Mapped>
					<DocumentsOpen>{$DocumentsCount - $Mapped}</DocumentsOpen>
					<BankingsOpen>{$BankingsCount - $Mapped}</BankingsOpen>
					<Transfer>{$Transfer}</Transfer>
					<Email>{$Email}</Email>
				</OverallCount>
		}
		</Dashboard>
	</result>