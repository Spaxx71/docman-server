xquery version "3.1";

(:
	Vorschläge für Stammdaten: Kreditor/Debitor neu, Bankverbindung ergänzen,
	Zahlungsintervall neu oder anpassen, Feldhinweise.
	Abgelehnte Vorschläge stehen in {jahr}/proposals-dismissed.xml und kommen wieder,
	sobald sich ihre Datenbasis (@basis) ändert.
:)
module namespace proposals = "http://bintellix.com/docman/proposals";

import module namespace match = "http://bintellix.com/docman/match" at "/db/apps/docman/modules/module_match.xqm";
import module namespace account = "http://bintellix.com/docman/account" at "/db/apps/docman/modules/module_account.xqm";

declare variable $proposals:kinds := ('party-new', 'bank-add', 'interval-new', 'interval-adjust', 'hint');

declare %private function proposals:collection($home-data as xs:string, $tenant as xs:string, $year as xs:integer) as xs:string {
	concat($home-data, '/', $tenant, '/', string($year))
};

declare %private function proposals:rows($home-data as xs:string, $tenant as xs:string, $year as xs:integer) as element(Account)* {
	if (doc-available(account:year-path($home-data, $tenant, $year))) then account:accounts($home-data, $tenant, $year) else ()
};

declare %private function proposals:accounts-doc($home-data as xs:string, $tenant as xs:string, $year as xs:integer) as document-node()? {
	let $path := concat(proposals:collection($home-data, $tenant, $year), '/accounts.dm.xml')
	return if (doc-available($path)) then doc($path) else ()
};

declare %private function proposals:compact($value) as xs:string {
	upper-case(replace(normalize-space(string($value)), '\s', ''))
};

declare %private function proposals:party-kind($account as element(Account)) as xs:string? {
	let $classes := tokenize(normalize-space(string-join(($account/@classes, $account/@type), ' ')), '\s+')
	return
		if ($classes = 'debitor') then 'debitor'
		else if ($classes = 'creditor') then 'creditor'
		else ()
};

declare %private function proposals:names($account as element(Account)) as xs:string* {
	distinct-values((
		normalize-space(string($account/Name)),
		normalize-space(string($account/Company/Name)),
		for $hint in $account/FieldHints/Hint[@field = 'party.self'] return normalize-space(string($hint/@label))
	)[. != ''])
};

declare %private function proposals:known-keys($accounts as element(Account)*, $own as xs:string*) as xs:string* {
	distinct-values((
		for $iban in ($accounts/@iban ! tokenize(string(.), '[,\s]+'), $accounts/BankAccounts/BankAccount/@iban ! string(.), $own)
		let $key := proposals:compact($iban)
		where $key != ''
		return concat('iban:', $key),
		for $id in ($accounts/@debtee ! tokenize(string(.), '[,\s]+'), $accounts/BankAccounts/BankAccount/@creditorId ! string(.))
		let $key := proposals:compact($id)
		where $key != ''
		return concat('creditor:', $key)
	))
};

declare %private function proposals:most($values as xs:string*) as xs:string {
	string((
		for $value in distinct-values($values[. != ''])
		order by count($values[. = $value]) descending, $value
		return $value
	)[1])
};

declare %private function proposals:id($kind as xs:string, $seed as xs:string) as xs:string {
	concat($kind, '-', substring(lower-case(string(util:hash($seed, 'md5'))), 1, 12))
};

declare %private function proposals:amount($accounting as element()) as xs:decimal? {
	let $text := translate(normalize-space(string($accounting/Amount)), ',', '.')
	return if ($text castable as xs:decimal) then xs:decimal($text) else ()
};

declare %private function proposals:direction($accounting as element()) as xs:string {
	let $amount := proposals:amount($accounting)
	return if (normalize-space(string($accounting/Amount/@type)) = 'DEBIT' or (exists($amount) and $amount lt 0)) then 'out' else 'in'
};

