This software is free and open source. When using it, you agree to accept to the Server Side Public License (SSPL).
Use is at your own risk and free of liability.


The docman root page can be found here:

Web GUI (with TLS): https://localhost:8443/exist/apps/docman/index.html
Wwb GUI (not SSL/TLS): http://localhost:8080/exist/apps/docman/index.html


RESTful API: https://localhost:8443/exist/restxq/docman/rest/index.html
Belege, Zahlungen, Matchings und der weitere Ausbau: docu/belegfluss.md
Zuordnung von Kontobewegungen und Vorgängen: docu/bank-zuordnung.md
For webDAV acces: https://localhost:8443/exist/webdav/db/apps/docman/

In case of proxy use:
Web-Interface: https://docman.yourdomain.xyz:443/app/
REST Inferface: https://docman.yourdomain.xyz:443/api/
webDAV interface: https://docman.yourdomain.xyz:443/exist-backend/webdav/db/apps/docman/


Needs to be initialized fist: 
https://localhost:8443/exist/rest/db/apps/docman/initialize.xqy

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


First try if eXist is available
http://localhost:8080/exist/
https://localhost:8443/exist/
https://docman.yourname.xyz:443/exist/ (if you are using a proxy)

If you find a note INVALID_PREFIX or "Invalid qname hbci4java:initialize" than you might have missed 
to first initialize the database with http://localhost:8080/exist/rest/db/apps/docman/initialize.xqy

