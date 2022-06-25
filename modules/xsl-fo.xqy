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


import module namespace xfo="http://bintellix.com/docman/xslfo" at "/db/apps/docman/modules/module_xfo.xqm";


(:
	can be tested by using this url:
	https://dev.yourdomain.xyz/exist-backend/rest/db/apps/com_bintellix_dev/general/functions/xsl-fo.xqy
:)


declare namespace fo="http://www.w3.org/1999/XSL/Format";
declare namespace xslfo="http://exist-db.org/xquery/xslfo";

declare namespace treenode="http://www.intersecurity.net/treenode";
declare namespace exist = "http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace xmldb = "http://exist-db.org/xquery/xmldb";


let $model := request:get-attribute("model")

let $lang := request:get-parameter("lang", ())
let $serverName := request:get-parameter("serverName", ())
let $filePath := request:get-parameter("file-path", ())
let $fileName := request:get-parameter("file-name", "index")
let $set-header-content-language := request:get-parameter("set-header-content-language", ())
let $set-header-link := request:get-parameter("set-header-link", ())

let $documentName := if ($fileName='index') then 'document' else $fileName
let $documentNamePrefix := "bintellix_IoT-services_"

return 
	try {
		let $pdf :=  xfo:createPDFfromBase64(request:get-data())
		return 
			response:stream-binary($pdf, "application/pdf", $documentNamePrefix || $documentName ||".pdf")
	}
	catch * {
		<error> The given xslfo document could not be generated... Caught error "{$err:code}": "{$err:description}". Data: "{$err:value}"</error>
	}
 

	
