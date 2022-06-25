xquery version "3.1";

module namespace bookings = "http://bintellix.com/docman/bookings";
import module namespace account="http://bintellix.com/docman/account" at "/db/apps/docman/modules/module_account.xqm";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:indent "no";


declare function bookings:listAccounts($dm-home-data as xs:string, $tenant-id as xs:string, $year as xs:integer, $account-kto as xs:string?) as node()? {
 	let $data-collection := concat($dm-home-data,'/',$tenant-id,'/',$year)

	let $bookings := collection($data-collection)//Bookings/Booking
	let $bookings2 := bookings:missingBankBookings($dm-home-data, $tenant-id, $year, (), 1372)
	(:
	let $credit := for $booking in $bookings
			let $group := $booking/@credit
			group by $group
			return
				xs:string($group)
	let $debit := for $booking in $bookings
			let $group := $booking/@debit
			group by $group
			return
				xs:string($group)
	let $accs := for $acc in distinct-values(($credit, $debit)) order by $acc return $acc
	:)
	(:
	let $accounts := if (not($account-kto)) then 
			collection(concat($dm-home-data, '/', $tenant-id, '/', $year))/Accounts/Account
		else
			collection(concat($dm-home-data, '/', $tenant-id, '/', $year))/Accounts/Account[@kto=$account-kto]
	:)
	let $accounts := if (not($account-kto)) then 
			account:listAccounts($dm-home-data, $tenant-id, $year)/Account
		else
			account:listAccounts($dm-home-data, $tenant-id, $year)/Account[@kto=$account-kto]

	return
		<Accounting version="1.0">
		{
			for $account in $accounts
			order by $account/@kto
			let $credit := sum($bookings[@credit=$account/@kto]/@amountValue) + sum($bookings2[@credit=$account/@kto]/@amountValue) + (if (contains-token($account/@classes,'essets') or contains-token($account/@classes,'expenses') or contains-token($account/@classes,'creditor')) then $account/Accounting/@openingBalance else 0)
			let $debit := sum($bookings[@debit=$account/@kto]/@amountValue) + sum($bookings2[@debit=$account/@kto]/@amountValue) + (if (contains-token($account/@classes,'liabilities') or contains-token($account/@classes,'revenues') or contains-token($account/@classes,'debitor')) then $account/Accounting/@openingBalance else 0)
			return
				<Account kto="{$account/@kto}" name="{$account/Name}" credit="{$credit}" debit="{$debit}" classes="{$account/@classes}" notes="{$account/Notes}">
					<Credits>
					{ 
						if (contains-token($account/@classes,'essets') or contains-token($account/@classes,'expenses') or contains-token($account/@classes,'creditor')) then 
							<Booking pro="AB" isStorno="false" date="{$year}-01-01" quality="3" amountValue="{$account/Accounting/@openingBalance}" amountUnit="EUR" credit="0" debit="0" taxKey="" taxAmount="0" refID="" description="AB"/> 
						else 
							() 
					}
					{ 
						for $booking in ($bookings[@credit=$account/@kto], $bookings2[@credit=$account/@kto])
						order by $booking/@date
						return
							<Booking pro="{$booking/../../../../@id}" isStorno="{$booking/../../@isStorno}">
							{$booking/@*}
							</Booking>
					}
					{ 
						if (contains-token($account/@classes,'liabilities') or contains-token($account/@classes,'revenues') or contains-token($account/@classes,'debitor')) then 
							<Booking pro="EB" isStorno="false" date="{$year}-01-01" quality="3" amountValue="{$debit - $credit}" amountUnit="EUR" credit="0" debit="0" taxKey="" taxAmount="0" refID="" description="EB"/> 
						else 
							() 
					}
					</Credits>
					<Debits>
					{ 
						if (contains-token($account/@classes,'liabilities') or contains-token($account/@classes,'revenues') or contains-token($account/@classes,'debitor')) then 
							<Booking pro="AB" isStorno="false" date="{$year}-01-01" quality="3" amountValue="{$account/Accounting/@openingBalance}" amountUnit="EUR" credit="0" debit="0" taxKey="1" taxAmount="0" refID="" description="AB"/> 
						else 
							() 
					}
					{
						for $booking in ($bookings[@debit=$account/@kto], $bookings2[@debit=$account/@kto])
						order by $booking/@date
						return
							<Booking pro="{$booking/../../../../@id}" isStorno="{$booking/../../@isStorno}">
							{$booking/@*}
							</Booking>
					}
					{ 
						if (contains-token($account/@classes,'essets') or contains-token($account/@classes,'expenses') or contains-token($account/@classes,'creditor')) then 
							<Booking pro="EB" isStorno="false" date="{$year}-01-01" quality="3" amountValue="{$credit - $debit}" amountUnit="EUR" credit="0" debit="0" taxKey="" taxAmount="0" refID="" description="EB"/> 
						else 
							() 
					}
					</Debits>
				</Account>
		}
		</Accounting>
};


