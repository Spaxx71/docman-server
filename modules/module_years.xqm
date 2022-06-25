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

module namespace years = "http://bintellix.com/docman/years";

declare function years:listYears($dm-home-data, $tenant) as node()* {
 	let $folders := xmldb:get-child-collections($dm-home-data||'/'||$tenant)
	return
	(
		<Years>
		{
			for $year in $folders
			where not($year = ('transfer')) and matches($year,'[0-9]{4}')
			order by $year descending
			return
				<Year>{$year}</Year>
		}
		</Years>
	,
		<CompanyPaperFiles>
		{
			for $folder in $folders
			where not($folder = ('transfer')) and not(matches($folder,'[0-9]{4}'))
			order by $folder descending
			return
				<CompanyPaperFile>{$folder}</CompanyPaperFile>
		}
		</CompanyPaperFiles>
	)
};