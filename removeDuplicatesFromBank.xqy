xquery version "3.1";

(:
This script might be tested at:

/exist-backend/rest/db/apps/docman/removeDuplicatesFromBank.xqy
:)

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace banking="http://bintellix.com/docman/banking" at "/db/apps/docman/modules/module_banking.xqm";

import module namespace packages = "http://exist-db.org/apps/existdb-packages" at "/db/apps/packageservice/modules/packages.xqm";
import module namespace functx = "http://www.functx.com";
import module namespace apputil = "http://exist-db.org/xquery/apps";

declare namespace docman = "http://docman.bintellix.com";

declare option output:indent "yes";

let $home-data := '/db/apps/docman/data'
let $tenant := 'intersecurity'
let $year := '2024'
let $bankAccount := '222765001'
let $collection := $home-data||'/'||$tenant||'/'||$year
let $Accountings := doc(concat($collection,'/bank-account_',$bankAccount,'.dm.xml'))/BankAccount/Accountings/Accounting

let $process-schema := doc('/db/apps/docman/Process.xsd')
let $bank-schema := doc('/db/apps/docman/Bank.xsd')
let $accounts-schema := doc('/db/apps/docman/Accounts.xsd')
return
<results>
	<BankAccount id="{$bankAccount}" year="{$year}" tenant="{$tenant}">
		<result type="duplicate IDs">
		{
			for $Account at $pos in $Accountings
			let $count := count($Accountings[@id = $Account/@id]) -1
			where  $count != 0
			return
				<Accounting id="{$Account/@id}" pos="{$pos}" count="{$count}">
					{ update delete $Accountings[@id = $Account/@id][last()] }
				</Accounting>
		}
		</result>

		<result type="duplicate values"> {(: aber nicht id="PAYxxxxxxxxxxxxxxxxx" :)}
		{
			for $Accounting in $Accountings
			group by
				$origin := $Accounting/@origin,
				$saldoTimestamp := $Accounting/@saldoTimestamp,
				$saldoAmount := $Accounting/@saldoAmount,
				$isStorno := $Accounting/@isStorno,
				$isSepa := $Accounting/@isSepa,
				$isCamt := $Accounting/@isCamt,
				$SalesTypeKey := $Accounting/SalesType/@key,
				$SalesType := $Accounting/SalesType/text(),
				$BookingDate := $Accounting/BookingDate/text(),
				$ValueDate := $Accounting/ValueDate/text(),
				$EndToEndRef := $Accounting/EndToEndRef/text(),
				$CustomerRef := $Accounting/CustomerRef/text(),
				$AmountType := $Accounting/Amount/@type,
				$Amount := $Accounting/Amount/text(),
				$CurrencyUnit := $Accounting/CurrencyUnit/text(),
				$Recipient := $Accounting/Recipient/text(),
				$IBAN := $Accounting/IBAN/text(),
				$BIC := $Accounting/BIC/text(),
				$PaymentDetail := normalize-space($Accounting/PaymentDetail/text()),
				$Usage := $Accounting/Usage/text()
			where count($Accounting) > 1
			let $doublet-ids := $Accounting[position() != 1]/@id
			return
					<Accounting ids="{$Accounting/@id}" positions="{$Accounting/position()}" deleted="{$doublet-ids}">
						{ (: $Accounting[position() != 1] :) }
						{ update delete $Accountings[@id = $doublet-ids] }
					</Accounting>
		}
		</result>
	</BankAccount>
</results>