declare %private function proposals:movements($collection as xs:string, $own as xs:string*) as element(Movement)* {
	for $bank in collection($collection)/BankAccount
	for $accounting in $bank/Accountings/Accounting[not(@isStorno = 'true')]
	let $iban := proposals:compact($accounting/IBAN)
	let $creditor := match:clean-ref($accounting/CreditorID)
	let $mandate := match:clean-ref($accounting/MandantRef)
	let $amount := proposals:amount($accounting)
	where ($iban != '' or $creditor != '') and not($iban = $own) and exists($amount)
	return
		<Movement bank="{string($bank/@kto)}" id="{string($accounting/@id)}" date="{substring(normalize-space(string($accounting/ValueDate)), 1, 10)}" amount="{format-number(abs($amount), '0.00')}" direction="{proposals:direction($accounting)}" recipient="{normalize-space(string($accounting/Recipient))}" iban="{$iban}" bic="{normalize-space(string($accounting/BIC))}" creditor="{$creditor}" mandate="{$mandate}" customer="{let $c := normalize-space(string($accounting/CustomerRef)) return if ($c = ('NONREF', 'NOTPROVIDED')) then '' else $c}" purpose="{normalize-space(string-join(($accounting/PaymentDetail, $accounting/Usage), ' '))}"/>
};

declare %private function proposals:best-party($recipient as xs:string, $parties as element(Account)*, $kind as xs:string) as element(Score)? {
	(
		for $account in $parties
		let $score := max((for $name in proposals:names($account) return match:name-score($recipient, $name), 0))
		where $score ge 0.8
		order by (if (proposals:party-kind($account) = $kind) then 0 else 1), $score descending
		return <Score kto="{string($account/@kto)}" value="{format-number($score, '0.00')}" name="{normalize-space(string($account/Name))}"/>
	)[1]
};

declare %private function proposals:bank-account($rows as element(Movement)*) as element(BankAccount) {
	let $from := min($rows/@date[. castable as xs:date] ! xs:date(.))
	return
		<BankAccount name="{proposals:most($rows/@recipient ! string(.))}" iban="{proposals:most($rows/@iban ! string(.))}" bic="{proposals:most($rows/@bic ! string(.))}" usage="" customerRef="{proposals:most($rows/@customer ! string(.))}" mandateRef="{proposals:most($rows/@mandate ! string(.))}" creditorId="{proposals:most($rows/@creditor ! string(.))}" notes="">
			{if (exists($from)) then attribute valid-from {$from} else ()}
		</BankAccount>
};

declare %private function proposals:evidence($rows as element(Movement)*) as element(Evidence) {
	<Evidence>{
		for $row in $rows
		order by $row/@date descending
		return $row
	}</Evidence>
};

declare %private function proposals:weight($rows as element()*) as xs:string {
	format-number(count($rows) + sum(for $row in $rows return xs:decimal($row/@amount)) div 1000, '0.00')
};

