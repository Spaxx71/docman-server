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
This script might be tested at:
https://docman.bintellix.com/exist-backend/rest/db/apps/docman/modules/functions/banking_attach.xqy
https://docman.bintellix.com/app/bintellix/2020/banking/222971400/attach.html

:)
declare namespace docman = "http://docman.bintellix.com";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:indent "yes";

declare function local:createTask($tenant as xs:string, $year  as xs:integer, $owner-kto as xs:string, $acc as element(), $bank-account-id  as xs:string, $bank-account-kto as xs:string, $bank, $amount as xs:double, $bank-transfer-id as xs:string, $isStorno as xs:boolean, $quality as xs:integer) {
	<Task type="payment_bank">
		<Accountings>
			<Accounting created="{current-dateTime()}" date="{$acc/@date}" id="ACC{util:uuid()}" quality="{$quality}">
				{ if ($isStorno) then
					(
					<From kto="{$bank-account-kto}"/>
					,
					<To kto="{$owner-kto}"/>
					,
					<Amount value="{$amount}" unit="EUR"/>
					)
				else
					(
					<From kto="{$owner-kto}"/>
					,
					<To kto="{$bank-account-kto}"/>
					,
					<Amount value="{$amount * - 1.0}" unit="EUR"/>
					)
				}
				<RefID>{$bank-transfer-id}</RefID>
				<Description>{$bank/CustomerRef[. != 'NONREF']/text()} {string-join($bank/Usages/Usage,' ')} {string-join($bank/PaymentDetails/PaymentDetail,' ')}</Description>
			</Accounting>
		</Accountings>
		<Files>
			<File src="/{$tenant}/{$year}/banking/{$bank-account-id}/{$bank-transfer-id}.pdf" fileName="{$bank-transfer-id}" fileExtension=".pdf" uploadName="/{$tenant}/{$year}/banking/{$bank-account-id}/{$bank-transfer-id}" mimeType="application/pdf" type="payment_bank" doctype="digital" archived="false"/>
		</Files>
	</Task>
};


(:
local:findCombinations((1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 6), 12)
<matches init="1 2 3 4 5 6 7 8 9 10 11 12 6" value="12">
	<match posA="12"/>
	<match posA="1" posB="11"/>
	<match posA="2" posB="10"/>
	<match posA="3" posB="9"/>
	<match posA="4" posB="8"/>
	<match posA="5" posB="7"/>
	<match posA="6" posB="13"/>
	<match posA="1" posB="5" posC="13"/>
	<match posA="2" posB="4" posC="13"/>
</matches>
:)
declare function local:findCombinations($values as xs:double*, $amount as xs:double) {
	let $anz := xs:integer(count($values))
	return

	<matches init="{$values}" value="{$amount}">
	{
		for $a in (1 to $anz)
		return
			if ($values[$a] = $amount) then
				<match posA="{$a}" quality="0.9"/>
			else
				()
	}
	{
		let $anz2 := xs:integer(round($anz div 2))
		for $a in (1 to $anz2)
		return
			for $b in ($anz2 to $anz)
			return
				if ($a = $b) then
					()
				else if (format-number($values[$a] + $values[$b],'0.00') = format-number($amount,'0.00')) then
					<match posA="{$a}" posB="{$b}" quality="0.8"/>
				else
					() (: <try posA="{$a}" posB="{$b}" sum="{$values[$a] + $values[$b]}"/> :)
	}
	{
		let $anz3 := xs:integer(round($anz div 3))
		for $a in (1 to $anz3)
		return
			for $b in ($anz3 to $anz3 * 2)
			return
				for $c in ($anz3 * 2 to $anz)
				return
					if ($a = $b or $b = $c or $a = $c) then
						()
					else if (format-number($values[$a] + $values[$b] + $values[$c],'0.00') = format-number($amount,'0.00')) then
						<match posA="{$a}" posB="{$b}" posC="{$c}" quality="0.7"/>
					else
						() (:<try posA="{$a}" posB="{$b}" posC="{$c}" sum="{$values[$a] + $values[$b] + $values[$c]}"/> :)
	}
	</matches>
};


(: local:findCombinationOnce((20.04, 14.28, 149.95, 13.5, 11.58, 14.28), 31.62) :)
declare function local:findCombinationOnce($values as xs:float*, $amount) as xs:integer* {
	try {
			let $anz := xs:integer(count($values))
			return
			(
				for $a in (1 to $anz)
				return
					if ($values[$a] = $amount) then
						error (xs:QName("docman:match"), "match", $a)
					else
						()
			,
				let $anz2 := xs:integer(round($anz div 2))
				for $a in (1 to $anz2)
				return
					for $b in ($anz2 to $anz)
					return
						if ($a = $b) then
							()
						else if (format-number($values[$a] + $values[$b],'0.00') = format-number($amount,'0.00')) then
							error (xs:QName("docman:match"),"match", ($a, $b))
						else
							() (: <try posA="{$a}" posB="{$b}" sum="{$values[$a] + $values[$b]}"/> :)
			,
				let $anz3 := xs:integer(round($anz div 3))
				for $a in (1 to $anz3)
				return
					for $b in ($anz3 to $anz3 * 2)
					return
						for $c in ($anz3 * 2 to $anz)
						return
							if ($a = $b or $b = $c or $a = $c) then
								()
							else if (format-number($values[$a] + $values[$b] + $values[$c],'0.00') = format-number($amount,'0.00')) then
								error (xs:QName("docman:match"),"match", ($a,$b,$c))
							else
								() (:<try posA="{$a}" posB="{$b}" posC="{$c}" sum="{$values[$a] + $values[$b] + $values[$c]}"/> :)
			)
	}
	catch docman:match {
		$err:value
	}
};


