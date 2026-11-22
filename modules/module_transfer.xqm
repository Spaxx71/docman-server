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

module namespace transfer = "http://bintellix.com/docman/transfer";

import module namespace di = "http://bintellix.com/docman/document-intelligence" at "/db/apps/docman/modules/module_document-intelligence.xqm";
import module namespace document = "http://bintellix.com/docman/document" at "/db/apps/docman/modules/module_document.xqm";

(: import module namespace crypto = "http://expath.org/ns/crypto"; 
import module "http://expath.org/ns/crypto";
:)

declare function local:filed-copies($home-data as xs:string, $tenant as xs:string, $year as xs:integer) as element(Filed)* {
	let $year-col := $home-data || '/' || $tenant || '/' || $year
	for $folder in xmldb:get-child-collections($year-col)
	where not($folder = ('trash', 'transfer'))
	let $collection := $year-col || '/' || $folder
	for $name in xmldb:get-child-resources($collection)
	where ends-with($name, '.dm.xml')
	let $process := doc($collection || '/' || $name)/Process
	for $file in $process/Tasks/*/Files/File
	let $hash :=
		if (matches(string($file/@hashcode), '^[0-9a-f]{64}$')) then
			string($file/@hashcode)
		else
			document:hashcode($home-data, string($file/@src))
	where exists($hash)
	return
		<Filed hash="{$hash}" folder="{$folder}" process="{string($process/@name)}" file="{concat(string($file/@fileName), string($file/@fileExtension))}"/>
};

declare function transfer:index ($home-data as xs:string, $tenant as xs:string, $year as xs:integer) {
	let $collection-transfer := $home-data||'/'||$tenant||'/'||$year||'/transfer'
	let $documents := xmldb:get-child-resources($collection-transfer)
	let $filed := local:filed-copies($home-data, $tenant, $year)
	let $items :=
		for $document in $documents
		where not(di:is-sidecar($document))
		let $ready := if (di:is-document($document)) then di:ensure($home-data, $tenant, $year, $document, '', '') else ()
		let $hash := document:hashcode($home-data, $collection-transfer || '/' || $document)
		order by $document
		return
			<Item name="{$document}" hash="{$hash}"
				size="{xmldb:size($collection-transfer, $document)}"
				created="{xmldb:created($collection-transfer, $document)}">
				{ di:summary($home-data, $tenant, $year, $document) }
				{ di:load($home-data, $tenant, $year, $document)[self::DocmanIntelligence] }
			</Item>
	return
	<Transfer version="1.0" tenantId="{$tenant}" yearId="{$year}">
		<Files>
		{
		for $item in $items
		let $hash := string($item/@hash)
		let $in-transfer := count($items[string(@hash) = $hash][string(@hash) != ''])
		let $hits := $filed[@hash = $hash]
		let $duplicate :=
			if (exists($hits)) then 'filed'
			else if ($in-transfer > 1) then 'transfer'
			else ''
		return
			<File name="{$item/@name}"
				size="{$item/@size}"
				created="{$item/@created}"
				hashcode="{$hash}"
				duplicate="{$duplicate}">
				{ $item/* }
				{
					if (exists($hits)) then
						<AlreadyFiled>{$hits}</AlreadyFiled>
					else ()
				}
			</File>
		}
		</Files>
	</Transfer>
};


declare function transfer:delete ($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $document) {
	let $companion := di:remove($home-data, $tenant, $year, $document)
	return xmldb:remove($home-data||'/'||$tenant||'/'||$year||'/transfer', $document)
};

declare function transfer:rename($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $document as xs:string, $name as xs:string) {
	let $transfer-collection := $home-data||'/'||$tenant||'/'||$year||'/transfer'
	let $pattern := '[A-Za-z0-9+$_\-\.]+\.(pdf|tif|tiff|png|gif|jpg|jpeg|txt|csv|xml)'
	return
		if (not(matches($name, $pattern))) then
			<error>Filename "{$name}" is not a valid file name.</error>
		else if (index-of(xmldb:get-child-resources($transfer-collection), $name) > 0) then
			<error>Filename "{$name}" already exists.</error>
		else
			let $rename := xmldb:rename($transfer-collection, $document, $name)
			let $companion := di:follow($home-data, $tenant, $year, $document, $name)
			return <result from="{$document}" to="{$name}" status="{$rename}"/>
};

declare function transfer:toTrash($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $document as xs:string) {
	let $transfer-collection := $home-data||'/'||$tenant||'/'||$year||'/transfer'
	let $parent := $home-data||'/'||$tenant
	let $trash-collection := $parent||'/trash'
	let $create := if (xmldb:collection-available($trash-collection)) then () else xmldb:create-collection($parent, 'trash')
	let $companion := di:trash($home-data, $tenant, $document, $year)
	let $move := xmldb:move($transfer-collection, $trash-collection, $document)
	return <result from="{$document}" to="trash" status="{$move}"/>
};

declare function local:unique-name($collection as xs:string, $name as xs:string) as xs:string {
	if (empty(index-of(xmldb:get-child-resources($collection), $name))) then
		$name
	else
		let $stem := replace($name, '\.[^.]+$', '')
		let $ext := if (contains($name, '.')) then '.' || replace($name, '^.*\.', '') else ''
		let $free :=
			(
				for $i in 1 to 99
				let $candidate := $stem || '_' || $i || $ext
				where empty(index-of(xmldb:get-child-resources($collection), $candidate))
				return $candidate
			)[1]
		return
			if ($free) then $free
			else error(xs:QName('transfer:NameClash'), concat('Kein freier Name für: ', $name))
};

(: Datei inkl. Intelligence-Sidecar in den Transfer eines anderen Jahres verschieben. :)
declare function transfer:moveToYear(
	$home-data as xs:string,
	$tenant as xs:string,
	$year as xs:integer,
	$document as xs:string,
	$to-year as xs:integer
) {
	let $name := normalize-space($document)
	let $from-col := $home-data || '/' || $tenant || '/' || $year || '/transfer'
	let $to-year-col := $home-data || '/' || $tenant || '/' || $to-year
	let $to-col := $to-year-col || '/transfer'
	return
		if ($name = '' or di:is-sidecar($name)) then
			error(xs:QName('transfer:InvalidFile'), concat('Ungültige Datei: ', $name))
		else if ($year = $to-year) then
			error(xs:QName('transfer:SameYear'), 'Zieljahr ist identisch mit dem aktuellen Jahr.')
		else if (not(xmldb:collection-available($from-col))) then
			error(xs:QName('transfer:Missing'), 'Transfer-Ordner fehlt.')
		else if (empty(index-of(xmldb:get-child-resources($from-col), $name))) then
			error(xs:QName('transfer:FileMissing'), concat('Datei fehlt: ', $name))
		else if (not(xmldb:collection-available($to-year-col))) then
			error(xs:QName('transfer:YearMissing'), concat('Zieljahr fehlt: ', $to-year))
		else
			let $ensure :=
				if (xmldb:collection-available($to-col)) then ()
				else xmldb:create-collection($to-year-col, 'transfer')
			let $target := local:unique-name($to-col, $name)
			let $sidecar := di:locate($from-col, $name)
			let $prepare :=
				if ($target = $name) then ()
				else if (exists(index-of(xmldb:get-child-resources($from-col), $target))) then
					error(xs:QName('transfer:NameClash'), concat('Temporärer Zielname belegt: ', $target))
				else
					xmldb:rename($from-col, $name, $target)
			let $moved := xmldb:move($from-col, $to-col, $target)
			let $sidecar-move :=
				if ($sidecar = '') then
					di:ensure($home-data, $tenant, $to-year, $target, '', '')
				else
					let $new-side := di:stem($target) || '.dm.xml'
					let $moved-side := xmldb:move($from-col, $to-col, $sidecar)
					let $side-rename :=
						if ($sidecar = $new-side) then ()
						else if (doc-available($to-col || '/' || $new-side)) then ()
						else xmldb:rename($to-col, $sidecar, $new-side)
					let $final-side := if (doc-available($to-col || '/' || $new-side)) then $new-side else $sidecar
					let $node := doc($to-col || '/' || $final-side)/DocmanIntelligence
					let $src := if (exists($node/@source)) then update value $node/@source with $target else ()
					return $moved-side
			return
				<result from="{$name}" to="{$target}" fromYear="{$year}" toYear="{$to-year}" status="{$moved}"/>
};

declare function transfer:trashIndex($home-data as xs:string, $tenant as xs:string) {
	let $trash-collection := $home-data||'/'||$tenant||'/trash'
	return
		<Trash version="1.0" tenantId="{$tenant}">
			<Files>
			{
				if (xmldb:collection-available($trash-collection)) then
					for $document in xmldb:get-child-resources($trash-collection)
					where not(di:is-sidecar($document))
					order by $document
					return
						<File name="{$document}"
							size="{xmldb:size($trash-collection, $document)}"
							created="{xmldb:created($trash-collection, $document)}"/>
				else ()
			}
			</Files>
		</Trash>
};