(: Unbekannte IBAN oder Gläubiger-ID: neues Konto oder Bankverbindung an bestehendem Konto. :)
declare %private function proposals:party-proposals($movements as element(Movement)*, $accounts as element(Account)*, $own as xs:string*) as element(Proposal)* {
	let $known := proposals:known-keys($accounts, $own)
	let $parties := $accounts[exists(proposals:party-kind(.))]
	let $unknown := $movements[not(concat('iban:', @iban) = $known)][not(@creditor != '' and concat('creditor:', @creditor) = $known)]
	let $groups :=
		for $key in distinct-values(for $row in $unknown return if ($row/@creditor != '') then concat('creditor:', $row/@creditor) else concat('iban:', $row/@iban))
		let $rows := $unknown[(if (@creditor != '') then concat('creditor:', @creditor) else concat('iban:', @iban)) = $key]
		let $recipient := proposals:most($rows/@recipient ! string(.))
		let $kind := if (count($rows[@direction = 'out']) ge count($rows[@direction = 'in'])) then 'creditor' else 'debitor'
		return <Cluster key="{$key}" recipient="{$recipient}" kind="{$kind}">{$rows}</Cluster>
	let $fallback := map { 'debitor': 10000, 'creditor': 70000 }
	let $new :=
		for $cluster in $groups
		let $rows := $cluster/Movement
		let $hit := proposals:best-party(string($cluster/@recipient), $parties, string($cluster/@kind))
		where empty($hit) and count($rows) ge 2 and string($cluster/@recipient) != ''
		return $cluster
	return (
		for $cluster in $groups
		let $rows := $cluster/Movement
		let $hit := proposals:best-party(string($cluster/@recipient), $parties, string($cluster/@kind))
		where exists($hit)
		let $bank := proposals:bank-account($rows)
		let $what := if (starts-with($cluster/@key, 'creditor:')) then 'Gläubiger-ID' else 'IBAN'
		return
			<Proposal id="{proposals:id('bank-add', concat($hit/@kto, '|', $cluster/@key))}" kind="bank-add" kto="{$hit/@kto}" name="{$hit/@name}" basis="{count($rows)}" count="{count($rows)}" amount="{format-number(sum(for $row in $rows return xs:decimal($row/@amount)), '0.00')}" weight="{proposals:weight($rows)}" score="{$hit/@value}">
				<Title>{concat($what, ' ', substring-after($cluster/@key, ':'), ' an ', $hit/@name, ' ergänzen')}</Title>
				<Reason>{concat('Der Empfänger „', $cluster/@recipient, '“ ähnelt dem Konto ', $hit/@name, ' (', $hit/@kto, ', Ähnlichkeit ', $hit/@value, '). Die ', $what, ' ist dort noch nicht hinterlegt.')}</Reason>
				{proposals:evidence($rows)}
				<Payload>{$bank}</Payload>
			</Proposal>,
		for $kind in ('creditor', 'debitor')
		let $taken := $accounts[proposals:party-kind(.) = $kind]/@kto[. castable as xs:integer] ! xs:integer(.)
		let $start := max(($taken, $fallback($kind)))
		for $cluster at $position in $new[@kind = $kind]
		let $rows := $cluster/Movement
		let $kto := string($start + $position)
		let $bank := proposals:bank-account($rows)
		return
			<Proposal id="{proposals:id('party-new', string($cluster/@key))}" kind="party-new" kto="{$kto}" name="{string($cluster/@recipient)}" basis="{count($rows)}" count="{count($rows)}" amount="{format-number(sum(for $row in $rows return xs:decimal($row/@amount)), '0.00')}" weight="{proposals:weight($rows)}">
				<Title>{concat(if ($kind = 'creditor') then 'Kreditor' else 'Debitor', ' „', $cluster/@recipient, '“ anlegen')}</Title>
				<Reason>{concat(count($rows), ' Bewegungen mit ', if (starts-with($cluster/@key, 'creditor:')) then 'Gläubiger-ID ' else 'IBAN ', substring-after($cluster/@key, ':'), ' gehören zu keinem Konto.')}</Reason>
				{proposals:evidence($rows)}
				<Payload>
					<Account id="{account:speaking-id(string($cluster/@recipient), $kto)}" kto="{$kto}" type="ledger_account" classes="{$kind}">
						<Name>{string($cluster/@recipient)}</Name>
						<Notes/>
						<BankAccounts>{$bank}</BankAccounts>
						<Accounting openingBalance="0" closingBalance="0" debitSum="0" creditSum="0"/>
					</Account>
				</Payload>
			</Proposal>
	)
};

declare %private function proposals:interval-label($interval as xs:string) as xs:string {
	if ($interval = 'monthly') then 'monatlich'
	else if ($interval = 'quarterly') then 'vierteljährlich'
	else if ($interval = 'annually') then 'jährlich'
	else $interval
};

declare %private function proposals:rows-for($past as element(Past)*, $kto as xs:string) as element(Past)* {
	let $rows := $past[@owner = $kto][@date castable as xs:date]
	let $latest := max(for $row in $rows return xs:date($row/@date))
	return if (empty($latest)) then () else $rows[xs:date(@date) ge $latest - xs:dayTimeDuration('P400D')]
};

declare %private function proposals:key-rule($rows as element(Past)*) as element(PaymentRule)? {
	let $creditor := proposals:most($rows/@creditor ! string(.))
	let $iban := proposals:most($rows/@iban ! string(.))
	return
		if ($creditor != '' and count($rows[@creditor = $creditor]) * 2 ge count($rows)) then <PaymentRule type="SEPA_DIRECT-DEBIT_CREDITOR-ID" use="required">{$creditor}</PaymentRule>
		else if ($iban != '' and count($rows[@iban = $iban]) * 2 ge count($rows)) then <PaymentRule type="{if ($rows[1]/@creditor != '') then 'SEPA_DIRECT-DEBIT_IBAN' else 'SEPA_CREDIT-TRANSFER_IBAN'}" use="required">{$iban}</PaymentRule>
		else ()
};

declare %private function proposals:stable-words($rows as element(Past)*) as xs:string* {
	let $need := xs:integer(ceiling(count($rows) * 0.6))
	return subsequence(
		for $word in distinct-values(for $row in $rows return match:words($row/@purpose))
		where string-length($word) ge 4 and not(matches($word, '[0-9]')) and count($rows[match:words(@purpose) = $word]) ge $need
		order by count($rows[match:words(@purpose) = $word]) descending, $word
		return $word, 1, 4)
};