let $home-web-gui := request:get-attribute('home-web-gui')
let $home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute('year')
let $resource-type := request:get-attribute('resource-type')
let $resource-id := request:get-attribute('resource-id')

let $billing-accounts := doc($home-data||'/'||$tenant||'/'||'accounts.dm.xml')/Accounts/Account

let $collection := $home-data||'/'||$tenant||'/'||$year
let $bank-account-id := $resource-id
let $bank-account-kto := $billing-accounts[@id=$bank-account-id]/@kto

let $accounts := for $account in $billing-accounts
				 where $account/@iban != '' or $account/@debtee != ''
				 return 
				 		<SubLedgerAccount>
						 {$account/@kto}
						 {
						 	for $iban in tokenize($account/@iban)
							return
								<IBAN>{$iban}</IBAN>
						 }
						 {
						 	for $debtee in tokenize($account/@debtee)
							return
								<Debtee>{$debtee}</Debtee>
						 }						 
						</SubLedgerAccount>
let $x := collection('/db/apps/')/Document

let $documents := for $document in collection($collection)/Document[not(@type='note') and not(./Tasks/Task[@type='payment_bank'])] (: and string-length(RefID) gt 5] :)
				return	
					<Document id="{$document/@id}" owner="{$billing-accounts[@kto=$document/Owner/@kto]/Name}" kto="{$document/Owner/@kto}" binder="{format-date($document/@date,'[M00]')}" 
						name="{$document/@name}" ref="{$document/RefID}" trans="{$document/TransactionID}" desc="{$document/Description}" amount="{$document/TotalAmount/@value}" date="{$document/@date}">
						{ for $task in $document/Tasks/Task[@type='invoice_in' or @type='invoice_in_storno']/Accountings/Accounting
						  return
							<Acc amount="{$task/Amount/@value}" date="{$task/@date}" ref="{$task/RefID}" desc="{$task/Description}"/>
						}
					</Document>
return

 
<result bank-account-id="{$bank-account-id}" kto="{$bank-account-kto}">
{
	for $bank in collection($collection)/BankAccount[@kto=$bank-account-id]/Accountings/Accounting
	let $bank-amount := $bank/Amount
	let $bank-date := $bank/ValueDate
	let $Usage := string-join($bank/Usages/Usage,'')
	let $PaymentDetail := string-join($bank/PaymentDetails/PaymentDetail,'')
	let $CustomerRef := normalize-space($bank/CustomerRef[text() != 'NONREF'])
	let $EndToEndRef := normalize-space($bank/EndToEndRef[text() != 'NOTPROVIDED'])
	return
		<BankAccountActivity id="{$bank/@id}" amount="{$bank-amount}" date="{$bank-date}" iban="{$bank/IBAN}" creditor="{$bank/CreditorID}"
			usage="{$Usage}" paymentDetail="{$PaymentDetail}" customer="{$bank/CustomerRef}" mandant="{$bank/MandantRef}" endtoend="{$bank/EndToEndRef}">
		{
			let $accounts := $accounts[IBAN = $bank/IBAN or Debtee = $bank/CreditorID] 
			let $candidatesWithKonto := $documents[@kto=$accounts/@kto]
			let $candidatesWithinTime := $candidatesWithKonto[(xs:date($bank-date) lt (xs:date(@date) + xs:dayTimeDuration('P21D')) and xs:date($bank-date) gt (xs:date(@date) - xs:dayTimeDuration('P14D')))]
			return
				if (count($candidatesWithinTime) != 0) then
					<Groups numOfKreditorAccounts="{count($accounts)}" numDocForKreditor="{count($candidatesWithKonto)}" numDocForKreditorWithinTime="{count($candidatesWithinTime)}">
					{
						let $group := $candidatesWithinTime[(string-length(@trans) gt 5 and (contains($CustomerRef,@trans) or contains($EndToEndRef,@trans) or contains($PaymentDetail,@trans) or contains($Usage,@trans)))  or 
															(string-length(@ref) gt 5 and (contains($CustomerRef,@ref) or contains($EndToEndRef,@ref) or contains($PaymentDetail,@ref) or contains($Usage,@ref)))]
						let $matches := local:findCombinationOnce($group/@amount, $bank-amount)
						return
							<Group amounts="{$group/@amount/data()}" group="{count($group/@amount)}" matches="{count($matches)}" transactionID="{$candidatesWithinTime/@trans/data()}" refID="{$candidatesWithinTime/@ref/data()}">
							{
								for $document in $group[position() = $matches]
								return
									<Document  transactionIDs="{$group/@trans}" refIDs="{$group/@ref}" candidates="{count($group)}">
										{$document/@*}
										{local:createTask($tenant, $year, $document/@kto, $document/Acc, $bank-account-id, $bank-account-kto, $bank, $document/@amount, $bank/@id, $bank/@isStorno='yes', 9)}
									</Document>
							}
							</Group>
					}
					</Groups>
				else
					()
		}
		</BankAccountActivity>
}
</result>