declare function bookings:getAccoutSheet($dm-home-data as xs:string, $tenant-id as xs:string, $year as xs:integer) {
	let $accounts := collection(concat($dm-home-data,'/',$tenant-id,'/',$year))/Accounts
	let $expenses := $accounts/Account[contains-token(@classes,'expenses')]
	let $revenues := $accounts/Account[contains-token(@classes,'revenues')]
	let $essets := $accounts/Account[contains-token(@classes,'essets')]
	let $liabilities := $accounts/Account[contains-token(@classes,'liabilities')]
	return
		<AccountingSheet>
			<Account kto="0" name="Gewinn- und Verlustkonto" credit="{sum($expenses/Accounting/@creditSum)}" debit="{sum($revenues/Accounting/@debitSum)}" classes="">
				<Credits>
				{
					for $account in $expenses
					order by xs:decimal($account/Accounting/@creditSum) descending 
					return
						<Booking date="" amountValue="{$account/Accounting/@creditSum - $account/Accounting/@debitSum}" amountUnit="EUR" credit="{$account/@kto}" debit="0000" description="{$account/Name}"/>
				}
				</Credits>

				<Debits>
				{
					for $account in $revenues
					order by xs:decimal($account/Accounting/@debitSum) descending 
					return
						<Booking date="" amountValue="{$account/Accounting/@debitSum - $account/Accounting/@creditSum}" amountUnit="EUR" credit="0000" debit="{$account/@kto}" description="{$account/Name}"/>
				}
				</Debits>
			</Account>
			<Account kto="0" name="Aktiva/Passiva" credit="{sum($essets/Accounting/@debitSum)}" debit="{sum($liabilities/Accounting/@debitSum)}" classes="">
				<Credits>
				{
					for $account in $essets
					order by xs:decimal($account/Accounting/@creditSum) descending 
					return
						<Booking date="" amountValue="{$account/Accounting/@creditSum - $account/Accounting/@debitSum}" amountUnit="EUR" credit="{$account/@kto}" debit="0000" description="{$account/Name}"/>
				}
				</Credits>

				<Debits>
				{
					for $account in $liabilities
					order by xs:decimal($account/Accounting/@debitSum) descending 
					return
						<Booking date="" amountValue="{$account/Accounting/@debitSum - $account/Accounting/@creditSum}" amountUnit="EUR" credit="0000" debit="{$account/@kto}" description="{$account/Name}"/>
				}
				</Debits>
			</Account>
		</AccountingSheet>
};


declare function bookings:refreshAccounts($dm-home-data as xs:string, $tenant-id as xs:string, $year as xs:integer) {
	let $accounts := collection(concat($dm-home-data,'/',$tenant-id,'/',$year))/Accounts
	let $bookings := collection(concat($dm-home-data,'/',$tenant-id,'/',$year))//Bookings/Booking
	return
		<Refresh>
		{
			for $account in $accounts/Account
				return
				(
						update value $account/Accounting/@creditSum with sum($bookings[@credit=$account/@kto]/@amountValue)
				,
						update value $account/Accounting/@debitSum with sum($bookings[@debit=$account/@kto]/@amountValue)
				)
		}
		</Refresh>
};


declare function bookings:missingBankBookings($dm-home-data as xs:string, $tenant-id as xs:string, $year as xs:integer, $month as xs:integer?, $missing-kto as xs:integer) as node()* {
	let $data-collection := $dm-home-data||'/'||$tenant-id||'/'||format-number($year,'00')
    let $accounts := doc($dm-home-data||'/'||$tenant-id||'/'||$year||'/accounts.dm.xml')/Accounts
    let $bookings := collection($data-collection)/Process//Booking
	let $accountings := collection($data-collection)/BankAccount/Accountings/Accounting
	
	for $item in if (not($month)) then $accountings else $accountings[month-from-date(ValueDate)=$month]
		let $isPositive := number($item/Amount/text()) > 0
		let $kto := $accounts/Account[@id eq $item/../../@kto]/@kto
		return
			if ($kto = '') then
				()
			else if ($item[@id = $bookings/@refID]) then
				let $payed-values := collection($data-collection)//PaymentTask[RefID=$item/@id]/Amount/@value
				let $payed := sum($payed-values)
				let $amount := if ($isPositive) then number($item/Amount) - abs($payed) else number($item/Amount) * -1.0 - abs($payed)
				return
					if ($item/Amount != $payed and $amount gt 0.001) then
						<Booking 
							date="{$item/ValueDate}" 
							amountValue="{$amount}" 
							amountUnit="EUR"
							credit="{if ($isPositive) then $kto/data() else xs:string($missing-kto)}" 
							debit="{if ($isPositive) then xs:string($missing-kto) else $kto/data()}" 
							taxAmount="0" 
							refID="{$item/@id/data()}" 
							description="{$item/Recipient/text()} {$item/PaymentDetails/PaymentDetail/data()}{$item/Usages/Usage/data()}" 
							quality="3" type="partly-payed"/>
					else
						()
			else
				<Booking 
					date="{$item/ValueDate}" 
					amountValue="{if ($isPositive) then number($item/Amount) else number($item/Amount) * -1.0}" 
					amountUnit="EUR"
					credit="{if ($isPositive) then $kto/data() else xs:string($missing-kto)}" 
					debit="{if ($isPositive) then xs:string($missing-kto) else $kto/data()}" 
					taxAmount="0" 
					refID="{$item/@id/data()}" 
					description="{$item/Recipient/text()} {$item/PaymentDetails/PaymentDetail/data()}{$item/Usages/Usage/data()}" 
					quality="3" type="not-payed"/>
};