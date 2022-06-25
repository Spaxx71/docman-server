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

(: external URL when using Docman without an proxy :)
declare variable $main:home-web-gui := '/exist/apps/docman';
declare variable $main:home-web-api := '/exist/restxq/docman';


(: external URL when using Docman with the given http proxy excample :)
(:
declare variable $main:home-web-gui := '/app';
declare variable $main:home-web-api := '/api';
:)

declare variable $main:home-data := '/db/apps/docman/data';
declare variable $main:home-views := '/db/apps/docman/views';
