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