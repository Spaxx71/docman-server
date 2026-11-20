(:
DATEV-Buchungsstapel eines Monatsordners.
Die Spaltenreihenfolge und die Prüfmuster stehen in datev_csv_format.xml
und werden von csv_export.xsl angewendet.
:)

xquery version "3.1" encoding "UTF-8";

module namespace datev = "http://bintellix.com/docman/datev";

import module namespace bookings="http://bintellix.com/docman/bookings" at "/db/apps/docman/modules/module_bookings.xqm";

declare function datev:format-uri() as xs:string {
	'xmldb:exist:///db/apps/docman/modules/datev_csv_format.xml'
};

declare function datev:plain($value as xs:string?, $max as xs:integer) as xs:string {
	let $clean := replace(string($value), '[^A-Za-z0-9_.\-/ ]', ' ')
	let $flat := replace(normalize-space($clean), ' +', ' ')
	return substring($flat, 1, $max)
};

declare function datev:partIssues($part as element(Part)?, $expected as xs:integer) as xs:string* {
	if (empty($part)) then
		'Teil fehlt.'
	else
		let $name := string($part/@name)
		let $numbers :=
			for $nr in $part/Column/@nr
			return if ($nr castable as xs:integer) then xs:integer($nr) else -1
		return (
			if (count($part/Column) ne $expected) then
				$name || ': ' || count($part/Column) || ' Spalten, erwartet werden ' || $expected || '.'
			else (),
			if (max($numbers) ne $expected) then
				$name || ': die höchste Spaltennummer ist ' || max($numbers) || ', erwartet wird ' || $expected || '.'
			else (),
			for $n in 1 to $expected
			let $hits := count($numbers[. eq $n])
			where $hits ne 1
			return $name || ': Spalte ' || $n || ' kommt ' || $hits || ' mal vor.',
			for $column-name in distinct-values($part/Column/@name)
			where count($part/Column[@name eq $column-name]) gt 1
			return $name || ': Spaltenname ' || $column-name || ' ist nicht eindeutig.',
			for $column in $part/Column
			let $regex := string($column/@regex)
			let $check :=
				if ($regex = '') then 'leer'
				else
					try {
						let $_ := matches(' ', $regex)
						return 'ok'
					} catch * {
						'ungültig'
					}
			where $check != 'ok'
			return $name || ': Spalte ' || $column/@nr || ' hat ein ' || $check || 'es Prüfmuster.'
		)
};

declare function datev:formatIssues() as xs:string* {
	try {
		let $format := doc('/db/apps/docman/modules/datev_csv_format.xml')/Format
		return
			if (empty($format)) then
				'DATEV-Formatdatei hat kein Format-Element.'
			else (
				datev:partIssues($format/Part[@name = 'ExportDetails'], 31),
				datev:partIssues($format/Part[@name = 'Buchungsstapel'], 124)
			)
	} catch * {
		'DATEV-Formatdatei kann nicht gelesen werden: ' || $err:description
	}
};

declare function datev:render($node as element(Export)) as xs:string* {
	let $parameters :=
		<parameters>
			<param name="exist:stop-on-warn" value="yes"/>
			<param name="exist:stop-on-error" value="yes"/>
			<param name="format-spec-uri" value="{datev:format-uri()}"/>
		</parameters>
	return transform:transform($node, xs:anyURI('xmldb:exist:///db/apps/docman/modules/csv_export.xsl'), $parameters)
};

declare function datev:header($tenant as xs:string, $year as xs:integer, $month as xs:integer) as xs:string* {
	let $startDate := xs:date(format-number($year, '0000') || '-' || format-number($month, '00') || '-01')
	let $isLeapYear := (($year mod 4 = 0) and ($year mod 100 != 0)) or ($year mod 400 = 0)
	let $daysInMonth :=
		if ($month = 2 and $isLeapYear) then 29
		else (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)[$month]
	let $endDate := xs:date(format-number($year, '0000') || '-' || format-number($month, '00') || '-' || format-number($daysInMonth, '00'))
	let $datevHead :=
		<Export name="DATEV" createHeadline="false">
			<ExportDetails>
				<ExportType>21</ExportType>
				<ExportName>Buchungsstapel</ExportName>
				<ExportVersion>12</ExportVersion>
				<CreatedDate>{current-dateTime()}</CreatedDate>
				<CreatorName>docman</CreatorName>
				<AdviserNr>416766</AdviserNr>
				<TenantNr>50328</TenantNr>
				<YearPeriodStart>{$year}-01-01</YearPeriodStart>
				<BookingStartDate>{$startDate}</BookingStartDate>
				<BookingEndDate>{$endDate}</BookingEndDate>
				<Description>{datev:plain($tenant || ' ' || format-number($month, '00') || '/' || format-number($year, '0000'), 30)}</Description>
				<DictationCode>DM</DictationCode>
				<CurrencyCode>EUR</CurrencyCode>
				<LockingUp>0</LockingUp>
				<AccountingType>1</AccountingType>
				<PurposeOfAccounting>0</PurposeOfAccounting>
				<AccountSystem>04</AccountSystem>
			</ExportDetails>
		</Export>
	let $headline :=
		<Export name="DATEV" createHeadline="true">
			<Buchungsstapel/>
		</Export>
	return (
		datev:render($datevHead),
		datev:render($headline)
	)
};

