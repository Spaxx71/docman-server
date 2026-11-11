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

(: import module namespace crypto = "http://expath.org/ns/crypto"; 
import module "http://expath.org/ns/crypto";
:)

declare function transfer:index ($home-data as xs:string, $tenant as xs:string, $year as xs:integer) {
	let $collection-transfer := $home-data||'/'||$tenant||'/'||$year||'/transfer'
	let $documents := xmldb:get-child-resources($collection-transfer)
	return
	<Transfer version="1.0" tenantId="{$tenant}" yearId="{$year}">
		<Files>
		{ 
		for $document in $documents
		order by $document 
		return
			<File name="{$document}" 
				size="{xmldb:size($home-data||'/'||$tenant||'/'||$year||'/transfer',$document)}"
				created="{xmldb:created($home-data||'/'||$tenant||'/'||$year||'/transfer',$document)}"
				/>
				(: hash-sha1="{crypto:hash(util:binary-doc($collection-transfer ||'/'||$document),'SHA1')}" :)
		}
		</Files>
	</Transfer>
};


declare function transfer:delete ($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $document) {
	xmldb:remove($home-data||'/'||$tenant||'/'||$year||'/transfer', $document)
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
			return <result from="{$document}" to="{$name}" status="{$rename}"/>
};

declare function transfer:toTrash($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $document as xs:string) {
	let $transfer-collection := $home-data||'/'||$tenant||'/'||$year||'/transfer'
	let $parent := $home-data||'/'||$tenant
	let $trash-collection := $parent||'/trash'
	let $create := if (xmldb:collection-available($trash-collection)) then () else xmldb:create-collection($parent, 'trash')
	let $move := xmldb:move($transfer-collection, $trash-collection, $document)
	return <result from="{$document}" to="trash" status="{$move}"/>
};

declare function transfer:trashIndex($home-data as xs:string, $tenant as xs:string) {
	let $trash-collection := $home-data||'/'||$tenant||'/trash'
	return
		<Trash version="1.0" tenantId="{$tenant}">
			<Files>
			{
				if (xmldb:collection-available($trash-collection)) then
					for $document in xmldb:get-child-resources($trash-collection)
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

