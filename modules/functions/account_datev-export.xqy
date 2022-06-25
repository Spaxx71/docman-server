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

(: 

https://docman.bintellix.com/app/bintellix/accounts/datev-export.csv?type=ledger_account

:)

import module namespace account="http://bintellix.com/docman/account" at "/db/apps/docman/modules/module_account.xqm";


declare option exist:serialize "method=text encoding=ISO-8859-15";

declare function local:datevExportHeader ($tenant as xs:string, $year as xs:string) as xs:string+
{

let $today := format-dateTime(current-dateTime(),'[YYYY]')
let $datevHead := 
		<Export name="DATEV" createHeadline="false">
			<ExportDetails> (: exclusive for "Debitoren/Kreditoren" see binder_datev-export for Buchungsstapel :)
				<ExportType>16</ExportType>
				<ExportName>Debitoren/Kreditoren</ExportName>
				<ExportVersion>5</ExportVersion>
				<CreatedDate>{current-dateTime()}</CreatedDate>
				<CreatorName>bix-accounting</CreatorName>
				<!-- Stb Kaiser 
				<AdviserNr>113845</AdviserNr>
				<TenantNr>20317</TenantNr>
				-->
				<AdviserNr>416766</AdviserNr>
				<TenantNr>50328</TenantNr>
				<YearPeriodStart>{$year}-01-01</YearPeriodStart>
				<Description>Deb/Kred {$tenant} {format-number($month,'00')}/{format-number($year,'0000')}</Description>
				<DictationCode>DM</DictationCode>
			</ExportDetails>
		</Export>

let $account-list := <Export name="DATEV" createHeadline="true">
			<Account>
			</Account>
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
	  transform:transform($account-list, xs:anyURI('xmldb:exist:///db/apps/docman/modules/csv_export.xsl'), $parameters)
	)
};


declare function local:datevExport ($home-data as xs:string, $tenant as xs:string, $year as xs:string) as xs:string+
{

	let $accounts := doc($home-data||'/'||$tenant||'/'||$year||'/'||'accounts.dm.xml')/Accounts
	return
		let $row :=
		<Export name="DATEV" createHeadline="false">
		{
			for $account in $accounts/Account[@type='ledger_account']
			return 
			<Account>
				<Konto>{$account/@kto/data()}</Konto>
				<Kurzbezeichnung>{$account/@id/data()}</Kurzbezeichnung>
				<Adressattyp>
				{
					if ($account/Company/Name/text()) then 
						2
					else if ($account/Person/Name/text()) then
						1
					else
						0
				}
				</Adressattyp>

				<FirmaName>{$account/Company/Name/data()}</FirmaName>
				<Unternehmensgegenstand>{$account/Service/data()}</Unternehmensgegenstand>
				<PersonName>
				{
					if ($account/Company/Name/text()) then 
						$account/Name/data()
					else if ($account/Person/Name/text()) then
						$account/Person/Name/data()
					else
						$account/Name/data()
				}
				</PersonName>
				<NameSonstige>{$account/Name/data()}</NameSonstige>
				{
				for $iban at $pos in tokenize($account/@iban)
				return
					element {'IBAN-'||$pos} {$iban}
				}
				<SEPA-Mandatsreferenz-1>{$account/@debtee}</SEPA-Mandatsreferenz-1>
				{
				if ('debitor'=$account/@classes) then
				(
					<Sprache>1</Sprache>
				,
					<Mahnung>9</Mahnung>
				,
					<Kontoauszug>3</Kontoauszug>
				,
					<Lastschrift>9</Lastschrift>
				)
				else if ('creditor'=$account/@classes) then 
					<Zahlungstraeger>9</Zahlungstraeger>
				else
					()
				}
				<Kundennummer>{$account/CustomerID}</Kundennummer>
				<Bemerkung>{$account/Notes}</Bemerkung>
			</Account>
		}
		</Export>
		let $parameters :=
			<parameters>
				<param name="exist:stop-on-warn" value="yes"/>
				<param name="exist:stop-on-error" value="yes"/>
				<param name="format-spec-uri" value="xmldb:exist:///db/apps/docman/modules/datev_csv_format.xml"/>
			</parameters>
		return 
	  		transform:transform($row, xs:anyURI('xmldb:exist:///db/apps/docman/modules/csv_export.xsl'), $parameters)
};


let $ct-home-web := request:get-attribute('home-web-gui')
let $ct-home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute('year')

let $fileName := 'Kreditoren_'||format-date(current-date(),'[Y0000][M00][D00]')||'.csv'

let $headers := local:datevExportHeader($tenant, $year)
let $data := local:datevExport($ct-home-data, $tenant, $year)

let $header := response:set-header( "Cache-Control",  'no-cache, no-store, max-age=0, must-revalidate')
let $header := response:set-header( "X-Content-Type-Options", 'nosniff' )

let $header := response:set-header( "Content-Type", "text/comma-separated-values; charset=ISO-8895-15")
let $header := response:set-header( "content-disposition", 'attachment; filename="' || $fileName || '"')

return
	( 
		$headers
	,
		$data
	)