declare function datev:taxKey($key as xs:string?) as xs:string? {
	if ($key = ('-', 'X', '1', '20', '')) then ()
	else if ($key = '27') then '7'
	else if ($key = '29') then '9'
	else if ($key = '60') then '10'
	else if ($key = '68') then '18'
	else if ($key = '69') then '19'
	else $key
};

declare function datev:bookingText($booking as element()) as xs:string {
	let $type :=
		if ($booking/../../name() = "PaymentTask") then
			concat("Bezahlung", if ($booking/../../@type = "payment-bank") then " (Bank)" else "")
		else if ($booking/../../name() = "CommodityTask") then
			concat("Rechnung", if ($booking/../../@type = "invoice-out") then " (aus)" else if ($booking/../../@type = "invoice-in") then " (ein)" else "")
		else if ($booking/../../name() = "EmployeeSalaryTask") then
			"Gehalt"
		else
			replace($booking/../../name(), 'Task', '')
	return substring($type || ": " || $booking/@description, 1, 60)
};

declare function datev:row($booking as element()) as xs:string* {
	let $row :=
		<Export name="DATEV" createHeadline="false">
			<Buchungsstapel>
				<Umsatz>{$booking/@amountValue/data()}</Umsatz>
				<SH-Kennzeichen>{
					if ($booking/@amountValue >= 0) then 'S'
					else 'ERROR: negative amount'
				}</SH-Kennzeichen>
				<WKZ-Umsatz>{$booking/@amountUnit/data()}</WKZ-Umsatz>
				<Konto>{$booking/@credit/data()}</Konto>
				<Gegenkonto>{$booking/@debit/data()}</Gegenkonto>
				<BU-Schluessel>{datev:taxKey($booking/@taxKey/data())}</BU-Schluessel>
				<Belegdatum>{$booking/@date/data()}</Belegdatum>
				<Belegfeld1>{
					if ($booking/@refID/data() = '#') then ''
					else substring(replace($booking/@refID/data(), '[^A-Za-z0-9$&amp;%*+\-/]', '-'), 1, 36)
				}</Belegfeld1>
				<Skonto/>
				<Buchungstext>{datev:bookingText($booking)}</Buchungstext>
				<Festschreibung>false</Festschreibung>
			</Buchungsstapel>
		</Export>
	return datev:render($row)
};

declare function datev:rows($home as xs:string, $tenant as xs:string, $year as xs:integer, $month as xs:integer) as xs:string* {
	let $data-collection := $home || '/' || $tenant || '/' || format-number($year, '0000')
	for $booking in collection($data-collection)/Process//Bookings/Booking[month-from-date(@date) = $month]
	order by xs:date($booking/@date)
	return datev:row($booking)
};

declare function datev:missing($home as xs:string, $tenant as xs:string, $year as xs:integer, $month as xs:integer) as xs:string* {
	for $item in bookings:missingBankBookings($home, $tenant, $year, $month, 1372)
	order by xs:date($item/@date)
	return
		let $row :=
			<Export name="DATEV" createHeadline="false">
				<Buchungsstapel>
					<Umsatz>{number($item/@amountValue/data())}</Umsatz>
					<SH-Kennzeichen>S</SH-Kennzeichen>
					<WKZ-Umsatz>EUR</WKZ-Umsatz>
					<Konto>{$item/@credit/data()}</Konto>
					<Gegenkonto>{$item/@debit/data()}</Gegenkonto>
					<Belegdatum>{$item/@date/data()}</Belegdatum>
					<Belegfeld1>keine-Belegzuordnung</Belegfeld1>
					<Buchungstext>{substring('Bank:' || $item/@description, 1, 60)}</Buchungstext>
					<Festschreibung>false</Festschreibung>
				</Buchungsstapel>
			</Export>
		return datev:render($row)
};

declare function datev:fileName($year as xs:integer, $month as xs:integer) as xs:string {
	'EXTF_Buchungsstapel_' || format-date(current-date(), '[Y0000]-[M00]-[D00]') || '_Monat_' || format-number($month, '00') || '-' || $year || '.csv'
};

declare function datev:csv($home as xs:string, $tenant as xs:string, $year as xs:integer, $month as xs:integer) as xs:string* {
	let $issues := datev:formatIssues()
	return
		if (exists($issues)) then
			error(xs:QName('datev:format'), string-join(('DATEV-Formatregeln sind unvollständig oder falsch:', $issues), ' '))
		else (
			datev:header($tenant, $year, $month),
			datev:rows($home, $tenant, $year, $month),
			datev:missing($home, $tenant, $year, $month)
		)
};
