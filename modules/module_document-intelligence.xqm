(:
Document Intelligence.
di:ensure legt nur eine docman.xml mit status="pending" an.
di:process liest sie im Hintergrund und ersetzt die Felder. Notes bleibt.
:)

xquery version "3.1";

module namespace di = "http://bintellix.com/docman/document-intelligence";

declare namespace file = "http://exist-db.org/xquery/file";

import module namespace main = "http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace process = "http://exist-db.org/xquery/process";
import module namespace scheduler = "http://exist-db.org/xquery/scheduler";

declare function di:collection($home as xs:string, $tenant as xs:string, $year) as xs:string {
	$home || '/' || $tenant || '/' || $year || '/transfer'
};

declare function di:is-document($name as xs:string) as xs:boolean {
	matches(lower-case($name), '\.(pdf|tif|tiff|png|jpg|jpeg)$')
};

declare function di:stem($name as xs:string) as xs:string {
	replace($name, '\.[^.]+$', '')
};

declare function di:locate($collection as xs:string, $file as xs:string) as xs:string {
	let $plain := di:stem($file) || '.docman.xml'
	let $full := $file || '.docman.xml'
	let $plain-source :=
		if (doc-available($collection || '/' || $plain)) then string(doc($collection || '/' || $plain)/*/@source)
		else ''
	return
		if ($plain-source = $file) then $plain
		else if (doc-available($collection || '/' || $full) and string(doc($collection || '/' || $full)/*/@source) = $file) then $full
		else ''
};

declare function di:target-name($collection as xs:string, $file as xs:string) as xs:string {
	let $found := di:locate($collection, $file)
	let $plain := di:stem($file) || '.docman.xml'
	return
		if ($found != '') then $found
		else if (doc-available($collection || '/' || $plain)) then $file || '.docman.xml'
		else $plain
};

declare function di:shell($file as xs:string, $from as xs:string, $subject as xs:string) as element() {
	<DocmanIntelligence version="1.0" source="{$file}" status="pending" created="{current-dateTime()}" updated="{current-dateTime()}">
		<Source kind="" origin="" pages="0"/>
		<Document type="unknown" quality="0"/>
		<Account id="" quality="0"/>
		<Fields/>
		<Articles/>
		<Text/>
		<Notes/>
		<Meta from="{$from}" subject="{$subject}"/>
		<Progress step="queued" message="In der Warteschlange." position="0" queued="0" at="{current-dateTime()}"/>
	</DocmanIntelligence>
};

declare function di:progress($step as xs:string, $message as xs:string, $position as xs:integer, $queued as xs:integer) as element() {
	<Progress step="{$step}" message="{$message}" position="{$position}" queued="{$queued}" at="{current-dateTime()}"/>
};

declare function di:installed() as xs:boolean {
	try {
		let $config := $main:home-data || '/document-intelligence.xml'
		return doc-available($config) and string(doc($config)/DocumentIntelligence/@installed) = 'true'
	} catch * {
		false()
	}
};

declare function di:schedule() as item()* {
	if (not(di:installed())) then ()
	else
		let $job := '/db/apps/docman/modules/functions/document_intelligence_process.xqy'
		return
			try {
				(: Letztes Argument false: bei Fehler nicht aus dem Plan nehmen. :)
				scheduler:schedule-xquery-periodic-job($job, 60000, 'docman-intelligence', <parameters/>, 2000, -1, false())
			} catch * {
				()
			}
};

declare function di:ensure($home as xs:string, $tenant as xs:string, $year, $file as xs:string, $from as xs:string, $subject as xs:string) as item()* {
	(: Der periodische Job kommt aus initialize.xqy. Hier nur die Metadatei anlegen. :)
	if (not(di:is-document($file))) then ()
	else
		let $collection := di:collection($home, $tenant, $year)
		let $name := di:target-name($collection, $file)
		return
			if (doc-available($collection || '/' || $name)) then ()
			else xmldb:store($collection, $name, di:shell($file, $from, $subject))
};

declare function di:command() as xs:string {
	let $config := $main:home-data || '/document-intelligence.xml'
	return
		if (doc-available($config) and string(doc($config)/DocumentIntelligence/@command) != '') then
			string(doc($config)/DocumentIntelligence/@command)
		else
			'/opt/docman-intelligence/.venv/bin/docman-intelligence'
};

