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

module namespace account = "http://bintellix.com/docman/account";

(: Todo: version="1.0" resource-id="{$resource-id}" :)

declare function account:listAccounts ($home-data, $tenant, $year as xs:integer) {
	let $accounts := doc($home-data||'/'||$tenant||'/'||$year||'/accounts.dm.xml')
	return
		<Accounts tenant="{$tenant}">
			{for $account in $accounts/Accounts/Account[@type='ledger_account']
			 order by $account/Name
			 return
			 	$account
			}
			{for $account in $accounts/Accounts/Account[not(@type='ledger_account')]
			 order by $account/@kto
			 return
			 	$account
			}
		</Accounts>
};

declare function account:listAccountsSimplified ($home-data, $tenant, $year as xs:integer) {
	let $accounts := doc($home-data||'/'||$tenant||'/'||$year||'/accounts.dm.xml')
	return
		<Accounts tenant="{$tenant}">
			{for $account in $accounts/Accounts/Account[@type='ledger_account']
			 order by $account/Name
			 return
			 	<Account>
				 	{$account/@id}
					{$account/@kto}
					{$account/@type}
					{$account/@classes}
					{$account/BankAccounts}
					{$account/Name}
					{$account/Service}
					{$account/Notes}					
				</Account>
			}
			{for $account in $accounts/Accounts/Account[not(@type='ledger_account')]
			 order by $account/@kto
			 return
			 	<Account>
				 	{$account/@id}
					{$account/@kto}
					{$account/@type}
					{$account/@classes}
					{$account/BankAccounts}
					{$account/Name}
					{$account/Service}
					{$account/Notes}
				</Account>
			}
		</Accounts>
};


declare function account:getAccount ($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $resource-id as xs:string) { 
	let $account-id := lower-case($resource-id)
	let $accounts := doc($home-data||'/'||$tenant||'/'||$year||'/accounts.dm.xml')
	return
		(
			$accounts/Accounts/Account[@kto=$resource-id]
		,
			$accounts/Accounts/Account[lower-case(@id)=$account-id]
		)
};


declare function account:getAccountByIban ($home-data, $tenant, $year as xs:integer, $iban) {
	let $account := doc($home-data||'/'||$tenant||'/'||$year||'/accounts.dm.xml')/Accounts/Account[BankAccounts/BankAccount/@iban=$iban]
	return
		$account
};


declare function account:storeAccount ($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $resource-id as xs:string, $account-data) {
	let $account-id := lower-case($resource-id)
	let $accounts := doc($home-data||'/'||$tenant||'/'||$year||'/accounts.dm.xml')
	let $current := $accounts/Accounts/Account[lower-case(@id)=$account-id]
	return
		if (exists($current)) then
			let $update := update replace collection($home-data||'/'||$tenant)/Accounts/Account[lower-case(@id)=$account-id] with $account-data
			return
				<Account>

				</Account>
		else
			let $int := update insert $account-data into $accounts/Accounts  
			return
				<Account>
					<!-- {$accounts/Accounts/Account[lower-case(@id)=$account-id]/(*|@*)} -->
				</Account>
};


declare function account:deleteAccount ($home-data, $tenant, $year as xs:integer, $resource-id) {
	let $account-id := lower-case($resource-id)
	let $accounts := doc($home-data||'/'||$tenant|'/'||$year||'/accounts.dm.xml')
	let $account := $accounts/Accounts/Account[lower-case(@id)=$account-id]
	return
		if ($account = ()) then
			<error>Kein Account '$resource-i' vorhanden</error>
		else
			<Account>
				{update delete $account}
			</Account>

};


