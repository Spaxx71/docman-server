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

(: Persistent passport path: absolute Passport/@url or EXIST_HOME/docman-passports.
   Relative placeholders like passport_123456789.dat are ignored – they resolve to the
   JVM cwd and break PinTan instantiation. :)
declare function banking:passport-path($bank as element(BankAccount)?, $account-id as xs:string) as xs:string {
	let $configured := normalize-space(string(($bank/BankAccountDetail/OnlineBanking/Passport/@url)[1]))
	let $default := system:get-exist-home() || '/docman-passports/passport_' || $account-id || '.dat'
	(: /tmp/passport*.dat is a legacy placeholder, not a stable store. :)
	let $legacy-tmp := matches($configured, '^/tmp/passport.*\.dat$')
	let $absolute :=
		not($legacy-tmp)
		and (
			starts-with($configured, '/')
			or matches($configured, '^[A-Za-z]:[/\\]')
			or starts-with($configured, 'file:')
		)
	return
		if ($configured != '' and $absolute) then
			if (starts-with($configured, 'file:')) then
				substring-after($configured, 'file:')
			else
				$configured
		else
			$default
};

declare function banking:as-string($value) as xs:string {
	string-join($value ! string(.), '')
};

declare function banking:passport-secret($bank as element(BankAccount)?) as xs:string {
	let $configured := normalize-space(string($bank/BankAccountDetail/OnlineBanking/Parameters/Parameter[@name='passportSecret']))
	return
		if ($configured != '') then $configured else 'geheim'
};