declare function di:accounts($home as xs:string, $tenant as xs:string, $year) as element() {
	let $path := $home || '/' || $tenant || '/' || $year || '/accounts.dm.xml'
	let $accounts := if (doc-available($path)) then doc($path)/Accounts else ()
	return
		<Accounts>{
			for $account in $accounts/Account
			let $classes := tokenize(normalize-space(string($account/@classes)), '\s+')
			let $type := string($account/@type)
			where $classes = ('creditor', 'debitor', 'self') or $type = ('creditor', 'debitor', 'self')
			return
				<Account id="{$account/@id}" classes="{string-join(($classes[normalize-space(.) != ''], $type[normalize-space(.) != '']), ' ')}" type="{$type}">
					<Name>{string($account/Name)}</Name>
					<Company>{string($account/Company/Name)}</Company>
					<Email>{string($account/Contact/Email)}</Email>
					<VatId>{string($account/VatId)}</VatId>
					<CustomerID>{string($account/CustomerID)}</CustomerID>
					<Address>{string($account/Address)}</Address>
					{ if (normalize-space(string($account/@iban)) != '') then <IBAN>{string($account/@iban)}</IBAN> else () }
					{
						for $bank in $account/BankAccounts/BankAccount
						where normalize-space(string($bank/@iban)) != ''
						return <IBAN>{string($bank/@iban)}</IBAN>
					}
					<Hints>{
						for $hint in $account/FieldHints/Hint
						return <Hint field="{$hint/@field}" label="{$hint/@label}" region="{$hint/@region}" pattern="{$hint/@pattern}"/>
					}</Hints>
				</Account>
		}</Accounts>
};

declare function di:chunks($text as xs:string) as xs:string* {
	if ($text = '') then ()
	else
		for $index in 0 to xs:integer(floor((string-length($text) - 1) div 76))
		return substring($text, $index * 76 + 1, 76)
};

declare function di:start-error($command as xs:string, $detail as xs:string) as element() {
	if (contains($detail, 'error=2') or contains($detail, 'nicht gefunden') or contains($detail, 'No such file')) then
		<Error>Programm nicht installiert: {$command}. Auf dem Server als root ausführen: sh /tmp/docman-intelligence/install-linux.sh</Error>
	else
		<Error>{substring($detail, 1, 500)}</Error>
};

declare function di:probe($command as xs:string) as element()? {
	try {
		let $run := process:execute(($command, '--version'), <options/>)
		let $detail := normalize-space(string-join(($run/stderr/line, $run/stdout/line), ' '))
		return
			if (xs:integer($run/@exitCode) = 0) then ()
			else di:start-error($command, $detail)
	} catch * {
		di:start-error($command, $err:description)
	}
};

declare function di:work-path($file as xs:string) as xs:string {
	'/tmp/docman-intelligence-work/' || replace($file, '[^A-Za-z0-9._-]+', '_')
};

(: @source kann %20 enthalten, die Ressource in der DB oft ein Leerzeichen. :)
declare function di:binary-uri($collection as xs:string, $file as xs:string) as xs:string? {
	let $decoded := replace($file, '%20', ' ')
	let $candidates := distinct-values(($file, $decoded))
	return
		(
			for $name in $candidates
			let $uri := $collection || '/' || $name
			where util:binary-doc-available($uri)
			return $uri
		)[1]
};

declare function di:run($home as xs:string, $tenant as xs:string, $year, $file as xs:string, $from as xs:string, $subject as xs:string) as item()* {
	let $command := di:command()
	let $probe := di:probe($command)
	let $collection := di:collection($home, $tenant, $year)
	let $binary := di:binary-uri($collection, $file)
	return
		if ($probe) then
			$probe
		else if (empty($binary)) then
			<Error>PDF fehlt in der Datenbank: {$collection}/{$file}</Error>
		else
			try {
				let $dir := file:mkdirs('/tmp/docman-intelligence-work')
				let $tmp := di:work-path($file)
				let $written := file:serialize-binary(util:binary-doc($binary), $tmp)
				return
					if (not($written) or not(file:exists($tmp))) then
						<Error>Temp-Datei nicht geschrieben: {$tmp}</Error>
					else
						let $accounts := serialize(di:accounts($home, $tenant, $year), map { 'method': 'xml', 'indent': false() })
						let $model-path := $home || '/' || $tenant || '/intelligence/model.xml'
						let $model := if (doc-available($model-path)) then serialize(doc($model-path)/Model, map { 'method': 'xml', 'indent': false() }) else ''
						let $lines := (
							'META',
							'from: ' || $from,
							'subject: ' || replace($subject, '\s+', ' '),
							'END',
							'ACCOUNTS',
							di:chunks($accounts),
							'END',
							'MODEL',
							di:chunks($model),
							'END',
							'FILEPATH',
							$tmp,
							'END'
						)
						(: PDF als Argument, nicht als Base64 — braucht Programm >= 0.1.1 :)
						let $run := process:execute(
							($command, 'read', $tmp),
							<options><stdin>{ for $line in $lines return <line>{$line}</line> }</stdin></options>
						)
						let $out := string-join($run/stdout/line, '')
						let $err := string-join($run/stderr/line, ' ')
						let $cleanup :=
							try { file:delete($tmp) } catch * { () }
						return
							if (starts-with(normalize-space($out), '<')) then
								try { parse-xml($out) } catch * {
									<Error>{substring(string-join(($err, $out, $err:description), ' '), 1, 500)}</Error>
								}
							else if (xs:integer($run/@exitCode) != 0) then
								<Error>{substring(string-join(($err, $out), ' '), 1, 500)}</Error>
							else
								<Error>{substring(string-join(($err, $out), ' '), 1, 500)}</Error>
			} catch * {
				<Error>{substring($err:description, 1, 500)}</Error>
			}
};

