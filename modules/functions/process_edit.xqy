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

xquery version "3.0";

(:

https://dev.bintellix.com/exist-backend/rest/db/apps/docman/modules/banking/banking_index.xqy

:)

import module namespace account="http://bintellix.com/docman/account" at "/db/apps/docman/modules/module_account.xqm";
import module namespace binder="http://bintellix.com/docman/binder" at "/db/apps/docman/modules/module_binder.xqm";
import module namespace document="http://bintellix.com/docman/document" at "/db/apps/docman/modules/module_document.xqm";

declare function local:replace($node as item(), $type as xs:string) {

	if ($node instance of document-node()) then
		for $subnode in $node/*
		return 
			local:replace($subnode, $type)
	else if ($node instance of node()) then
		element {$node/name()} {
			for $attribute in $node/@*
			return
				if ($attribute/name()="type") then
					attribute type {$type}
				else
					$attribute
			,
			for $subnode in $node/*
			return
				local:replace($subnode, $type)
		}
	else
		$node

};

let $home-web-gui := request:get-attribute('home-web-gui')
let $home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute('year')
let $binder := request:get-attribute('binder')
let $document := request:get-attribute('resource-id')
let $file := request:get-attribute('ref')
let $path := request:get-attribute('path')
let $function-temp := request:get-attribute('function')
let $function := $function-temp || 'Task'
let $type := request:get-parameter('type','')

let $file-name := tokenize($file,'/')[last()]
let $file-path := substring-before($file, $file-name)
return
	<result resource-id="{$file-name}" function="{$function}" type="{$type}">
		{	
			if (contains($path,'/enter/')) then
				document:getNewDocumentTemplate($home-data, $tenant, $function, $type)
			else (: '/edit/' :)
				document:getDocument($home-data, $tenant, $year, $binder, $document)
		}
		{
			if ($file-name != '') then
				let $src := concat($file-path, $file-name)
				let $hash := document:hashcode($home-data, $src)
				return
				<Files>
					<File src="{$src}" fileName="{substring-before($file-name,'.')}" fileExtension=".{lower-case(substring-after($file-name,'.'))}" uploadName="{$file-name}" uploadSrc="{$home-web-gui}{$file}" mimeType="{xmldb:get-mime-type(xs:anyURI(concat('http://localhost:8080/exist/apps/docman', $file-path,$file-name)))}" type="{$type}" doctype="" archived="false">
						{ if ($hash) then attribute hashcode { $hash } else () }
					</File>
				</Files>
			else
				()
		}
		{binder:listBinders($home-data, $tenant, $year)}
		{account:listAccounts($home-data, $tenant, $year)}
	</result>
