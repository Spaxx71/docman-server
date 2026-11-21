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
	(: Font-Embedding schreibt unter .fop; ohne Schreibrecht oder fehlende TTFs schlägt das fehl.
	   Daher: zuerst mit Fonts, bei Fehler ohne Custom-Config rendern. :)
	let $font-regular := '/db/apps/com_bintellix_www/global/fonts/font-awesome/webfonts/fa-regular-400.ttf'
	let $font-solid := '/db/apps/com_bintellix_www/global/fonts/font-awesome/webfonts/fa-solid-900.ttf'
	let $font-brands := '/db/apps/com_bintellix_www/global/fonts/font-awesome/webfonts/fa-brands-400.ttf'
	let $fonts-available :=
		util:binary-doc-available($font-regular)
		and util:binary-doc-available($font-solid)
		and util:binary-doc-available($font-brands)
	let $fopConf :=
		if ($fonts-available) then
			<fop version="1.0">
				<strict-configuration>false</strict-configuration>
				<strict-validation>false</strict-validation>
				<base>file:///tmp/</base>
				<font-base>file:///tmp/</font-base>
				<renderers>
					<renderer mime="application/pdf">
						<fonts>
							<font kerning="yes" embed-url="{$font-regular}">
								<font-triplet name="FontAwesomeRegular" style="normal" weight="normal"/>
							</font>
							<font embed-url="{$font-solid}">
								<font-triplet name="FontAwesomeSolid" style="normal" weight="normal"/>
							</font>
							<font embed-url="{$font-brands}">
								<font-triplet name="FontAwesomeBrand" style="normal" weight="normal"/>
							</font>
						</fonts>
					</renderer>
				</renderers>
			</fop>
		else
			()
	return
	try {
		if (exists($fopConf)) then
			try {
				xslfo:render($xmlFoDocument, "application/pdf", (), $fopConf)
			}
			catch * {
				(: z. B. .fop ohne Schreibrecht – Fallback ohne Font-Config :)
				xslfo:render($xmlFoDocument, "application/pdf", ())
			}
		else
			xslfo:render($xmlFoDocument, "application/pdf", ())
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
