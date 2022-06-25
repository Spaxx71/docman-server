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

xquery version "3.1" encoding "UTF-8";

(: https://apps.datev.de/dnlexka/document/1080789 :)

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace bookings="http://bintellix.com/docman/bookings" at "/db/apps/docman/modules/module_bookings.xqm";

(: 
https://docman.bintellix.com/app/test/binder/2000/01/datev_export.csv

:)

declare option exist:serialize "method=text encoding=ISO-8859-15";

declare function local:datevExportHeader ($tenant as xs:string, $year as xs:integer, $month as xs:integer) as xs:string+
{

let $startDate := xs:date(format-number($year,'00')||'-'||format-number($month,'00')||'-01')
let $isLeapYear := if ((($year mod 4 = 0) and ($year mod 100 != 0)) or ($year mod 400 = 0)) then true() else false()

let $daysInMonth := if ($month = 2 and $isLeapYear) then
			"29"
		    else 
			("31","28","31","30","31","30","31","31","30","31","30","31")[$month]
let $endDate := xs:date(format-number($year,'00')||'-'||format-number($month,'00')||'-'||format-number($daysInMonth,'00'))

let $test := format-dateTime(current-dateTime(),'[Y][M][D]')
let $datevHead := 
		<Export name="DATEV" createHeadline="false">
			<ExportDetails> (: exclusive for "Buchungsstapel" see account_datev-export for Debitoren/Kreditoren :)
				<ExportType>21</ExportType>
				<ExportName>Buchungsstapel</ExportName>
				<ExportVersion>12</ExportVersion>
				<CreatedDate>{current-dateTime()}</CreatedDate>
				<CreatorName>docman</CreatorName>
				<!-- Stb Kaiser 
				<AdviserNr>113845</AdviserNr>
				<TenantNr>20317</TenantNr>
				-->
				<AdviserNr>416766</AdviserNr>
				<TenantNr>50328</TenantNr>
				<YearPeriodStart>{$year}-01-01</YearPeriodStart>
				<BookingStartDate>{$startDate}</BookingStartDate>
				<BookingEndDate>{$endDate}</BookingEndDate>
				<Description>{$tenant} {format-number($month,'00')}/{format-number($year,'0000')}</Description>
				<DictationCode>DM</DictationCode>
				<CurrencyCode>EUR</CurrencyCode>
				<LockingUp>0</LockingUp>
				<AccountingType>1</AccountingType>
				<PurposeOfAccounting>0</PurposeOfAccounting>
				<AccountSystem>04</AccountSystem>
			</ExportDetails>
		</Export>

let $buchungsstapel := <Export name="DATEV" createHeadline="true">
			<Buchungsstapel>
			</Buchungsstapel>
		</Export>

let $parameters :=
	<parameters>
		<param name="exist:stop-on-warn" value="yes"/>
		<param name="exist:stop-on-error" value="yes"/>
		<param name="format-spec-uri" value="xmldb:exist:///db/apps/docman/modules/datev_csv_format.xml"/>
	</parameters>
return 
	(
	  transform:transform($datevHead, xs:anyURI('xmldb:exist:///db/apps/docman/modules/csv_export.xsl'), $parameters)
	,
	  transform:transform($buchungsstapel, xs:anyURI('xmldb:exist:///db/apps/docman/modules/csv_export.xsl'), $parameters)
	)
};


declare function local:datevExport ($ct-home-data, $tenant as xs:string, $year as xs:integer, $month as xs:integer) as xs:string+
{
	let $data-collection := $ct-home-data||'/'||$tenant||'/'||format-number($year,'00')
	let $accounts := doc($ct-home-data||'/'||$tenant||'/'||'accounts.dm.xml')/Accounts
	for $booking at $pos in collection($data-collection)/Process//Bookings/Booking[month-from-date(@date) = $month]
	order by xs:date($booking/@date)
	return
		let $doctype := $booking/../@type/data()
		let $toClasses := $accounts/Account[@kto=$booking/To/@kto]/@classes
		let $row :=
		<Export name="DATEV" createHeadline="false">
			<Buchungsstapel>
				<Umsatz>{ $booking/@amountValue/data() }</Umsatz>
				<SH-Kennzeichen>
				{
					if ($booking/@amountValue >= 0) then
						'S'
					else
						'ERROR: negative amount'
					(: - Aktivkonto -
					if ('creditor' = $toClasses) then
						'S'
					- Passivkonto - 
					else if ('debitor' = $toClasses) then
						'H'
					else
						"ERROR: undefined From classes '"||$toClasses||"' mapping. At "||$pos||" From/@kto="||$booking/From/@kto||"."
					:)
				}
				</SH-Kennzeichen>
				<WKZ-Umsatz>{$booking/@amountUnit/data()}</WKZ-Umsatz>
				<Konto>{$booking/@credit/data()}</Konto>
				<Gegenkonto>{$booking/@debit/data()}</Gegenkonto>
				<BU-Schluessel>
				{
					if($booking/@taxKey/data()='-') then
						()
					else if($booking/@taxKey/data()='X') then
						()
					else if($booking/@taxKey/data()='1') then (: todo :)
						()
					else if($booking/@taxKey/data()='20') then (: todo :)
						()
					else if($booking/@taxKey/data()='27') then (: todo :)
						'7'
					else if($booking/@taxKey/data()='29') then (: todo :)
						'9'
					else if($booking/@taxKey/data()='60') then (: todo :)
						'10'
					else if($booking/@taxKey/data()='68') then (: todo :)
						'18'
					else if($booking/@taxKey/data()='69') then (: todo :)
						'19'
					else
						$booking/@taxKey/data()
				}
				</BU-Schluessel>
				<!--
				{
					if ($booking/@taxKey = ('91','92','94','95')) then
						<SachverhaltLL>7</SachverhaltLL>
					else	
						()
				}
				-->
				<Belegdatum>{$booking/@date/data()}</Belegdatum>
				<Belegfeld1>{if ($booking/@refID/data() = '#') then '' else substring(replace($booking/@refID/data(),'[^A-Za-z0-9$&amp;%*+\-/]','-'),1,36)}</Belegfeld1>
				<!--
				<Belegfeld2>{$booking/@transactionID/data()}</Belegfeld2>
				-->
				<Skonto></Skonto>
				<Buchungstext>{
					let $type := 
						if ($booking/../../name()="PaymentTask") then 
							concat("Bezahlung", if ($booking/../../@type="payment-bank") then " (Bank)" else "")
						else if ($booking/../../name()="CommodityTask") then 
							concat("Rechnung", if ($booking/../../@type="invoice-out") then " (aus)" else if ($booking/../../@type="invoice-in") then " (ein)" else "")
						else if ($booking/../../name()="EmployeeSalaryTask") then 
							"Gehalt"
						else 
							replace($booking/../../name(),'Task','')
					let $description := $booking/@description
					return
						substring($type || ": " || $description,1,60)}</Buchungstext>
				<!--
 				<Beleglink>{$booking/../../../../@id/data()}</Beleglink>
				-->
				<!--
				<Beleglink>
				{
					if (name($booking/../..)='CommodityTask') then 
						concat('https://docman.bintellix.com/app', xs:string(($booking/../../../(InvoiceInTask|InvoiceOutTask)/Files/File)[1]/@src))
					else
						let $src := ($booking/../../Files/File/@src)[1]/data()
						return 
							if ($src != '') then
								concat('https://docman.bintellix.com/app',$src)
							else
								()
				}
				</Beleglink>
				<BeleginfoArt1>{$booking/@type/data()}</BeleginfoArt1>
				<BeleginfoInhalt1>{$booking/@id/data()}</BeleginfoInhalt1>
				-->
				<Festschreibung>false</Festschreibung>
			</Buchungsstapel>
		</Export>
		let $parameters :=
			<parameters>
				<param name="exist:stop-on-warn" value="yes"/>
				<param name="exist:stop-on-error" value="yes"/>
				<param name="format-spec-uri" value="xmldb:exist:///db/apps/docman/modules/datev_csv_format.xml"/>
			</parameters>
		return 
			(: transform:stream-transform :)
	  		transform:transform($row, xs:anyURI('xmldb:exist:///db/apps/docman/modules/csv_export.xsl'), $parameters)
};


declare function local:datevMissingBank ($ct-home-data, $tenant as xs:string, $year as xs:integer, $month as xs:integer) as xs:string+ 
{
    for $item at $pos in bookings:missingBankBookings($ct-home-data, $tenant, $year, $month, 1372) (: or better 1370?! :)
    order by xs:date($item/@date)
    return
        let $row :=
        <Export name="DATEV" createHeadline="false">
            <Buchungsstapel>
                <Umsatz>{number($item/@amountValue/data())}</Umsatz>
                <SH-Kennzeichen>{'S'}</SH-Kennzeichen>
                <WKZ-Umsatz>EUR</WKZ-Umsatz>
                <Konto>{$item/@credit/data()}</Konto>
                <Gegenkonto>{$item/@debit/data()}</Gegenkonto>
                <Belegdatum>{$item/@date/data()}</Belegdatum>
                <Belegfeld1>keine-Belegzuordnung</Belegfeld1>
                <!--<Belegfeld2>{''}</Belegfeld2>-->
                <Buchungstext>Bank:{substring($item/@description,1,60 - 5)}</Buchungstext>
				
				<!--
				<Beleglink>{$item/@refID/data()}</Beleglink>
                <BeleginfoArt1>Fehlende Bankzuordnung</BeleginfoArt1>
                <BeleginfoInhalt1>Fehlende Bankzuordnung</BeleginfoInhalt1>
				-->
                <Festschreibung>false</Festschreibung>
            </Buchungsstapel>
        </Export>
        let $parameters :=
            <parameters>
                <param name="exist:stop-on-warn" value="yes"/>
                <param name="exist:stop-on-error" value="yes"/>
                <param name="format-spec-uri" value="xmldb:exist:///db/apps/docman/modules/datev_csv_format.xml"/>
            </parameters>
        return 
			(: transform:stream-transform :)
            transform:transform($row, xs:anyURI('xmldb:exist:///db/apps/docman/modules/csv_export.xsl'), $parameters)
};



let $ct-home-web := request:get-attribute('home-web-gui')
let $ct-home-data := request:get-attribute('home-data')

let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute('year')
let $month := request:get-attribute('binder')
let $fileName := 'EXTF_Buchungsstapel_'||format-date(current-date(),'[Y0000]-[M00]-[D00]')||'_Monat_'||$month||'-'||$year||'.csv'

let $header := response:set-header( "Cache-Control",  'no-cache, no-store, max-age=0, must-revalidate')
let $header := response:set-header( "X-Content-Type-Options", 'nosniff' )

let $header := response:set-header( "Content-Type", "text/comma-separated-values; charset=ISO-8895-15")
let $header := response:set-header( "content-disposition", 'attachment; filename="' || $fileName || '"')

return
	( 
		local:datevExportHeader($tenant, xs:integer($year), xs:integer($month))
	,
		local:datevExport($ct-home-data, $tenant, xs:integer($year), xs:integer($month))
	,
		local:datevMissingBank($ct-home-data, $tenant, xs:integer($year), xs:integer($month))
	)


