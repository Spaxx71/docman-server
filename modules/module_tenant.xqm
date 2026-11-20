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

(: /rest/db/apps/docman/modules/module_tenant.xqm :)

xquery version "3.1";

module namespace tenant = "http://bintellix.com/docman/tenant";


declare function tenant:existsTenant($dm-home-data as xs:string, $tenant-id as xs:string) as xs:boolean {
	let $collection := $dm-home-data
	let $tenants := xmldb:get-child-collections(xs:anyURI($collection))
	return
		if (exists(index-of($tenants, $tenant-id))) then
			true()
		else
			false()
};


declare function tenant:listTenants($dm-home-data as xs:string) as node()? {
	<Tenants version="1.0">
	{
		for $collection in xmldb:get-child-collections(xs:anyURI($dm-home-data))
		return
			if (sm:has-access(xs:anyURI($dm-home-data||'/'||$collection),'r--')) then
				tenant:getTenant($dm-home-data, $collection)
			else
				()
	}
	</Tenants>
};


declare function tenant:getTenant($dm-home-data as xs:string, $tenant-id as xs:string) as node()? {
	let $tenant-collection := $dm-home-data||'/'||$tenant-id
	let $tenant-details := doc($tenant-collection||'/tenant.dm.xml')
	let $email := $tenant-details/Tenant/EmailAccount
	return
	<Tenant version="1.0" id="{$tenant-id}">
		{$tenant-details/Tenant/@priority}
		{
			if ($tenant-details/Tenant/Name) then
				<Name>{$tenant-details/Tenant/Name/text()}</Name>
			else
				<Name>{$tenant-id} (leer)</Name>
		}
		{
			if (exists($tenant-details/Tenant/dateFormat)) then
				<dateFormat>{string($tenant-details/Tenant/dateFormat)}</dateFormat>
			else ()
		}
		{
			if (exists($tenant-details/Tenant/currency)) then
				<currency>{string($tenant-details/Tenant/currency)}</currency>
			else ()
		}
		{
			if (exists($tenant-details/Tenant/currencies)) then
				<currencies>{string($tenant-details/Tenant/currencies)}</currencies>
			else ()
		}
		{
			if (exists($email)) then
				<EmailAccount>
					<Hostname>{string($email/Hostname)}</Hostname>
					<Port>{string($email/Port)}</Port>
					<TlsMode>{
						let $mode := lower-case(normalize-space(string($email/TlsMode)))
						return
							if ($mode = ('tls', 'starttls', 'none')) then $mode
							else if (string($email/Protocol) = 'imaps' or string($email/@protocol) = 'imaps') then 'tls'
							else 'tls'
					}</TlsMode>
					<Username>{string($email/Username)}</Username>
					<Password>{
						if (normalize-space(string($email/Password)) = '') then ''
						else '********'
					}</Password>
				</EmailAccount>
			else ()
		}
		<CompanyPaperFiles>
		{
			let $folders := xmldb:get-child-collections($dm-home-data||'/'||$tenant-id)
			for $folder in $folders
			where not($folder = ('transfer')) and not(matches($folder,'[0-9]{4}'))
			order by $folder descending
			return
				<CompanyPaperFile>{$folder}</CompanyPaperFile>
		}
		</CompanyPaperFiles>	
	</Tenant>
};

(: Schreibt Tenant-Stammdaten inkl. E-Mail-Zugang; Access bleibt aus der bestehenden Datei erhalten. :)
declare function tenant:storeTenant($dm-home-data as xs:string, $tenant-id as xs:string, $body as node()) {
	let $path := $dm-home-data||'/'||$tenant-id
	let $stored := doc($path||'/tenant.dm.xml')/Tenant
	let $incoming := if ($body/self::Tenant) then $body else $body/Tenant
	return
		if (empty($stored)) then
			error(xs:QName('docman:TenantMissing'), concat('Tenant ', $tenant-id, ' existiert nicht.'))
		else if (empty($incoming)) then
			error(xs:QName('docman:TenantInvalid'), 'Tenant-XML fehlt.')
		else
			let $password-in := normalize-space(string($incoming/EmailAccount/Password))
			let $password :=
				if (empty($incoming/EmailAccount)) then
					string($stored/EmailAccount/Password)
				else if ($password-in = '' or matches($password-in, '^\*+$')) then
					string($stored/EmailAccount/Password)
				else
					$password-in
			let $tls :=
				let $mode := lower-case(normalize-space(string($incoming/EmailAccount/TlsMode)))
				return
					if ($mode = ('tls', 'starttls', 'none')) then $mode else 'tls'
			let $port :=
				let $raw := normalize-space(string($incoming/EmailAccount/Port))
				return
					if ($raw castable as xs:integer) then $raw
					else if ($tls = 'tls') then '993'
					else '143'
			let $email :=
				if (empty($incoming/EmailAccount)) then
					$stored/EmailAccount
				else
					<EmailAccount>
						<Hostname>{normalize-space(string($incoming/EmailAccount/Hostname))}</Hostname>
						<Port>{$port}</Port>
						<TlsMode>{$tls}</TlsMode>
						<Username>{normalize-space(string($incoming/EmailAccount/Username))}</Username>
						<Password>{$password}</Password>
					</EmailAccount>
			let $priority :=
				if (exists($incoming/@priority) and string($incoming/@priority) != '') then $incoming/@priority
				else $stored/@priority
			let $name :=
				if (normalize-space(string($incoming/Name)) != '') then normalize-space(string($incoming/Name))
				else string($stored/Name)
			let $next :=
				<Tenant id="{$tenant-id}">
					{$priority}
					<Name>{$name}</Name>
					{
						if (exists($incoming/dateFormat)) then <dateFormat>{normalize-space(string($incoming/dateFormat))}</dateFormat>
						else $stored/dateFormat
					}
					{
						if (exists($incoming/currency)) then <currency>{normalize-space(string($incoming/currency))}</currency>
						else $stored/currency
					}
					{
						if (exists($incoming/currencies)) then <currencies>{normalize-space(string($incoming/currencies))}</currencies>
						else $stored/currencies
					}
					{$email}
					{$stored/Access}
				</Tenant>
			let $store := xmldb:store($path, 'tenant.dm.xml', $next)
			return tenant:getTenant($dm-home-data, $tenant-id)
};