(: Normiert Text für Keyword-Treffer (Umlaute, Kleinbuchstaben). :)
declare function di:norm-text($text as xs:string) as xs:string {
	let $lower := lower-case(normalize-space($text))
	let $ae := replace($lower, 'ä', 'ae')
	let $oe := replace($ae, 'ö', 'oe')
	let $ue := replace($oe, 'ü', 'ue')
	return replace($ue, 'ß', 'ss')
};

declare function di:keyword-hits($hay as xs:string, $keywords as xs:string*) as xs:integer {
	sum(
		for $word in $keywords
		let $needle := di:norm-text($word)
		where string-length($needle) >= 3 and contains($hay, $needle)
		return 1
	)
};

(: Dokumentenart aus Python-Sidecar (Text/Source/Felder), optional Accounts für invoice.in vs invoice.out. :)
declare function di:classify-document($intel as element(), $accounts as element()?) as element() {
	let $kind := string($intel/Source/@kind)
	let $text := di:norm-text(string-join(($intel/Text, $intel/Meta/@subject, $intel/Meta/@from), ' '))
	let $has-invoice-field :=
		exists($intel/Fields/Field[@id = ('invoice.id', 'invoice.amount.payable', 'invoice.amount.brutto')][normalize-space(@value) != ''])
	let $score-invoice :=
		(if ($kind = 'zugferd') then 5 else 0)
		+ di:keyword-hits($text, ('rechnung', 'rechnungsnummer', 'rechnungsnr', 'invoice', 'mwst', 'ust-id', 'ust id', 'netto', 'brutto', 'zahlbetrag', 'rechnungsbetrag'))
		+ (if ($has-invoice-field) then 2 else 0)
	let $score-statement := di:keyword-hits($text, ('kontoauszug', 'kontostand', 'anfangssaldo', 'endsaldo', 'buchungstag', 'valuta', 'auszug nr', 'kontoauszugsnummer', 'kontobewegung'))
	let $score-transfer := di:keyword-hits($text, ('ueberweisung', 'sepa-ueberweisung', 'sepa ueberweisung', 'zahlungsauftrag', 'auftraggeber', 'zahlungsempfaenger', 'verwendungszweck', 'ueberweisungsbeleg'))
	let $score-tax := di:keyword-hits($text, ('umsatzsteuervoranmeldung', 'ustva', 'elster', 'finanzamt', 'steuernummer', 'steueranmeldung', 'lohnsteueranmeldung', 'steuerbescheid'))
	let $score-income := di:keyword-hits($text, ('lohnsteuerbescheinigung', 'entgeltabrechnung', 'gehaltsabrechnung', 'lohnabrechnung', 'einkommenssteuerbescheid', 'einkommensteuerbescheid', 'verdienstabrechnung'))
	let $best := (
		<score type="invoice" value="{$score-invoice}"/>,
		<score type="bank.statement" value="{$score-statement}"/>,
		<score type="bank.transfer" value="{$score-transfer}"/>,
		<score type="tax.filing" value="{$score-tax}"/>,
		<score type="income.report" value="{$score-income}"/>
	)
	let $ordered :=
		for $row in $best
		order by xs:integer($row/@value) descending, string($row/@type)
		return $row
	let $top := $ordered[1]
	let $top-value := xs:integer($top/@value)
	let $second := xs:integer(($ordered[2]/@value, 0)[1])
	let $quality :=
		if ($top-value <= 0) then 0
		else if ($kind = 'zugferd' and string($top/@type) = 'invoice') then 0.95
		else if ($top-value >= 4 and $top-value > $second) then min((0.92, 0.55 + $top-value * 0.08))
		else if ($top-value >= 2) then min((0.75, 0.4 + $top-value * 0.08))
		else 0.35
	let $base-type :=
		if ($top-value <= 0) then 'unknown'
		else if (string($top/@type) = 'invoice') then
			di:invoice-direction($intel, $accounts)
		else
			string($top/@type)
	return <Document type="{$base-type}" quality="{$quality}"/>
};

declare function di:invoice-direction($intel as element(), $accounts as element()?) as xs:string {
	let $seller := di:norm-text(string(($intel/Fields/Field[@id = 'sender.name']/@value)[1]))
	let $self-names :=
		for $account in $accounts/Account
		let $classes := tokenize(normalize-space(string-join(($account/@classes, $account/@type), ' ')), '\s+')
		where $classes = 'self'
		return (
			di:norm-text(string($account/Name)),
			di:norm-text(string($account/Company)),
			for $hint in $account/Hints/Hint[@field = 'party.self']
			return di:norm-text(string($hint/@label))
		)
	let $self-hit :=
		some $name in $self-names[string-length(.) >= 4]
		satisfies ($seller != '' and contains($seller, $name)) or ($seller != '' and contains($name, $seller))
	return
		if ($self-hit) then 'invoice.out'
		else 'invoice.in'
};

