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
	Home of DocMan:   http://localhost:8080/exist/apps/docman/
	Home of DocMan:   https://localhost:8443/exist/apps/docman/ 

	Needs to be initialized fist: http://localhost:8080/exist/rest/db/apps/docman/initialize.xqy
:)


declare namespace xmldb = "http://exist-db.org/xquery/xmldb";
declare namespace sm = "http://exist-db.org/xquery/securitymanager";

declare variable $exist:root external;
declare variable $exist:prefix external;
declare variable $exist:controller external;
declare variable $exist:path external;
declare variable $exist:resource external;

declare option exist:serialize "method=xhtml media-type=text/html indent=yes";


import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace tenant="http://bintellix.com/docman/tenant" at "/db/apps/docman/modules/module_tenant.xqm";
import module namespace binder="http://bintellix.com/docman/binder" at "/db/apps/docman/modules/module_binder.xqm";
import module namespace document="http://bintellix.com/docman/document" at "/db/apps/docman/modules/module_document.xqm";
import module namespace account="http://bintellix.com/docman/account" at "/db/apps/docman/modules/module_account.xqm";
import module namespace user="http://bintellix.com/docman/user" at "/db/apps/docman/modules/module_user.xqm";

(: normal sites for logged in users :)
declare function local:processStandardSite($tenant as xs:string, $year as xs:string?, $format as xs:string, $resource-type as xs:string, $resource-id as xs:string?, $function as xs:string, $param as node()?, $path as xs:string) {

	local:processSite($tenant, $year, $format, '', $resource-type, $resource-id, $function, $param, $path)
};


(: settings pages for advance users :)
declare function local:processSettingsSite($tenant as xs:string, $year as xs:string?, $format as xs:string, $resource-type as xs:string, $resource-id as xs:string?, $function as xs:string, $param as node()?, $path as xs:string) {

	local:processSite($tenant, $year, $format, 'settings/', $resource-type, $resource-id, $function, $param, $path)
};


