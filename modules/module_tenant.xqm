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

xquery version "3.1";

module namespace tenant = "http://bintellix.com/docman/tenant";


declare function tenant:listTenants($dm-home-data) as node()? {
 	let $tenant-collection := $dm-home-data
	return
	<Tenants version="1.0">
	{
		for $collection in xmldb:get-child-collections(xs:anyURI($tenant-collection))
		return
			if (sm:has-access(xs:anyURI($tenant-collection||'/'||$collection),'r--')) then
				tenant:getTenant($dm-home-data, $collection)
			else
				()
	}
	</Tenants>
};


declare function tenant:getTenant($dm-home-data, $tenant-id) as node()? {
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
	</Tenant>
};

