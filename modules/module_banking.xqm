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
/rest/db/apps/docman/modules/module_banking.xqm
:)

module namespace banking = "http://bintellix.com/docman/banking";

import module namespace csv="http://bintellix.com/docman/csv" at "/db/apps/docman/modules/module_csv.xqm";
import module namespace hbci4java="http://exist-db.org/library/hbci4java" at "java:hbci4java.existdb.OnlineBankingModule";
import module namespace xfo="http://bintellix.com/docman/xslfo" at "/db/apps/docman/modules/module_xfo.xqm";
import module namespace document="http://bintellix.com/docman/document" at "/db/apps/docman/modules/module_document.xqm";

declare namespace docman = "http://docman.bintellix.com";

(: declare decimal-format local:EU decimal-separator = "," grouping-separator = "."; :)

declare function banking:listBankAccounts ($home-data as xs:string, $tenant as xs:string, $year as xs:integer) {
	let $bank-accounts := collection($home-data||'/'||$tenant||'/'||$year)/BankAccount
	return
		<BankAccounts version="1.0">
		{
			for $bank-account in $bank-accounts
			order by $bank-account/BankAccountDetail/AccountNick
			return
			<BankAccount kto="{$bank-account/@kto}" year="{$year}" hasOnlineBanking="{exists($bank-account/BankAccountDetail/OnlineBanking/*)}">
				<BankAccountDetail>
				{$bank-account/BankAccountDetail/@*}
				{$bank-account/BankAccountDetail/*[name()!='OnlineBanking']}
				</BankAccountDetail>
				
				{
					let $credits := $bank-account/Accountings/Accounting/Amount[@type="CREDIT"]
					let $debits := $bank-account/Accountings/Accounting/Amount[@type="DEBIT"]
					let $countAll := count($bank-account/Accountings/Accounting)
					let $countCredits := count($credits) 
					let $countDebits := count($debits)
					return
					if ($countAll != $countCredits + $countDebits) then
						<error test="{count($bank-account/Accountings/Accounting)}">
							{$bank-account/Accountings}
							<values count="{count($credits)}" value="{sum($credits)}">{$credits}</values>
							<values count="{count($debits)}" value="{sum($debits)}">{$debits}</values>
							<values>{$bank-account/Accountings/Accounting/Amount[not(@type=('DEBIT','CREDIT'))]}</values>
						</error>
					else
						<Status movements="{$countAll}" saldoInitAmount="{$bank-account/Accountings/@saldoInitAmount}" saldoClosingAmount="{$bank-account/Accountings/Accounting[last()]/@saldoAmount + $bank-account/Accountings/Accounting[last()]/Amount}">
							<Movement type="credit" count="{$countCredits}" value="{sum($credits)}"/>
							<Movement type="debit" count="{$countDebits}" value="{sum($debits)}"/>
						</Status>
				}
			</BankAccount>
		}
		</BankAccounts>
};

(:
	Take care of online banking data given back (: .../BankAccountDetail/[name()!='OnlineBanking'] :)
:)
declare function banking:getBankAccount ($home-data as xs:string, $tenant as xs:string, $bank-account-id as xs:string, $year as xs:integer) {
	let $bank-account := collection($home-data||'/'||$tenant||'/'||$year)/BankAccount[@kto=$bank-account-id]
	return
		<BankAccount version="1.0" kto="{$bank-account-id}" hasOnlineBanking="{exists($bank-account/BankAccountDetail/OnlineBanking/*)}">
		{
			<BankAccountDetail>
				{collection($home-data||'/'||$tenant||'/'||$year)/BankAccount[@kto=$bank-account-id]/BankAccountDetail/@*}
				{collection($home-data||'/'||$tenant||'/'||$year)/BankAccount[@kto=$bank-account-id]/BankAccountDetail/*}
			</BankAccountDetail>
		}
		</BankAccount>
};



declare function banking:listAccountings ($home-data as xs:string, $tenant as xs:string, $bank-account-id as xs:string, $year as xs:integer) {
	let $bank-account := collection($home-data||'/'||$tenant||'/'||$year)/BankAccount[@kto eq $bank-account-id]
	let $payment-tasks := collection($home-data||'/'||$tenant||'/'||$year)/Process/Tasks/PaymentTask
	return
		<BankAccount version="1.0" kto="{$bank-account-id}" name="{$bank-account/@name}" year="{$year}" hasOnlineBanking="{exists($bank-account/BankAccountDetail/OnlineBanking/*)}">
			<Accountings>
				{$bank-account/Accountings/@*}
				{for $accounting in $bank-account//Accounting
				return
					<Accounting>
						{$accounting/@*}
						{
							for $booked in $payment-tasks[RefID eq $accounting/@id]
							group by $d := ($booked/RefID)[1]
							return
								(
								attribute booked {$booked/../../@id}
								,
								attribute booked-amount {sum($booked/Amount/@value)}
								)
						}
						<!--
						{
							let $booked := $payment-tasks[RefID eq $accounting/@id]
							return
								(
								attribute booked {$booked/../../@id}
								,
								attribute booked-amount {sum($booked/Amount/@value)}
								)
						}
						-->
						{$accounting/*}
					</Accounting>
				}	
			</Accountings>
		</BankAccount>
};


declare function banking:listAccountingIDs ($home-data as xs:string, $tenant as xs:string, $bank-account-id as xs:string, $year as xs:integer) {
	let $bank-account := collection($home-data||'/'||$tenant||'/'||$year)/BankAccount[@kto=$bank-account-id]
	return
		<UsedIDs>
		{
			for $id in $bank-account/Accountings/Accounting/@id
			return	
				<UsedID>{$id/data()}</UsedID>
		}
		</UsedIDs>
};


declare function banking:getAccountingByIban ($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $iban as xs:string) {

	<BankAccounts>
	{
		if ($iban != '') then
		
			let $statements := collection($home-data||'/'||$tenant||'/'||$year)
			for $bank-account in $statements/BankAccount
			return 
				<BankAccount kto="{$bank-account/@kto}" name="{$bank-account/BankAccountDetail/AccountName}" nick="{$bank-account/BankAccountDetail/AccountNick}">
				{
					<Accountings version="1.0" tenant="{$tenant}" year="{$year}" iban="{$iban}">
					{
						for $accounting in $bank-account/Accountings/Accounting[IBAN=$iban]
						return
							$accounting
					}
					</Accountings>
				}
				</BankAccount>
		else
			()
	}
	</BankAccounts>
};


declare function banking:getAccountingById($home-data as xs:string, $tenant as xs:string, $bank-account as xs:string?, $year as xs:integer, $payment-id as xs:string) {
	
	if ($bank-account = '' or $year = 0 or $payment-id = '') then
		<error>Mandatory parameter missing</error>
	else
		let $account := if (not($bank-account)) then
				collection($home-data||'/'||$tenant||'/'||$year)/BankAccount/Accountings/Accounting[@id=$payment-id]
			else
				collection($home-data||'/'||$tenant||'/'||$year)/BankAccount[@kto=$bank-account]/Accountings/Accounting[@id=$payment-id]
		return
		if ($account != '') then
			<BankAccount kto="{$account/../../@kto}">
				{$account}
			</BankAccount>
		else
			<error tenant="{$tenant}" year="{$year}" bank-account="{$bank-account}" record="{$payment-id}">
				collection({$home-data||'/'||$tenant||'/'||$year})/BankAccount[@kto='{$bank-account}']/Accountings/Accounting[@id='{$payment-id}'] does not exist.
			</error>

};


declare function banking:getAccountingByIdAsPDF($home-data as xs:string, $home-web-gui as xs:string, $tenant as xs:string, $bank-account as xs:string, $year as xs:integer, $record) {

	if ($bank-account = '' or $year = '' or $record = '') then
		error(xs:QName('docman:getAccountingByIdAsPDF'), "Mandatory parameter missing")
	else
		let $xml := 	<result resource-id="{$record}">
					{banking:getBankAccount ($home-data, $tenant, $bank-account, $year)}
					{banking:getAccountingById($home-data, $tenant, $bank-account, $year, $record)}
				</result>
		let $xsl := doc(concat('../views/','banking_details_html.xsl'))

		let $xslParam :=   <parameters>
					<param name="home-web-gui" value="$home-web-gui"/>
					<param name="tenant" value="$tenant"/>
					<param name="year" value="$year"/>
					<param name="resource-id" value="$record"/>
					<param name="environment" value="'docman'"/>
				</parameters>
		let $xmlPage := transform:transform($xml, $xsl, $xslParam)

		let $xsl2 := doc('../views/templates/taglib-pdf.xsl')

		let $xmlFoPart := transform:transform($xmlPage, $xsl2, $xslParam)

		let $xsl3 := doc('../views/templates/generate-pdf.xsl')

		let $xmlFo := transform:transform($xmlFoPart, $xsl3, $xslParam)

		let $pdf := xfo:createPDF($xmlFo)

		return
			$pdf
};


declare function banking:getAccountBalanceList($home-data as xs:string, $tenant as xs:string, $bank-account-id as xs:string, $year as xs:string) {

	if ($home-data = '' or $tenant = '' or $bank-account-id = '' or $year = '' ) then
		<error>Mandatory parameter missing</error>
	else if ($bank-account-id castable as xs:integer and xs:integer($bank-account-id) = 0) then
		let $bank-accounts := collection($home-data||'/'||$tenant||'/'||$year)/BankAccount
		let $start-saldo := sum($bank-accounts/Accountings/@saldoInitAmount)
		let $changes := 
			for $item in $bank-accounts/Accountings/Accounting
			let $d := $item/ValueDate
			group by $d
			order by $d
			return
				<change date="{$d}" value="{sum($item/Amount)}"/> 
		return
		<Balances tenant="{$tenant}" year="{$year}" bank-account="0" unit="EUR" saldoInitAmount="{$start-saldo}" href="{concat('/',$tenant,'/',$year,'/banking/index.html')}">
		{
			for $item at $pos in $changes
			return
				try {
					<Balance date="{$item/@date}" value="{$start-saldo + sum($changes[position() le $pos]/@value)}" bank-account="0" day="{xs:integer((xs:date($item/@date) - xs:date(concat(year-from-date($item/@date),'-01-01'))) div xs:dayTimeDuration('P1D'))}"/>
				}
				catch * {
					<error date="{$item/@date}" pos="{$pos}"/>
				}
		}
		</Balances>
	else 
		let $bank-account := collection($home-data||'/'||$tenant||'/'||$year)/BankAccount[@kto=$bank-account-id]
		let $payments := collection($home-data||'/'||$tenant||'/'||$year)/Process/Tasks/PaymentTask/RefID
		return
		<Balances tenant="{$tenant}" year="{$year}" bank-account="{$bank-account/BankAccountDetail/AccountNick}" unit="EUR" saldoInitAmount="{$bank-account/Accountings/@saldoInitAmount}" href="{concat('/',$tenant,'/',$year,'/banking/',$bank-account-id,'/index.html')}">
		{
			for $item at $pos in $bank-account/Accountings/Accounting
			let $d := $item/ValueDate
			let $b := $item[@id = $payments]
			group by $d
			order by $d
			return
				try {
					<Balance date="{$d}" value="{sum($item/@saldoAmount) div count($item/@saldoAmount)}" day="{xs:integer((xs:date($d) - xs:date(concat(year-from-date($d),'-01-01'))) div xs:dayTimeDuration('P1D'))}" href="{concat('/',$tenant,'/',$year,'/banking/',$bank-account-id,'/',$item[1]/@id,'/details.html')}">
					{
						if ($b) then
							attribute {'isBooked'} {'true'}
						else
							attribute {'isBooked'} {'false'}
					}
					</Balance>
				}
				catch * {
					<error date="{$d}" pos="{$pos}"/>
				}
		}
		</Balances>
};


declare function banking:importStatementCSV($home-data, $tenant as xs:string, $csv as xs:string, $from as xs:date?, $till as xs:date?, $bank-account as xs:string?, $doImport as xs:boolean?) as element()? {

	let $format-spec-uri := 'banking_csv_format.xml'
	let $csv-format-spec := doc($format-spec-uri)
	let $xmlPlain := csv:csv-to-xml($csv, $csv-format-spec, 'number')
	let $start := if ($from castable as xs:date) then $from else xs:date('2000-01-01') 
	let $end := if ($till castable as xs:date) then $till else current-date()
	let $bank := collection($home-data||'/'||$tenant||'/'||format-date($end,'[Y0000]'))/BankAccount[@kto=$bank-account]
	let $bank-details := $bank/BankAccountDetail
	let $usedIDs := banking:listAccountingIDs ($home-data, $tenant, $bank-account, format-date($till,'[Y0000]'))
	return
(:
	<BankAccountDetail>
		<BankName>Beispiel Bank</BankName>
		<AccountName>Meine Bank Hauptkonto</AccountName>
		<AccountNick>Hauptkonto</AccountNick>
		<KTNR>123456789</KTNR>
		<BLZ>10020030</BLZ>
		<IBAN>DE99100200300123456789</IBAN>
		<BIC>DEUTDEXYMUC</BIC>
		<CustomerID>12345</CustomerID>
		<CustomerName>Meine Firma</CustomerName>	
		<Type>Kontokorrentkonto</Type>
		<CurrencyUnit>EUR</CurrencyUnit>	
		<OnlineBanking>
			<Auth type="901"> <!-- 911:smsTAN | 920:chipTAN optisch | 955:photoTAN -->
				<PIN>12345</PIN>
			</Auth>
			<Hostname/>
			<Port>443</Port>
			<Mesages url="/db/apps/docman/data/bintellix/2019/hbci4java_123456789.xml"/>
			<Passport url="passport_123456789.dat"/>
		</OnlineBanking>
		<Notes/>
	</BankAccountDetail>
:)
	<BankAccount>
		<Accountings from="{$start}" till="{$end}" saldoInitAmount="{$xmlPlain/Saldo/Row/SaldoAmount}">
		{
			let $rows := $xmlPlain/Statement/Row[not(@type='HEADER')]
			let $saldoInitial := xs:double($xmlPlain/Saldo/Row/SaldoAmount)
			for $row at $pos in $rows
			(: WARNING: Last row has to be ignored as it is just a summary :)
			where $pos < count($rows)-1 
			(: filter only Dates of the given period :) 
			where xs:date($row/ValueDate/text()) >= xs:date($start) and xs:date($row/ValueDate/text()) <= xs:date($end)
			return 
				let $saldo := 	$saldoInitial 
						+ sum($xmlPlain/Statement/Row[not(@type='HEADER')][position() le $pos]/DebitAmount[text() castable as xs:double]) 
						+ sum($xmlPlain/Statement/Row[not(@type='HEADER')][position() le $pos]/KreditAmount[text() castable as xs:double])
				let $accountingBase := 
					<Accounting saldoAmount="{format-number($saldo,'0.00')}">
						<ValueDate>{$row/ValueDate/text()}</ValueDate>
						<BookingDate>{$row/BookingDate/text()}</BookingDate>
						<SalesType>
						{
							if (starts-with($row/SalesType, 'SEPA-Dauerauftrag an')) then
								attribute code {"008"}
							else if (starts-with($row/SalesType, 'Kartenzahlung')) then
								attribute code {"083"}
							else if (starts-with($row/SalesType, 'SEPA-Lastschrift von')) then
								attribute code {"105"}
							else if (starts-with($row/SalesType, 'SEPA-Lastschrift (ELV) von')) then
								attribute code {"107"}
							else if (starts-with($row/SalesType, 'SEPA-Überweisung an')) then
								attribute code {"116"}
							else if (starts-with($row/SalesType, 'SEPA-Gutschrift von')) then
								attribute code {"166"} 

							else if (starts-with($row/SalesType, 'SMS-Gebühren für')) then
								attribute code {"835"}
							else if (starts-with($row/SalesType, 'Saldo der Abschlussposten')) then
								attribute code {"835"}
							else if (contains($row/SalesType, ' DEUTSCHE BANK KREDITKARTE ')) then
								attribute code {"835"}
							else
								()
						}
						{	
							$row/SalesType/text()
						}
						</SalesType>
						<Recipient>{$row/Recipient/text()}</Recipient>
						{ 
						if ($row/DivergentRecepient != '') then
							<DivergentRecepient>{$row/DivergentRecepient/text()}</DivergentRecepient>
						else
							()
						}
						<PaymentDetails>
							<PaymentDetail row="1">{$row/PaymentDetails/text()}</PaymentDetail>
						</PaymentDetails>
						<IBAN>{$row/IBAN/text()}</IBAN>
						<BIC>{$row/BIC/text()}</BIC>
						{ 
						if ($row/CustomerRef != '') then
							<CustomerRef>{$row/CustomerRef/text()}</CustomerRef>
						else
							()
						}
						{ 
						if ($row/MandantRef != '') then
							<MandantRef>{$row/MandantRef/text()}</MandantRef>
						else
							()
						}
						{ 
						if ($row/CreditorID) then
							<CreditorID>{$row/CreditorID/text()}</CreditorID>
						else
							()
						}
						{ 
						if ($row/DebitAmount/text() != '') then
								<Amount type="DEBIT">{$row/DebitAmount/text()}</Amount>
						else if ($row/CreditAmount/text() != '') then
								<Amount type="CREDIT">{$row/CreditAmount/text()}</Amount>
						else
							error(xs:QName('docman:transformCSV2XML'), "No Amount (debit or credit) given.")
						}
						{ 
						if ($row/OriginalAmount) then
							<OriginalAmount>{$row/OriginalAmount/text()}</OriginalAmount>
						else
							()
						}
						{ 
						if ($row/ExternalCosts) then
							<ExternalCosts>{$row/ExternalCosts/text()}</ExternalCosts>
						else
							()
						}
						<CurrencyUnit>{$row/CurrencyUnit/text()}</CurrencyUnit>
					</Accounting>
				let $dayCounter := count($xmlPlain/Statement/Row[not(@type='HEADER')][position() lt $pos]/ValueDate[text()=$row/ValueDate/text()])
				let $accounting := local:updateAccountingID($bank-details/IBAN, $dayCounter, $accountingBase)
				let $schema := doc('/db/apps/docman/resources/Bank.xsd')
				return
					if (not(validation:jaxv($accounting, $schema))) then
						error(xs:QName('docman:NotSchemaConform'),'The bank statement CSV import can not be handled, as it is not schema conform.', validation:jaxv-report($accounting, $schema))
					else if ($doImport = true()) then
						if ($accounting/@id = $usedIDs/UsedID) then
							<update>{update replace $bank//Accountings/Accounting[@id = $accounting/@id] with $accounting}</update>
						else
							<insert>{update insert $accounting into $bank//Accountings}</insert>
					else
						$accounting
		}
		</Accountings>
	</BankAccount>
};



declare function banking:importHibiscus($home-data as xs:string, $tenant as xs:string, $xmlHibiscus as item(), $from as xs:date?, $till as xs:date?, $hibiscusAccount as xs:string?, $bank-account as xs:string?, $doImport as xs:boolean?) as element()? {

	let $start := if ($from castable as xs:date) then xs:date($from) else xs:date('2000-01-01') 
	let $end := if ($till castable as xs:date) then xs:date($till) else current-date()

	let $bank := collection($home-data||'/'||$tenant||'/'||format-date($end,'[Y0000]'))/BankAccount[@kto=$bank-account]
	let $bank-details := $bank/BankAccountDetail

	let $xslt := doc('functions/banking_import_hibiscus.xsl')
	let $xslParam :=   <parameters>
			<param name="home-web-gui" value="$home-web-gui"/>
			<param name="tenant" value="$tenant"/>
			<param name="year" value="$year"/>
			<param name="resource-id" value="$record"/>
		</parameters>
	let $bankingBase := transform:transform($xmlHibiscus, $xslt, $xslParam)
	let $banking := local:updateAccountingID($bank-details/IBAN, (), $bankingBase)
	let $schema := doc('/db/apps/docman/resources/Bank.xsd')

	return 
		if (not(validation:jaxv($banking, $schema))) then
			error(xs:QName('docman:NotSchemaConform'),'The Hibiscus update can not be handled, as it is not schema conform.', validation:jaxv-report($banking, $schema))
		else if ($doImport = true()) then
				<insert status="fine">{update insert $banking//BankAccount[@kto=$hibiscusAccount]/Accountings/Accounting[xs:date(ValueDate) >= $start and xs:date(ValueDate) <= $end] into $bank//Accountings}</insert>
		else
			$banking
};



declare function banking:updateViaFinTS ($home-data, $tenant as xs:string, $bank-account as xs:string, $year as xs:integer, $from as xs:date?, $till as xs:date?, $doImport as xs:boolean?) {

	let $start := if ($from castable as xs:date) then xs:date($from) else format-date(current-dateTime()-xs:dayTimeDuration('P90D'),'[Y0000]-[M00]-[D00]') 
	let $end := if ($till castable as xs:date) then xs:date($till) else format-date(current-dateTime()-xs:dayTimeDuration('P1D'),'[Y0000]-[M00]-[D00]')
	let $bank := collection($home-data||'/'||$tenant||'/'||$year)/BankAccount[@kto=$bank-account]
	let $usedIDs := banking:listAccountingIDs ($home-data, $tenant, $bank-account, xs:integer(format-date($till,'[Y0000]')))

	return
		if (not($bank/BankAccountDetail)) then
			error(xs:QName('docman:NoValidBankAccount'),'The bank account &apos;'||$bank-account||'&apos; for year &apos;'||$year||'&apos; within '||$from||' and '||$till||' is not valid.')
		else
			let $authHeader := "Basic " || util:base64-encode('bix-accounting'||':'||'bix-acc')
			
			let $bank-statement-init := hbci4java:initialize($bank/BankAccountDetail/CustomerID, "DE", $bank/BankAccountDetail/OnlineBanking/Port, $bank/BankAccountDetail/BLZ, $bank/BankAccountDetail/BIC, $bank/BankAccountDetail/IBAN, $bank/BankAccountDetail/KTNR, $bank/BankAccountDetail/BankUserID, $bank/BankAccountDetail/CustomerID, "geheim", $bank/BankAccountDetail/OnlineBanking/Auth/@type, $bank/BankAccountDetail/OnlineBanking/Auth/PIN, $bank/BankAccountDetail/OnlineBanking/MessageIn/@url, $bank/BankAccountDetail/OnlineBanking/MessageOut/@url, $authHeader)
			let $bank-statement-text := hbci4java:getTransactions($bank/BankAccountDetail/CustomerID, $start, $end)
			let $bank-statement-close := hbci4java:close($bank/BankAccountDetail/CustomerID)
			
			(:
			let $bank-statement-text := hbci4java:getAccountActivity("DE", $bank/BankAccountDetail/BLZ, $bank/BankAccountDetail/OnlineBanking/Port, $bank/BankAccountDetail/CustomerName, $bank/BankAccountDetail/CustomerID, $start, $end, "geheim", $bank/BankAccountDetail/OnlineBanking/Auth/PIN, $bank/BankAccountDetail/OnlineBanking/Passport/@url, $bank/BankAccountDetail/OnlineBanking/MessageIn/@url, $bank/BankAccountDetail/OnlineBanking/MessageOut/@url, $authHeader)
			:)
			return
				if (starts-with($bank-statement-text,"<BankAccount")) then
					let $bank-statement-fints := parse-xml($bank-statement-text)
					let $bank-statement := local:updateAccountingID($bank/BankAccountDetail/IBAN, (), $bank-statement-fints)
					let $schema := doc('/db/apps/docman/resources/Bank.xsd')
					return
					(
						(: if (not(validation:jaxv($bank-statement, $schema))) then
							error(xs:QName('docman:NotSchemaConform'),'The HBCI/FinTS update can not be handled, as it is not schema conform.', validation:jaxv-report($bank-statement, $schema))
						else :)
						if ($doImport) then
							for $accounting in $bank-statement//Accountings/Accounting[xs:date(ValueDate) >= $start and xs:date(ValueDate) <= $end]
							order by $accounting/ValueDate
							return
								if ($accounting/@id = $usedIDs/UsedID) then
									<update status="fine">{update replace $bank//Accountings/Accounting[@id = $accounting/@id] with $accounting}</update>
								else
									<insert status="fine">{update insert $accounting into $bank//Accountings}</insert>
						else
							()
					,
						$bank-statement
					)
				else
					<error url="{concat('hbci4java:getAccountActivity(DE,',$bank/BankAccountDetail/BLZ,',', xs:string($bank/BankAccountDetail/OnlineBanking/Port),',',$bank/BankAccountDetail/CustomerName,',',$bank/BankAccountDetail/CustomerID,',',$start,',',$end,',','geheim',',PIN,',$bank/BankAccountDetail/OnlineBanking/Passport/@url,',',$bank/BankAccountDetail/OnlineBanking/MessageIn/@url,',',$bank/BankAccountDetail/OnlineBanking/MessageOut/@url,',',$authHeader,')')}">
						<bank-statement-init>{$bank-statement-init}</bank-statement-init>
						<bank-statement-text>{$bank-statement-text}</bank-statement-text>
						<bank-statement-close>{$bank-statement-close}</bank-statement-close>
					</error>
};


declare function banking:storeBankAccount ($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $bank-account-id as xs:string, $bank-account) {
	let $schema := doc('/db/apps/docman/resources/Bank.xsd')
	return
		if (not(validation:jaxv($bank-account, $schema))) then
			error(xs:QName('docman:NotSchemaConform'),'The bank account can not be saved, as it is not schema conform.', validation:jaxv-report($bank-account, $schema))
		else
			let $update := update replace collection($home-data||'/'||$tenant||'/'||$year)/BankAccount[@kto=$bank-account-id]/BankAccountDetail with $bank-account/BankAccount/BankAccountDetail
			let $update := update replace collection($home-data||'/'||$tenant||'/'||$year)/BankAccount[@kto=$bank-account-id]/Accountings with $bank-account/BankAccount/Accountings
			let $payID := for $accounting in collection($home-data||'/'||$tenant||'/'||$year)/BankAccount[@kto=$bank-account-id]/Accountings/Accounting[@id='PAYxxx']
				return
					update value $accounting/@id with "PAY"||util:uuid()
			return
				<BankAccount kto="{$bank-account-id}">
				</BankAccount>
};


declare function banking:storeAccountings ($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $bank-account-id as xs:string, $accountings) {
	let $schema := doc('/db/apps/docman/resources/Bank.xsd')
	return
		if (not(validation:jaxv($accountings, $schema))) then
			error(xs:QName('docman:NotSchemaConform'),'The bank accountings can not be saved, as it is not schema conform.', validation:jaxv-report($accountings, $schema))
		else
			let $update := update replace collection($home-data||'/'||$tenant||'/'||$year)/BankAccount[@kto=$bank-account-id]/Accountings with $accountings
			let $payID := for $accounting in collection($home-data||'/'||$tenant||'/'||$year)/BankAccount[@kto=$bank-account-id]/Accountings/Accounting[@id='PAYxxx']
				return
					update value $accounting/@id with "PAY"||util:uuid()
			return
				<Accountings kto="{$bank-account-id}">
				</Accountings>
};


declare function banking:getPeriodicPayment ($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $bank-account-id as xs:string, $payment-id as xs:string) {
	let $collection := $home-data||'/'||$tenant||'/'||$year
	let $bank-account := collection($home-data||'/'||$tenant||'/'||$year)/BankAccount[@kto eq $bank-account-id]
	let $Movement := $bank-account/Accountings/Accounting[@id=$payment-id]
	let $Accountings := doc(concat($home-data,'/',$tenant,'/',$year,'/accounts.dm.xml'))/Accounts/Account[PeriodicPayments/PeriodicPayment]
	for $PeriodicPayment in $Accountings[contains-token(@iban, $Movement/IBAN)]/PeriodicPayments/PeriodicPayment (: [Period/@valid-from <= $Movement/ValueDate and Periodic/@valid-till >= $Movement/ValueDate] :)
	return
		if ($PeriodicPayment/PaymentOptions/PaymentOption/PaymentDetail/@type='TEXT' and not(contains(string-join($Movement/PaymentDetails/PaymentDetail,''), $PeriodicPayment/PaymentOptions/PaymentOption/PaymentDetail))) then
			<error>The Payment Detail '{$Movement/PaymentDetails/PaymentDetail/text()}' does not contain the text '{$PeriodicPayment/PaymentOptions/PaymentOption/PaymentDetail/text()}'</error>
		else if ($PeriodicPayment/PaymentOptions/PaymentOption/PaymentDetail/@type='REGEX' and not(matches(string-join($Movement/PaymentDetails/PaymentDetail,''), $PeriodicPayment/PaymentOptions/PaymentOption/PaymentDetail))) then
			<error>The Payment Detail '{$Movement/PaymentDetails/PaymentDetail/text()}' RegEx does not match with '{$PeriodicPayment/PaymentOptions/PaymentOption/PaymentDetail/text()}'</error>
		else if (not($Movement/CurrencyUnit/text() = $PeriodicPayment/DocumentTemplate/TotalAmount/@unit)) then
			<error>The Payment Unit '{$Movement/CurrencyUnit/text()}' does not match with '{$PeriodicPayment/DocumentTemplate/TotalAmount/@unit/data()}'</error>
		else if (not(xs:double($Movement/Amount[@type='DEBIT']) eq xs:double($PeriodicPayment/DocumentTemplate/TotalAmount/@value))) then
			<error>The Payment Amount '{$Movement/Amount[@type='DEBIT']/text()}' does not match with '{$PeriodicPayment/DocumentTemplate/TotalAmount/@value/data()}'</error>
		else if ($PeriodicPayment/@valid-from != '' and not((xs:date($PeriodicPayment/@valid-from) le xs:date($Movement/ValueDate)))) then
			<error>Template is future (valid from '{$PeriodicPayment/@valid-from/data()}'</error>
		else if ($PeriodicPayment/@valid-till != '' and not((xs:date($PeriodicPayment/@valid-till) ge xs:date($Movement/ValueDate)))) then
			<error>Template is outdated (valid till '{$PeriodicPayment/@valid-till/data()}'</error>
		else
			let $binder := format-date($Movement/ValueDate,'[M00]')
			let $document-filename := concat($Movement/ValueDate,'_Dauerbezug_(',$PeriodicPayment/../../@id/data(),')_(',replace(translate($PeriodicPayment/DocumentTemplate/RefID,' ','_'),'[^A-Za-z0-9_\-]','-'),')_(',replace(translate($PeriodicPayment/DocumentTemplate/TransactionID,' ','_'),'[^A-Za-z0-9_\-]','-'),')_PeriodicPayment')
			let $amount := $Movement/Amount[@type='DEBIT']
			return
			<Process id="PRO{util:uuid()}" name="{$document-filename}" binder="{substring($Movement/ValueDate,6,2)}" date="{$Movement/ValueDate}" user="automate" created="{current-dateTime()}">
				<Section/>
				<TotalAmount value="{$amount}"/>
				<Tasks>
					<InvoiceInTask type="invoice-in" id="ACC{util:uuid()}" date="{$Movement/ValueDate}" created="{current-dateTime()}" isMaster="true" user="" isStorno="false">
						<Notes>{$PeriodicPayment/DocumentTemplate/Notes/text()}</Notes>
						<Files>
							<File src="/{$tenant}/{$year}/banking/{$bank-account-id}/{$Movement/@id/data()}/periodic-payment.pdf" fileName="{$document-filename}" fileExtension=".pdf" uploadName="/{$tenant}/{$year}/banking/{$bank-account-id}/{$Movement/@id/data()}/periodic-payment.pdf" mimeType="application/pdf" type="doc-periodic-payment" doctype="digital" archived="false"/>
							<!-- uploadSrc="/{$tenant}/{$year}/banking/{$bank-account-id}/{$Movement/@id/data()}/periodic-payment.pdf" -->
						</Files>
						<Bookings/>
						<Amount value="{$amount}"/>
						<Owner>{$PeriodicPayment/../../@kto/data()}</Owner>
						<RefID>{$PeriodicPayment/DocumentTemplate/RefID/text()}</RefID>
						<TransactionID>{$PeriodicPayment/DocumentTemplate/TransactionID/text()}</TransactionID>
						<Description>Dauerauftrag: {$PeriodicPayment/DocumentTemplate/Description/text()}</Description>
					</InvoiceInTask>
					<CommodityTask type="invoice-in" id="ACC{util:uuid()}" date="{$Movement/ValueDate}" created="{current-dateTime()}" isMaster="false" user="automate" isStorno="false">
						<Notes/>
						<Files/>
						<Bookings>
							<Booking date="{$Movement/ValueDate}" quality="5" amountValue="{$amount * -1.0}" amountUnit="{$Movement/CurrencyUnit/data()}" credit="{$PeriodicPayment/DocumentTemplate/Other/@kto/data()}" debit="{$PeriodicPayment/../../@kto/data()}" taxKey="1" taxAmount="0" refID="{$PeriodicPayment/DocumentTemplate/RefID/text()}" description="{$PeriodicPayment/DocumentTemplate/Description/text()}"/>
						</Bookings>
						<Amount value="{$amount}" unit="{$Movement/CurrencyUnit/data()}"/>
						<!-- {$PeriodicPayment/DocumentTemplate/Tax/text()} -->
						<Tax key="L+X-0" region="inland" type="GOODS"/>
						<Other>{$PeriodicPayment/DocumentTemplate/Other/@kto/data()}</Other>
						<Description>{$PeriodicPayment/DocumentTemplate/Description/text()}</Description>
					</CommodityTask>
					<PaymentTask type="invoice-in" id="ACC{util:uuid()}" date="{$Movement/ValueDate}" created="{current-dateTime()}" isMaster="false" user="automate" isStorno="false">
						<Notes/>
						<Files>
							<File src="/{$tenant}/{$year}/banking/{$bank-account-id}/{$Movement/@id}.pdf" fileName="{$Movement/@id}" fileExtension=".pdf" uploadName="/{$tenant}/{$year}/banking/{$bank-account-id}/{$Movement/@id}.pdf" mimeType="application/pdf" type="doc-payment-bank" doctype="digital" archived="false"/>
						</Files>
						<Bookings>
							<Booking date="{$Movement/ValueDate/text()}" quality="5" amountValue="{$amount * -1.0}" amountUnit="{$Movement/CurrencyUnit/text()}" credit="{$PeriodicPayment/../../@kto/data()}" debit="1800" taxKey="1" taxAmount="0" refID="{$Movement/@id/data()}" description="Dauerbezug: {$Movement/PaymentDetails/PaymentDetail/text()}"/>
							</Bookings>
						<Amount value="{$amount}" unit="{$Movement/CurrencyUnit/text()}"/>
						<RefID>{$Movement/@id/data()}</RefID>
						<Description>Dauerbezug: {$Movement/PaymentDetails/PaymentDetail/text()} via {$Movement/IBAN/text()}</Description>
						<Trigger/>									
					</PaymentTask>
				</Tasks>
				<Notes/>
			</Process>
};

declare function banking:updateViaFinTS ($RecipientCountry as xs:string, $RecipientBic as xs:string, $RecipientIban as xs:string, $RecipientName as xs:string, $Date as xs:date, $CurrencyAmount as xs:double, $CurrencyUnit as xs:string, $UsageText as xs:string) {
	let $authHeader := "Basic " || util:base64-encode('bix-accounting'||':'||'bix-acc')

	let $bank-statement-init := hbci4java:initialize($bank/BankAccountDetail/CustomerID, "DE", $bank/BankAccountDetail/OnlineBanking/Port, $bank/BankAccountDetail/BLZ, $bank/BankAccountDetail/BIC, $bank/BankAccountDetail/IBAN, $bank/BankAccountDetail/KTNR, $bank/BankAccountDetail/BankUserID, $bank/BankAccountDetail/CustomerID, "geheim", $bank/BankAccountDetail/OnlineBanking/Auth/@type, $bank/BankAccountDetail/OnlineBanking/Auth/PIN, $bank/BankAccountDetail/OnlineBanking/MessageIn/@url, $bank/BankAccountDetail/OnlineBanking/MessageOut/@url, $authHeader)
	let $bank-statement-bankTransfer := hbci4java:arangeBankTransfer($bank/BankAccountDetail/CustomerID, $RecipientCountry, RecipientBic, $RecipientIban, $RecipientName, null, $CurrencyAmount, $CurrencyUnit, $UsageText)
	let $bank-statement-close := hbci4java:close($bank/BankAccountDetail/CustomerID)
	return
		<result>
			<init>{$bank-statement-init}</init>
			<transfer>{$bank-statement-bankTransfer}</transfer>
			<close>{$close}</close>
		</result>
};

declare function banking:createPeriodicPayments ($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $bank-account-id as xs:string) {
	let $collection := $home-data||'/'||$tenant||'/'||$year
	let $Accountings := doc(concat($home-data,'/',$tenant,'/',$year,'/accounts.dm.xml'))/Accounts/Account[PeriodicPayments/PeriodicPayment]
	let $PaymentList := collection($collection)/Document/Tasks/PaymentTask/RefID
	let $BankMovements := banking:listAccountings($home-data, $tenant, $bank-account-id, $year)
	return
	<result>
	{
		<PeriodicPayments>
		{
			for $PeriodicPayment in $Accountings/PeriodicPayments/PeriodicPayment
			return
				<PeriodicPayment name="{$PeriodicPayment/Name}" id="{$PeriodicPayment/../../@id}" kto="{$PeriodicPayment/../../@kto}" iban="{$PeriodicPayment/../../@iban}">
				{
					for $Movement in $BankMovements/Accountings/Accounting
					let $date := format-date($Movement/ValueDate,'[M00]')
					where $Movement[IBAN = $PeriodicPayment/PaymentOptions/PaymentOption/IBAN]
					where $Movement[not(@id = $PaymentList)]
					return
						try {
							let $document-data := banking:getPeriodicPayment($home-data, $tenant, $year, $bank-account-id, $Movement/@id)
							return
							if (not($document-data)) then
								<EmptyMatch/>
							else
								let $schema := doc('/db/apps/docman/resources/Process.xsd')
								return
								(
									<BankActivity a="{$Movement/PaymentDetails/PaymentDetail}" b="{$PeriodicPayment/PaymentOptions/PaymentOption/PaymentDetail}">
									{$Movement}
									</BankActivity>
								,
									if (not($document-data[name()='Process'])) then
										$document-data[name()!='Process']
									else 
										(
											$document-data[name()='Process']
										,
											if (not(validation:jaxv($document-data[name()='Process'], $schema))) then
												<error>The document can not be updated, as it is not schema conform. {validation:jaxv-report($document-data[name()='Process'], $schema)}</error>
											else
												document:createDocument($home-data, $tenant, $year, $document-data/@binder, $document-data/@name, $document-data[name()='Process'])
										)
								)
						}
						catch * {
							(
								<BankActivity>
								{$Movement}
								</BankActivity>
							,
								<NoMatch reason="{$err:description}"/>
							)
						}
				}
				</PeriodicPayment>
		}
		</PeriodicPayments>
	}
	</result>
};

(: 
: can be used for full bank account / for accountings, then no day-counter should be given 
: or just for one accounting, but than an day-couter has to be given
:)

declare function local:updateAccountingID($bank-iban as xs:string?, $day-counter as xs:integer?, $input as item()*) as item()* {
	for $node in $input
	return 
		typeswitch($node)
			case document-node() return 
				local:updateAccountingID($bank-iban, $day-counter, $node/node())

			case element() return
				element {name($node)} {  (: node-name($node) :)
					if (name($node) = 'Accounting') then 
						( $node/@*[name() != 'id'], attribute id { local:createAccountingID($bank-iban, $node, $day-counter) } )
					
					else 
						(: output each attribute in this element :)
						for $att in $node/@*
						return
							attribute {name($att)} {$att}
					
				,
					(: output all the sub-elements of this element recursively :)
					for $child at $pos in $node/node()
					return
						if (name($node) = 'Accountings') then
							let $dc := count($node/Accounting[position() le $pos and ValueDate = $child/ValueDate])
							return 
								local:updateAccountingID($bank-iban, $dc, $child)
								
						else
							local:updateAccountingID($bank-iban, $day-counter, $child)
				}

			case text() return
				$node
			(: otherwise pass it through. Used for comments, and PIs :)
			default return 
				$node
};



declare function local:createAccountingID($bank-iban as xs:string?, $accounting, $dayCounter as xs:integer) as xs:string {
	let $values := (
					$bank-iban
				,
					$accounting/SalesType/@code
				, 
					$accounting/ValueDate/text()
				,
					$accounting/Amount/text()
				,
					$accounting/@saldoAmount
				,
					$accounting/CurrencyUnit/text()
				,
					$accounting/CustomerRef[text()!='NONREF']/text()
				,
					$accounting/EndToEndRef[text()!='NOTPROVIDED']/text()
				,
					$accounting/MandantRef/text()
				,
					$accounting/CreditorID/text()
				,
					$accounting/Recipient/text()
				, 
					$accounting/IBAN/text()
				,
					$accounting/BIC/text()
				,
					normalize-space(string-join($accounting/PaymentDetails/PaymentDetail/text(),''))
				,
					$dayCounter
				)
	let $value := string-join($values,'|')
	return
		(: "DEBUG" || $value || " $dayCounter = '" || $dayCounter || "' hash=" || util:hash($value,"MD5",false()) :)
		"PAY" || util:hash($value,"MD5",false())
};
