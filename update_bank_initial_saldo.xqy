xquery version "3.1";

(:
This script might be tested at:

/exist-backend/rest/db/apps/docman/update_bank_initial_saldo.xqy
:)

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace banking="http://bintellix.com/docman/banking" at "/db/apps/docman/modules/module_banking.xqm";

import module namespace packages = "http://exist-db.org/apps/existdb-packages" at "/db/apps/packageservice/modules/packages.xqm";
import module namespace functx = "http://www.functx.com";
import module namespace apputil = "http://exist-db.org/xquery/apps";

declare namespace docman = "http://docman.bintellix.com";

declare option output:indent "yes";

let $home-data := '/db/apps/docman/data'
let $tenant := 'bintellix'
let $years := ('2019', '2020', '2021', '2022', '2023', '2024')
let $bankAccounts := ('222971400', '222971401', '222971460')
return
<result>
{
	for $year in $years
	order by $year
	return
		for $bankAccount in $bankAccounts
		order by $bankAccount
		let $collection := $home-data||'/'||$tenant||'/'||$year
		let $Accountings := doc(concat($collection,'/bank-account_',$bankAccount,'.dm.xml'))/BankAccount/Accountings
		let $AccountingList := $Accountings/Accounting
		return
			if (not($Accountings/@saldoInitAmount)) then
				<BankAccount tenant="{$tenant}" year="{$year}" bankAccount="{$bankAccount}">Does not exist</BankAccount>
			else if (not($AccountingList/*)) then
				<BankAccount tenant="{$tenant}" year="{$year}" bankAccount="{$bankAccount}" initialAccount="{$Accountings/@saldoInitAmount}">No bank movements</BankAccount>
			else
				<BankAccount tenant="{$tenant}" year="{$year}" bankAccount="{$bankAccount}" initialAccount="{$Accountings/@saldoInitAmount}" calculatedSaldo="{format-number($AccountingList[1]/@saldoAmount - $AccountingList[1]/Amount, '##0.00')}">
					{ update value $Accountings/@saldoInitAmount with format-number($AccountingList[1]/@saldoAmount - $AccountingList[1]/Amount, '##0.00') }			
				</BankAccount>
}
</result>