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

module namespace xfo = "http://bintellix.com/docman/xslfo";

declare namespace xslfo="http://exist-db.org/xquery/xslfo";


declare function xfo:createPDF($xmlFoDocument as node()) {
	let $fopConf :=
	<fop version="1.0">
		<strict-configuration>true</strict-configuration>
		<strict-validation>true</strict-validation>
		<base>./</base>
		<renderers>
			<renderer mime="application/pdf">
				<fonts>
					<!-- /db/apps/com_bintellix_www/global/fonts/font-awesome/webfonts/abc.ttf -->
					<!-- file:/tmp/fonts/abc.ttf -->
					<font kerning="yes" embed-url="/db/apps/com_bintellix_www/global/fonts/font-awesome/webfonts/fa-regular-400.ttf">
						<font-triplet name="FontAwesomeRegular" style="normal" weight="normal"/>
					</font>
					<font embed-url="/db/apps/com_bintellix_www/global/fonts/font-awesome/webfonts/fa-solid-900.ttf">
						<font-triplet name="FontAwesomeSolid" style="normal" weight="normal"/>
					</font>
					<font embed-url="/db/apps/com_bintellix_www/global/fonts/font-awesome/webfonts/fa-brands-400.ttf">
						<font-triplet name="FontAwesomeBrand" style="normal" weight="normal"/>
					</font>
				</fonts>
			</renderer>
		</renderers>
	</fop>

	return 
	try {
		xslfo:render($xmlFoDocument, "application/pdf", (), $fopConf)
	}
	catch * {
		<error> The given xslfo document could not be generated... Caught error "{$err:code}": "{$err:description}". Data: "{$err:value}"</error>
	}
};


declare function xfo:createPDFfromBase64($FoDocumentBase64 as xs:string) {

	let $xmlFoDocument := 
		try {
			parse-xml(util:base64-decode($FoDocumentBase64))
		}
		catch * {
			<fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format">
			    <fo:layout-master-set>
			        <fo:simple-page-master master-name="my-page">
			            <fo:region-body margin="0.5in"/>
			        </fo:simple-page-master>
			    </fo:layout-master-set>
			    <fo:page-sequence master-reference="my-page">
			        <fo:flow flow-name="xsl-region-body">
			            <fo:block>
					Sorry, but the original document could not be parsed...
				    </fo:block>
			            <fo:block>
					{util:base64-decode($FoDocumentBase64)}
			            </fo:block>
			            <fo:block>
			    		{$err:code, $err:value, " module: ", $err:module, "(", $err:line-number, ",", $err:column-number, ")"}
			            </fo:block>
			        </fo:flow>
			    </fo:page-sequence>
			</fo:root>
		}
	return
		xfo:createPDF ($xmlFoDocument)
};
