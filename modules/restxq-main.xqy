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

(: can be tested by using 
http://localhost:8080/exist/restxq/docman/index.html 

restxq documentation:
https://docs.basex.org/wiki/RESTXQ#Paths
http://exquery.github.io/exquery/exquery-restxq-specification/restxq-1.0-specification.html#path-annotation
http://adamretter.org.uk/presentations/restxq_mugl_20120308.pdf

:)


module namespace dmmain="http://exist-db.org/apps/restxq/docman-main";

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http="http://expath.org/ns/http-client";
declare namespace rerr= "http://exquery.org/ns/restxq/error";



(: 
	Error handler
	see also: https://docs.basex.org/wiki/RESTXQ#Error_Handling
declare 
%rest:error("err:user")
%rest:error-param("description", "{$user}")
  function page:user-error($user)
{
  'User "' || $user || '" is unknown.'
};
:)


(: 
	http://localhost:8080/exist/restxq/docman

declare
	%rest:GET
	%rest:path("/docman/index.html")
	%output:media-type("text/html")
	%output:method("html5")
function dmmain:index() {
	<rest:response>
		<http:response status="301" message="Permanent Redirect">
			<http:header name="location" value="{$main:home-web-gui}/index.html"/>
		</http:response>
	</rest:response>
};
:)

(: 
	http://localhost:8080/exist/restxq/docman
:)
declare
	%rest:GET
	%rest:path("/docman")
(:	%rest:consumes("application/xml")
	%rest:consumes("text/xml")
	%output:method("xml")
	%output:media-type("text/xml")
:)
	%rest:query-param("user", "{$user}", "Guest")
function dmmain:welcome($user as xs:string*) {
	<Tenants version="1.0">
		<Tenant id="bix" name="bintellix"/>
		<Tenant id="is" name="INTERSECURITY"/>
	</Tenants>
};


(: 
	http://localhost:8080/exist/restxq/docman/resources/docman.css

declare
    %rest:GET
    %rest:path("/docman/resources/{$location}.css")
    %output:method("text")
    %output:media-type("text/css")
function dmmain:cssFile($location) {
	unparsed-text("/db/apps/docman"||"/resources/"||$location||".css")
};
:)

(: 
	http://localhost:8080/exist/restxq/docman/resources/jquery-3.5.1.js

declare
    %rest:GET
    %rest:path("/docman/resources/{$location}.js")
    %output:method("text")
    %output:media-type("text/css")
function dmmain:jsFile($location) {
	unparsed-text("/db/apps/docman"||"/resources/"||$location||".js")
};
:)


(:
<rest:forward>{ $location }</rest:forward>

<rest:response>
  <http:response status="302" message="Temporary Redirect">
    <http:header name="location" value="{ $location }"/>
  </http:response>
</rest:response>

%rest:header-param("User-Agent", "{$user-agent}")
%rest:header-param("Referer", "{$referer}", "none")

	(<rest:response xmlns:rest="http://exquery.org/ns/restxq">
		<output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
			<output:method value="xhtml"/>
			<output:media-type value='text/xhtml'/>
		</output:serialization-parameters>
	</rest:response>, "nenene")
	
<restxq:redirect/> 
    
<rest:response><output:serialization-parameters><output:method value=“html”/></output:serialization-parameters>...</rest:response>

<rest:response>
		<http:response status="404" xmlns:http="http://expath.org/ns/http-client">
			<http:header name="Content-Language" value="en"/>
			<http:header name="Content-Type" value="text/html; charset=utf-8"/>
		</http:response>
	</rest:response>
%output:method(“binary”)
%output:method(“json”)
%output:method(“html5”)

:)

