xquery version "3.1";

(:
	Baut den Testmandanten systematisch auf.
	Vorhandene Dateien bleiben stehen. Ein zweiter Lauf ergänzt nur, was fehlt.
:)

module namespace test-tenant = "http://bintellix.com/docman/test-tenant";

import module namespace year="http://bintellix.com/docman/year" at "/db/apps/docman/modules/module_year.xqm";
import module namespace binder="http://bintellix.com/docman/binder" at "/db/apps/docman/modules/module_binder.xqm";
import module namespace document="http://bintellix.com/docman/document" at "/db/apps/docman/modules/module_document.xqm";

declare function test-tenant:build($home as xs:string, $tenant as xs:string, $year as xs:integer) as element(TestTenant) {
	let $tenant-col := $home || "/" || $tenant
	let $year-col := $tenant-col || "/" || string($year)
	let $tenant-step := test-tenant:ensure-tenant($home, $tenant)
	let $year-step := test-tenant:ensure-year($home, $tenant, $year)
	let $folders := test-tenant:ensure-folders($tenant-col, $year-col)
	let $bank := test-tenant:ensure-bank($year-col, $year)
	let $archive := test-tenant:ensure-archive($home, $tenant, string($year))
	let $process := test-tenant:ensure-process($home, $tenant, $year)
	let $rights :=
		if (xmldb:collection-available($year-col)) then
			year:applyYearDataPermissions($year-col, $tenant)
		else
			<Permissions skipped="year-missing"/>
	return
		<TestTenant tenant="{$tenant}" year="{$year}">
			{$tenant-step}
			{$year-step}
			<Folders>{$folders}</Folders>
			{$bank}
			{$archive}
			{$process}
			{$rights}
		</TestTenant>
};

declare function test-tenant:ensure-tenant($home as xs:string, $tenant as xs:string) as element(Tenant) {
	let $col := $home || "/" || $tenant
	let $file := $col || "/tenant.dm.xml"
	return
		if (doc-available($file)) then
			<Tenant status="skipped" id="{doc($file)/Tenant/@id}"/>
		else
			let $created :=
				if (xmldb:collection-available($col)) then ()
				else xmldb:create-collection($home, $tenant)
			let $stored := xmldb:store($col, "tenant.dm.xml",
				<Tenant id="mycompany" priority="5">
					<Name>MyCompany (test)</Name>
					<Access>
						<Group id="test">
							<Users>
								<User id="admin"/>
							</Users>
						</Group>
					</Access>
				</Tenant>
			)
			return
				<Tenant status="created" id="mycompany" resource="{$stored}"/>
};

declare function test-tenant:ensure-year($home as xs:string, $tenant as xs:string, $year as xs:integer) as element(Year) {
	let $col := $home || "/" || $tenant || "/" || string($year)
	let $made :=
		if (xmldb:collection-available($col)) then "skipped"
		else (
			xmldb:create-collection($home || "/" || $tenant, string($year)),
			"created"
		)
	let $year-file :=
		if (doc-available($col || "/year.dm.xml")) then "skipped"
		else (
			xmldb:store($col, "year.dm.xml", <Year><InitSaldo amount="0.0"/></Year>),
			"created"
		)
	return
		<Year status="{$made}" file="{$year-file}" accounts="{if (doc-available($col || '/accounts.dm.xml')) then 'present' else 'missing'}"/>
};

declare function test-tenant:ensure-folders($tenant-col as xs:string, $year-col as xs:string) as element(Folder)* {
	let $months := ("01","02","03","04","05","06","07","08","09","10","11","12","dokumente","steuer","transfer")
	let $year-folders :=
		for $name in $months
		return test-tenant:ensure-collection($year-col, $name)
	let $paper := test-tenant:ensure-collection($tenant-col, "business-paper")
	return ($year-folders, $paper)
};

declare function test-tenant:ensure-collection($parent as xs:string, $name as xs:string) as element(Folder) {
	let $path := $parent || "/" || $name
	return
		if (xmldb:collection-available($path)) then
			<Folder name="{$name}" status="skipped"/>
		else
			<Folder name="{$name}" status="created">{xmldb:create-collection($parent, $name)}</Folder>
};

