xquery version "3.1";

(:
Zustandstest Document Intelligence (di:check).
Muss setuid admin sein (rwsr-xr-x), damit process:execute auch aus RESTXQ
ohne DBA-Rolle läuft. Rechte setzt initialize.xqy / install.xqy.
:)

import module namespace di = "http://bintellix.com/docman/document-intelligence" at "/db/apps/docman/modules/module_document-intelligence.xqm";

di:check()
