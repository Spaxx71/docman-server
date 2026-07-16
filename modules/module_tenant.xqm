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
	return
	<Tenant version="1.0" id="{$tenant-id}">
		{$tenant-details/Tenant/@priority}
		{
			if ($tenant-details/Tenant/Name) then
				<Name>{$tenant-details/Tenant/Name/text()}</Name>
			else
				<Name>{$tenant-id} (leer)</Name>
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

