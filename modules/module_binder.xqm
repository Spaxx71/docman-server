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

import module namespace di = "http://bintellix.com/docman/document-intelligence" at "/db/apps/docman/modules/module_document-intelligence.xqm";

declare function local:is-sidecar($name as xs:string) as xs:boolean {
	di:is-sidecar($name)
};

declare function local:archive-path($home-data as xs:string, $tenant as xs:string, $year as xs:string, $binder as xs:string) as xs:string {
	$home-data || '/' || $tenant || '/' || $year || '/' || $binder
};

declare function local:transfer-path($home-data as xs:string, $tenant as xs:string, $year as xs:string) as xs:string {
	$home-data || '/' || $tenant || '/' || $year || '/transfer'
};

declare function local:ensure-transfer($home-data as xs:string, $tenant as xs:string, $year as xs:string) as xs:string {
	let $year-col := $home-data || '/' || $tenant || '/' || $year
	let $transfer := local:transfer-path($home-data, $tenant, $year)
	let $_ :=
		if (xmldb:collection-available($transfer)) then ()
		else if (not(xmldb:collection-available($year-col))) then
			error(xs:QName('binder:YearMissing'), concat('Jahr fehlt: ', $year))
		else
			xmldb:create-collection($year-col, 'transfer')
	return $transfer
};

declare function local:unique-transfer-name($transfer as xs:string, $name as xs:string) as xs:string {
	if (empty(index-of(xmldb:get-child-resources($transfer), $name))) then
		$name
	else
		let $stem := replace($name, '\.[^.]+$', '')
		let $ext :=
			if (contains($name, '.')) then
				'.' || replace($name, '^.*\.', '')
			else
				''
		let $candidates :=
			for $i in 1 to 99
			return $stem || '_' || $i || $ext
		let $free := $candidates[empty(index-of(xmldb:get-child-resources($transfer), .))][1]
		return
			if ($free) then $free
			else error(xs:QName('binder:NameClash'), concat('Kein freier Name in Transfer für: ', $name))
};

declare function local:related-xml-names($file as xs:string) as xs:string* {
	let $stem := di:stem($file)
	return distinct-values((
		$stem || '.dm.xml',
		$file || '.dm.xml'
	))
};

declare function local:remove-related-xml($collection as xs:string, $file as xs:string) as element()* {
	for $name in local:related-xml-names($file)
	where exists(index-of(xmldb:get-child-resources($collection), $name))
	return
		try {
			let $_ := xmldb:remove($collection, $name)
			return <RemovedXml name="{$name}" collection="{$collection}"/>
		} catch * {
			<RemovedXml name="{$name}" collection="{$collection}" error="{$err:description}"/>
		}
};

(: Alle Nicht-Sidecar-Dateien rekursiv, inkl. Unterordner. :)
declare function local:collect-files($collection as xs:string, $rel as xs:string) as element(File)* {
	(
		for $name in xmldb:get-child-resources($collection)
		where not(local:is-sidecar($name))
		order by $name
		return
			<File name="{$name}"
				folder="{$rel}"
				size="{xmldb:size($collection, $name)}"
				created="{xmldb:created($collection, $name)}"/>
		,
		for $child in xmldb:get-child-collections($collection)
		order by $child
		let $next-rel := if ($rel = '') then $child else $rel || '/' || $child
		return local:collect-files($collection || '/' || $child, $next-rel)
	)
};

declare function local:collect-sidecars($collection as xs:string) as xs:string* {
	(
		for $name in xmldb:get-child-resources($collection)
		where local:is-sidecar($name)
		return $collection || '::' || $name
		,
		for $child in xmldb:get-child-collections($collection)
		return local:collect-sidecars($collection || '/' || $child)
	)
};

declare function local:find-file-collection($collection as xs:string, $file as xs:string) as xs:string? {
	if (exists(index-of(xmldb:get-child-resources($collection), $file))) then
		$collection
	else
		(
			for $child in xmldb:get-child-collections($collection)
			let $found := local:find-file-collection($collection || '/' || $child, $file)
			where exists($found)
			return $found
		)[1]
};

declare function local:archive-stats($path as xs:string) as map(*) {
	let $files :=
		if (xmldb:collection-available($path)) then
			local:collect-files($path, '')
		else
			()
	let $sidecars :=
		if (xmldb:collection-available($path)) then
			local:collect-sidecars($path)
		else
			()
	let $subcols :=
		if (xmldb:collection-available($path)) then
			xmldb:get-child-collections($path)
		else
			()
	return map {
		"files": count($files),
		"size": sum(($files/@size ! (if (. castable as xs:long) then xs:long(.) else 0), 0)),
		"sidecars": count($sidecars),
		"empty": empty($files) and empty($sidecars) and empty($subcols)
	}
};

