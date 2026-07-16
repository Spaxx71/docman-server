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

(: /rest/db/apps/docman/modules/restxq-main.xqy :)
xquery version "3.1";

(: can be tested by using 
http://localhost:8080/exist/restxq/docman/index.html 

restxq documentation:
https://docs.basex.org/wiki/RESTXQ#Paths
http://exquery.github.io/exquery/exquery-restxq-specification/restxq-1.0-specification.html#path-annotation
http://adamretter.org.uk/presentations/restxq_mugl_20120308.pdf

:)


module namespace dmaccess="http://exist-db.org/apps/restxq/docman-access";

(: import module namespace access="http://bintellix.com/docman/access" at "/db/apps/docman/modules/module_access.xqm"; :)

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http="http://expath.org/ns/http-client";
declare namespace rerr= "http://exquery.org/ns/restxq/error";


(: 
	GET http://localhost:8080/exist/restxq/docman/login
	GET /api/(XML|JSON)/login
:)
declare
	%rest:GET
	%rest:path("/docman/xml/access/login")
	%rest:query-param("user", "{$user}", "Guest")
	%output:media-type("text/xml")
	%output:method("xml")

function dmaccess:loginGetXML($user as xs:string*) {
	<Login version="1.0">
		<Status>SUCCESS</Status>
		<Token>abc</Token>
	</Login>
};

declare
	%rest:GET
	%rest:path("/docman/json/access/login")
	%rest:query-param("user", "{$user}", "Guest")
	%output:media-type("application/json")
	%output:method("json")

function dmaccess:loginGetJSON($user as xs:string*) {
	<Login version="1.0">
		<Status>SUCCESS</Status>
		<Token>abc</Token>
	</Login>
};

(: 
	POST http://localhost:8080/exist/restxq/docman/login
	POST /api/login
:)
declare
	%rest:POST
	%rest:path("/docman/xml/access/login")
	%rest:query-param("user", "{$user}", "Guest")
	%output:media-type("text/xml")
	%output:method("xml")

function dmaccess:loginXML($user as xs:string*) {
	<Login version="1.0">
		<Status>SUCCESS</Status>
		<Token>abc</Token>
	</Login>
};

declare
	%rest:POST
	%rest:path("/docman/json/access/login")
	%rest:query-param("user", "{$user}", "Guest")
	%output:media-type("application/json")
	%output:method("json")

function dmaccess:loginJSON($user as xs:string*) {
	<Login version="1.0">
		<Status>SUCCESS</Status>
		<Token>abc</Token>
	</Login>
};


(: 
	POST http://localhost:8080/exist/restxq/docman/logout
	POST /api/login
:)
declare
	%rest:POST
	%rest:path("/docman/xml/access/logout")
	%rest:query-param("user", "{$user}", "Guest")
	%rest:consumes("application/xml")
	%rest:consumes("text/xml")
	%output:media-type("text/xml")
	%output:method("xml")

function dmaccess:logoutXML($user as xs:string*) {
	<Logout version="1.0">
	</Logout>
};

declare
	%rest:POST
	%rest:path("/docman/json/access/logout")
	%rest:query-param("user", "{$user}", "Guest")
	%rest:consumes("application/json")
	%output:media-type("application/json")
	%output:method("json")

function dmaccess:logoutJSON($user as xs:string*) {
	<Logout version="1.0">
	</Logout>
};

(: 
	http://localhost:8080/exist/restxq/docman/resources/docman.css

declare
    %rest:GET
    %rest:path("/docman/xml/resources/{$location}.css")
    %output:method("text")
    %output:media-type("text/css")
function dmaccess:cssFile($location) {
	unparsed-text("/db/apps/docman"||"/resources/"||$location||".css")
};
:)

(: 
	http://localhost:8080/exist/restxq/docman/resources/jquery-3.5.1.js

declare
    %rest:GET
    %rest:path("/docman/xml/resources/{$location}.js")
    %output:method("text")
    %output:media-type("text/css")
function dmaccess:jsFile($location) {
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

