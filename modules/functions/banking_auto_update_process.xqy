xquery version "3.1";

(:
Periodic FinTS auto update for all OnlineBanking accounts of the current year.
Uses mode=auto; SCA_REQUIRED is recorded without blocking.
:)

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace banking="http://bintellix.com/docman/banking" at "/db/apps/docman/modules/module_banking.xqm";
import module namespace scheduler="http://exist-db.org/xquery/scheduler";

declare function local:current-year() as xs:integer {
	xs:integer(format-date(current-date(), '[Y0000]'))
};

declare function local:update-tenant($tenant as xs:string, $year as xs:integer) {
	let $banks := collection($main:home-data || '/' || $tenant || '/' || $year)/BankAccount[BankAccountDetail/OnlineBanking]
	return
		for $bank in $banks
		let $kto := string($bank/@kto)
		let $from := current-date() - xs:dayTimeDuration('P14D')
		let $till := current-date() - xs:dayTimeDuration('P1D')
		let $result :=
			try {
				banking:updateViaFinTS($main:home-data, $tenant, $kto, $year, $from, $till, true(), 'auto')
			} catch * {
				<error code="{$err:code}">{$err:description}</error>
			}
		let $sca := exists($result[@code='SCA_REQUIRED']) or contains(string($result), 'SCA_REQUIRED')
		let $status-file := 'hbci_auto_' || $kto || '_status.dm.xml'
		let $_ := xmldb:store($main:home-data, $status-file,
			<AutoUpdate timestamp="{current-dateTime()}" tenant="{$tenant}" year="{$year}" kto="{$kto}" sca-required="{$sca}">
				{$result}
			</AutoUpdate>
		)
		return
			<Account kto="{$kto}" sca-required="{$sca}">{$result}</Account>
};

let $year := local:current-year()
let $tenants := xmldb:get-child-collections($main:home-data)
return
	<result src="banking_auto_update_process.xqy" year="{$year}" timestamp="{current-dateTime()}">
	{
		for $tenant in $tenants
		where doc-available($main:home-data || '/' || $tenant || '/' || $year) or xmldb:collection-available($main:home-data || '/' || $tenant || '/' || $year)
		return
			<Tenant id="{$tenant}">{local:update-tenant($tenant, $year)}</Tenant>
	}
	</result>