declare %private function proposals:past-evidence($rows as element(Past)*) as element(Evidence) {
	<Evidence>{
		for $row in $rows
		order by $row/@date descending
		return <Movement id="{$row/@id}" process="{$row/@process}" date="{$row/@date}" amount="{$row/@amount}" direction="{$row/@direction}" iban="{$row/@iban}" creditor="{$row/@creditor}" purpose="{$row/@purpose}"/>
	}</Evidence>
};

declare %private function proposals:active($account as element(Account), $date as xs:date) as element(PeriodicPayment)* {
	for $payment in $account/PeriodicPayments/PeriodicPayment
	let $from := normalize-space(string($payment/Period/@valid-from))
	let $till := normalize-space(string($payment/Period/@valid-till))
	where (not($from castable as xs:date) or xs:date($from) le $date) and (not($till castable as xs:date) or xs:date($till) ge $date)
	return $payment
};

(:
	Nur laufende Beziehungen (letzte Zahlung höchstens 120 Tage vor der jüngsten bestätigten Zahlung)
	und nur mit einem Schlüssel (IBAN, Gläubiger-ID) oder einer engen Betragsspanne.
	Sammelkonten wie „Diverse Lieferanten“ fallen so heraus.
:)
declare %private function proposals:interval-new($accounts as element(Account)*, $past as element(Past)*, $focus as xs:string?) as element(Proposal)* {
	let $newest := max(for $row in $past[@date castable as xs:date] return xs:date($row/@date))
	for $account in $accounts[exists(proposals:party-kind(.))]
	let $kto := string($account/@kto)
	where empty($focus) or $focus = '' or $focus = $kto
	let $rows := proposals:rows-for($past, $kto)
	where count($rows) ge (if ($focus = $kto) then 2 else 3)
	let $dates := for $row in $rows return xs:date($row/@date)
	where $focus = $kto or max($dates) ge $newest - xs:dayTimeDuration('P120D')
	let $interval := match:infer-interval($dates)
	where empty(proposals:active($account, max($dates))[string(Period/@interval) = $interval])
	let $amounts := for $row in $rows return xs:decimal($row/@amount)
	let $min := floor(min($amounts) * 0.9)
	let $max := ceiling(max($amounts) * 1.1)
	let $key := proposals:key-rule($rows)
	where $focus = $kto or exists($key) or max($amounts) le 3 * min($amounts)
	let $words := proposals:stable-words($rows)
	let $other := proposals:most($rows/@other ! string(.))
	let $days := for $date in $dates return day-from-date($date)
	let $payday := proposals:most($days ! string(.))
	let $name := normalize-space(string($account/Name))
	return
		<Proposal id="{proposals:id('interval-new', concat($kto, '|', $interval))}" kind="interval-new" kto="{$kto}" name="{$name}" basis="{count($rows)}" count="{count($rows)}" amount="{format-number(sum($amounts), '0.00')}" weight="{proposals:weight($rows)}">
			<Title>{concat('Zahlungsintervall ', proposals:interval-label($interval), ' für ', $name)}</Title>
			<Reason>{concat(count($rows), ' bestätigte Zahlungen zwischen ', min($dates), ' und ', max($dates), ', Beträge ', format-number(min($amounts), '0.00'), ' bis ', format-number(max($amounts), '0.00'), ' EUR.')}</Reason>
			{proposals:past-evidence($rows)}
			<Payload>
				<PeriodicPayment>
					<Name>{concat($name, ' (', proposals:interval-label($interval), ')')}</Name>
					<Period interval="{$interval}" min="1" max="1" amount-min="{format-number($min, '0.00')}" amount-max="{format-number($max, '0.00')}" valid-from="{string(min($dates))}"/>
					<DocumentTemplate>
						<Section/>
						<Other kto="{$other}"/>
						<RefID/>
						<TransactionID/>
						<Description>{if (exists($words)) then string-join($words, ' ') else $name}</Description>
						<Tax key="" region="" type=""/>
						<TotalAmount value="" unit="EUR"/>
						<Appointment date=""/>
						<Notes/>
					</DocumentTemplate>
					<PaymentRules>
						{$key}
						{for $word in $words return <PaymentRule type="SEPA_PAYMENT-DETAILS_ASCII" use="{if (empty($key)) then 'required' else 'optional'}">{$word}</PaymentRule>}
					</PaymentRules>
					<Notes>{if ($payday = '') then () else concat('Zahltag ', $payday)}</Notes>
				</PeriodicPayment>
			</Payload>
		</Proposal>
};