declare function binder:listArchiveFiles($home-data as xs:string, $tenant as xs:string, $year as xs:string, $binder as xs:string) {
	let $folder := normalize-space($binder)
	let $path := local:archive-path($home-data, $tenant, $year, $folder)
	return
		if (not(local:deletable-archive-name($folder))) then
			error(xs:QName('binder:InvalidName'), concat('Ungültiger Ordnername: ', $folder))
		else if (not(xmldb:collection-available($path))) then
			error(xs:QName('binder:Missing'), concat('Ordner fehlt: ', $folder))
		else
			let $files := local:collect-files($path, '')
			let $stats := local:archive-stats($path)
			return
				<ArchiveFiles version="1.0" tenant="{$tenant}" year="{$year}" binder="{$folder}"
					files="{$stats?files}" size="{$stats?size}" sidecars="{$stats?sidecars}" empty="{$stats?empty}">
				{
					for $file in $files
					order by string($file/@folder), string($file/@name)
					return $file
				}
				</ArchiveFiles>
};

declare function binder:moveFileToTransfer(
	$home-data as xs:string,
	$tenant as xs:string,
	$year as xs:string,
	$binder as xs:string,
	$file as xs:string
) {
	let $folder := normalize-space($binder)
	let $name := normalize-space($file)
	let $root := local:archive-path($home-data, $tenant, $year, $folder)
	let $path := local:find-file-collection($root, $name)
	return
		if (not(local:deletable-archive-name($folder))) then
			error(xs:QName('binder:InvalidName'), concat('Ungültiger Ordnername: ', $folder))
		else if ($name = '' or local:is-sidecar($name)) then
			error(xs:QName('binder:InvalidFile'), concat('Ungültige Datei: ', $name))
		else if (not(xmldb:collection-available($root))) then
			error(xs:QName('binder:Missing'), concat('Ordner fehlt: ', $folder))
		else if (empty($path)) then
			error(xs:QName('binder:FileMissing'), concat('Datei fehlt: ', $name))
		else
			let $transfer := local:ensure-transfer($home-data, $tenant, $year)
			let $target := local:unique-transfer-name($transfer, $name)
			let $prepare :=
				if ($target = $name) then ()
				else if (exists(index-of(xmldb:get-child-resources($path), $target))) then
					error(xs:QName('binder:NameClash'), concat('Temporärer Zielname belegt: ', $target))
				else
					xmldb:rename($path, $name, $target)
			let $moved := xmldb:move($path, $transfer, $target)
			let $intel := di:ensure($home-data, $tenant, xs:integer($year), $target, '', '')
			let $removed := local:remove-related-xml($path, $name)
			return
				<Moved toTransfer="true" binder="{$folder}" from="{$name}" to="{$target}" year="{$year}" fromCollection="{$path}">
					{$removed}
				</Moved>
};

declare function binder:moveAllToTransfer($home-data as xs:string, $tenant as xs:string, $year as xs:string, $binder as xs:string) {
	let $folder := normalize-space($binder)
	let $path := local:archive-path($home-data, $tenant, $year, $folder)
	return
		if (not(local:deletable-archive-name($folder))) then
			error(xs:QName('binder:InvalidName'), concat('Ungültiger Ordnername: ', $folder))
		else if (not(xmldb:collection-available($path))) then
			error(xs:QName('binder:Missing'), concat('Ordner fehlt: ', $folder))
		else
			let $files := local:collect-files($path, '')
			let $moved :=
				for $file in $files
				return binder:moveFileToTransfer($home-data, $tenant, $year, $folder, string($file/@name))
			let $leftover-xml :=
				for $entry in local:collect-sidecars($path)
				let $col := substring-before($entry, '::')
				let $name := substring-after($entry, '::')
				return
					try {
						let $_ := xmldb:remove($col, $name)
						return <RemovedXml name="{$name}" collection="{$col}"/>
					} catch * {
						<RemovedXml name="{$name}" collection="{$col}" error="{$err:description}"/>
					}
			return
				<MovedAll binder="{$folder}" year="{$year}" count="{count($moved)}">
					{$moved}
					{$leftover-xml}
				</MovedAll>
};

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
				let $stats := local:archive-stats(local:archive-path($home-data, $tenant, $year, $folder))
				return
					<Binder name="{$folder}" type="ARCHIVE"
						files="{$stats?files}" size="{$stats?size}" sidecars="{$stats?sidecars}" empty="{$stats?empty}"/>
	}
	</Binders>
};

