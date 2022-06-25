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

https://dev.bintellix.com/exist-backend/rest/db/apps/docman/modules/account/account_edit.xqy

/app/bintellix/2019/banking/222971400/PAY0f6a8823-38e3-4994-aa88-2338e35994dd/assign-document.html?owner=70000

:)

import module namespace banking="http://bintellix.com/docman/banking" at "/db/apps/docman/modules/module_banking.xqm";
import module namespace account="http://bintellix.com/docman/account" at "/db/apps/docman/modules/module_account.xqm";
import module namespace document="http://bintellix.com/docman/document" at "/db/apps/docman/modules/module_document.xqm";


let $home-web-gui := request:get-attribute('home-web-gui')
let $home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute('year')
let $bank-account := request:get-attribute('bank-account')
let $resource-id := request:get-attribute('resource-id')
let $resource-type := request:get-attribute('resource-type')
let $owner := request:get-attribute('owner')

return
	if (not($owner)) then
		<result resource-type="{$resource-type}" resource-id="{$resource-id}">
			<Accounts>
			{
				for $account in account:listAccountsSimplified($home-data, $tenant, $year)/Account[tokenize(@classes)='debitor' or tokenize(@classes)='creditor' or tokenize(@classes)='bank' or tokenize(@classes)='self']
				order by $account/Name 
				return
					$account
			}
			</Accounts>
		</result>
	else
		let $documents := document:listDocuments($home-data, $tenant, $year, $owner)
		return
		<result resource-type="{$resource-type}" resource-id="{$resource-id}" owner="{$owner}">
			{account:getAccount ($home-data, $tenant, $year, $owner)}
			{banking:getAccountingById($home-data, $tenant, $bank-account, $year, $resource-id)}
			{document:listDocuments($home-data, $tenant, $year, $owner)}
			<bank-payments account="{$bank-account}">
			</bank-payments>
		</result>
