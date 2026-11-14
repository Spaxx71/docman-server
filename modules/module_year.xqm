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

import module namespace email="http://bintellix.com/docman/email" at "/db/apps/docman/modules/module_email.xqm";


declare function year:existsYear($dm-home-data as xs:string, $tenant-id as xs:string, $year as xs:string) as xs:boolean {
	let $collection := $dm-home-data ||"/"|| $tenant-id
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
	let $Collection := concat($dm-home-data, '/', $tenant, '/', string($year))
	let $processes := collection($Collection)/Process[not(Tasks/DocumentTask) and not(Tasks/SimpleTask)]
	let $open-processes := count($processes[not(.//PaymentTask)])
	let $linked-ids := distinct-values(
		for $ref in collection($Collection)//PaymentTask/RefID
		let $id := normalize-space(string($ref))
		where $id != ''
		return $id
	)
	let $accountings := collection($Collection)/BankAccount//Accounting
	let $booked := count($accountings[string(@id) = $linked-ids])
	let $bankings-open := count($accountings) - $booked
	let $transfer :=
		try { count(xmldb:get-child-resources(concat($Collection, '/transfer'))) } catch * { 0 }
	let $email := email:count-unfinished($tenant, $year)
	let $max := $booked + $open-processes + $bankings-open + $transfer + $email
	return
		<Dashboard>
			<OverallCount count="{$max}">
				<Mapped>{$booked}</Mapped>
				<DocumentsOpen>{$open-processes}</DocumentsOpen>
				<BankingsOpen>{$bankings-open}</BankingsOpen>
				<Transfer>{$transfer}</Transfer>
				<Email>{$email}</Email>
			</OverallCount>
		</Dashboard>
};