declare function local:valid-archive-name($name as xs:string) as xs:boolean {
	matches($name, '^[A-Za-z0-9][A-Za-z0-9._-]*$')
	and not($name = ('transfer', 'trash'))
	and not(matches($name, '^[0-9]{4}$'))
	and not($name = ('01','02','03','04','05','06','07','08','09','10','11','12'))
};

(: Löschen: Monate/transfer/trash bleiben gesperrt; vierstellige Legacy-Archive (z.B. "2023") sind erlaubt. :)
declare function local:deletable-archive-name($name as xs:string) as xs:boolean {
	matches($name, '^[A-Za-z0-9][A-Za-z0-9._-]*$')
	and not($name = ('transfer', 'trash'))
	and not($name = ('01','02','03','04','05','06','07','08','09','10','11','12'))
};

(: Archiv-Ordner anlegen (Jahr + optional Mandanten-Company-Paper). :)
declare function binder:createArchive($home-data as xs:string, $tenant as xs:string, $year as xs:string, $name as xs:string) {
	let $folder := normalize-space($name)
	let $year-col := $home-data || '/' || $tenant || '/' || $year
	let $tenant-col := $home-data || '/' || $tenant
	return
		if (not(local:valid-archive-name($folder))) then
			error(xs:QName('binder:InvalidName'), concat('Ungültiger Ordnername: ', $folder))
		else if (not(xmldb:collection-available($year-col))) then
			error(xs:QName('binder:YearMissing'), concat('Jahr fehlt: ', $year))
		else if (xmldb:collection-available($year-col || '/' || $folder)) then
			error(xs:QName('binder:Exists'), concat('Ordner existiert bereits: ', $folder))
		else
			let $year-folder := xmldb:create-collection($year-col, $folder)
			let $tenant-folder :=
				if (xmldb:collection-available($tenant-col || '/' || $folder)) then ()
				else xmldb:create-collection($tenant-col, $folder)
			return
				<Binder name="{$folder}" type="ARCHIVE" year="{$year}" tenant="{$tenant}"/>
};

declare function binder:renameArchive($home-data as xs:string, $tenant as xs:string, $year as xs:string, $old as xs:string, $new as xs:string) {
	let $from := normalize-space($old)
	let $to := normalize-space($new)
	let $year-col := $home-data || '/' || $tenant || '/' || $year
	let $tenant-col := $home-data || '/' || $tenant
	return
		if (not(local:valid-archive-name($from)) or not(local:valid-archive-name($to))) then
			error(xs:QName('binder:InvalidName'), 'Ungültiger Ordnername.')
		else if ($from = $to) then
			<Binder name="{$to}" type="ARCHIVE" year="{$year}" tenant="{$tenant}"/>
		else if (not(xmldb:collection-available($year-col || '/' || $from))) then
			error(xs:QName('binder:Missing'), concat('Ordner fehlt: ', $from))
		else if (xmldb:collection-available($year-col || '/' || $to)) then
			error(xs:QName('binder:Exists'), concat('Zielordner existiert bereits: ', $to))
		else
			let $renamed-year := xmldb:rename($year-col, $from, $to)
			let $renamed-tenant :=
				if (xmldb:collection-available($tenant-col || '/' || $from) and not(xmldb:collection-available($tenant-col || '/' || $to))) then
					xmldb:rename($tenant-col, $from, $to)
				else ()
			return
				<Binder name="{$to}" type="ARCHIVE" year="{$year}" tenant="{$tenant}" from="{$from}"/>
};

declare function binder:deleteArchive($home-data as xs:string, $tenant as xs:string, $year as xs:string, $name as xs:string) {
	let $folder := normalize-space($name)
	let $year-path := $home-data || '/' || $tenant || '/' || $year || '/' || $folder
	let $tenant-path := $home-data || '/' || $tenant || '/' || $folder
	return
		if (not(local:deletable-archive-name($folder))) then
			error(xs:QName('binder:InvalidName'), concat('Ungültiger Ordnername: ', $folder))
		else if (not(xmldb:collection-available($year-path))) then
			error(xs:QName('binder:Missing'), concat('Ordner fehlt: ', $folder))
		else if (exists(xmldb:get-child-collections($year-path)) or exists(xmldb:get-child-resources($year-path))) then
			error(xs:QName('binder:NotEmpty'), concat('Ordner ist nicht leer: ', $folder))
		else
			let $removed-year := xmldb:remove($year-path)
			let $removed-tenant :=
				if (
					xmldb:collection-available($tenant-path)
					and empty(xmldb:get-child-collections($tenant-path))
					and empty(xmldb:get-child-resources($tenant-path))
				) then
					xmldb:remove($tenant-path)
				else ()
			return
				<deleted name="{$folder}" year="{$year}" tenant="{$tenant}"/>
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