declare function di:merge($old as element(), $fresh as element(), $accounts as element()?) as element() {
	let $meta := ($fresh/Meta, $old/Meta)[1]
	let $document :=
		if ($fresh/Document) then $fresh/Document
		else
			di:classify-document(
				<Intelligence>
					{$fresh/Source}
					{$fresh/Account}
					{$fresh/Fields}
					{$fresh/Articles}
					{$fresh/Text}
					{$meta}
				</Intelligence>,
				$accounts
			)
	return
		<DocmanIntelligence version="1.0" source="{$old/@source}" status="done" created="{$old/@created}" updated="{current-dateTime()}">
			{$fresh/Source}
			{$document}
			{$fresh/Account}
			{$fresh/Fields}
			{$fresh/Articles}
			{$fresh/Lines}
			{$fresh/Text}
			<Notes>{string($old/Notes)}</Notes>
			{$meta}
			{di:progress('done', 'Fertig.', 0, 0)}
		</DocmanIntelligence>
};

declare function di:fail($old as element(), $message as xs:string) as element() {
	<DocmanIntelligence version="1.0" source="{$old/@source}" status="error" created="{$old/@created}" updated="{current-dateTime()}">
		<Source kind="error" origin="" pages="0"/>
		<Error>{$message}</Error>
		{$old/Fields}
		{$old/Lines}
		{$old/Text}
		<Notes>{string($old/Notes)}</Notes>
		{$old/Meta}
		{di:progress('error', substring($message, 1, 200), 0, 0)}
	</DocmanIntelligence>
};

