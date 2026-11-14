xquery version "3.1";

(:
Hintergrundjob für Document Intelligence.
Muss setuid admin und für guest lesbar sein: rwsr-xr-x.
Mit unschedule=false geplant, damit ein Fehler den Job nicht beendet.
:)

import module namespace di = "http://bintellix.com/docman/document-intelligence" at "/db/apps/docman/modules/module_document-intelligence.xqm";

try {
	let $home := '/db/apps/docman/data'
	let $ping := di:heartbeat($home, 'tick', (), ())
	return di:process($home)
} catch * {
	try {
		di:heartbeat('/db/apps/docman/data', 'error', (), ())
	} catch * {
		()
	},
	<error>{substring($err:description, 1, 500)}</error>
}
