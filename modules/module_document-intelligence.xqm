(:
Document Intelligence.
di:ensure legt nur eine docman.xml mit status="pending" an.
di:process liest sie im Hintergrund und ersetzt die Felder. Notes bleibt.
:)

xquery version "3.1";

module namespace di = "http://bintellix.com/docman/document-intelligence";

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
		<Source kind="" pages="0"/>
		<Account id="" quality="0"/>
		<Fields/>
		<Lines/>
		<Text/>
		<Notes/>
		<Meta from="{$from}" subject="{$subject}"/>
	</DocmanIntelligence>
};

declare function di:schedule() as item()* {
	let $job := 'xquery version "3.1"; import module namespace di="http://bintellix.com/docman/document-intelligence" at "/db/apps/docman/modules/module_document-intelligence.xqm"; di:process("/db/apps/docman/data")'
	return
		try {
			scheduler:schedule-xquery-periodic-job($job, 60000, 'docman-intelligence', 2000)
		} catch * {
			try {
				scheduler:schedule-xquery-periodic-job($job, 60000, 'docman-intelligence')
			} catch * {
				()
			}
		}
};

declare function di:ensure($home as xs:string, $tenant as xs:string, $year, $file as xs:string, $from as xs:string, $subject as xs:string) as item()* {
	if (not(di:is-document($file))) then ()
	else
		let $collection := di:collection($home, $tenant, $year)
		let $name := di:target-name($collection, $file)
		let $store :=
			if (doc-available($collection || '/' || $name)) then ()
			else xmldb:store($collection, $name, di:shell($file, $from, $subject))
		return di:schedule()
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

declare function di:run($home as xs:string, $tenant as xs:string, $year, $file as xs:string, $from as xs:string, $subject as xs:string) as item()* {
	let $collection := di:collection($home, $tenant, $year)
	let $binary := $collection || '/' || $file
	return
		if (not(util:binary-doc-available($binary))) then
			<Error>Datei fehlt.</Error>
		else
			let $accounts := serialize(di:accounts($home, $tenant, $year), map { 'method': 'xml', 'indent': false() })
			let $model-path := $home || '/' || $tenant || '/intelligence/model.xml'
			let $model := if (doc-available($model-path)) then serialize(doc($model-path)/Model, map { 'method': 'xml', 'indent': false() }) else ''
			let $payload := string(util:binary-doc($binary))
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
				'FILE',
				di:chunks($payload),
				'END'
			)
			let $run := process:execute(
				(di:command(), 'read'),
				<options><stdin>{ for $line in $lines return <line>{$line}</line> }</stdin></options>
			)
			let $out := string-join($run/stdout/line, '')
			let $err := string-join($run/stderr/line, ' ')
			return
				if (xs:integer($run/@exitCode) != 0 or not(starts-with(normalize-space($out), '<'))) then
					<Error>{substring(string-join(($err, $out), ' '), 1, 500)}</Error>
				else
					parse-xml($out)
};

declare function di:merge($old as element(), $fresh as element()) as element() {
	<DocmanIntelligence version="1.0" source="{$old/@source}" status="done" created="{$old/@created}" updated="{current-dateTime()}">
		{$fresh/Source}
		{$fresh/Account}
		{$fresh/Fields}
		{$fresh/Lines}
		{$fresh/Text}
		<Notes>{string($old/Notes)}</Notes>
		{$old/Meta}
	</DocmanIntelligence>
};

declare function di:fail($old as element(), $message as xs:string) as element() {
	<DocmanIntelligence version="1.0" source="{$old/@source}" status="error" created="{$old/@created}" updated="{current-dateTime()}">
		<Source kind="error" pages="0"/>
		<Error>{$message}</Error>
		{$old/Fields}
		{$old/Lines}
		{$old/Text}
		<Notes>{string($old/Notes)}</Notes>
		{$old/Meta}
	</DocmanIntelligence>
};

declare function di:read-one($home as xs:string, $tenant as xs:string, $year, $companion as xs:string) as item()* {
	let $collection := di:collection($home, $tenant, $year)
	let $old := doc($collection || '/' || $companion)/DocmanIntelligence
	let $file := string($old/@source)
	let $from := string($old/Meta/@from)
	let $subject := string($old/Meta/@subject)
	let $fresh :=
		try { di:run($home, $tenant, $year, $file, $from, $subject) }
		catch * { <Error>{$err:description}</Error> }
	let $next :=
		if ($fresh/self::Error or $fresh//Error) then
			di:fail($old, string(($fresh//Error, $fresh)[1]))
		else
			di:merge($old, $fresh/*)
	return xmldb:store($collection, $companion, $next)
};

declare function di:process($home as xs:string) as element() {
	let $done :=
		for $tenant in xmldb:get-child-collections($home)
		for $year in xmldb:get-child-collections($home || '/' || $tenant)
		where matches($year, '^\d{4}$')
		let $collection := di:collection($home, $tenant, $year)
		where xmldb:collection-available($collection)
		for $name in xmldb:get-child-resources($collection)[ends-with(., '.docman.xml')]
		where doc-available($collection || '/' || $name)
			and doc($collection || '/' || $name)/DocmanIntelligence/@status = 'pending'
		return di:read-one($home, $tenant, $year, $name)
	return <processed count="{count($done)}"/>
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
			return
				<Intelligence
					status="{$doc/@status}"
					number="{$fields/InvoiceNumber/@value}"
					number-quality="{$fields/InvoiceNumber/@quality}"
					date="{$fields/InvoiceDate/@value}"
					date-quality="{$fields/InvoiceDate/@quality}"
					amount="{$fields/PayableAmount/@value}"
					amount-quality="{$fields/PayableAmount/@quality}"
					seller="{$fields/Seller/Name/@value}"
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
