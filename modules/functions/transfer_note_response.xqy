xquery version "3.1";

import module namespace di = "http://bintellix.com/docman/document-intelligence" at "/db/apps/docman/modules/module_document-intelligence.xqm";

let $home := request:get-attribute('home-web-gui')
let $data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $year := request:get-attribute('year')
let $file := request:get-attribute('resource-id')
let $notes := request:get-parameter('notes', '')
let $save := di:notes($data, $tenant, $year, $file, $notes)
return
	<html>
		<head>
			<meta http-equiv="refresh" content="0; URL='{$home}/{$tenant}/{$year}/transfer/index.html'"/>
			<title>Notiz</title>
		</head>
		<body>
			<a href="{$home}/{$tenant}/{$year}/transfer/index.html">Zurück zum Eingangskorb</a>
		</body>
	</html>
