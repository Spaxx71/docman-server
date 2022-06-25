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

(: 
/rest/db/apps/docman/modules/module_binder.xqm
:)

module namespace binder = "http://bintellix.com/docman/binder";

declare function binder:listBinders ($home-data as xs:string, $tenant as xs:string, $year as xs:string) {
	let $binder-collection := $home-data||'/'||$tenant||'/'||$year
	return
	<Binders version="1.0" tenantId="{$tenant}" year="{$year}">
	{
		for $folder in xmldb:get-child-collections($binder-collection)
		where $folder ne "transfer"
		order by $folder
		return
			if ($folder = ('01','02','03','04','05','06','07','08','09','10','11','12')) then
				<Binder name="{$folder}" type="MONTH" month="{$folder}"/>
			else
				<Binder name="{$folder}" type="ARCHIVE"/>
	}
	</Binders>
};

declare function binder:getBinder ($home-data as xs:string, $tenant as xs:string, $year as xs:string, $month as xs:string) {
	let $binder-collection := $home-data||'/'||$tenant||'/'||$year||'/'||format-number($month,'00')||'/'
	return
	<Binder name="{format-number($month,'00')}" type="MONTH" month="{format-number($month,'00')}"/>
};


declare function binder:getBinderBalanceList($home-data as xs:string, $tenant as xs:string, $year as xs:string) {
	if ($year = '' ) then
		<error>Mandatory parameter missing</error>
	else
		let $binder-collection := $home-data||'/'||$tenant||'/'||$year
		let $documents := collection($binder-collection)/Process[not(exists(Tasks/DocumentTask))]

		let $yearInit := doc($home-data||'/'||$tenant||'/'||$year||'/year.dm.xml')//InitSaldo/@amount
		let $startValue := if ($yearInit castable as xs:double) then $yearInit else 0

		let $amounts := 
			for $item in $documents
			let $d := $item/@date
			group by $d
			order by $d
			return
				let $v := sum($item/TotalAmount/@value) div count($item)
				return
					<Amount value="{$v}" date="{$d}" name="{($item/@name)[1]}" type="{substring-before(name(($item/Tasks/*)[1]),'Task')}"/>

		return
		<Balances tenant="{$tenant}" year="{$year}" unit="EUR" saldoInitAmount="{$yearInit}" href="{concat('/',$tenant,'/',$year,'/binders/index.html')}">
		{
			for $item at $pos in $amounts
			return
				try {
					<Balance date="{$item/@date}" value="{$startValue + sum($amounts[position() le $pos]/@value)}" day="{xs:integer((xs:date($item/@date) - xs:date(concat(year-from-date($item/@date),'-01-01'))) div xs:dayTimeDuration('P1D'))}" href="{concat('/',$tenant,'/',$year,'/binders/',format-date($item/@date,'[M00]'),'/',$item/@name,'/edit/',$item/@type,'.html')}"/>
				}
				catch * {
					<error date="{$item/@date}" pos="{$pos}"/>
				} 
		}
		</Balances>
};

