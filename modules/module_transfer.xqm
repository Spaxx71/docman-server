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