declare %private function proposals:interval-rows($payment as element(PeriodicPayment), $account as element(Account), $rows as element(Past)*) as element(Past)* {
	let $keys := $payment/PaymentRules/PaymentRule[@type = ('SEPA_DIRECT-DEBIT_IBAN', 'SEPA_CREDIT-TRANSFER_IBAN', 'SEPA_DIRECT-DEBIT_CREDITOR-ID')]
	return
		if (exists($keys)) then
			$rows[some $rule in $keys satisfies (if ($rule/@type = 'SEPA_DIRECT-DEBIT_CREDITOR-ID') then @creditor = proposals:compact($rule) else @iban = proposals:compact($rule))]
		else if (count($account/PeriodicPayments/PeriodicPayment) = 1) then $rows
		else ()
};

declare %private function proposals:interval-adjust($accounts as element(Account)*, $past as element(Past)*) as element(Proposal)* {
	for $account in $accounts[exists(proposals:party-kind(.))][PeriodicPayments/PeriodicPayment]
	let $kto := string($account/@kto)
	let $owned := proposals:rows-for($past, $kto)
	for $payment at $index in $account/PeriodicPayments/PeriodicPayment
	let $rows := proposals:interval-rows($payment, $account, $owned)
	let $till := normalize-space(string($payment/Period/@valid-till))
	let $successor := $till castable as xs:date and exists($account/PeriodicPayments/PeriodicPayment[Period/@valid-from castable as xs:date][xs:date(Period/@valid-from) gt xs:date($till)])
	let $late := if ($till castable as xs:date and not($successor)) then $rows[xs:date(@date) gt xs:date($till)] else ()
	let $recent := subsequence(for $row in $rows order by $row/@date descending return $row, 1, 3)
	let $low := xs:decimal((translate(string($payment/Period/@amount-min), ',', '.')[. castable as xs:decimal], -1)[1])
	let $high := xs:decimal((translate(string($payment/Period/@amount-max), ',', '.')[. castable as xs:decimal], -1)[1])
	let $outside := $recent[($low ge 0 and xs:decimal(@amount) lt $low) or ($high gt 0 and xs:decimal(@amount) gt $high)]
	let $name := normalize-space(string($payment/Name))
	return (
		if (count($late) ge 2) then
			<Proposal id="{proposals:id('interval-adjust', concat($kto, '|', $index, '|till'))}" kind="interval-adjust" kto="{$kto}" index="{$index}" name="{normalize-space(string($account/Name))}" basis="{count($late)}" count="{count($late)}" amount="{format-number(sum($late/@amount ! xs:decimal(.)), '0.00')}" weight="{proposals:weight($late)}">
				<Title>{concat('Zahlungsintervall „', $name, '“ läuft weiter')}</Title>
				<Reason>{concat('Das Intervall endet am ', $till, ', danach gab es ', count($late), ' bestätigte Zahlungen.')}</Reason>
				{proposals:past-evidence($late)}
				<Payload>{
					element PeriodicPayment {
						$payment/@*,
						for $child in $payment/*
						return if ($child/self::Period) then element Period { $child/@*[not(local-name() = 'valid-till')], attribute valid-till {''} } else $child
					}
				}</Payload>
			</Proposal>
		else (),
		if (count($recent) = 3 and count($outside) = 3) then
			let $amounts := $recent/@amount ! xs:decimal(.)
			return
				<Proposal id="{proposals:id('interval-adjust', concat($kto, '|', $index, '|range'))}" kind="interval-adjust" kto="{$kto}" index="{$index}" name="{normalize-space(string($account/Name))}" basis="{string-join($recent/@id, ',')}" count="3" amount="{format-number(sum($amounts), '0.00')}" weight="{proposals:weight($recent)}">
					<Title>{concat('Betragsspanne von „', $name, '“ anpassen')}</Title>
					<Reason>{concat('Die letzten drei Zahlungen (', string-join($amounts ! format-number(., '0.00'), ', '), ' EUR) liegen außerhalb der Spanne ', $payment/Period/@amount-min, ' bis ', $payment/Period/@amount-max, '.')}</Reason>
					{proposals:past-evidence($recent)}
					<Payload>{
						element PeriodicPayment {
							$payment/@*,
							for $child in $payment/*
							return
								if ($child/self::Period) then
									element Period {
										$child/@*[not(local-name() = ('amount-min', 'amount-max'))],
										attribute amount-min {format-number(floor(min($amounts) * 0.95), '0.00')},
										attribute amount-max {format-number(ceiling(max($amounts) * 1.05), '0.00')}
									}
								else $child
						}
					}</Payload>
				</Proposal>
		else ()
	)
};

declare %private function proposals:hint-proposals($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $accounts as element(Account)*) as element(Proposal)* {
	let $path := concat(proposals:collection($home-data, $tenant, $year), '/accounts.hint-proposals.xml')
	let $file := if (doc-available($path)) then doc($path)/AccountHintProposals else ()
	for $entry in $file/Account
	let $account := $accounts[string(@kto) = string($entry/@kto)][1]
	where exists($account)
	for $hint in $entry/FieldHints/Hint
	let $field := string($hint/@field)
	let $label := normalize-space(string($hint/@label))
	let $pattern := normalize-space(string($hint/@pattern))
	where empty($account/FieldHints/Hint[@field = $field][normalize-space(@label) = $label][normalize-space(@pattern) = $pattern])
	return
		<Proposal id="{proposals:id('hint', concat($entry/@kto, '|', $field, '|', $label, '|', $pattern))}" kind="hint" kto="{string($entry/@kto)}" name="{string($entry/@name)}" basis="1" count="1" amount="0" weight="0.50">
			<Title>{concat('Feldhinweis ', $field, ' für ', $entry/@name)}</Title>
			<Reason>{concat('Quelle: ', $hint/@source, '. ', if ($label != '') then concat('Text „', $label, '“') else concat('Muster ', $pattern))}</Reason>
			<Evidence/>
			<Payload><Hint field="{$field}" label="{$label}" pattern="{$pattern}" region="{string($hint/@region)}"/></Payload>
		</Proposal>
};

declare %private function proposals:dismissed-path($home-data as xs:string, $tenant as xs:string, $year as xs:integer) as xs:string {
	concat(proposals:collection($home-data, $tenant, $year), '/proposals-dismissed.xml')
};

declare %private function proposals:dismissed($home-data as xs:string, $tenant as xs:string, $year as xs:integer) as element(Proposal)* {
	let $path := proposals:dismissed-path($home-data, $tenant, $year)
	return if (doc-available($path)) then doc($path)/Dismissed/Proposal else ()
};

declare %private function proposals:kind-rank($kind as xs:string) as xs:integer {
	(index-of($proposals:kinds, $kind), 9)[1]
};

declare function proposals:all($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $focus as xs:string?) as element(Proposal)* {
	let $collection := proposals:collection($home-data, $tenant, $year)
	let $accounts := proposals:rows($home-data, $tenant, $year)
	let $own := distinct-values(for $iban in collection($collection)/BankAccount/BankAccountDetail/IBAN return proposals:compact($iban))[. != '']
	let $movements := proposals:movements($collection, $own)
	let $past := match:history($home-data, $tenant, $year)
	let $dismissed := proposals:dismissed($home-data, $tenant, $year)
	let $found := (
		proposals:party-proposals($movements, $accounts, $own),
		proposals:interval-new($accounts, $past, $focus),
		proposals:interval-adjust($accounts, $past),
		proposals:hint-proposals($home-data, $tenant, $year, $accounts)
	)
	for $proposal in $found
	where empty($dismissed[@id = $proposal/@id][@basis = $proposal/@basis])
	where empty($focus) or $focus = '' or $proposal/@kto = $focus
	order by proposals:kind-rank(string($proposal/@kind)), xs:decimal($proposal/@weight) descending
	return $proposal
};

declare function proposals:list($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $focus as xs:string?) as element(Proposals) {
	let $all := proposals:all($home-data, $tenant, $year, $focus)
	return
		<Proposals tenant="{$tenant}" year="{$year}" count="{count($all)}">
			{for $kind in $proposals:kinds return <Kind id="{$kind}" count="{count($all[@kind = $kind])}"/>}
			{$all}
		</Proposals>
};

(: Verwerfen braucht kind/kto/basis. Kommen sie im Rumpf, entfällt die teure Neuberechnung. :)
declare function proposals:reject($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $id as xs:string, $body as element()?, $user as xs:string) as element(Rejected) {
	let $stub :=
		if (exists($body) and normalize-space(string($body/@kind)) != '') then
			<Proposal id="{$id}" kind="{string($body/@kind)}" kto="{string($body/@kto)}" basis="{string($body/@basis)}"/>
		else ()
	let $found := if (exists($stub)) then $stub else proposals:all($home-data, $tenant, $year, ())[@id = $id][1]
	let $path := proposals:dismissed-path($home-data, $tenant, $year)
	let $entry := <Proposal id="{$id}" kind="{string($found/@kind)}" kto="{string($found/@kto)}" basis="{string($found/@basis)}" user="{$user}" at="{current-dateTime()}"/>
	return
		if (empty($found)) then <Rejected id="{$id}" error="Vorschlag nicht gefunden."/>
		else
			try {
				let $stored :=
					if (doc-available($path)) then (
						update delete doc($path)/Dismissed/Proposal[@id = $id],
						update insert $entry into doc($path)/Dismissed
					)
					else
						let $collection := proposals:collection($home-data, $tenant, $year)
						let $file := xmldb:store($collection, 'proposals-dismissed.xml', <Dismissed>{$entry}</Dismissed>)
						let $mode := sm:chmod(xs:anyURI($path), 'rwxrwxr-x')
						let $group := sm:chgrp(xs:anyURI($path), 'docman')
						return ()
				return <Rejected id="{$id}"/>
			} catch * { <Rejected id="{$id}" error="{$err:description}"/> }
};

declare %private function proposals:ensure($account as element(), $name as xs:string) as element() {
	if (exists($account/*[local-name() = $name])) then $account/*[local-name() = $name][1]
	else
		let $made := update insert element {$name} {} into $account
		return $account/*[local-name() = $name][1]
};

declare %private function proposals:clean-account($incoming as element(Account), $kto as xs:string, $kind as xs:string) as element(Account) {
	let $given := normalize-space(string($incoming/@id))
	let $id := if ($given != '' and $given != $kto) then $given else account:speaking-id(string($incoming/Name), $kto)
	return
	<Account id="{$id}" kto="{$kto}" type="ledger_account" classes="{$kind}">
		<Name>{normalize-space(string($incoming/Name))}</Name>
		{($incoming/Notes, <Notes/>)[1]}
		{$incoming/*[not(local-name() = ('Name', 'Notes', 'Accounting'))]}
		{($incoming/Accounting, <Accounting openingBalance="0" closingBalance="0" debitSum="0" creditSum="0"/>)[1]}
	</Account>
};

declare %private function proposals:apply($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $proposal as element(Proposal), $payload as element()?) as element(Accepted) {
	let $kind := string($proposal/@kind)
	let $kto := string($proposal/@kto)
	let $target := if ($kind = 'party-new') then () else account:mutable($home-data, $tenant, $year, $kto)
	return
		if (empty($payload)) then <Accepted error="Leerer Vorschlag."/>
		else if ($kind = 'party-new') then
			let $accounts := proposals:rows($home-data, $tenant, $year)
			let $incoming := $payload/descendant-or-self::Account[1]
			let $new-kto := normalize-space(string($incoming/@kto))
			let $class := tokenize(string($incoming/@classes), '\s+')[. = ('creditor', 'debitor')][1]
			return
				if (not($new-kto castable as xs:integer)) then <Accepted error="Kontonummer fehlt."/>
				else if (exists($accounts[string(@kto) = $new-kto])) then <Accepted error="Kontonummer {$new-kto} ist vergeben."/>
				else if (normalize-space(string($incoming/Name)) = '') then <Accepted error="Name fehlt."/>
				else if (empty($class)) then <Accepted error="Kreditor oder Debitor wählen."/>
				else
					let $account := proposals:clean-account($incoming, $new-kto, $class)
					return
						if (exists($accounts[lower-case(@id) = lower-case($account/@id)])) then <Accepted error="Konto-Id {string($account/@id)} ist vergeben."/>
						else if (exists(account:contact($home-data, $tenant, $year, string($account/@id)))) then <Accepted error="Kontakt-Id {string($account/@id)} ist vergeben."/>
						else
							let $saved := account:create-party($home-data, $tenant, $year, $account)
							return <Accepted kind="{$kind}" kto="{$new-kto}" account="{string($saved/@id)}" contact="{string($saved/@contactsRef)}"/>
		else if (empty($target)) then <Accepted error="Konto {$kto} nicht gefunden."/>
		else if ($kind = 'bank-add') then
			let $bank := $payload/descendant-or-self::BankAccount[1]
			let $iban := proposals:compact($bank/@iban)
			let $creditor := proposals:compact($bank/@creditorId)
			let $same := $target/BankAccounts/BankAccount[($iban != '' and proposals:compact(@iban) = $iban) or ($iban = '' and $creditor != '' and proposals:compact(@creditorId) = $creditor)]
			return
				if (empty($bank)) then <Accepted error="Bankverbindung fehlt."/>
				else if (exists($same)) then
					let $done := update replace $same[1] with $bank
					return <Accepted kind="{$kind}" kto="{$kto}" replaced="true"/>
				else
					let $box := proposals:ensure($target, 'BankAccounts')
					let $done := update insert $bank into $box
					return <Accepted kind="{$kind}" kto="{$kto}"/>
		else if ($kind = 'interval-new') then
			let $payment := $payload/descendant-or-self::PeriodicPayment[1]
			return
				if (empty($payment) or normalize-space(string($payment/Name)) = '') then <Accepted error="Zahlungsintervall ohne Bezeichnung."/>
				else
					let $box := proposals:ensure($target, 'PeriodicPayments')
					let $done := update insert $payment into $box
					return <Accepted kind="{$kind}" kto="{$kto}"/>
		else if ($kind = 'interval-adjust') then
			let $payment := $payload/descendant-or-self::PeriodicPayment[1]
			let $index := xs:integer(($proposal/@index[. castable as xs:integer], 0)[1])
			let $current := $target/PeriodicPayments/PeriodicPayment[$index]
			return
				if (empty($payment) or empty($current)) then <Accepted error="Zahlungsintervall nicht gefunden."/>
				else
					let $done := update replace $current with $payment
					return <Accepted kind="{$kind}" kto="{$kto}"/>
		else if ($kind = 'hint') then
			let $hint := $payload/descendant-or-self::Hint[1]
			return
				if (empty($hint)) then <Accepted error="Feldhinweis fehlt."/>
				else
					let $box := proposals:ensure($target, 'FieldHints')
					let $done := update insert <Hint field="{string($hint/@field)}" label="{string($hint/@label)}" pattern="{string($hint/@pattern)}" region="{string($hint/@region)}"/> into $box
					return <Accepted kind="{$kind}" kto="{$kto}"/>
		else <Accepted error="Unbekannte Art {$kind}."/>
};

(: Der Rumpf ist der Vorschlag, wie ihn der Nutzer bearbeitet hat (Proposal mit Payload oder nur das Payload-Element).
   Mit kind und kto im Rumpf entfällt die teure Neuberechnung aller Vorschläge. :)
declare function proposals:accept($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $id as xs:string, $body as element()?, $user as xs:string) as element(Accepted) {
	let $stub :=
		if ($body/self::Proposal and normalize-space(string($body/@kind)) != '' and normalize-space(string($body/@kto)) != '') then
			<Proposal id="{$id}" kind="{string($body/@kind)}" kto="{string($body/@kto)}" index="{string($body/@index)}" basis="{string($body/@basis)}">
				{$body/Payload}
			</Proposal>
		else ()
	let $found := if (exists($stub)) then $stub else proposals:all($home-data, $tenant, $year, ())[@id = $id][1]
	let $ready := doc-available(account:year-path($home-data, $tenant, $year))
	let $payload :=
		if (empty($body)) then $found/Payload/*[1]
		else if ($body/self::Proposal) then ($body/Payload/*[1], $found/Payload/*[1])[1]
		else if ($body/self::Payload) then $body/*[1]
		else $body
	return
		if (empty($found)) then <Accepted id="{$id}" error="Vorschlag nicht gefunden oder schon erledigt."/>
		else if (not($ready)) then <Accepted id="{$id}" error="accounts.dm.xml fehlt."/>
		else
			try {
				let $result := proposals:apply($home-data, $tenant, $year, $found, $payload)
				return <Accepted id="{$id}" user="{$user}">{$result/@*[local-name() != 'id']}</Accepted>
			} catch * { <Accepted id="{$id}" error="{$err:description}"/> }
};
