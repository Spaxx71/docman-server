xquery version "3.1" encoding "UTF-8";

import module namespace datev="http://bintellix.com/docman/datev" at "/db/apps/docman/modules/module_datev.xqm";

declare option exist:serialize "method=text encoding=ISO-8859-15";

let $home := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $year := xs:integer(request:get-attribute('year'))
let $month := xs:integer(request:get-attribute('binder'))
let $fileName := datev:fileName($year, $month)

let $header := response:set-header("Cache-Control", 'no-cache, no-store, max-age=0, must-revalidate')
let $header := response:set-header("X-Content-Type-Options", 'nosniff')
let $header := response:set-header("Content-Type", "text/comma-separated-values; charset=ISO-8859-15")
let $header := response:set-header("content-disposition", 'attachment; filename="' || $fileName || '"')

return
	try {
		datev:csv($home, $tenant, $year, $month)
	} catch * {
		string-join(('DATEV-Export fehlgeschlagen:', $err:description, $err:value), ' ')
	}