(: internal function only :)
declare function local:processSite($tenant as xs:string, $year as xs:string?, $format as xs:string, $package-prefix as xs:string, $resource-type as xs:string, $resource-id as xs:string?, $function as xs:string, $param as node()?, $path as xs:string) {

	let $username := sm:id()/sm:id/sm:real/sm:username
	let $groups := sm:id()/sm:id/sm:real/sm:groups/sm:group
	let $TimezoneOffset := 'PT2H'
	let $activity := <Activity user="{$username}" date="{current-dateTime()}" tenant="{$tenant}" year="{$year}" resource-type="{$resource-type}" resource-id="{$resource-id}" function="{$function}" param="{$param}" path="{$path}"/>
	let $logfile := update insert $activity into doc(concat($main:home-data,'/activities.dm.xml'))/Activities
	return
	<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
		<forward>
			{attribute {"url"} {
				if ($resource-type = 'process' and not($function='index')) then
					'/docman/modules/functions/process_edit.xqy'
				else 
					concat('/docman/modules/functions/',$package-prefix,$resource-type,'_',$function,'.xqy')
				} 
			}
			<set-attribute name="home-web-gui" value="{$main:home-web-gui}"/> 
			<set-attribute name="home-web-api" value="{$main:home-web-api}"/> 
			<set-attribute name="home-data" value="{$main:home-data}"/> 
			<set-attribute name="tenant" value="{$tenant}"/>
			{ if (not($year)) then () else <set-attribute name="year" value="{$year}"/> }
			{ 
			  for $p in $param/*:parameter
			  return
				element set-attribute {
					attribute name {$p/@name}
					,
					attribute value {$p/@value}
				}
			}
			<set-attribute name="path" value="{$path}"/>
			<set-attribute name="resource-type" value="{$resource-type}"/>
			<set-attribute name="resource-id" value="{$resource-id}"/>
			<set-attribute name="function" value="{$function}"/>
			<set-attribute name="format" value="{$format}"/>
			<set-attribute name="username" value="{$username}"/>
			<set-attribute name="groups" value="{$groups}"/>
		</forward>
		{ if ($format = ("html","pdf")) then 
			<view>
				<forward servlet="XSLTServlet">
					<set-attribute name="xslt.stylesheet">
					{ attribute {"value"} {if ($resource-type = 'process' and not($function='index')) then 
							concat($exist:root, $exist:controller, '/views/process_edit_html.xsl')
						else
							concat($exist:root, $exist:controller, '/views/', $package-prefix, $resource-type,'_',$function,'_html.xsl')
						}
					}
					</set-attribute>
					<set-attribute name="xslt.home-web-gui" value="{$main:home-web-gui}"/>
					<set-attribute name="xslt.home-web-api" value="{$main:home-web-api}"/>
					<set-attribute name="xslt.home-data" value="{$main:home-data}"/> 
					<set-attribute name="xslt.home-views" value="{$main:home-views}"/> 
					<set-attribute name="xslt.tenant" value="{$tenant}"/>
					<set-attribute name="xslt.username" value="{$username}"/>
					<set-attribute name="xslt.groups" value="{$groups}"/>
					{ if (not($year)) then () else <set-attribute name="xslt.year" value="{$year}"/> }
					{ 
						for $p in $param/*:parameter
						return
							element set-attribute {
								attribute name {concat('xslt.',$p/@name)}
								,
								attribute value {$p/@value}
							}
					}
					<set-attribute name="xslt.path" value="{$path}"/>
					<set-attribute name="xslt.resource-type" value="{$resource-type}"/>
					<set-attribute name="xslt.resource-id" value="{$resource-id}"/>
					<set-attribute name="xslt.function" value="{$function}"/>
					<set-attribute name="xslt.format" value="{$format}"/>
					<set-attribute name="xslt.TimezoneOffset" value="{$TimezoneOffset}"/>
				</forward>
				{ 
				if ($format = "html") then
					<forward servlet="XSLTServlet">
						<set-attribute name="xslt.stylesheet" value="{concat($exist:root, $exist:controller, '/views/frame.xsl')}"/>
						<set-attribute name="xslt.home-web-gui" value="{$main:home-web-gui}"/>
						<set-attribute name="xslt.home-web-api" value="{$main:home-web-api}"/>
						<set-attribute name="xslt.home-data" value="{$main:home-data}"/> 
						<set-attribute name="xslt.home-views" value="{$main:home-views}"/> 
						<set-attribute name="xslt.tenant" value="{$tenant}"/>
						<set-attribute name="xslt.format" value="{$format}"/>
						<set-attribute name="xslt.username" value="{$username}"/>
						<set-attribute name="xslt.groups" value="{$groups}"/>
						{ if (not($year)) then () else <set-attribute name="xslt.year" value="{$year}"/> }
						{ 
							for $p in $param/*:parameter
							return
								element set-attribute {
									attribute name {'xslt.' || $p/@name}
									,
									attribute value {$p/@value}
								}
						}
						<set-attribute name="xslt.path" value="{$path}"/>
						<set-attribute name="xslt.filename" value="{$function}.{$format}"/>
						<set-attribute name="xslt.username" value="{$username}"/>
						<set-attribute name="xslt.groups" value="{$groups}"/>
						<set-attribute name="xslt.resource-type" value="{$resource-type}"/>
						<set-attribute name="xslt.resource-id" value="{$resource-id}"/>
						<set-attribute name="xslt.output.method" value="xhtml"/>
						{
							if (($resource-type = 'process' and not($function='index')) or $function = 'edit' or $function = 'attach') then
								<set-attribute name="xslt.output.media-type" value="text/xml"/> 
							else
								<set-attribute name="xslt.output.media-type" value="text/html"/> 
						}
						<set-attribute name="xslt.output.omit-xml-declaration" value="yes"/>
						<set-attribute name="xslt.output.process-xsl-pi" value="no"/>
						<set-attribute name="xslt.output.indent" value="yes"/>

						<set-attribute name="xslt.xsltforms_lang" value="de"/>
						<set-header name="Expires" value="0"/>
						<set-header name="Cache-Control" value="max-age=0"/>
					</forward>
				else  (: if ($format = "pdf") then :)
					(
					<forward servlet="XSLTServlet">
						<clear-attribute name="xslt.input"/>
						<set-attribute name="xslt.stylesheet" 
							value="{concat($exist:root, $exist:controller, '/views/templates/taglib-pdf.xsl')}"/>
						<set-attribute name="xslt.output.method" value="pdf"/>
						<set-attribute name="xslt.output.encoding" value="UTF-8"/>
						<set-attribute name="xslt.output.media-type" value="application/pdf"/>
						<set-attribute name="xslt.output.process-xsl-pi" value="no"/>
						<set-attribute name="xslt.environment" value="'docman'"/>
						<set-attribute name="xslt.file-path-prefix" value=""/>
						<set-attribute name="xslt.file-path" value=""/>
						<set-attribute name="xslt.file-name" value=""/>
						<set-attribute name="xslt.file-ext" value=""/>
						<set-attribute name="xslt.format" value="{$format}"/>
					</forward>
					,
					<forward servlet="XSLTServlet">
						<clear-attribute name="xslt.input"/>
						<set-attribute name="xslt.stylesheet" 
							value="{concat($exist:root, $exist:controller, '/views/templates/generate-pdf.xsl')}"/>
						<set-attribute name="xslt.output.method" value="pdf"/>
						<set-attribute name="xslt.output.encoding" value="UTF-8"/>
						<set-attribute name="xslt.output.media-type" value="application/pdf"/>
						<set-attribute name="xslt.output.process-xsl-pi" value="no"/>
						<set-attribute name="xslt.environment" value="'docman'"/>
						<set-attribute name="xslt.file-path-prefix" value=""/>
						<set-attribute name="xslt.file-path" value=""/>
						<set-attribute name="xslt.file-name" value=""/>
						<set-attribute name="xslt.file-ext" value=""/>
						<set-attribute name="xslt.format" value="{$format}"/>
					</forward>
					,
					<forward url="/docman/modules/xsl-fo.xqy">
						<set-attribute name="xquery.report-errors" value="yes"/>
						<add-parameter name="collection" value="/db/apps//lang/"/>
						<add-parameter name="file-path" value=""/>
						<add-parameter name="file-name" value=""/>
						<set-header name="Expires" value="{format-dateTime( dateTime(current-date(), util:system-time()) + xs:dayTimeDuration('P1D'), '[FNn,*-3], [D01] [MNn,*-3] [Y0001] [H01]:[m01]:[s01] GMT' )}"/>
						<set-header name="Cache-Control" value="max-age={1000 * 3600 * 24}"/>
					</forward>
					)
			}	
			</view>
		else
			()
		}

		<cache-control cache="no"/>
	</dispatch>
};

(:
	http://localhost:8080/exist/apps/docman/
:)

(: 
	https://docman.bintellix.com/app/ 
:)

let $username := sm:id()/sm:id/sm:real/sm:username
let $groups := sm:id()/sm:id/sm:real/sm:groups/sm:group
let $parameterOwner := request:get-parameter('owner','')
let $parameterYear := request:get-parameter('year','')
	(: for process handling :)
let $parameterType := request:get-parameter('type','')
let $parameterAttach := request:get-parameter('attach','')
let $parameterRef := request:get-parameter('ref','')
return 

(: /app/test.html :)
if (matches($exist:path, "^/test.html")) then
	let $format := request:get-parameter("format", ())
	return
	<test>
		<environment>
			<root>{$exist:root}</root>
			<prefix>{$exist:prefix}</prefix>
			<controller>{$exist:controller}</controller>
			<path>{$exist:path}</path>
			<resource>{$exist:resource}</resource>
			<hostname>{request:get-hostname()}</hostname>
			<get-method>{request:get-method()}</get-method>
			<remote-addr>{request:get-remote-addr()}</remote-addr>
			<remote-name>{request:get-remote-host()}</remote-name>
			<scheme>{request:get-scheme()}</scheme>
			<servername>{request:get-server-name()}</servername>
			<uri>{request:get-uri()}</uri>
			<url>{request:get-url()}</url>
			<attribute-names>{request:attribute-names()}</attribute-names>
			<parameter-names>{request:get-parameter-names()}</parameter-names>
			<cookie-names>{request:get-cookie-names()}</cookie-names>
			<header>{request:get-header-names()}</header>
			<x-realip>{request:get-header('x-real-ip')}</x-realip>
		</environment>
		<test1>
		{ let $ana := analyze-string("/de/misc/imprint.html", "^/(de|en)/(.*)\.html")
		  return 
		  	<result>
		  		<a>{$ana}</a>
		  		<b>{$ana//fn:group[@nr="1"]}</b>
		  	</result>
		}
		</test1>
		<test2>
		</test2>
		<test3>
		{
			if ($format = 'plain') then
				'ja'
			else
				'nein'
		}
		</test3>
	</test>


else if (request:get-header('Authorization')=() or lower-case($username)='guest') then
	(: request http plain authentication to continue :)
	(
		response:set-status-code(401)
	, 
		response:set-header("meta http-equiv='cache-control'", "content='no-cache'") 
	,
		response:set-header("meta http-equiv='expires'", "content='0'") 
	,
		response:set-header("meta http-equiv='pragma'", "content='no-cache'") 
	,
		response:set-header("WWW-Authenticate:", 'basic realm="Docman"')
	,
		<html>
			<head>
				<meta http-equiv="Refresh" content="0; url='{$main:home-web-gui}/logout.html'" />
				<script>
<![CDATA[
var p = window.location.protocol + '//'
// current location must return 200 OK for this GET
window.location = window.location.href.replace(p, p + 'logout:password@')
]]>
				</script>
			</head>
			<body>
				<div>Sie sind nicht angemeldet.</div>
				<a href="{$main:home-web-gui}/logout.html">Logout</a>
			</body>
		</html>
	)
	
else if (equals($exist:path,'/robots.txt')) then
	<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
		<forward url="/docman/robots.txt"/>
	</dispatch>

else if (equals($exist:path,'') or equals($exist:path,'/')) then
	let $tenant := ()
	let $query := '<html xmlns="http://www.w3.org/1999/xhtml">
		<head>
			<title>Welcome</title>
		</head>
		<body>
			<h1>Docman Finanzmanagment</h1>
			<ul>
				<li>
					<a href="' || concat($main:home-web-gui,'/index.html') || '">Zur Mandantenübersicht</a>
				</li>
			</ul>
		</body>
	</html>'
	return
	<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
		<forward servlet="XQueryServlet">
			<set-attribute name="xquery.source" value="{$query}"/>
			<!-- <set-attribute name="xquery.attribute" value="results"/> -->
			<set-attribute name="xquery.report-errors" value="yes"/>
		</forward>
		<view>
			<forward servlet="XSLTServlet">
				<clear-attribute name="xquery.source"/>
				<set-attribute name="xslt.stylesheet" value="{concat($exist:root, $exist:controller, '/views/frame.xsl')}"/>
				<set-attribute name="xslt.home-web-gui" value="{$main:home-web-gui}"/>
				<set-attribute name="xslt.home-web-api" value="{$main:home-web-api}"/>
				<set-attribute name="xslt.home-data" value="{$main:home-data}"/> 
				<set-attribute name="xslt.home-views" value="{$main:home-views}"/> 
				<set-attribute name="xslt.tenant" value="{$tenant}"/>               
				<set-attribute name="xslt.path" value="/$tenant/"/>
				<set-attribute name="xslt.username" value="{$username}"/>
				<set-attribute name="xslt.groups" value="{$groups}"/>
				<set-header name="Expires" value="0"/>
				<set-header name="Cache-Control" value="max-age=0"/>
				<set-attribute name="xslt.output.method" value="xhtml"/>
				<set-attribute name="xslt.output.media-type" value="text/html"/>
			</forward>
		</view>
	</dispatch>

(:
	https://docman.bintellix.com/app/index.html
:)
else if (equals($exist:path,'/index.html')) then
	let $filename := "index.html"
	let $result := tenant:listTenants($main:home-data)
	let $query := "xquery version '3.1';" || serialize($result)
	return

	<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
		<forward servlet="XQueryServlet">
			<set-attribute name="xquery.source" value="{$query}"/>
			<!-- <set-attribute name="xquery.attribute" value="results"/> -->
			<set-attribute name="xquery.report-errors" value="yes"/>
		</forward> 
		<view>
			<forward servlet="XSLTServlet">
				<set-attribute name="xslt.stylesheet" value="{concat($exist:root, $exist:controller, '/views/tenants_index_html.xsl')}"/>
				<set-attribute name="xslt.home-web-gui" value="{$main:home-web-gui}"/>
				<set-attribute name="xslt.home-web-api" value="{$main:home-web-api}"/>
				<set-attribute name="xslt.home-data" value="{$main:home-data}"/> 
				<set-attribute name="xslt.home-views" value="{$main:home-views}"/> 
				<set-attribute name="xslt.tenant" value="()"/>
				<set-attribute name="xslt.path" value="/"/> 
			</forward>
			<forward servlet="XSLTServlet">
				<clear-attribute name="xquery.source"/>
				<set-attribute name="xslt.stylesheet" value="{concat($exist:root, $exist:controller, '/views/frame.xsl')}"/>
				<set-attribute name="xslt.home-web-gui" value="{$main:home-web-gui}"/>
				<set-attribute name="xslt.home-web-api" value="{$main:home-web-api}"/>
				<set-attribute name="xslt.home-data" value="{$main:home-data}"/> 
				<set-attribute name="xslt.home-views" value="{$main:home-views}"/> 
				<set-attribute name="xslt.tenant" value="()"/>               
				<set-attribute name="xslt.path" value="/"/>
				<set-attribute name="xslt.filename" value="{$filename}"/>
				<set-attribute name="xslt.username" value="{$username}"/>
				<set-attribute name="xslt.groups" value="{$groups}"/>
				<set-header name="Expires" value="0"/>
				<set-header name="Cache-Control" value="max-age=0"/>
				<set-attribute name="xslt.output.method" value="xhtml"/>
				<set-attribute name="xslt.output.media-type" value="text/html"/>
			</forward>
		</view>
	</dispatch>
	
(: 
	/app/$tenant/index.html
:)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(index)\.(html|xml)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(index)\.(html|xml)')//fn:group, 1)
	let $tenant := $params[1]
	let $function := $params[2]
	let $format := $params[3]
	let $resource-type := 'tenant'
	let $resource-id := ()
	return
		local:processStandardSite($tenant, (), $format, $resource-type, $resource-id, $function, (), '/$tenant/')


(: 
	/app/$tenant/files/$folder/index.html
:)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/files/([A-Za-z0-9_\-]+)/(index)\.(html|xml)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/files/([A-Za-z0-9_\-]+)/(index)\.(html|xml)')//fn:group, 1)
	let $tenant := $params[1]
	let $folder := $params[2]
	let $function := $params[3]
	let $format := $params[4]
	let $resource-type := 'files'
	let $resource-id := ()
	let $param := <parameters xmlns="">
				<parameter name="folder" value="{$folder}"/>
			</parameters>
	return
		local:processStandardSite($tenant, (), $format, $resource-type, $resource-id, $function, $param, '/$tenant/files/$folder/')


(: 
	/app/$tenant/files/$folder/$filename
:)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/files/([A-Za-z0-9_\-]+)/([^/]+)\.(pdf|txt|tiff|gif|png|csv|xml)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/files/([A-Za-z0-9_\-]+)/([^/]+)\.(pdf|txt|tiff|gif|png|csv|xml)')//fn:group, 1)
	let $tenant := $params[1]
	let $folder := $params[2]
	let $resource-id := $params[3]
	let $format := $params[4]
	return
(:
Content-Disposition: inline; filename="filename.pdf"
Content-Disposition: attachment; filename="filename.pdf"
:)
	(
		(: response:set-header("Content-Disposition", concat('inline; filename="',$resource-id,'"')) :)
		response:set-header("Content-Disposition", "inline")
	,
		<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        		<forward url="/docman/data/{$tenant}/{$folder}/{$resource-id}.{$format}"/> 
	    	</dispatch>
	)


(: 
	/app/$tenant/2020/index.html
:)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(2[0-9]{3})/(index|test)\.(html|xml)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(2[0-9]{3})/(index|test)\.(html|xml)')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $function := $params[3]
	let $format := $params[4]
	let $resource-type := 'year'
	let $resource-id := ()
	return
		local:processStandardSite($tenant, $year, $format, $resource-type, $resource-id, $function, (), '/$tenant/$year/')


(: 
	/app/$tenant/binder/index.html
:)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/binders/(index)\.(html|xml)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/binders/(index)\.(html|xml)')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $function := $params[3]
	let $format := $params[4]
	let $resource-type := 'binder'
	let $resource-id := ()
	return
		local:processStandardSite($tenant, $year, $format, $resource-type, $resource-id, $function, (), '/$tenant/$year/binders/')


else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/binders/([A-Za-z0-9\-]+)\.(html|xml)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/binders/([A-Za-z0-9\-]+)\.(html|xml)')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $function := 'search'
	let $format := $params[4]
	let $resource-type := 'binder'
	let $resource-id := $params[3]
	let $param := <parameters xmlns="">
				<parameter name="attach" value="{$parameterAttach}"/>
				<parameter name="ref" value="{$parameterRef}"/>
			</parameters>
	return
		local:processStandardSite($tenant, $year, $format, $resource-type, $resource-id, $function, $param, '/$tenant/$year/binders/$resource-id/')


(: /$tenant/$year/binders/enter/index :)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/binders/enter/(index|Simple|Document|InvoiceIn|InvoiceOut|PeriodicPayment|BankBalancing|Tax|EmployeeSalary)\.(html|xml)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/binders/enter/(index|Simple|Document|InvoiceIn|InvoiceOut|PeriodicPayment|BankBalancing|Tax|EmployeeSalary)\.(html|xml)')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $function := replace($params[3],'-storno','')
	let $format := $params[4]
	let $resource-type := 'process'
	let $resource-id := ()
	let $param := <parameters xmlns="">
				<parameter name="type" value="{$parameterType}"/>
				<parameter name="ref" value="{$parameterRef}"/>
			</parameters>
	return
		local:processStandardSite($tenant, $year, $format, $resource-type, $resource-id, $function, $param, '/$tenant/$year/binders/enter/')


(: /$tenant/binders/edit/ :) (: All MainTasks schema types :)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/binders/([0-9a-zA-Z]+)/(.*)/edit/(Simple|Document|InvoiceIn|InvoiceOut|PeriodicPayment|BankBalancing|Tax|EmployeeSalary)\.(html|xml)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/(binder)s/([0-9a-zA-Z]+)/(.*)/edit/(Simple|Document|InvoiceIn|InvoiceOut|PeriodicPayment|BankBalancing|Tax|EmployeeSalary)\.(html|xml)')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $binder := $params[4]
	let $resource-type := 'enter'
	let $resource-id := $params[5]
	let $function := if ($params[6] = 'invoice') then
						'invoice-in'
					else if ($params[6] = 'invoice-in-storno') then
						'invoice-in'
					else
						$params[6]
	let $format := $params[7]
	let $param := <parameters xmlns="">
				<parameter name="attach" value="{$parameterAttach}"/>
				<parameter name="ref" value="{$parameterRef}"/>
				<parameter name="binder" value="{$binder}"/>
			</parameters>
	return
		local:processStandardSite($tenant, $year, $format, 'process', $resource-id, $function, $param, '/$tenant/$year/binders/$binder/$resource-id/edit/')


(: /$tenant/$year/binders/attach/ :)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/binders/attach/(index)\.(html|xml)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/binders/attach/(index)\.(html|xml)')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $function := $params[3]
	let $format := $params[4]
	let $resource-type := 'attach'
	let $resource-id := ()
	let $param := <parameters xmlns="">
				<parameter name="attach" value="{$parameterAttach}"/>
				<parameter name="ref" value="{$parameterRef}"/>
			</parameters>
	return
		local:processStandardSite($tenant, $year, $format, 'attach/'||$resource-type, $resource-id, $function, $param, '/$tenant/$year/binders/attach/')


(: /$tenant/$year/binders/attach/ :) (: all AttachTask schema types :)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/binders/(PRO[a-f0-9\-]+)/attach/(payment|attachment|delivery-note|dunning-fee|transfer-voucher)\.(xml)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/binders/(PRO[a-f0-9\-]+)/attach/(payment|attachment|delivery-note|dunning-fee|transfer-voucher)\.(xml)')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $function := $params[4]
	let $format := $params[5]
	let $resource-type := 'attach'
	let $resource-id := $params[3]
	let $param := <parameters xmlns="">
				<parameter name="attach" value="{$parameterAttach}"/>
				<parameter name="ref" value="{$parameterRef}"/>
			</parameters>
	return
		local:processStandardSite($tenant, $year, $format, 'attach/'||$resource-type, $resource-id, $function, $param, '/$tenant/$year/binders/$binder/attach/')


(: /$tenant/binders/ $operation :)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/binders/([A-Za-z0-9\-]+)/(index)\.(html|xml)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/binders/([A-Za-z0-9\-]+)/(index)\.(html|xml)')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $binder := $params[3]
	let $function := $params[4]
	let $format := $params[5]
	let $resource-type := 'document'
	let $resource-id := ()
	let $param := <parameters xmlns="">
				<parameter name="binder" value="{$binder}"/>
			</parameters>
	return
		local:processStandardSite($tenant, $year, $format, $resource-type, $resource-id, $function, $param, '/$tenant/$year/binders/$binder/')


(: binders search :)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/binders/([A-Za-z0-9\-]+)/(search)\.(html|xml)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/binders/([A-Za-z0-9\-]+)/(search)\.(html|xml)')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $function := $params[4]
	let $format := $params[5]
	let $resource-type := 'binder'
	let $resource-id := $params[3]
	let $param := <parameters xmlns="">
				<parameter name="attach" value="{$parameterAttach}"/>
				<parameter name="ref" value="{$parameterRef}"/>
			</parameters>
	return
		local:processStandardSite($tenant, $year, $format, $resource-type, $resource-id, $function, (), '/$tenant/$year/binders/$resource-id/')


(: /$tenant/binders/ $operation :)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/(binder)s/(01|02|03|04|05|06|07|08|09|10|11|12)/(datev-export)\.csv')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/(binder)s/(01|02|03|04|05|06|07|08|09|10|11|12)/(datev-export)\.csv')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $binder := $params[4]
	let $function := $params[5]
	let $format := "csv"
	let $resource-type := 'binder'
	let $resource-id := ()
	let $param := <parameters xmlns="">
				<parameter name="binder" value="{$binder}"/>
			</parameters>
	return
		local:processStandardSite($tenant, $year, $format, $resource-type, $resource-id, $function, $param, '/$tenant/$year/binders/$binder/')



(: https://docman.bintellix.com/app/$tenant/$year/binder/$binder/$filename/delete.html :)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/(binder)s/([0-9a-zA-Z]+)/(.*)/(delete|delete_response|transfer)\.(html|xml)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/(binder)s/([0-9a-zA-Z]+)/(.*)/(delete|delete_response|transfer)\.(html|xml)')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $binder := $params[4]
	let $resource-type := 'document'
	let $resource-id := $params[5]
	let $function := $params[6]
	let $format := $params[7]
	let $param := <parameters xmlns="">
				<parameter name="binder" value="{$binder}"/>
			</parameters>
	return
		local:processStandardSite($tenant, $year, $format, $resource-type, $resource-id, $function, $param, '/$tenant/$year/binders/$binder/$resource-id/')


(: https://docman.bintellix.com/app/$tenant/binder/$year/$binder/$filename (mostly pdf) :)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/(binder)s/([0-9a-zA-Z]+)/(.*)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/(binder)s/([0-9a-zA-Z]+)/(.*)')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $binder := $params[4]
	let $filename := $params[5]
	return
	(
		(: response:set-header("Content-Disposition", 'inline; filename="',$filename,'"')) :)
		response:set-header("Content-Disposition", "inline")
	,
		<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
			<forward url="/docman/data/{$tenant}/{$year}/{$binder}/{$filename}"/>
		</dispatch>
	)

(: /$tenant/$year/transfer/$operation :)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/transfer/(index|upload_file|upload_file_response|upload_folder|upload_folder_response)\.(html|xml)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/transfer/(index|upload_file|upload_file_response|upload_folder|upload_folder_response)\.(html|xml)')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $function := $params[3]
	let $format := $params[4]
	let $resource-type := 'transfer'
	let $resource-id := ()
	return
		local:processStandardSite($tenant, $year, $format, $resource-type, $resource-id, $function, (), '/$tenant/$year/transfer/')


(: /$tenant/$year/transfer/$resource-id/$operation :)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/(transfer)/(.*)/(delete|delete_response|rename|rename_response|banking_import|banking_import_response|hibiscus_import|hibiscus_import_response)\.(html|xml)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/(transfer)/(.*)/(delete|delete_response|rename|rename_response|banking_import|banking_import_response|hibiscus_import|hibiscus_import_response)\.(html|xml)')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $resource-type := $params[3]
	let $resource-id := $params[4]
	let $function := $params[5]
	let $format := $params[6]
	return
		local:processStandardSite($tenant, $year, $format, $resource-type, $resource-id, $function, (), '/$tenant/$year/transfer/$resource-id/')


(: /$tenant/$transfer/ $operation :)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/transfer/(.*)/(datev_import)\.(html|xml)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/transfer/(.*)/(datev_import)\.(html|xml)')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $resource-type := 'transfer'
	let $resource-id := $params[3]
	let $function := $params[4]
	let $format := $params[5]
	return
		local:processStandardSite($tenant, $year, $format, $resource-type, $resource-id, $function, (), '/$tenant/$year/transfer/$resource-id/')



(: /$tenant/$year/transfer/$resource-id :)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/transfer/([^/]+\.(pdf|txt|tiff|gif|png|csv))')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/transfer/([^/]+\.(pdf|txt|tiff|gif|png|csv))')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $resource-id := $params[3]
	return
(:
Content-Disposition: inline; filename="filename.pdf"
Content-Disposition: attachment; filename="filename.pdf"
:)
	(
		(: response:set-header("Content-Disposition", concat('inline; filename="',$resource-id,'"')) :)
		response:set-header("Content-Disposition", "inline")
	,
		<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        		<forward url="/docman/data/{$tenant}/{$year}/transfer/{$resource-id}"/> 
	    	</dispatch>
	)

(: 
	/app/$tenant/mail/index.html
:)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/mail/(index)\.(html|xml)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/mail/(index)\.(html|xml)')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $function := $params[3]
	let $format := $params[4]
	let $resource-type := 'mail'
	let $resource-id := ()
	return
		local:processStandardSite($tenant, $year, $format, $resource-type, $resource-id, $function, (), '/$tenant/$year/mail/')

(: 
	/app/$tenant/mail/{$message}/index.html
:)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/mail/([0-9]+)/(index)\.(html|xml)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/mail/([0-9]+)/(index)\.(html|xml)')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $function := 'message'
	let $format := $params[5]
	let $resource-type := 'mail'
	let $resource-id := $params[3]
	return
		local:processStandardSite($tenant, $year, $format, $resource-type, $resource-id, $function, (), '/$tenant/$year/mail/$message/')

(: 
	/app/$tenant/mail/{$message}/index.html
:)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/mail/([0-9]+)/attachment/([0-9]+)/(transfer)\.(html|xml)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/mail/([0-9]+)/attachment/([0-9]+)/(transfer)\.(html|xml)')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $function := 'transfer'
	let $format := $params[6]
	let $resource-type := 'mail'
	let $resource-id := $params[3]
	let $param := <parameters xmlns="">
			<parameter name="attachment" value="{$params[4]}"/>		
		</parameters>
	return
		local:processStandardSite($tenant, $year, $format, $resource-type, $resource-id, $function, $param, '/$tenant/$year/mail/$message/attachment/$attachment/')

(: 
	/app/$tenant/mail/{$message}/index.html
:)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/mail/([0-9]+)/attachment/([0-9]+)/([A-Za-z0-9\-_]+)\.(pdf|png|jpg)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/mail/([0-9]+)/attachment/([0-9]+)/([A-Za-z0-9\-_]+)\.(pdf|png|jpg)')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $function := 'attachment'
	let $format := ''
	let $resource-type := 'mail'
	let $resource-id := $params[3]
	let $param := <parameters xmlns="">
			<parameter name="attachment" value="{$params[4]}"/>
			<parameter name="filename" value="{$params[5]}"/>			
		</parameters>
	return
		local:processStandardSite($tenant, $year, $format, $resource-type, $resource-id, $function, $param, '/$tenant/$year/mail/$message/attachment/$attachment')


(: /$tenant/banking/$bank-account/$year $operation :)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/banking/(index|search)\.(html|xml)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/banking/(index|search)\.(html|xml)')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $function := $params[3]
	let $format := $params[4]
	let $resource-type := 'bankings'
	let $resource-id := ()
	return
		local:processStandardSite($tenant, $year, $format, $resource-type, $resource-id, $function, (), '/$tenant/$year/banking/')


(: /$tenant/banking/$bank-account/$year $operation :)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/banking/([0-9A-Za-z]+)/(index|update|attach|create-periodics)\.(html|xml)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/banking/([0-9A-Za-z]+)/(index|update|attach|create-periodics)\.(html|xml)')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $function := $params[4]
	let $format := $params[5]
	let $resource-type := 'banking'
	let $bank-account := $params[3]
	let $resource-id := $bank-account
	let $param := <parameters xmlns="">
			<parameter name="bank-account" value="{$bank-account}"/>
		</parameters>
	return
		local:processStandardSite($tenant, $year, $format, $resource-type, $resource-id, $function, $param, '/$tenant/$year/banking/$bank-account/')




(: /$tenant/banking/$bank-account/$year/$resurce-id/periodic-payment.pdf :)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/banking/([0-9A-Za-z]+)/(PAY[a-f0-9\-]+)/periodic-payment.(html|xml|pdf)$')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/banking/([0-9A-Za-z]+)/(PAY[a-f0-9\-]+)/periodic-payment\.(html|xml|pdf)$')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $resource-type := 'banking'
	let $bank-account := $params[3]
	let $resource-id := $params[4]
	let $function := 'periodic-payment'
	let $format := $params[5]
	let $param := <parameters xmlns="">
			<parameter name="bank-account" value="{$bank-account}"/>
			<parameter name="owner" value="{$parameterOwner}"/>
		</parameters>	
	return
		local:processStandardSite($tenant, $year, $format, $resource-type, $resource-id, $function, $param, '/$tenant/$year/banking/$bank-account/$resource-id/')


(: /$tenant/banking/$bank-account/$year/$resource-id/$operation :)
(: /$tenant/banking/$bank-account/$year/$resurce-id.pdf :)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/banking/([0-9A-Za-z]+)/(PAY[a-f0-9\-]+)(/details|/assign-document)?\.(html|xml|pdf)$')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/banking/([0-9A-Za-z]+)/(PAY[a-f0-9\-]+)(/details|/assign-document)?\.(html|xml|pdf)$')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $resource-type := 'banking'
	let $bank-account := $params[3]
	let $resource-id := $params[4]
	let $function := if (not($params[6])) then 'details' else replace($params[5],'/','')
	let $format := if (not($params[6])) then $params[5] else $params[6]
	let $param := <parameters xmlns="">
			<parameter name="bank-account" value="{$bank-account}"/>
			<parameter name="owner" value="{$parameterOwner}"/>
		</parameters>	
	return
		local:processStandardSite($tenant, $year, $format, $resource-type, $resource-id, $function, $param, '/$tenant/$year/banking/$bank-account/$resource-id/')



(: /$tenant/$year/bookings :)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/bookings/(index|sheet|accounts|refresh)\.(html|xml|pdf)$')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/bookings/(index|sheet|accounts|refresh)\.(html|xml|pdf)$')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $resource-type := 'bookings'
	let $resource-id := ''
	let $function := $params[3]
	let $format := $params[4]
	return
		local:processStandardSite($tenant, $year, $format, $resource-type, $resource-id, $function, (), '/$tenant/$year/bookings/')


(: 
	/app/$tenant/user/abc/index.html
:)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/user/(index|change-password|change-password_response)\.(html|xml)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/user/(index|change-password|change-password_response)\.(html|xml)')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $function := $params[3]
	let $format := $params[4]
	let $resource-type := "user"
	return
		local:processStandardSite($tenant, $year, $format, $resource-type, (), $function, (), '/$tenant/user/')



(: /$tenant/accounts/$operation :)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/(account)s/(index|new|datev-export)\.(html|xml|csv)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/(account)s/(index|new|datev-export)\.(html|xml|csv)')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $resource-type := $params[3]
	let $function := $params[4]
	let $format := $params[5]
	let $resource-id := ()
	let $param := <parameters xmlns="">
			<parameter name="type" value="{request:get-parameter('type','ledger_account')}"/>
		</parameters>
	return
		local:processStandardSite($tenant, $year, $format, $resource-type, $resource-id, $function, $param, '/$tenant/$year/accounts/')



(: /$tenant/accounts/$resource-id/$operation :)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/(account)s/([a-zA-Z0-9_\-]+)/(details|new|edit|delete)\.(xml|html)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/(account)s/([a-zA-Z0-9_\-]+)/(details|new|edit|delete)\.(xml|html)')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $resource-type := $params[3]
	let $resource-id := $params[4]
	let $function := $params[5]
	let $format := $params[6]
	return
		local:processStandardSite($tenant, $year, $format, $resource-type, $resource-id, $function, (), '/$tenant/$year/accounts/$resource-id/')



(: /$tenant/settings/$function :)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/settings/(index)\.(html|xml)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/settings/(index)\.(html|xml)')//fn:group, 1)
	let $tenant := $params[1]
	let $function := $params[2]
	let $format := $params[3]
	let $resource-type := 'settings'
	let $resource-id := ()
	return
		local:processSettingsSite($tenant, (), $format, $resource-type, $resource-id, $function, (), '/$tenant/settings/')



(: /$tenant/settings/banking/$bank-account/$year $operation :)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/banking/([0-9A-Za-z]+)/(edit)\.(html|xml)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/(20[0-9][0-9])/banking/([0-9A-Za-z]+)/(edit)\.(html|xml)')//fn:group, 1)
	let $tenant := $params[1]
	let $year := $params[2]
	let $function := $params[4]
	let $format := $params[5]
	let $resource-type := 'banking'
	let $resource-id := $params[3]
	return
		local:processSettingsSite($tenant, $year, $format, $resource-type, $resource-id, $function, (), '/$tenant/$year/banking/$resource-id/')


(: 
	/app/$tenant/settings/users/index.html
	/docman/modules/functions/settings/users_index.xqy
:)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/settings/users/(index)\.(html|xml)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/settings/users/(index)\.(html|xml)')//fn:group, 1)
	let $tenant := $params[1]
	let $result := user:listUsers($main:home-data, $tenant)
	let $query := "xquery version '3.1';" || serialize($result)
	let $resource-type := 'users'
	let $resource-id := ()
	let $function := $params[2]
	let $format := $params[3]
	return
		local:processSettingsSite($tenant, (), $format, $resource-type, $resource-id, $function, (), '/$tenant/settings/users/')


(: 
	https://docman.bintellix.com/app/settings/bintellix/users/abc/index.html
:)
else if (matches($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/settings/users/([A-Za-z0-9_\-]+)/(index|change-password|change-password_response)\.(html|xml)')) then
	let $params := subsequence(analyze-string($exist:path, '^/([a-zA-Z][a-zA-Z0-9_\-]+)/settings/users/([A-Za-z0-9_\-]+)/(index||change-password|change-password_response)\.(html|xml)')//fn:group, 1)
	let $tenant := $params[1]
	let $user-name := $params[2]
	let $function := $params[3]
	let $resource-type := "users"
	let $format := $params[4]
	return
		local:processSettingsSite($tenant, (), $format, $resource-type, $user-name, $function, (), '/$tenant/settings/users/')


(: /logout.html :)
else if (matches($exist:path, "^/logout\.html$")) then
	(
		response:set-status-code(410)
	, 
		response:set-header("Clear-Site-Data", "cookies, cache")
	,
		response:set-header("WWW-Authenticate", 'Basic realm="Login required"')
	,
		<html>
			<body>
				<div>Goodby</div>
<script>

  var userAgent = navigator.userAgent.toLowerCase();

  if (userAgent.indexOf("msie") != -1) {{
    document.execCommand("ClearAuthenticationCache", false);
  }}

  xhr_objectCarte = null;

  if(window.XMLHttpRequest)
    xhr_object = new XMLHttpRequest();
  else if(window.ActiveXObject)
    xhr_object = new ActiveXObject("Microsoft.XMLHTTP");
  else
    alert ("Your browser doesn't support XMLHTTPREQUEST");

  xhr_object.open ('GET', 'https://docman.bintellix.com/app/logout.html', false, 'username', 'password');
  xhr_object.send ("");
  xhr_object = null;

  document.location = 'https://docman.bintellix.com/app/index.html'; 

</script>
			</body>
		</html>
	)

(: /resources/* :)
else if (matches($exist:path, "^/resources/.*")) then
	<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
		<ignore xmlns="http://exist.sourceforge.net/NS/exist">
	    		<cache-control cache="yes"/>
		</ignore>
	</dispatch>


(: /xsltforms/* :)
else if (matches($exist:path, "^/xsltforms/(.*)")) then
	let $params := subsequence(analyze-string($exist:path, '^/xsltforms/(.*)')//fn:group, 1)
	return
	<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
		<forward url="/xsltforms/{$params[1]}"/>
	</dispatch>

else
	(: everything else is an 404 - Not found :)
	(
		response:set-status-code(404)
	, 
		response:set-header("X-Error-Type", "No-such-resouce")
	,
		<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
			<forward url="/docman/modules/not_found.xql" method="get"/>
			<cache-control cache="no"/> (: cache="no" is IMPORTANT, as otherwise the second request will be handled without 404 :)
		</dispatch>
	)