declare function di:who() as xs:string {
	try {
		let $id := sm:id()
		let $real := string(($id//sm:real/sm:username, $id//sm:username)[1])
		let $effective := string(($id//sm:effective/sm:username, $real)[1])
		return $real || '→' || $effective
	} catch * {
		'?'
	}
};

declare function di:queue($home as xs:string) as element()* {
	for $tenant in xmldb:get-child-collections($home)
	for $year in xmldb:get-child-collections($home || '/' || $tenant)
	where matches($year, '^\d{4}$')
	let $collection := di:collection($home, $tenant, $year)
	where xmldb:collection-available($collection)
	for $name in xmldb:get-child-resources($collection)[ends-with(., '.docman.xml')]
	let $path := $collection || '/' || $name
	where doc-available($path)
	let $doc := doc($path)/DocmanIntelligence
	let $retry := contains($doc/Error, 'dba role')
		or contains($doc/Error, 'nicht installiert')
		or contains($doc/Error, 'error=2')
		or contains($doc/Error, 'Wartet auf den Hintergrundjob')
		or contains($doc/Error, 'Keine Datei')
		or contains($doc/Error, 'FILEPATH')
		or contains($doc/Error, 'Temp-Datei')
	where $doc/@status = 'pending' or ($doc/@status = 'error' and $retry)
	order by string($doc/@updated)
	return
		<item
			home="{$home}"
			tenant="{$tenant}"
			year="{$year}"
			name="{$name}"
			source="{string($doc/@source)}"
			status="{string($doc/@status)}"
			updated="{string($doc/@updated)}"/>
};

(: Aktive Läufe. Nach 45 Minuten gilt running als hängen geblieben. :)
declare function di:active-runs($home as xs:string) as element()* {
	let $cutoff := current-dateTime() - xs:dayTimeDuration('PT45M')
	for $tenant in xmldb:get-child-collections($home)
	for $year in xmldb:get-child-collections($home || '/' || $tenant)
	where matches($year, '^\d{4}$')
	let $collection := di:collection($home, $tenant, $year)
	where xmldb:collection-available($collection)
	for $name in xmldb:get-child-resources($collection)[ends-with(., '.docman.xml')]
	let $path := $collection || '/' || $name
	where doc-available($path)
	let $doc := doc($path)/DocmanIntelligence
	where $doc/@status = 'running'
		and (
			not($doc/@updated castable as xs:dateTime)
			or xs:dateTime($doc/@updated) >= $cutoff
		)
	return
		<item
			tenant="{$tenant}"
			year="{$year}"
			name="{$name}"
			source="{string($doc/@source)}"
			status="running"
			updated="{string($doc/@updated)}"/>
};

declare function di:requeue-stale($home as xs:string) as item()* {
	let $cutoff := current-dateTime() - xs:dayTimeDuration('PT45M')
	for $tenant in xmldb:get-child-collections($home)
	for $year in xmldb:get-child-collections($home || '/' || $tenant)
	where matches($year, '^\d{4}$')
	let $collection := di:collection($home, $tenant, $year)
	where xmldb:collection-available($collection)
	for $name in xmldb:get-child-resources($collection)[ends-with(., '.docman.xml')]
	let $path := $collection || '/' || $name
	where doc-available($path)
	let $doc := doc($path)/DocmanIntelligence
	where $doc/@status = 'running'
		and $doc/@updated castable as xs:dateTime
		and xs:dateTime($doc/@updated) lt $cutoff
	let $next :=
		<DocmanIntelligence version="1.0" source="{$doc/@source}" status="pending" created="{$doc/@created}" updated="{current-dateTime()}">
			{$doc/*[not(local-name() = ('Error', 'Progress'))]}
			<Error>Vorheriger Lauf abgebrochen (Timeout). Erneut in der Warteschlange.</Error>
			{di:progress('queued', 'Erneut eingereiht nach Timeout.', 0, 0)}
		</DocmanIntelligence>
	return xmldb:store($collection, $name, $next)
};

declare function di:heartbeat($home as xs:string, $state as xs:string, $current as element()?, $queue as element()*) as item()* {
	try {
		xmldb:store(
			$home,
			'document-intelligence-status.xml',
			<DocumentIntelligenceStatus at="{current-dateTime()}" state="{$state}" who="{di:who()}" queued="{count($queue)}">
				{
					if (empty($current)) then ()
					else
						<Current
							tenant="{$current/@tenant}"
							year="{$current/@year}"
							file="{$current/@source}"
							companion="{$current/@name}"
							status="{$current/@status}"/>
				}
				<Queue count="{count($queue)}">{
					for $item at $pos in $queue
					return
						<Item
							position="{$pos}"
							tenant="{$item/@tenant}"
							year="{$item/@year}"
							file="{$item/@source}"
							companion="{$item/@name}"
							status="{$item/@status}"/>
				}</Queue>
			</DocumentIntelligenceStatus>
		)
	} catch * {
		()
	}
};

declare function di:mark-running($home as xs:string, $tenant as xs:string, $year, $companion as xs:string, $position as xs:integer, $queued as xs:integer) as element() {
	let $collection := di:collection($home, $tenant, $year)
	let $old := doc($collection || '/' || $companion)/DocmanIntelligence
	let $next :=
		<DocmanIntelligence version="1.0" source="{$old/@source}" status="running" created="{$old/@created}" updated="{current-dateTime()}">
			{$old/*[not(local-name() = ('Error', 'Progress'))]}
			{di:progress('running', 'Datei wird gelesen (' || $position || '/' || $queued || ').', $position, $queued)}
		</DocmanIntelligence>
	let $store := xmldb:store($collection, $companion, $next)
	return $next
};

declare function di:read-one($home as xs:string, $tenant as xs:string, $year, $companion as xs:string, $position as xs:integer, $queued as xs:integer) as item()* {
	let $collection := di:collection($home, $tenant, $year)
	let $started := di:mark-running($home, $tenant, $year, $companion, $position, $queued)
	let $old := doc($collection || '/' || $companion)/DocmanIntelligence
	let $file := string($old/@source)
	let $from := string($old/Meta/@from)
	let $subject := string($old/Meta/@subject)
	let $fresh :=
		try { di:run($home, $tenant, $year, $file, $from, $subject) }
		catch * { <Error>{$err:description}</Error> }
	let $accounts := di:accounts($home, $tenant, $year)
	let $next :=
		if ($fresh/self::Error) then
			di:fail($old, string($fresh))
		else if ($fresh/Error) then
			di:fail($old, string($fresh/Error[1]))
		else if ($fresh//Error) then
			di:fail($old, string(($fresh//Error)[1]))
		else
			di:merge($old, $fresh/*, $accounts)
	return xmldb:store($collection, $companion, $next)
};

(: Pro Lauf nur eine Datei. Läuft noch ein Tick, startet kein zweiter — sonst stapeln sich OCR-Prozesse. :)
declare function di:process($home as xs:string) as element() {
	let $stale := di:requeue-stale($home)
	let $active := di:active-runs($home)
	return
		if (exists($active)) then
			let $queue := di:queue($home)
			let $skip := di:heartbeat($home, 'busy', $active[1], $queue)
			return <processed count="0" who="{di:who()}" queued="{count($queue)}" skipped="busy"/>
		else
			let $queue := di:queue($home)
			let $next := $queue[1]
			let $start := di:heartbeat($home, if (empty($next)) then 'idle' else 'read', $next, $queue)
			let $done :=
				if (empty($next)) then ()
				else di:read-one($home, string($next/@tenant), string($next/@year), string($next/@name), 1, count($queue))
			let $rest := di:queue($home)
			let $end := di:heartbeat($home, 'done', (), $rest)
			return <processed count="{count($done)}" who="{di:who()}" queued="{count($rest)}" skipped=""/>
};

(: RESTXQ serialisiert DB-Knoten über cglib. Eine Kopie im Speicher vermeidet den 500. :)
declare function di:detach($doc as element()) as element() {
	element { node-name($doc) } {
		$doc/@*,
		$doc/node()
	}
};

declare function di:load($home as xs:string, $tenant as xs:string, $year, $file as xs:string) as element() {
	try {
		let $collection := di:collection($home, $tenant, $year)
		let $name := di:locate($collection, $file)
		let $doc := if ($name = '') then () else doc($collection || '/' || $name)/DocmanIntelligence
		return
			if (empty($doc)) then
				<error>Keine Metadaten.</error>
			else
				di:detach($doc)
	} catch * {
		<error>{substring($err:description, 1, 500)}</error>
	}
};

(: Der HTTP-Aufruf startet keinen Lesevorgang. Sonst kollidiert er mit dem Job und eXist antwortet mit 500. :)
declare function di:refresh-file($home as xs:string, $tenant as xs:string, $year, $file as xs:string) as element() {
	try {
		let $ensure := di:ensure($home, $tenant, $year, $file, '', '')
		let $collection := di:collection($home, $tenant, $year)
		let $name := di:locate($collection, $file)
		let $old := if ($name = '') then () else doc($collection || '/' || $name)/DocmanIntelligence
		return
			if (empty($old)) then
				<error>Keine Metadaten.</error>
			else if ($old/@status = 'pending') then
				di:detach($old)
			else
				let $queued :=
					<DocmanIntelligence version="1.0" source="{$old/@source}" status="pending" created="{$old/@created}" updated="{current-dateTime()}">
						{$old/*[not(local-name() = ('Error', 'Progress'))]}
						<Error>Wartet auf den Hintergrundjob.</Error>
						{di:progress('queued', 'Wartet auf den Hintergrundjob.', 0, 0)}
					</DocmanIntelligence>
				let $store := xmldb:store($collection, $name, $queued)
				return $queued
	} catch * {
		<error>{substring($err:description, 1, 500)}</error>
	}
};

declare function di:notes($home as xs:string, $tenant as xs:string, $year, $file as xs:string, $text as xs:string) as element() {
	let $collection := di:collection($home, $tenant, $year)
	let $ensure := di:ensure($home, $tenant, $year, $file, '', '')
	let $name := di:locate($collection, $file)
	let $old := doc($collection || '/' || $name)/DocmanIntelligence
	let $next :=
		<DocmanIntelligence version="1.0" source="{$old/@source}" status="{$old/@status}" created="{$old/@created}" updated="{current-dateTime()}">
			{$old/*[local-name() != 'Notes']}
			<Notes>{$text}</Notes>
		</DocmanIntelligence>
	let $store := xmldb:store($collection, $name, $next)
	return <noted file="{$file}"/>
};

declare function di:summary($home as xs:string, $tenant as xs:string, $year, $file as xs:string) as element()? {
	let $collection := di:collection($home, $tenant, $year)
	let $name := di:locate($collection, $file)
	let $doc := if ($name = '') then () else doc($collection || '/' || $name)/DocmanIntelligence
	return
		if (empty($doc)) then ()
		else
			let $fields := $doc/Fields
			let $progress := $doc/Progress
			let $number := ($fields/Field[@id='invoice.id'], $fields/InvoiceNumber)[1]
			let $date := ($fields/Field[@id='invoice.date'], $fields/InvoiceDate)[1]
			let $amount := ($fields/Field[@id='invoice.amount.payable'], $fields/Field[@id='invoice.amount.brutto'], $fields/PayableAmount)[1]
			let $seller := ($fields/Field[@id='sender.name'], $fields/Seller/Name)[1]
			return
				<Intelligence
					status="{$doc/@status}"
					updated="{$doc/@updated}"
					kind="{string($doc/Source/@kind)}"
					origin="{string($doc/Source/@origin)}"
					doctype="{string($doc/Document/@type)}"
					doctype-quality="{string($doc/Document/@quality)}"
					step="{string($progress/@step)}"
					message="{string(($progress/@message, $doc/Error)[1])}"
					position="{string($progress/@position)}"
					queued="{string($progress/@queued)}"
					account="{string($doc/Account/@id)}"
					account-quality="{string($doc/Account/@quality)}"
					number="{string($number/@value)}"
					number-quality="{string($number/@quality)}"
					date="{string($date/@value)}"
					date-quality="{string($date/@quality)}"
					amount="{string($amount/@value)}"
					amount-quality="{string($amount/@quality)}"
					seller="{string($seller/@value)}"
					note="{string($doc/Notes)}"/>
};

declare function di:follow($home as xs:string, $tenant as xs:string, $year, $from as xs:string, $to as xs:string) as item()* {
	let $collection := di:collection($home, $tenant, $year)
	let $old-name := di:locate($collection, $from)
	return
		if ($old-name = '') then ()
		else
			let $new-name :=
				if (di:stem($to) || '.docman.xml' = $old-name or not(doc-available($collection || '/' || di:stem($to) || '.docman.xml'))) then
					di:stem($to) || '.docman.xml'
				else
					$to || '.docman.xml'
			let $rename := if ($old-name = $new-name) then () else xmldb:rename($collection, $old-name, $new-name)
			let $node := doc($collection || '/' || $new-name)/DocmanIntelligence
			return update value $node/@source with $to
};

declare function di:remove($home as xs:string, $tenant as xs:string, $year, $file as xs:string) as item()* {
	let $collection := di:collection($home, $tenant, $year)
	let $name := di:locate($collection, $file)
	return if ($name = '') then () else xmldb:remove($collection, $name)
};

declare function di:trash($home as xs:string, $tenant as xs:string, $file as xs:string, $year) as item()* {
	let $collection := di:collection($home, $tenant, $year)
	let $name := di:locate($collection, $file)
	let $trash := $home || '/' || $tenant || '/trash'
	let $create := if ($name = '' or xmldb:collection-available($trash)) then () else xmldb:create-collection($home || '/' || $tenant, 'trash')
	return if ($name = '') then () else xmldb:move($collection, $trash, $name)
};

declare function di:archive($home as xs:string, $tenant as xs:string, $year, $file as xs:string, $process as element()?) as item()* {
	let $collection := di:collection($home, $tenant, $year)
	let $name := di:locate($collection, $file)
	return
		if ($name = '') then ()
		else
			let $doc := doc($collection || '/' || $name)/DocmanIntelligence
			let $note := normalize-space(string($doc/Notes))
			let $description := ($process//Description)[1]
			let $append :=
				if ($note = '' or empty($description) or contains(string($description), $note)) then ()
				else update value $description with normalize-space(string($description) || ' ' || $note)
			let $parent := $home || '/' || $tenant
			let $intel := $parent || '/intelligence'
			let $examples := $intel || '/examples'
			let $make-intel := if (xmldb:collection-available($intel)) then () else xmldb:create-collection($parent, 'intelligence')
			let $make-examples := if (xmldb:collection-available($examples)) then () else xmldb:create-collection($intel, 'examples')
			let $clash :=
				if (doc-available($examples || '/' || $name)) then
					xmldb:rename($examples, $name, di:stem($name) || '-' || format-dateTime(current-dateTime(), '[Y0001][M01][D01][H01][m01][s01]') || '.docman.xml')
				else ()
			let $moved := xmldb:move($collection, $examples, $name)
			let $stored := di:remember($examples, $name, $process)
			let $learn := di:learn($home, $tenant)
			return $moved
};

declare function di:confirmed($process as element()?) as element()* {
	if (empty($process)) then ()
	else (
		if (normalize-space(string($process/@date)) = '') then ()
		else <Confirmed field="invoiceDate" value="{string($process/@date)}"/>,
		if (normalize-space(string($process/TotalAmount/@value)) = '') then ()
		else <Confirmed field="payable" value="{string($process/TotalAmount/@value)}"/>,
		let $ref := normalize-space(string(($process//RefID)[1]))
		return
			if ($ref = '') then ()
			else <Confirmed field="invoiceNumber" value="{$ref}"/>
	)
};

declare function di:remember($examples as xs:string, $name as xs:string, $process as element()?) as item()* {
	let $confirmed := di:confirmed($process)
	let $old := doc($examples || '/' || $name)/DocmanIntelligence
	return
		if (empty($confirmed) or empty($old)) then ()
		else
			let $next :=
				<DocmanIntelligence>
					{$old/@*}
					{$old/*[local-name() != 'Training']}
					<Training>{$confirmed}</Training>
				</DocmanIntelligence>
			return xmldb:store($examples, $name, $next)
};

declare function di:learn($home as xs:string, $tenant as xs:string) as item()* {
	try {
		let $intel := $home || '/' || $tenant || '/intelligence'
		let $examples := $intel || '/examples'
		let $docs := collection($examples)/DocmanIntelligence
		let $xml := serialize(<Examples>{$docs}</Examples>, map { 'method': 'xml', 'indent': false() })
		let $lines := ('EXAMPLES', di:chunks($xml), 'END')
		let $run := process:execute(
			(di:command(), 'train'),
			<options><stdin>{ for $line in $lines return <line>{$line}</line> }</stdin></options>
		)
		let $out := string-join($run/stdout/line, '')
		return
			if (xs:integer($run/@exitCode) != 0 or not(starts-with(normalize-space($out), '<Model'))) then ()
			else xmldb:store($intel, 'model.xml', parse-xml($out))
	} catch * {
		()
	}
};

(: Prüft, ob ein Hint-Feld mit gleichem field(+label/pattern) schon existiert. :)
declare function di:hint-exists($hints as element()*, $field as xs:string, $label as xs:string, $pattern as xs:string) as xs:boolean {
	some $hint in $hints
	satisfies string($hint/@field) = $field
		and (
			($label != '' and normalize-space(string($hint/@label)) = normalize-space($label))
			or ($pattern != '' and normalize-space(string($hint/@pattern)) = normalize-space($pattern))
			or ($label = '' and $pattern = '' and true())
		)
};

(: Leitet aus beobachteten Rechnungsnummern ein grobes Regex-Muster ab. :)
declare function di:invoice-id-pattern($values as xs:string*) as xs:string? {
	let $clean :=
		for $value in $values
		let $trimmed := normalize-space($value)
		where string-length($trimmed) >= 3 and string-length($trimmed) <= 40
		return $trimmed
	let $sample := $clean[1]
	return
		if (empty($clean) or count(distinct-values($clean)) < 2) then ()
		else if (every $value in $clean satisfies matches($value, '^\d+$')) then
			let $lens := distinct-values(for $value in $clean return string-length($value))
			return
				if (count($lens) = 1) then '^\d{' || $lens[1] || '}$'
				else '^\d{' || min($lens) || ',' || max($lens) || '}$'
		else if (matches($sample, '^[A-Za-z]+[-/]?\d+$')) then
			let $prefix := replace($sample, '^([A-Za-z]+).*$', '$1')
			return
				if (every $value in $clean satisfies starts-with($value, $prefix)) then
					'^' || $prefix || '[-/]?\d+$'
				else ()
		else ()
};

declare function di:propose-hint($field as xs:string, $label as xs:string, $pattern as xs:string, $source as xs:string, $existing as element()*) as element()? {
	if (($label = '' and $pattern = '') or di:hint-exists($existing, $field, $label, $pattern)) then ()
	else
		<Hint field="{$field}" label="{$label}" pattern="{$pattern}" region="" source="{$source}" status="proposed"/>
};

(: Einmalige Hint-Vorschläge für Kreditoren — schreibt accounts.hint-proposals.xml, ändert accounts.dm.xml nicht. :)
declare function di:propose-creditor-hints($home as xs:string, $tenant as xs:string, $year) as element() {
	let $path := $home || '/' || $tenant || '/' || $year || '/accounts.dm.xml'
	let $accounts := if (doc-available($path)) then doc($path)/Accounts else ()
	let $examples := $home || '/' || $tenant || '/intelligence/examples'
	let $example-docs :=
		if (xmldb:collection-available($examples)) then collection($examples)/DocmanIntelligence
		else ()
	let $transfer := di:collection($home, $tenant, $year)
	let $transfer-docs :=
		if (xmldb:collection-available($transfer)) then
			collection($transfer)/DocmanIntelligence[@status = 'done']
		else ()
	let $intel-docs := ($example-docs, $transfer-docs)
	let $proposals :=
		<AccountHintProposals tenant="{$tenant}" year="{$year}" created="{current-dateTime()}" note="Vorschläge zur manuellen Übernahme in FieldHints. accounts.dm.xml bleibt unverändert.">{
			for $account in $accounts/Account
			let $classes := tokenize(normalize-space(string-join(($account/@classes, $account/@type), ' ')), '\s+')
			where $classes = 'creditor' or string($account/@type) = 'creditor'
			let $existing := $account/FieldHints/Hint
			let $name := normalize-space(string($account/Name))
			let $company := normalize-space(string(($account/Company/Name, $account/Company)[1]))
			let $vat := normalize-space(string($account/VatId))
			let $customer := normalize-space(string($account/CustomerID))
			let $ibans := distinct-values((
				normalize-space(string($account/@iban))[normalize-space(.) != ''],
				for $bank in $account/BankAccounts/BankAccount
				let $iban := normalize-space(string($bank/@iban))
				where $iban != ''
				return $iban
			))
			let $invoice-ids :=
				for $doc in $intel-docs[string(Account/@id) = string($account/@id)]
				let $value := normalize-space(string(($doc/Fields/Field[@id = 'invoice.id']/@value)[1]))
				where $value != ''
				return $value
			let $id-pattern := di:invoice-id-pattern($invoice-ids)
			let $hints := (
				di:propose-hint('party.self', $name, '', 'account.name', $existing),
				di:propose-hint('party.self', $company, '', 'account.company', $existing),
				di:propose-hint('sender.vat', $vat, '', 'account.vat', $existing),
				di:propose-hint('invoice.customer.id', $customer, '', 'account.customerId', $existing),
				for $iban in $ibans
				return di:propose-hint('sender.iban', $iban, '', 'account.iban', $existing),
				if (empty($id-pattern)) then ()
				else di:propose-hint('invoice.id', '', $id-pattern, 'intelligence.pattern', $existing)
			)
			where exists($hints)
			return
				<Account id="{$account/@id}" kto="{string($account/@kto)}" name="{$name}">
					<FieldHints>{$hints}</FieldHints>
					{
						if (exists($existing)) then
							<ExistingHints count="{count($existing)}"/>
						else ()
					}
				</Account>
		}</AccountHintProposals>
	let $target := $home || '/' || $tenant || '/' || $year
	let $stored :=
		if (empty($accounts)) then ()
		else xmldb:store($target, 'accounts.hint-proposals.xml', $proposals)
	return $proposals
};
