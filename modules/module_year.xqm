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

(: /rest/db/apps/docman/modules/module_year.xqm :)

xquery version "3.1";

module namespace year = "http://bintellix.com/docman/year";


declare function year:existsYear($dm-home-data as xs:string, $tenant-id as xs:string, $year as xs:string) as xs:boolean {
	let $collection := $dm-home-data ||"/"|| $tenant
	let $years := xmldb:get-child-collections(xs:anyURI($collection))
	return
		if (exists(index-of($years, $year))) then
			true()
		else
			false()
};


declare function year:listYears($dm-home-data, $tenantId as xs:string) as node()* {
 	let $folders := xmldb:get-child-collections($dm-home-data||'/'||$tenantId)
	return
	(
		<Years version="1.0" tenant="{$tenantId}">
		{
			for $year in $folders
			where not($year = ('transfer')) and matches($year,'[0-9]{4}')
			order by $year descending
			return
				<Year>{$year}</Year>
		}
		</Years>

	)
};


declare function year:getYear($dm-home-data, $tenantId as xs:string, $year as xs:integer) as node()* {
 	let $folders := xmldb:get-child-collections($dm-home-data||'/'||$tenantId)
	return
	(
		<Year version="1.0" tenant="{$tenantId}">
		</Year>
	)
};

declare function year:dashboard($dm-home-data as xs:string, $tenant as xs:string, $year as xs:integer) as element(Dashboard) {
	let $Collection := concat($dm-home-data, '/', $tenant, '/', $year)
	let $Documents := collection($Collection)/Process[not(Tasks/DocumentTask) and not(Tasks/SimpleTask)]
	let $DocumentsCount := count($Documents)
	let $Mapped := count($Documents[.//PaymentTask])
	let $BankingsCount := count(collection($Collection)/BankAccount//Accounting)
	let $Transfer := count(xmldb:get-child-resources(concat($Collection, '/transfer')))
	let $Email := 0
	let $Max := $Mapped + ($DocumentsCount - $Mapped) + ($BankingsCount - $Mapped) + $Transfer + $Email
	return
		<Dashboard>
			<OverallCount count="{$Max}">
				<Mapped>{$Mapped}</Mapped>
				<DocumentsOpen>{$DocumentsCount - $Mapped}</DocumentsOpen>
				<BankingsOpen>{$BankingsCount - $Mapped}</BankingsOpen>
				<Transfer>{$Transfer}</Transfer>
				<Email>{$Email}</Email>
			</OverallCount>
		</Dashboard>
};