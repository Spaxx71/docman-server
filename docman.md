The docman root page can be found here:


WEB GUI:

https://localhost:8443/exist/apps/docman/
https://localhost:8443/exist/apps/docman/test/transfer/upload_file.html
https://localhost:8443/exist/apps/docman/test/transfer/upload_folder.html


RESTful API:
https://localhost:8443/exist/restxq/docman/rest/index.html


Die wichtigsten globalen Variablen finden sich in der eXist-db im Verzeichnis
/db/apps/docman/modules/modules_main.xqy

Nach der Intallation kann es zu einem Problem mit der Berechtigung kommen,
in diesem Fall ist das folgenden Script (mit Admin-User) zu starten:
https://localhost:8443/exist/rest/db/apps/docman/initialize.xqy

NOTE: There are two cleanup rules within the initialize.xqy script:
All files named "__contents__.xml files" and ".DS_Store" will be dropped from /db/apps/docman/ and underneth

For the full featured functionality the XSLTForms have to be installed in eXist-db at
/db/apps/xsltforms


EXPath Packaging Structure:
http://expath.org/spec/pkg

https://github.com/eXist-db/exist-apps-archetype/issues/2

