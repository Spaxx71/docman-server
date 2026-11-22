xquery version "3.1";

(:
Vorschläge Bankbewegung ↔ Vorgang.
Aufruf über util:eval aus restxq-document / restxq-bank.
:)

import module namespace match="http://bintellix.com/docman/match" at "/db/apps/docman/modules/module_match.xqm";

let $home-data := string(request:get-attribute('home-data'))
let $tenant := string(request:get-attribute('tenant'))
let $year := xs:integer(request:get-attribute('year'))
let $bank := normalize-space(string(request:get-attribute('bank')))
let $payment-id := normalize-space(string(request:get-attribute('payment-id')))
let $process-id := normalize-space(string(request:get-attribute('process-id')))
let $days-before := xs:integer(request:get-attribute('days-before'))
let $days-after := xs:integer(request:get-attribute('days-after'))
let $tolerance-text := translate(normalize-space(string(request:get-attribute('tolerance'))), ',', '.')
let $tolerance := if ($tolerance-text castable as xs:decimal) then abs(xs:decimal($tolerance-text)) else xs:decimal('0.01')
return match:suggestions(
	$home-data,
	$tenant,
	$year,
	if ($bank = '') then () else $bank,
	if ($payment-id = '') then () else $payment-id,
	if ($process-id = '') then () else $process-id,
	$days-before,
	$days-after,
	$tolerance
)