(:
	hbci4java:initialize is arity 17 in 0.6 (passport+mode) and arity 15 in older jars still loaded in JVM.
	Use function-lookup so module_banking compiles against either build.
:)
declare function banking:hbci-initialize(
	$account-key as xs:string,
	$port,
	$blz,
	$bic,
	$iban,
	$ktnr,
	$bank-user-id,
	$customer-id,
	$secret as xs:string,
	$auth-type,
	$pin,
	$message-in-url,
	$message-out-url,
	$auth-header as xs:string,
	$passport as xs:string,
	$mode as xs:string
) {
	let $init17 := function-lookup(xs:QName("hbci4java:initialize"), 17)
	let $init15 := function-lookup(xs:QName("hbci4java:initialize"), 15)
	return
		if (exists($init17)) then
			$init17($account-key, "DE", $port, $blz, $bic, $iban, $ktnr, $bank-user-id, $customer-id, $secret, $auth-type, $pin, $message-in-url, $message-out-url, $auth-header, $passport, $mode)
		else if (exists($init15)) then
			$init15($account-key, "DE", $port, $blz, $bic, $iban, $ktnr, $bank-user-id, $customer-id, $secret, $auth-type, $pin, $message-in-url, $message-out-url, $auth-header)
		else
			error(xs:QName("docman:HbciMissing"), "hbci4java:initialize is not available (expected arity 17 or 15)")
};

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
			<BankAccountDetail>
				{collection($home-data||'/'||$tenant||'/'||$year)/BankAccount[@kto=$bank-account-id]/BankAccountDetail/@*}
				{collection($home-data||'/'||$tenant||'/'||$year)/BankAccount[@kto=$bank-account-id]/BankAccountDetail/*[name()!='OnlineBanking' and name()!='Notes']}
				<!-- <OnlineBanking> is hidden by security reason -->
				{collection($home-data||'/'||$tenant||'/'||$year)/BankAccount[@kto=$bank-account-id]/BankAccountDetail/Notes}
			</BankAccountDetail>
			{collection($home-data||'/'||$tenant||'/'||$year)/BankAccount[@kto=$bank-account-id]/Accountings}
		</BankAccount>
};


(:
	Take care of online banking data given back (: .../BankAccountDetail/[name()!='OnlineBanking'] :)
:)
declare function banking:getBankAccountDetail ($home-data as xs:string, $tenant as xs:string, $bank-account-id as xs:string, $year as xs:integer) {
	let $bank-account := collection($home-data||'/'||$tenant||'/'||$year)/BankAccount[@kto=$bank-account-id]
	let $detail := $bank-account/BankAccountDetail
	let $online := $detail/OnlineBanking
	return
		<BankAccount version="1.0" kto="{$bank-account-id}" hasOnlineBanking="{exists($online/*)}">
			<BankAccountDetail>
				{$detail/@*}
				{$detail/*[name()!='OnlineBanking' and name()!='Notes']}
				<OnlineBanking>
					{$online/@*}
					{
						(: Auth-Typ für die Oberfläche, PIN nur maskiert. :)
						if (exists($online/Auth)) then
							<Auth type="{$online/Auth/@type}">
								<PIN>{if (normalize-space(string($online/Auth/PIN)) = '') then '' else '********'}</PIN>
							</Auth>
						else ()
					}
					{$online/*[not(self::Auth)]}
				</OnlineBanking>
				{$detail/Notes}
			</BankAccountDetail>
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


declare function local:getBookings($accounting-id as xs:string, $payments as node()*) as element()* {
	for $payment in $payments/PaymentTask[RefID = $accounting-id]
	return 
		<Booking id="{$payment/@id}" 
			amount="{format-number(xs:double($payment/Amount/text()), '0.00')}"
			paymentDetail="{$payment/PaymentDetail/text()}"/>
};


declare function banking:getAccountBalanceList($home-data as xs:string, $tenant as xs:string, $year as xs:string, $bankAccountId as xs:string) {
	if ($home-data = '' or $tenant = '' or $year = '' or $bankAccountId = '') then
		<error>Mandatory parameter missing</error>
	
	(: Fall: Summierung für alle Konten (bank-account-id = 0) :)
  else if ($bankAccountId castable as xs:integer and xs:integer($bankAccountId) = 0) then
    let $bankAccounts := collection($home-data || '/' || $tenant || '/' || $year)/BankAccount
    let $paymentTasks := collection($home-data || '/' || $tenant || '/' || $year)/Process/Tasks/PaymentTask/RefID
    return
      let $start-saldo := sum($bankAccounts/Accountings/@saldoInitAmount)
      (: Erfasse alle relevanten Datumswerte und gruppiere sie :)
      let $dates := distinct-values(
        for $account in $bankAccounts
        for $accounting in $account/Accountings/Accounting
        order by $accounting/ValueDate
        return 
          xs:date($accounting/ValueDate)
      )
      let $balances :=
        for $date in $dates
        (: Berechne die Tagesbuchungen über alle Konten :)
        let $daily-balance := round-half-to-even(
          sum(
            for $account in $bankAccounts
            for $accounting in $account/Accountings/Accounting[xs:date(ValueDate) = $date]
            return xs:double($accounting/Amount) + (if ($accounting/ExternalCosts castable as xs:double) then xs:double($accounting/ExternalCosts) else 0)
          ) * 100
        ) div 100
        (: Berechne den laufenden Saldo als Startsaldo plus alle Buchungen bis einschließlich dieses Tages :)
        let $daySaldo := $start-saldo + sum(
          for $account in $bankAccounts
          for $accounting in $account/Accountings/Accounting
          where xs:date($accounting/ValueDate) <= $date
          return xs:double($accounting/Amount) + (if ($accounting/ExternalCosts castable as xs:double) then xs:double($accounting/ExternalCosts) else 0)
        )
        return
          (: Erstelle die Liste der Bankbewegungen mit Details und verknüpfe sie mit den Buchungen :)
          let $transactions := 
            for $account in $bankAccounts
            for $accounting in $account/Accountings/Accounting[xs:date(ValueDate) = $date]
            return 
              <Transaction id="{$accounting/@id}" 
                amount="{format-number(xs:double($accounting/Amount/text()), '0.00')}"
                paymentDetail="{$accounting/PaymentDetail/text()}">
                  <Bookings>
                    { local:getBookings($accounting/@id, $paymentTasks) }
                  </Bookings>
              </Transaction>
          let $day-of-year := xs:integer((xs:date($date) - xs:date(concat($year, '-01-01'))) div xs:dayTimeDuration('P1D')) + 1
          return 
            <Balance date="{$date}" 
              day="{$day-of-year}"
              amount="{format-number($daily-balance, '0.00')}"
              saldo="{format-number($daySaldo, '0.00')}">
              { $transactions }
            </Balance>
      return
        (: Ausgabe der Balances für alle Konten im gewünschten Format :)
        <Balances tenantId="{$tenant}" yearId="{$year}" bankAccountId="0" bankName="0" unit="EUR" saldoInitAmount="{$start-saldo}" numberOfPaymentTasks="{count($paymentTasks)}">
          { $balances }
        </Balances>
	
	(: Fall: Verarbeitung eines spezifischen Kontos :)
	else
		let $bankAccount := collection($home-data || '/' || $tenant || '/' || $year)/BankAccount[@kto = $bankAccountId]
		let $paymentTasks := collection($home-data || '/' || $tenant || '/' || $year)/Process/Tasks/PaymentTask/RefID
		return
		if (empty($bankAccount)) then
			<error>No Bank movements found for {$bankAccountId}</error>
		else
			let $start-saldo := xs:double($bankAccount/Accountings/@saldoInitAmount)
			(: Gruppiere und summiere alle Buchungen pro Datum, basierend auf Amount/text(), und liste die Bewegungen auf :)
			let $changes :=
				for $date in distinct-values($bankAccount/Accountings/Accounting/ValueDate)
				order by $date
				let $daily-balance := round-half-to-even(
					sum(
						for $accounting in $bankAccount/Accountings/Accounting[xs:date(ValueDate) = xs:date($date)]
						return xs:double($accounting/Amount) + (if ($accounting/ExternalCosts castable as xs:double) then xs:double($accounting/ExternalCosts) else 0)
					) * 100
				) div 100
				let $transactions := 
					for $accounting in $bankAccount/Accountings/Accounting[xs:date(ValueDate) = xs:date($date)]
					return 
						<Transaction id="{$accounting/@id}" 
							amount="{format-number(xs:double($accounting/Amount/text()), '0.00')}"
							paymentDetail="{$accounting/PaymentDetail/text()}">
							<Bookings>
								{ local:getBookings($accounting/@id, $paymentTasks) }
							</Bookings>
						</Transaction>
				let $day-of-year := xs:integer((xs:date($date) - xs:date(concat($year, '-01-01'))) div xs:dayTimeDuration('P1D')) + 1
				let $daySaldo := $start-saldo + sum(
					for $accounting in $bankAccount/Accountings/Accounting[xs:date(ValueDate) < xs:date($date)]
					return xs:double($accounting/Amount) + (if ($accounting/ExternalCosts castable as xs:double) then xs:double($accounting/ExternalCosts) else 0)
				) + $daily-balance
				(: let $daySaldo := $bankAccount/Accountings/Accounting[xs:date(ValueDate) = xs:date($date)][last()]/@saldoAmount :)(: Saldo is given based on booking date order! :)
				return
					<Balance date="{$date}" 
						day="{$day-of-year}"
						amount="{format-number($daily-balance, '0.00')}"
						saldo="{format-number($daySaldo, '0.00')}">
						{ $transactions }
					</Balance>
			return
				(: Ausgabe im gewünschten Format für ein spezifisches Konto :)
				<Balances tenantId="{$tenant}" yearId="{$year}" bankAccountId="{$bankAccount/@kto}" bankName="{$bankAccount/BankAccountDetail/AccountNick}" unit="EUR" saldoInitAmount="{$start-saldo}" numberOfPaymentTasks="{count($paymentTasks)}">
					{ $changes }
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
			<Passport url=""/>
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
							<DivergentRecepient type="{$row/DivergentRecepient/@type/data()}">{$row/DivergentRecepient/text()}</DivergentRecepient>
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
	banking:updateViaFinTS($home-data, $tenant, $bank-account, $year, $from, $till, $doImport, 'interactive')
};

declare function banking:updateViaFinTS ($home-data, $tenant as xs:string, $bank-account as xs:string, $year as xs:integer, $from as xs:date?, $till as xs:date?, $doImport as xs:boolean?, $mode as xs:string) {
	let $start := if ($from castable as xs:date) then xs:date($from) else format-date(current-dateTime()-xs:dayTimeDuration('P90D'),'[Y0000]-[M00]-[D00]') 
	let $end := if ($till castable as xs:date) then xs:date($till) else format-date(current-dateTime()-xs:dayTimeDuration('P1D'),'[Y0000]-[M00]-[D00]')
	let $bank := (collection($home-data||'/'||$tenant||'/'||$year)/BankAccount[@kto=$bank-account])[1]
	let $usedIDs := banking:listAccountingIDs ($home-data, $tenant, $bank-account, xs:integer(format-date($till,'[Y0000]')))
	let $detail := $bank/BankAccountDetail
	let $online := $detail/OnlineBanking
	(: Session key must be unique per Docman account; shared CustomerIDs collide otherwise.
	   Keep filename-safe (no '#') because hbci4j writes passport_<key>.dat.
	   Deutsche Bank Bank-ID: CustomerID is often empty – fall back to BankUserID. :)
	let $account-key-id :=
		if (normalize-space(banking:as-string($detail/CustomerID)) != '') then banking:as-string($detail/CustomerID)
		else if (normalize-space(banking:as-string($detail/BankUserID)) != '') then banking:as-string($detail/BankUserID)
		else $bank-account
	let $account-key := $account-key-id || '_' || $bank-account
	let $passport := banking:passport-path($bank, $account-key)
	let $secret := banking:passport-secret($bank)
	let $mode-eff := if ($mode = 'auto') then 'auto' else 'interactive'
	(: Java signatures need typed atoms; as-string is only for text fields / return values. :)
	let $port := if (banking:as-string($online/Port) castable as xs:integer) then xs:integer(banking:as-string($online/Port)) else 443
	let $blz := xs:long(banking:as-string($detail/BLZ))
	let $bic := banking:as-string($detail/BIC)
	let $iban := banking:as-string($detail/IBAN)
	let $ktnr := xs:long(banking:as-string($detail/KTNR))
	let $bank-user-id := banking:as-string($detail/BankUserID)
	let $customer-id := banking:as-string($detail/CustomerID)
	let $auth-type := xs:integer(banking:as-string($online/Auth/@type))
	let $pin := banking:as-string($online/Auth/PIN)
	let $message-in-url := banking:as-string($online/MessageIn/@url)
	let $message-out-url := banking:as-string($online/MessageOut/@url)

	return
		if (not($detail)) then
			error(xs:QName('docman:NoValidBankAccount'),'The bank account &apos;'||$bank-account||'&apos; for year &apos;'||$year||'&apos; within '||$from||' and '||$till||' is not valid.')
		else
			let $authHeader := "Basic " || util:base64-encode('bix-accounting'||':'||'bix-acc')
			
			let $bank-statement-init := banking:hbci-initialize($account-key, $port, $blz, $bic, $iban, $ktnr, $bank-user-id, $customer-id, $secret, $auth-type, $pin, $message-in-url, $message-out-url, $authHeader, $passport, $mode-eff)
			let $init-text := banking:as-string($bank-statement-init)
			(: Defensive: older hbci4java builds returned "already exist" for stale sessions. :)
			let $bank-statement-init :=
				if (contains($init-text, 'already exist')) then
					let $closed := hbci4java:close($account-key)
					return banking:hbci-initialize($account-key, $port, $blz, $bic, $iban, $ktnr, $bank-user-id, $customer-id, $secret, $auth-type, $pin, $message-in-url, $message-out-url, $authHeader, $passport, $mode-eff)
				else
					$bank-statement-init
			let $init-text := banking:as-string($bank-statement-init)
			return
				if (contains($init-text, 'SCA_REQUIRED')) then
					let $closed := try { hbci4java:close($account-key) } catch * { () }
					return
						<error code="SCA_REQUIRED" mode="{$mode-eff}" passport="{$passport}">
							<bank-statement-init>{$init-text}</bank-statement-init>
						</error>
				else if (contains($init-text, 'unerwarteter Fehler')
					or contains($init-text, 'initialize failed')
					or contains($init-text, 'kann kein Passport')
					or contains($init-text, 'already exist')) then
					let $closed := try { hbci4java:close($account-key) } catch * { () }
					return
						<error url="hbci4java:initialize" passport="{$passport}" mode="{$mode-eff}">
							<bank-statement-init>{$init-text}</bank-statement-init>
						</error>
				else
					let $bank-statement-text := hbci4java:getTransactions($account-key, $start, $end)
					let $bank-statement-close := hbci4java:close($account-key)
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
						else if (contains(string($bank-statement-text), 'SCA_REQUIRED')) then
							<error code="SCA_REQUIRED" mode="{$mode-eff}" passport="{$passport}">
								<bank-statement-init>{$bank-statement-init}</bank-statement-init>
								<bank-statement-text>{$bank-statement-text}</bank-statement-text>
								<bank-statement-close>{$bank-statement-close}</bank-statement-close>
							</error>
						else
							<error url="{concat('hbci4java:getTransactions(',$account-key,',',$start,',',$end,')')}" passport="{$passport}" mode="{$mode-eff}">
								<bank-statement-init>{$bank-statement-init}</bank-statement-init>
								<bank-statement-text>{$bank-statement-text}</bank-statement-text>
								<bank-statement-close>{$bank-statement-close}</bank-statement-close>
							</error>
};


declare function local:mergeOnlineBanking($incoming as element(OnlineBanking)?, $stored as element(OnlineBanking)?) as element(OnlineBanking)? {
	if (empty($incoming) or empty($incoming/*)) then
		$stored
	else if (empty($stored) or empty($stored/*)) then
		$incoming
	else
		let $pin-raw := normalize-space(string($incoming/Auth/PIN))
		(: Leer oder nur Sternchen (Maske aus GET /detail) → hinterlegte PIN behalten. :)
		let $keep-pin := $pin-raw = '' or matches($pin-raw, '^\*+$')
		let $auth-type :=
			if (normalize-space(string($incoming/Auth/@type)) != '') then string($incoming/Auth/@type)
			else string($stored/Auth/@type)
		let $pin := if ($keep-pin) then string($stored/Auth/PIN) else $pin-raw
		return
			<OnlineBanking>
				{$incoming/@*}
				<Auth type="{$auth-type}">
					<PIN>{$pin}</PIN>
				</Auth>
				{$incoming/*[not(self::Auth)]}
				{
					if (empty($incoming/Parameters) and exists($stored/Parameters)) then $stored/Parameters else ()
				}
			</OnlineBanking>
};

declare function local:valid-bank-kto($kto as xs:string) as xs:boolean {
	matches($kto, '^[A-Za-z0-9]{5,15}$')
};

declare function banking:storeBankAccount ($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $bank-account-id as xs:string, $bank-account) {
	let $schema := doc('/db/apps/docman/resources/Bank.xsd')
	let $stored := collection($home-data||'/'||$tenant||'/'||$year)/BankAccount[@kto=$bank-account-id]
	let $root := if ($bank-account/self::BankAccount) then $bank-account else $bank-account/BankAccount
	let $incoming := $root/BankAccountDetail
	let $online := local:mergeOnlineBanking($incoming/OnlineBanking, $stored/BankAccountDetail/OnlineBanking)
	let $detail :=
		<BankAccountDetail>
			{$incoming/@*}
			{$incoming/*[not(self::OnlineBanking or self::Notes)]}
			{$online}
			{
				if (exists($incoming/Notes)) then $incoming/Notes
				else if (exists($stored/BankAccountDetail/Notes)) then $stored/BankAccountDetail/Notes
				else <Notes/>
			}
		</BankAccountDetail>
	(: Connection-Save darf ohne Accountings kommen; für Schema und Persistenz Bestand übernehmen. :)
	let $accountings :=
		if (exists($root/Accountings)) then $root/Accountings
		else if (exists($stored/Accountings)) then $stored/Accountings
		else <Accountings saldoInitAmount="0"/>
	let $candidate :=
		<BankAccount kto="{$bank-account-id}">
			{$detail}
			{$accountings}
		</BankAccount>
	return
		if (empty($stored)) then
			error(xs:QName('docman:BankMissing'), concat('Bank account ', $bank-account-id, ' does not exist.'))
		else if (not(validation:jaxv($candidate, $schema))) then
			error(xs:QName('docman:NotSchemaConform'),'The bank account can not be saved, as it is not schema conform.', validation:jaxv-report($candidate, $schema))
		else
			let $update := update replace $stored/BankAccountDetail with $detail
			let $update :=
				if (exists($root/Accountings) and exists($root/Accountings/Accounting)) then
					update replace $stored/Accountings with $root/Accountings
				else
					()
			let $payID := for $accounting in collection($home-data||'/'||$tenant||'/'||$year)/BankAccount[@kto=$bank-account-id]/Accountings/Accounting[@id='PAYxxx']
				return
					update value $accounting/@id with "PAY"||util:uuid()
			return
				<BankAccount kto="{$bank-account-id}">
				</BankAccount>
};

(: Neues Bankkonto als bank-account_{kto}.dm.xml anlegen. :)
declare function banking:createBankAccount ($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $bank-account) {
	let $schema := doc('/db/apps/docman/resources/Bank.xsd')
	let $root := if ($bank-account/self::BankAccount) then $bank-account else $bank-account/BankAccount
	let $kto := normalize-space(string(($root/@kto, '')[1]))
	let $col := $home-data || '/' || $tenant || '/' || $year
	let $nick := normalize-space(string($root/BankAccountDetail/AccountNick))
	let $name := normalize-space(string($root/BankAccountDetail/AccountName))
	let $bank := normalize-space(string($root/BankAccountDetail/BankName))
	let $label := if ($nick != '') then $nick else if ($name != '') then $name else $kto
	let $currency :=
		let $raw := normalize-space(string($root/BankAccountDetail/CurrencyUnit))
		return if ($raw != '') then $raw else 'EUR'
	let $candidate :=
		<BankAccount kto="{$kto}">
			<BankAccountDetail>
				<BankName>{if ($bank != '') then $bank else $label}</BankName>
				<AccountName>{if ($name != '') then $name else $label}</AccountName>
				<AccountNick>{if ($nick != '') then $nick else $label}</AccountNick>
				<KTNR>{normalize-space(string($root/BankAccountDetail/KTNR))}</KTNR>
				<BLZ>{normalize-space(string($root/BankAccountDetail/BLZ))}</BLZ>
				<IBAN>{normalize-space(string($root/BankAccountDetail/IBAN))}</IBAN>
				<BIC>{normalize-space(string($root/BankAccountDetail/BIC))}</BIC>
				<CurrencyUnit>{$currency}</CurrencyUnit>
				<Notes>{string($root/BankAccountDetail/Notes)}</Notes>
			</BankAccountDetail>
			<Accountings saldoInitAmount="0"/>
		</BankAccount>
	return
		if (not(local:valid-bank-kto($kto))) then
			error(xs:QName('docman:BankInvalid'), concat('Ungültige Konto-ID: ', $kto))
		else if (not(xmldb:collection-available($col))) then
			error(xs:QName('docman:YearMissing'), concat('Jahr fehlt: ', $year))
		else if (exists(collection($col)/BankAccount[@kto=$kto])) then
			error(xs:QName('docman:BankExists'), concat('Bankkonto existiert bereits: ', $kto))
		else if (not(validation:jaxv($candidate, $schema))) then
			error(xs:QName('docman:NotSchemaConform'), 'Bankkonto ist nicht schema-konform.', validation:jaxv-report($candidate, $schema))
		else
			let $store := xmldb:store($col, concat('bank-account_', $kto, '.dm.xml'), $candidate)
			return banking:getBankAccountDetail($home-data, $tenant, $kto, $year)
};

declare function banking:deleteBankAccount ($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $bank-account-id as xs:string) {
	let $kto := normalize-space($bank-account-id)
	let $stored := collection($home-data || '/' || $tenant || '/' || $year)/BankAccount[@kto=$kto]
	return
		if (empty($stored)) then
			error(xs:QName('docman:BankMissing'), concat('Bankkonto fehlt: ', $kto))
		else if (exists($stored/Accountings/Accounting)) then
			error(xs:QName('docman:BankNotEmpty'), concat('Bankkonto hat noch Bewegungen und kann nicht gelöscht werden: ', $kto))
		else
			let $removed := xmldb:remove(util:collection-name($stored), util:document-name($stored))
			return <deleted kto="{$kto}" year="{$year}" tenant="{$tenant}"/>
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

(: Setzt nur Accounting/@budgetCategory – ohne Full-Rewrite der Accountings-Tabelle. :)
declare function banking:setAccountingBudgetCategory (
	$home-data as xs:string,
	$tenant as xs:string,
	$year as xs:integer,
	$bank-account-id as xs:string,
	$accounting-id as xs:string,
	$category-id as xs:string
) {
	let $node := collection($home-data||'/'||$tenant||'/'||$year)/BankAccount[@kto=$bank-account-id]/Accountings/Accounting[@id=$accounting-id]
	return
		if (empty($node)) then
			error(xs:QName('docman:AccountingMissing'), concat('Accounting ', $accounting-id, ' not found on bank ', $bank-account-id, '.'))
		else
			let $update :=
				if (exists($node/@budgetCategory)) then
					update value $node/@budgetCategory with $category-id
				else
					update insert attribute budgetCategory { $category-id } into $node
			return
				<BudgetCategory id="{$category-id}" kto="{$bank-account-id}" accounting="{$accounting-id}"/>
};



(:
	is been used by periodic-payments.xqy
:)
declare function banking:getPeriodicPaymentList ($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $bank-account-id as xs:string) {
	let $collection := $home-data||'/'||$tenant||'/'||$year
	let $Accountings := doc(concat($home-data,'/',$tenant,'/',$year,'/accounts.dm.xml'))/Accounts/Account[PeriodicPayments/PeriodicPayment]
	let $bank-account := collection($home-data||'/'||$tenant||'/'||$year)/BankAccount[@kto eq $bank-account-id]
	for $PeriodicPayment in $Accountings/PeriodicPayments/PeriodicPayment
	return
		<PeriodicPayments>
			<PeriodicPayment>
				{$PeriodicPayment/@*}
				{$PeriodicPayment/node()}
				<RegardingAccount>
					{$PeriodicPayment/../../@*}
					{$PeriodicPayment/../../Name}
					{$PeriodicPayment/../../Notes}
				</RegardingAccount>
			</PeriodicPayment>
		</PeriodicPayments>
};


(:
	Create a list of all available periodic payments (from accounts.dm.xml of given year).
	$date: if given, then the given date should be used to filter only acive payment periods.
:)
declare function banking:getPeriodicPayments ($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $date as xs:date?) {
	let $collection := $home-data||'/'||$tenant||'/'||$year
	let $Accountings := doc(concat($home-data,'/',$tenant,'/',$year,'/accounts.dm.xml'))/Accounts/Account[PeriodicPayments/PeriodicPayment]
	for $PeriodicPayment in $Accountings/PeriodicPayments/PeriodicPayment
	return
		if ($date) then
			let $from := $PeriodicPayment/Period/@valid-from
			let $till := $PeriodicPayment/Period/@valid-till
			return
				if ($from castable as xs:date and xs:date($from) <= $date
					and (not($till castable as xs:date) or xs:date($till) >= $date)) then
					$PeriodicPayment
				else
					()
		else
			$PeriodicPayment
};

declare function banking:payment-rule-matches($rule as element(PaymentRule), $Movement as element()) as xs:boolean {
	let $text := normalize-space(string($rule))
	let $details := string-join($Movement/PaymentDetails/PaymentDetail | $Movement/PaymentDetail | $Movement/Usage, '')
	let $iban := normalize-space(string(($Movement/IBAN, $Movement/Counterpart/IBAN)[1]))
	return
		if ($text = '') then
			false()
		else if ($rule/@type = ('SEPA_DIRECT-DEBIT_IBAN', 'SEPA_CREDIT-TRANSFER_IBAN')) then
			upper-case(replace($iban, '\s', '')) = upper-case(replace($text, '\s', ''))
		else if ($rule/@type = 'SEPA_DIRECT-DEBIT_CREDITOR-ID') then
			contains(upper-case(string(($Movement/CreditorID, $Movement/Mandate/CreditorID, '')[1])), upper-case($text))
		else if ($rule/@type = 'SEPA_PAYMENT-DETAILS_REGEX') then
			matches($details, $text)
		else if ($rule/@type = 'PAYER_BANK-ACCOUNT_CONCERNED') then
			true()
		else
			contains(upper-case($details), upper-case($text))
};

declare function banking:amount-in-range($PeriodicPayment as element(PeriodicPayment), $amount as xs:double) as xs:boolean {
	let $min := $PeriodicPayment/Period/@amount-min
	let $max := $PeriodicPayment/Period/@amount-max
	let $exact := $PeriodicPayment/DocumentTemplate/TotalAmount/@value
	return
		if ($min castable as xs:double or $max castable as xs:double) then
			(not($min castable as xs:double) or $amount ge xs:double($min))
			and (not($max castable as xs:double) or $amount le xs:double($max))
		else if ($exact castable as xs:double) then
			$amount eq xs:double($exact)
		else
			true()
};

(:
	is been used by banking:createPeriodicPayments, banking_periodic-payment.xqy, banking_create-periodics.xqy, automatic_periodic-payments.xqy
:)
declare function banking:getPeriodicPayment ($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $bank-account-id as xs:string, $payment-id as xs:string) {
	let $collection := $home-data||'/'||$tenant||'/'||$year
	let $bank-account := collection($home-data||'/'||$tenant||'/'||$year)/BankAccount[@kto eq $bank-account-id]
	let $Movement := $bank-account/Accountings/Accounting[@id=$payment-id]
	let $PeriodicPayments := banking:getPeriodicPayments($home-data, $tenant, $year, ())
	let $amount-node := ($Movement/Amount[@type='DEBIT'], $Movement/Amount[@type='CREDIT'], $Movement/Amount)[1]
	let $amount := if ($amount-node castable as xs:double) then abs(xs:double($amount-node)) else 0
	for $PeriodicPayment in $PeriodicPayments
	let $rules := $PeriodicPayment/PaymentRules/PaymentRule
	let $legacy-iban := $PeriodicPayment/PaymentOptions/PaymentOption/IBAN
	let $matched :=
		if (exists($rules)) then
			every $rule in $rules satisfies banking:payment-rule-matches($rule, $Movement)
		else if (exists($legacy-iban)) then
			upper-case(replace(string(($Movement/IBAN)[1]), '\s', '')) = upper-case(replace(string($legacy-iban[1]), '\s', ''))
		else
			false()
	where $matched
	return
		if (exists($PeriodicPayment/DocumentTemplate/TotalAmount/@unit)
			and normalize-space(string($Movement/CurrencyUnit)) != ''
			and not(string($Movement/CurrencyUnit) = string($PeriodicPayment/DocumentTemplate/TotalAmount/@unit))) then
			<error>The Payment Unit '{$Movement/CurrencyUnit/text()}' does not match with '{$PeriodicPayment/DocumentTemplate/TotalAmount/@unit/data()}'</error>
		else if (not(banking:amount-in-range($PeriodicPayment, $amount))) then
			<error>The Payment Amount '{$amount}' is outside cost range / expected amount for '{$PeriodicPayment/Name/text()}'</error>
		else if ($PeriodicPayment/Period/@valid-from castable as xs:date and not((xs:date($PeriodicPayment/Period/@valid-from) le xs:date($Movement/ValueDate)))) then
			<error>Template is future (valid from '{$PeriodicPayment/Period/@valid-from/data()}'</error>
		else if ($PeriodicPayment/Period/@valid-till castable as xs:date and not((xs:date($PeriodicPayment/Period/@valid-till) ge xs:date($Movement/ValueDate)))) then
			<error>Template is outdated (valid till '{$PeriodicPayment/Period/@valid-till/data()}'</error>
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

declare function banking:transferViaFinTS ($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $bank-account-id as xs:string, $RecipientCountry as xs:string, $RecipientBic as xs:string, $RecipientIban as xs:string, $RecipientName as xs:string, $Date as xs:date, $CurrencyAmount as xs:double, $CurrencyUnit as xs:string, $UsageText as xs:string) {
	let $collection := $home-data||'/'||$tenant||'/'||$year
	let $bank-account := (collection($home-data||'/'||$tenant||'/'||$year)/BankAccount[@kto eq $bank-account-id])[1]
	let $detail := $bank-account/BankAccountDetail
	let $online := $detail/OnlineBanking
	let $account-key-id :=
		if (normalize-space(banking:as-string($detail/CustomerID)) != '') then banking:as-string($detail/CustomerID)
		else if (normalize-space(banking:as-string($detail/BankUserID)) != '') then banking:as-string($detail/BankUserID)
		else $bank-account-id
	let $account-key := $account-key-id || '_' || $bank-account-id
	let $passport := banking:passport-path($bank-account, $account-key)
	let $secret := banking:passport-secret($bank-account)
	let $authHeader := "Basic " || util:base64-encode('bix-accounting'||':'||'bix-acc')
	let $bank-statement-init := banking:hbci-initialize(
		$account-key,
		if (banking:as-string($online/Port) castable as xs:integer) then xs:integer(banking:as-string($online/Port)) else 443,
		xs:long(banking:as-string($detail/BLZ)),
		banking:as-string($detail/BIC),
		banking:as-string($detail/IBAN),
		xs:long(banking:as-string($detail/KTNR)),
		banking:as-string($detail/BankUserID),
		banking:as-string($detail/CustomerID),
		$secret,
		xs:integer(banking:as-string($online/Auth/@type)),
		banking:as-string($online/Auth/PIN),
		banking:as-string($online/MessageIn/@url),
		banking:as-string($online/MessageOut/@url),
		$authHeader,
		$passport,
		"interactive"
	)
	let $bank-statement-bankTransfer := hbci4java:arangeBankTransfer($account-key, $RecipientCountry, $RecipientBic, $RecipientIban, $RecipientName, $Date, $CurrencyAmount, $CurrencyUnit, $UsageText)
	let $bank-statement-close := hbci4java:close($account-key)
	return
		<result>
			<init>{banking:as-string($bank-statement-init)}</init>
			<transfer>{banking:as-string($bank-statement-bankTransfer)}</transfer>
			<close>{banking:as-string($bank-statement-close)}</close>
			<passport>{$passport}</passport>
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
