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
	let $accounts := doc($home-data||'/'||$tenant||'/'||$year||'/accounts.dm.xml')
	let $by-id := $accounts/Accounts/Account[lower-case(@id)=lower-case($resource-id)]
	let $by-kto :=
		if ($resource-id castable as xs:integer) then
			$accounts/Accounts/Account[@kto=xs:integer($resource-id)]
		else
			()
	return
		($by-id, $by-kto)[1]
};


declare function account:getAccountByIban ($home-data, $tenant, $year as xs:integer, $iban) {
	let $account := doc($home-data||'/'||$tenant||'/'||$year||'/accounts.dm.xml')/Accounts/Account[BankAccounts/BankAccount/@iban=$iban]
	return
		$account
};


declare function account:storeAccount ($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $resource-id as xs:string, $account-data) {
	let $account-id := lower-case($resource-id)
	let $accounts := doc($home-data||'/'||$tenant||'/'||$year||'/accounts.dm.xml')
	let $incoming := if ($account-data instance of document-node()) then $account-data/*[1] else $account-data
	let $current := $accounts/Accounts/Account[lower-case(@id)=$account-id]
	return
		if (exists($current)) then (
			update replace $current with $incoming,
			$incoming
		) else (
			update insert $incoming into $accounts/Accounts,
			$incoming
		)
};


declare function account:deleteAccount ($home-data, $tenant, $year as xs:integer, $resource-id) {
	let $accounts := doc($home-data||'/'||$tenant||'/'||$year||'/accounts.dm.xml')
	let $account := $accounts/Accounts/Account[lower-case(@id)=lower-case($resource-id)]
	return
		if ($account = ()) then
			<error>Kein Account vorhanden</error>
		else
			<Account>
				{update delete $account}
			</Account>

};


