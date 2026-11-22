xquery version "3.1";

(:
Sichere Zuordnungen schreiben.
Aufruf über util:eval aus restxq-bank.
:)

import module namespace match="http://bintellix.com/docman/match" at "/db/apps/docman/modules/module_match.xqm";

let $home-data := string(request:get-attribute('home-data'))
let $tenant := string(request:get-attribute('tenant'))
let $year := xs:integer(request:get-attribute('year'))
let $bank := string(request:get-attribute('bank'))
let $payment-id := string(request:get-attribute('payment-id'))
let $days-before := xs:integer(request:get-attribute('days-before'))
let $days-after := xs:integer(request:get-attribute('days-after'))
let $tolerance-text := translate(normalize-space(string(request:get-attribute('tolerance'))), ',', '.')
let $tolerance := if ($tolerance-text castable as xs:decimal) then abs(xs:decimal($tolerance-text)) else xs:decimal('0.01')
let $user := string((request:get-attribute('username'), 'Guest')[1])
return match:apply($home-data, $tenant, $year, $bank, $payment-id, $days-before, $days-after, $tolerance, $user)
