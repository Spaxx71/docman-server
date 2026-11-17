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

(:
	Permissions as in initialize.xqy for /data/{tenant}/...:
	collections rwxrwx---, files rwxrw----, owner admin, group from tenant.dm.xml Access/Group/@id
:)
declare function year:applyYearDataPermissions($year-col as xs:string, $tenant as xs:string) as element(Permissions) {
	let $tenant-col := replace($year-col, "/[^/]+$", "")
	let $group :=
		let $configured := normalize-space(string(doc($tenant-col || "/tenant.dm.xml")/Tenant/Access/Group/@id))
		return
			if ($configured != "" and sm:group-exists($configured)) then
				$configured
			else if (sm:group-exists($tenant)) then
				$tenant
			else
				"docman"
	let $collections := (
		xs:anyURI($year-col),
		for $child in xmldb:get-child-collections($year-col)
		return xs:anyURI($year-col || "/" || $child)
	)
	let $_cols :=
		for $col in $collections
		return (
			sm:chown($col, "admin"),
			sm:chgrp($col, $group),
			sm:chmod($col, "rwxrwx---")
		)
	let $files :=
		for $col in $collections
		for $file in xmldb:get-child-resources($col)
		let $uri := xs:anyURI($col || "/" || $file)
		return (
			sm:chown($uri, "admin"),
			sm:chgrp($uri, $group),
			sm:chmod($uri, "rwxrw----"),
			<file uri="{$uri}"/>
		)
	return
		<Permissions owner="admin" group="{$group}" collections="{count($collections)}" files="{count($files)}"/>
};

(:
	Create a new accounting year from a previous year:
	- create year collection + child folders
	- copy accounts.dm.xml and year.dm.xml
	- copy bank-account_*.dm.xml, clear prior-year accountings, set saldoInitAmount
	- apply data permissions (same rules as initialize.xqy)
:)
declare function year:createNewYear(
	$dm-home-data as xs:string,
	$tenant as xs:string,
	$new-year as xs:integer,
	$from-year as xs:integer
) as element() {
	let $old-year := $from-year
	let $from := $dm-home-data || "/" || $tenant || "/" || $old-year
	let $to := $dm-home-data || "/" || $tenant || "/" || $new-year
	let $tenant-col := $dm-home-data || "/" || $tenant
	return
		if (not(xmldb:collection-available($tenant-col))) then
			<error code="TENANT_MISSING">Invalid tenant '{$tenant}'</error>
		else if (not(xmldb:collection-available($from))) then
			<error code="FROM_YEAR_MISSING">Source year '{$old-year}' does not exist for tenant '{$tenant}'</error>
		else if (xmldb:collection-available($to)) then
			<error code="YEAR_EXISTS">Target year '{$new-year}' already exists for tenant '{$tenant}'</error>
		else
			let $created :=
				<results tenant="{$tenant}" from="{$old-year}" year="{$new-year}">
					<Folders>
					{
						xmldb:create-collection($tenant-col, string($new-year))
					}
					{
						for $subcollection in xmldb:get-child-collections($from)
						return
							<folder name="{$subcollection}">{xmldb:create-collection($to, $subcollection)}</folder>
					}
					</Folders>
					<Files>
						<Accounts>
						{
							if (xmldb:get-child-resources($from) = "accounts.dm.xml") then
								xmldb:copy-resource($from, "accounts.dm.xml", $to, "accounts.dm.xml")
							else
								<skipped>accounts.dm.xml missing in source year</skipped>
						}
						</Accounts>
						<Year>
						{
							if (xmldb:get-child-resources($from) = "year.dm.xml") then
								xmldb:copy-resource($from, "year.dm.xml", $to, "year.dm.xml")
							else
								<skipped>year.dm.xml missing in source year</skipped>
						}
						</Year>
						<BankAccounts>
						{
							for $file in xmldb:get-child-resources($from)
							where matches($file, "bank\-account_[0-9A-Za-z]+\.dm\.xml")
							return
								<BankAccount file="{$file}">
									<Filename>{xmldb:copy-resource($from, $file, $to, $file)}</Filename>
									{ doc($to || "/" || $file)/BankAccount/BankAccountDetail/AccountName }
									{ doc($to || "/" || $file)/BankAccount/BankAccountDetail/IBAN }
									{
										for $Accounting in doc($to || "/" || $file)/BankAccount/Accountings/Accounting
											[@saldoTimestamp castable as xs:dateTime]
											[@saldoTimestamp <= xs:dateTime($old-year || "-12-31T23:59:59")]
										return
											update delete $Accounting
									}
									{
										let $accountings := doc($from || "/" || $file)/BankAccount/Accountings/Accounting
										let $sortedAccountings :=
											for $accounting in $accountings
											order by $accounting/@saldoTimestamp
											return $accounting
										let $Saldo := $sortedAccountings[last()]/@saldoAmount
										let $AccountingsNode := doc($to || "/" || $file)/BankAccount/Accountings
										return
											if ($Saldo) then
												<Saldo>{update replace $AccountingsNode/@saldoInitAmount with $Saldo}{xs:string($Saldo)}</Saldo>
											else
												<Saldo>{update replace $AccountingsNode/@saldoInitAmount with 0}0</Saldo>
									}
								</BankAccount>
						}
						</BankAccounts>
					</Files>
				</results>
			return
				<results tenant="{$tenant}" from="{$old-year}" year="{$new-year}">
					{$created/Folders}
					{$created/Files}
					{year:applyYearDataPermissions($to, $tenant)}
				</results>
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