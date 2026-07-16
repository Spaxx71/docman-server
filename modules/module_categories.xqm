(:
========================================================================
LICENSE AGREEMENT:
This software is distributed WITHOUT ANY WARRANTY and without even the
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
========================================================================
This copy of Docman (a Document managgement an categoriesing system) 
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

module namespace categories = "http://bintellix.com/docman/categories";

(: Todo: version="1.0" :)

declare function categories:listCategories ($home-data, $tenant, $year as xs:integer) {
	let $categories := doc($home-data||'/'||$tenant||'/'||$year||'/budget-categories.dm.xml')
	return
		<BudgetCategories domain="{$categories/BudgetCategories/@domain}">
			{for $category in $categories/BudgetCategories/BudgetCategory
			 order by $categories/@id
			 return
			 	$category
			}
		</BudgetCategories>
};


declare function categories:storeCategories ($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $body) {
	let $collection-path := $home-data||'/'||$tenant||'/'||$year
	let $categories-schema := doc('/db/apps/docman/resources/BudgetCategories.xsd')
	let $validate := validation:jaxv($body, $categories-schema)
	return
		if ($validate) then
			let $result := xmldb:store($collection-path, "budget-categories.dm.xml", $body)
			return
				<BudgetCategories domain="{$body/BudgetCategories/@domain}">
					{$body/BudgetCategories/node()}
				</BudgetCategories>
		else
			let $report := validation:jaxv-report($body, $categories-schema)
			return
				error(xs:QName("schema-validation-error"), "Das XML-Dokument entspricht nicht dem Schema.", $report)
};

