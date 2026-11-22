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

module namespace main = "http://bintellix.com/docman/main";

declare variable $main:deployment-uri := '/db/apps/docman/deployment.xml';

declare function main:configured-path($name as xs:string, $fallback as xs:string) as xs:string {
    let $configured :=
        if (doc-available($main:deployment-uri)) then
            normalize-space(doc($main:deployment-uri)/config/*[local-name() = $name])
        else
            ''
    return
        if ($configured ne '') then $configured else $fallback
};

(: Proxy-Pfade, solange deployment.xml fehlt. Das Test-XAR legt die Datei mit den eXist-Pfaden an. :)
declare variable $main:home-web-gui := main:configured-path('gui', '/app');
declare variable $main:home-web-api := main:configured-path('api', '/api/xml');

declare variable $main:home-data := '/db/apps/docman/data';
declare variable $main:home-views := '/db/apps/docman/views';