declare function test-tenant:bank-document($year as xs:integer) as element(BankAccount) {
	<BankAccount kto="12000">
		<BankAccountDetail>
			<BankName>Testbank</BankName>
			<AccountName>Giro Test</AccountName>
			<AccountNick>Giro</AccountNick>
			<KTNR>1234567890</KTNR>
			<BLZ>37040044</BLZ>
			<IBAN>DE89370400440532013000</IBAN>
			<BIC>COBADEFFXXX</BIC>
			<CurrencyUnit>EUR</CurrencyUnit>
			<Notes>Testkonto ohne Online-Banking</Notes>
		</BankAccountDetail>
		<Accountings saldoInitAmount="0">
			<Accounting id="PAY00000000-0000-4000-8000-000000000001" saldoAmount="2500.00" saldoTimestamp="{$year}-01-15T10:00:00" origin="Manual" budgetCategory="Erlöse">
				<SalesType key="credit">Eingang</SalesType>
				<BookingDate>{$year}-01-15</BookingDate>
				<ValueDate>{$year}-01-15</ValueDate>
				<CustomerRef>TEST-IN-001</CustomerRef>
				<EndToEndRef>E2E-TEST-001</EndToEndRef>
				<Amount type="CREDIT">2500.00</Amount>
				<CurrencyUnit>EUR</CurrencyUnit>
			</Accounting>
			<Accounting id="PAY00000000-0000-4000-8000-000000000002" saldoAmount="2381.00" saldoTimestamp="{$year}-03-02T10:00:00" origin="Manual" budgetCategory="Miete">
				<SalesType key="debit">Miete</SalesType>
				<BookingDate>{$year}-03-02</BookingDate>
				<ValueDate>{$year}-03-02</ValueDate>
				<CustomerRef>TEST-RENT-003</CustomerRef>
				<EndToEndRef>E2E-TEST-003</EndToEndRef>
				<Amount type="DEBIT">-119.00</Amount>
				<CurrencyUnit>EUR</CurrencyUnit>
			</Accounting>
		</Accountings>
	</BankAccount>
};

declare function test-tenant:ensure-bank($year-col as xs:string, $year as xs:integer) as element(Bank) {
	let $name := "bank-account_12000.dm.xml"
	return
		if (doc-available($year-col || "/" || $name)) then
			<Bank status="skipped" kto="12000"/>
		else
			let $doc := test-tenant:bank-document($year)
			let $schema := doc("/db/apps/docman/resources/Bank.xsd")
			return
				if (not(validation:jaxv($doc, $schema))) then
					<Bank status="error" kto="12000">{validation:jaxv-report($doc, $schema)}</Bank>
				else
					<Bank status="created" kto="12000">{xmldb:store($year-col, $name, $doc)}</Bank>
};

declare function test-tenant:ensure-archive($home as xs:string, $tenant as xs:string, $year as xs:string) as element(Archive) {
	let $path := $home || "/" || $tenant || "/" || $year || "/Eingang"
	return
		if (xmldb:collection-available($path)) then
			<Archive status="skipped" name="Eingang"/>
		else
			try {
				<Archive status="created">{binder:createArchive($home, $tenant, $year, "Eingang")}</Archive>
			} catch * {
				<Archive status="error">{$err:description}</Archive>
			}
};

declare function test-tenant:process-document($year as xs:integer, $binder as xs:string) as element(Process) {
	let $stamp := string($year) || "-03-15T09:00:00"
	return
		<Process id="PRO00000000-0000-4000-8000-000000000010" name="{concat($year, '-03-15_Miete')}" binder="{$binder}" date="{$year}-03-15" created="{$stamp}" user="admin">
			<Section/>
			<TotalAmount value="119.00"/>
			<Tasks>
				<SimpleTask id="ACCxxx" type="note" date="{$year}-03-15" created="{$stamp}" user="admin" isMaster="true">
					<Files/>
					<Bookings/>
					<Owner>70000</Owner>
					<RefID>TEST-RENT-003</RefID>
					<Description>Miete März, Testbeleg</Description>
				</SimpleTask>
			</Tasks>
			<Notes/>
		</Process>
};

declare function test-tenant:ensure-process($home as xs:string, $tenant as xs:string, $year as xs:integer) as element(Process) {
	let $filename := string($year) || "-03-15_Miete"
	let $path := $home || "/" || $tenant || "/" || string($year) || "/Eingang/" || $filename || ".dm.xml"
	return
		if (doc-available($path)) then
			<Process status="skipped" file="{$filename}.dm.xml"/>
		else if (not(xmldb:collection-available($home || "/" || $tenant || "/" || string($year) || "/Eingang"))) then
			<Process status="skipped" reason="archive-missing"/>
		else
			let $created := document:createDocument($home, $tenant, $year, "Eingang", $filename, test-tenant:process-document($year, "Eingang"))
			return
				if ($created/self::error) then
					<Process status="error">{$created}</Process>
				else
					<Process status="created">{$created}</Process>
};
