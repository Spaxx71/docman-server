(:
========================================================================
LICENSE AGREEMENT:
This software is distributed WITHOUT ANY WARRANTY and without even the
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
========================================================================
This copy of Docman (a Document managgement an accounting system) 
is licensed under the Server Side Public License (SSPL), v 1 ("the License").

See the License for details about distribution rights, 
modification and transformation of it.

========================================================================
All rights reserved by bintellix GmbH, Germany
========================================================================
@Author: Eduard Huber
@Version: 1.0
======================================================================== 
:)

xquery version "3.1";

module namespace account = "http://bintellix.com/docman/account";

(: Todo: version="1.0" resource-id="{$resource-id}" :)

declare function account:book-path($home-data as xs:string, $tenant as xs:string) as xs:string {
	concat($home-data, '/', $tenant, '/contacts.dm.xml')
};

declare function account:year-path($home-data as xs:string, $tenant as xs:string, $year as xs:integer) as xs:string {
	concat($home-data, '/', $tenant, '/', $year, '/accounts.dm.xml')
};

(: Fehlt accounts.dm.xml (Jahr nur mit Banken o. Ä.), aus Vorjahr projizieren oder leeren Rahmen anlegen. :)
declare function account:ensure-year($home-data as xs:string, $tenant as xs:string, $year as xs:integer) as document-node() {
	let $path := account:year-path($home-data, $tenant, $year)
	return
		if (doc-available($path)) then doc($path)
		else
			let $parent := concat($home-data, '/', $tenant)
			let $col := concat($parent, '/', $year)
			let $create :=
				if (xmldb:collection-available($col)) then ()
				else if (xmldb:collection-available($parent)) then xmldb:create-collection($parent, string($year))
				else error(xs:QName('docman:YearMissing'), concat('Mandant oder Jahr fehlt: ', $tenant, '/', $year))
			let $prior :=
				max((
					0,
					for $name in xmldb:get-child-collections($parent)
					where $name castable as xs:integer and xs:integer($name) lt $year
						and doc-available(account:year-path($home-data, $tenant, xs:integer($name)))
					return xs:integer($name)
				))
			let $template :=
				(
					for $name in xmldb:get-child-collections($parent)
					where $name castable as xs:integer and doc-available(account:year-path($home-data, $tenant, xs:integer($name)))
					order by xs:integer($name) descending
					return doc(account:year-path($home-data, $tenant, xs:integer($name)))/Accounts
				)[1]
			let $seed :=
				if ($prior gt 0) then account:project-year($home-data, $tenant, $prior, $year)
				else
					<Accounts
						chart="{string(($template/@chart[. != ''], 'SKR04')[1])}"
						personNumbers="{string(($template/@personNumbers[. != ''], 'A-Z')[1])}"
					/>
			let $stored := ($create, xmldb:store($col, 'accounts.dm.xml', $seed))
			return doc($path)
};

declare function account:has-book($home-data as xs:string, $tenant as xs:string) as xs:boolean {
	doc-available(account:book-path($home-data, $tenant))
};

declare function account:in-year($from as xs:string?, $till as xs:string?, $year as xs:integer) as xs:boolean {
	let $start := xs:date(concat($year, '-01-01'))
	let $end := xs:date(concat($year, '-12-31'))
	let $opened := if ($from castable as xs:date) then xs:date($from) else $start
	let $closed := if ($till castable as xs:date) then xs:date($till) else $end
	return $opened <= $end and $closed >= $start
};

declare %private function account:node-in-year($node as element(), $year as xs:integer) as xs:boolean {
	account:in-year(string($node/@valid-from), string($node/@valid-till), $year)
};

declare function account:kto-on($book as element()?, $year as xs:integer) as xs:string {
	let $hit := $book/Numbers/Number[account:node-in-year(., $year)][1]
	return if ($hit) then string($hit/@kto) else string($book/@kto)
};

declare %private function account:join($book as element(), $year-account as element(Account)?, $year as xs:integer) as element(Account) {
	<Account id="{string(($year-account/@id, $book/@id)[1])}" kto="{string($year-account/@kto)}" type="{string(($year-account/@type, 'ledger_account')[1])}" classes="{string($year-account/@classes)}" contactsRef="{string(($year-account/@contactsRef[normalize-space(.) != ''], $book/@id)[1])}">
		{$book/@debtee}
		<Name>{string(($year-account/Name, $book/Name)[1])}</Name>
		{$book/Alias}
		<Notes>{string($year-account/Notes)}</Notes>
		{$book/(Service|Company|Person|contacts|Notes|CustomerID)}
		<BankAccounts>
			{$book/BankAccounts/BankAccount[account:node-in-year(., $year)]}
		</BankAccounts>
		<ProcessTemplates>{$book/ProcessTemplates/ProcessTemplate[account:node-in-year(., $year)]}</ProcessTemplates>
		{$book/(PeriodicPayments|FieldHints)}
		{($year-account/BudgetCategories, <BudgetCategories/>)[1]}
		{($year-account/Accounting, <Accounting openingBalance="0" closingBalance="0" debitSum="0" creditSum="0"/>)[1]}
	</Account>
};

(: Jahreskonten, mit dem Buch zusammengesetzt. Ohne Buch die Knoten der Jahresdatei. :)
declare function account:accounts($home-data as xs:string, $tenant as xs:string, $year as xs:integer) as element(Account)* {
	let $year-doc := doc(account:year-path($home-data, $tenant, $year))
	return
		if (not(account:has-book($home-data, $tenant))) then $year-doc/Accounts/Account
		else
			let $book := doc(account:book-path($home-data, $tenant))/Contacts/Contact
			return (
				for $row in $year-doc/Accounts/Account
				let $ref := account:contacts-ref($row)
				let $entry := ($book[lower-case(@id) = lower-case($ref)], $book[lower-case(@id) = lower-case($row/@id)])[1]
				where exists($entry) and account:node-in-year($entry, $year)
				return account:join($entry, $row, $year),
				$year-doc/Accounts/Account[not(account:contacts-ref(.) = $book/@id)][not(lower-case(@id) = $book/lower-case(@id))]
			)
};

declare %private function account:person($account as element()?) as xs:boolean {
	tokenize(normalize-space(string-join(($account/@classes, $account/@type), ' ')), '\s+') = ('creditor', 'debitor', 'self')
};

declare %private function account:bankish($account as element()?) as xs:boolean {
	tokenize(normalize-space(string-join(($account/@classes, $account/@type), ' ')), '\s+') = ('bank', 'bank_account')
};

declare %private function account:extended($account as element()?) as xs:boolean {
	exists($account/@debtee) or normalize-space(string($account/@iban)) != '' or exists($account/(CustomerID|Service|Company|Person|Contact|contacts|Notes|BankAccounts|ProcessTemplates|PeriodicPayments|FieldHints))
};

declare function account:contacts-ref($account as element(Account)?) as xs:string {
	let $given := normalize-space(string($account/@contactsRef))
	return
		if ($given != '') then $given
		else if (account:person($account) or account:extended($account)) then string($account/@id)
		else ''
};

declare function account:banks-ref($account as element(Account)?) as xs:string {
	let $given := normalize-space(string($account/@banksRef))
	return
		if ($given != '') then $given
		else if (account:bankish($account)) then string($account/@kto)
		else ''
};

declare %private function account:slim($account as element(Account)) as element(Account) {
	<Account id="{$account/@id}" kto="{$account/@kto}" type="{$account/@type}" classes="{$account/@classes}" contactsRef="{account:contacts-ref($account)}" banksRef="{account:banks-ref($account)}">
		<Name>{string($account/Name)}</Name>
		<Notes>{string($account/Notes)}</Notes>
		{($account/BudgetCategories, <BudgetCategories/>)[1]}
		{($account/Accounting, <Accounting openingBalance="0" closingBalance="0" debitSum="0" creditSum="0"/>)[1]}
	</Account>
};

declare function account:speaking-id($name as xs:string, $fallback as xs:string) as xs:string {
	let $folded := replace(replace(replace(replace(replace(replace(replace($name, 'ä', 'ae'), 'ö', 'oe'), 'ü', 'ue'), 'Ä', 'Ae'), 'Ö', 'Oe'), 'Ü', 'Ue'), 'ß', 'ss')
	let $slug := replace(replace(replace($folded, '[^A-Za-z0-9]+', '_'), '^_+|_+$', ''), '_+', '_')
	return if ($slug != '') then $slug else $fallback
};

declare function account:is-uuid($value as xs:string?) as xs:boolean {
	matches(normalize-space(string($value)), '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
};

declare function account:fresh-contact-id() as xs:string {
	lower-case(util:uuid())
};

declare %private function account:kept($incoming as element()?, $previous as element()?, $name as xs:string) as element()? {
	($incoming/*[local-name() = $name], $previous/*[local-name() = $name])[1]
};

declare %private function account:named($node as element()?) as xs:boolean {
	normalize-space(string-join($node//text(), '')) != ''
};

(: Firma oder Person, nie beides. Ein Name der Person gewinnt nur, wenn die Firma keinen Namen hat. :)
declare %private function account:chosen-party($node as element()?) as element()? {
	let $company := $node/Company
	let $person := $node/Person
	return
		if (exists($company) and exists($person)) then
			if (account:named($person) and not(account:named($company))) then $person
			else if (account:named($company) or not(account:named($person))) then
				if (account:named($company)) then $company else ()
			else $person
		else if (exists($person)) then $person
		else $company
};

declare %private function account:party-kept($incoming as element()?, $previous as element()?) as element()? {
	let $fresh := account:chosen-party($incoming)
	return if (exists($fresh)) then $fresh else account:chosen-party($previous)
};

declare function account:channel-values($node as element()?, $type as xs:string) as xs:string* {
	let $direct := $node/contacts/contact[@type = $type] ! normalize-space(string(.))
	let $legacy :=
		if ($type = 'email') then normalize-space(string($node/Contact/Email))
		else if ($type = 'website') then normalize-space(string($node/Contact/Website))
		else if ($type = 'phone') then normalize-space(string($node/Contact/Telefon))
		else ''
	for $value in ($direct, $legacy)
	where $value != ''
	return $value
};

declare %private function account:legacy-channels($node as element()?) as element(contact)* {
	let $inner := $node/Contact
	let $person-name := normalize-space(string-join(($node/Person/Vorname, $node/Person/Nachname), ' '))
	let $spoken := normalize-space(string-join(($inner/Vorname, $inner/Nachname), ' '))
	return (
		for $email in tokenize(string($inner/Email), ';')[normalize-space(.) != '']
		return <contact type="email">{normalize-space($email)}</contact>,
		if (normalize-space(string($inner/Website)) != '') then <contact type="website">{normalize-space(string($inner/Website))}</contact> else (),
		if (normalize-space(string($inner/Telefon)) != '') then <contact type="phone">{normalize-space(string($inner/Telefon))}</contact> else (),
		if (normalize-space(string-join($inner/Adresse//text(), '')) != '') then <contact type="address">{$inner/Adresse/*}</contact> else (),
		if ($spoken != '' and $spoken != $person-name) then
			<contact type="person">
				<Vorname>{normalize-space(string($inner/Vorname))}</Vorname>
				<Nachname>{normalize-space(string($inner/Nachname))}</Nachname>
			</contact>
		else ()
	)
};

declare %private function account:channels-from($node as element()?) as element(contacts)? {
	let $existing := $node/contacts/contact
	let $fresh := account:legacy-channels($node)[not(account:channel-key(.) = ($existing ! account:channel-key(.)))]
	let $items := ($existing, $fresh)
	return if (exists($items)) then <contacts>{$items}</contacts> else ()
};

declare %private function account:channel-key($item as element()) as xs:string {
	concat(string($item/@type), '|', normalize-space(string-join($item//text(), ' ')))
};

declare %private function account:merge-channels($incoming as element()?, $previous as element()?) as element(contacts)? {
	let $items := (account:channels-from($previous)/contact, account:channels-from($incoming)/contact)
	let $unique := fold-left($items, (), function($acc as element()*, $item as element()) as element()* {
		if (account:channel-key($item) = ($acc ! account:channel-key(.))) then $acc else ($acc, $item)
	})
	return if (exists($unique)) then <contacts>{$unique}</contacts> else ()
};

declare %private function account:channels-kept($incoming as element()?, $previous as element()?) as element(contacts)? {
	if (exists($incoming/(contacts|Contact))) then account:merge-channels($incoming, $previous)
	else account:channels-from($previous)
};

declare %private function account:book-entry($account as element(Account), $id as xs:string, $year as xs:integer, $previous as element()?) as element(Contact) {
	let $from := concat($year, '-01-01')
	let $opened := if ($previous/@valid-from castable as xs:date) then string($previous/@valid-from) else $from
	let $banks :=
		if (empty($account/BankAccounts) and exists($previous/BankAccounts)) then $previous/BankAccounts/BankAccount
		else ($previous/BankAccounts/BankAccount[not(account:node-in-year(., $year))], $account/BankAccounts/BankAccount)
	return
		<Contact id="{$id}" valid-from="{$opened}">
			{$previous/@valid-till}
			{$account/@debtee}
			{if (normalize-space(string(($account/@iban, $previous/@iban)[1])) != '') then attribute iban {normalize-space(string(($account/@iban, $previous/@iban)[1]))} else ()}
			<Name>{normalize-space(string(($account/Name[normalize-space(.) != ''], $previous/Name)[1]))}</Name>
			{account:kept($account, $previous, 'Alias')}
			{account:kept($account, $previous, 'CustomerID')}
			{account:kept($account, $previous, 'Service')}
			{account:party-kept($account, $previous)}
			{account:channels-kept($account, $previous)}
			{account:kept($account, $previous, 'Notes')}
			<BankAccounts>{$banks}</BankAccounts>
			{account:kept($account, $previous, 'ProcessTemplates')}
			{account:kept($account, $previous, 'PeriodicPayments')}
			{account:kept($account, $previous, 'FieldHints')}
		</Contact>
};

declare %private function account:close($entry as element(), $till as xs:date) {
	if ($entry/@valid-till) then update value $entry/@valid-till with string($till)
	else update insert attribute valid-till {string($till)} into $entry
};

declare function account:year-accounts($home-data as xs:string, $tenant as xs:string, $year as xs:integer) as element(Account)* {
	doc(account:year-path($home-data, $tenant, $year))/Accounts/Account
};

declare %private function account:allowed-numbering($value as xs:string?, $allowed as xs:string*) as xs:string? {
	let $normalized := upper-case(normalize-space(string($value)))
	return if ($normalized = $allowed) then $normalized else ()
};

declare %private function account:put-attribute($node as element(Accounts), $name as xs:string, $value as xs:string?) {
	let $current := $node/@*[local-name() = $name]
	return
		if (normalize-space(string($value)) = '') then
			if ($current) then update delete $current else ()
		else if ($current) then
			update value $current with $value
		else
			update insert attribute { $name } { $value } into $node
};

declare function account:listAccounts ($home-data, $tenant, $year as xs:integer) {
	let $root := doc(account:year-path($home-data, $tenant, $year))/Accounts
	let $rows := $root/Account
	return
		<Accounts tenant="{$tenant}">
			{$root/@chart}
			{$root/@personNumbers}
			{for $account in $rows[@type='ledger_account'] order by $account/Name return $account}
			{for $account in $rows[not(@type='ledger_account')] order by $account/@kto return $account}
		</Accounts>
};

(: Schreibt nur Kontorahmen und Nummernkreise an die Jahresdatei. Kontenzeilen bleiben stehen. :)
declare function account:store-numbering($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $body as item()) as element(Accounts) {
	let $raw := if ($body instance of document-node()) then $body/*[1] else $body
	let $root := doc(account:year-path($home-data, $tenant, $year))/Accounts
	let $chart := account:allowed-numbering(string($raw/@chart), ('SKR03', 'SKR04'))
	let $circles := account:allowed-numbering(string($raw/@personNumbers), 'A-Z')
	let $result :=
		<Accounts tenant="{$tenant}" year="{$year}">
			{if ($chart) then attribute chart { $chart } else ()}
			{if ($circles) then attribute personNumbers { $circles } else ()}
		</Accounts>
	let $fresh :=
		<Accounts>
			{if ($chart) then attribute chart { $chart } else ()}
			{if ($circles) then attribute personNumbers { $circles } else ()}
		</Accounts>
	return
		if ($raw/Account) then
			error(xs:QName('docman:AccountsSettings'), 'Die Jahresdatei der Buchungskonten wird hier nicht ersetzt.')
		else if (empty($root)) then
			let $file := account:year-path($home-data, $tenant, $year)
			let $stored := xmldb:store(substring-before($file, '/accounts.dm.xml'), 'accounts.dm.xml', $fresh)
			return $result
		else
			let $chart-write := account:put-attribute($root, 'chart', $chart)
			let $circles-write := account:put-attribute($root, 'personNumbers', $circles)
			return $result
};

declare function account:listAccountsSimplified ($home-data, $tenant, $year as xs:integer) {
	let $root := doc(account:year-path($home-data, $tenant, $year))/Accounts
	let $rows := $root/Account
	return
		<Accounts tenant="{$tenant}">
			{$root/@chart}
			{$root/@personNumbers}
			{for $account in $rows order by (if ($account/@type='ledger_account') then $account/Name else ())[1], $account/@kto return
			 	<Account>
				 	{$account/@id}
					{$account/@kto}
					{$account/@type}
					{$account/@classes}
					{$account/BankAccounts}
					{$account/Name}
					{$account/Service}
					{$account/Notes}
				</Account>
			}
		</Accounts>
};

declare function account:getAccount ($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $resource-id as xs:string) {
	let $rows := account:year-accounts($home-data, $tenant, $year)
	let $by-id := $rows[lower-case(@id)=lower-case($resource-id)]
	let $by-kto := if ($resource-id castable as xs:integer) then $rows[@kto=xs:integer($resource-id)] else ()
	return ($by-id, $by-kto)[1]
};

declare function account:getAccountByIban ($home-data, $tenant, $year as xs:integer, $iban) {
	account:accounts($home-data, $tenant, $year)[BankAccounts/BankAccount/@iban=$iban]
};

declare %private function account:held($incoming as element(), $id as xs:string) as element(Account) {
	<Account id="{$id}" kto="{$incoming/@kto}" type="{$incoming/@type}" classes="{$incoming/@classes}">
		{$incoming/@debtee}
		{$incoming/*}
	</Account>
};

(: Solange kein Buch steht, bleibt die Jahresdatei vollständig. Danach trennt das Speichern Stamm und Jahreszeile. Die bestehende Buch-Id bleibt. :)
declare function account:storeAccount ($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $resource-id as xs:string, $account-data) {
	let $raw := if ($account-data instance of document-node()) then $account-data/*[1] else $account-data
	let $incoming :=
		if ($raw/self::AccountRecord) then account:held(($raw/Year/Account, $raw/Book/Account)[1], string(($raw/Book/Account/@id, $raw/Year/Account/@id, $resource-id)[1]))
		else $raw
	let $year-doc := account:ensure-year($home-data, $tenant, $year)
	let $existing := $year-doc/Accounts/Account[lower-case(@id) = lower-case($resource-id)][1]
	let $guard := account:own-firm-error($incoming, $existing)
	return
		if ($guard != '') then error(xs:QName('docman:OwnFirm'), $guard)
		else if (not(account:has-book($home-data, $tenant))) then
			let $current := $year-doc/Accounts/Account[lower-case(@id) = lower-case($resource-id)]
			let $kept := $current/(Service|Company|Person|Contact|CustomerID|BankAccounts|ProcessTemplates|PeriodicPayments|FieldHints)[not(local-name() = $incoming/*/local-name())]
			let $stored :=
				<Account>
					{$incoming/@*[not(local-name() = ('contactsRef', 'banksRef'))]}
					{attribute contactsRef { (normalize-space(string($incoming/@contactsRef))[. != ''], account:contacts-ref($current))[1] }}
					{attribute banksRef { (normalize-space(string($incoming/@banksRef))[. != ''], account:banks-ref($current))[1] }}
					{$incoming/*}
					{$kept}
				</Account>
			return
				if (exists($current)) then (update replace $current with $stored, $stored)
				else (update insert $stored into $year-doc/Accounts, $stored)
		else
			let $book := doc(account:book-path($home-data, $tenant))
			let $hint := account:contacts-ref($incoming)
			let $previous := $book/Contacts/Contact[lower-case(@id) = lower-case($hint) or lower-case(@id) = lower-case($resource-id)][1]
			let $id := if ($previous) then string($previous/@id) else normalize-space(string(($incoming/@id[normalize-space(.) != ''], $resource-id)[1]))
			let $held := account:held($incoming, $id)
			let $slim := account:slim($held)
			let $current := ($year-doc/Accounts/Account[lower-case(@id) = lower-case($resource-id)], $year-doc/Accounts/Account[lower-case(@id) = lower-case($id)])[1]
			let $stored :=
				if (exists($current)) then (update replace $current with $slim, $slim)
				else (update insert $slim into $year-doc/Accounts, $slim)
			let $booked :=
				if (account:person($slim) or exists($previous)) then
					let $entry := account:book-entry($held, if ($previous) then string($previous/@id) else account:contacts-ref($slim), $year, $previous)
					return
						if (exists($previous)) then (update replace $previous with $entry, $entry)
						else (update insert $entry into $book/Contacts, $entry)
				else ()
			return ($stored, $booked, $slim)[last()]
};

declare function account:deleteAccount ($home-data, $tenant, $year as xs:integer, $resource-id) {
	let $year-doc := doc(account:year-path($home-data, $tenant, $year))
	let $row := $year-doc/Accounts/Account[lower-case(@id) = lower-case($resource-id)]
	return
		if (empty($row)) then <error>Kein Account vorhanden</error>
		else if (normalize-space(string($row/@kto)) = '1') then error(xs:QName('docman:OwnFirm'), 'Das Buchungskonto der eigenen Firma bleibt erhalten.')
		else
			<Account id="{$row/@id}">
				{update delete $row}
			</Account>
};

(: Der echte Knoten, den Vorschläge und Muster fortschreiben: Buch, sobald es steht, sonst die Jahresdatei. :)
declare function account:mutable($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $key as xs:string) as element()? {
	if (account:has-book($home-data, $tenant)) then
		let $hit := account:getAccount($home-data, $tenant, $year, $key)
		let $ref := account:contacts-ref($hit)
		let $book := doc(account:book-path($home-data, $tenant))/Contacts/Contact[lower-case(@id) = lower-case($ref)]
		return ($book, $hit)[1]
	else
		let $doc := doc(account:year-path($home-data, $tenant, $year))
		return (
			$doc/Accounts/Account[lower-case(@id) = lower-case($key)],
			$doc/Accounts/Account[string(@kto) = $key]
		)[1]
};

declare function account:record($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $resource-id as xs:string) as element(AccountRecord) {
	let $joined := account:getAccount($home-data, $tenant, $year, $resource-id)
	let $id := string(($joined/@id, $resource-id)[1])
	let $book := if (account:has-book($home-data, $tenant)) then doc(account:book-path($home-data, $tenant))/Contacts/Contact[lower-case(@id) = lower-case($id)] else ()
	let $row := doc(account:year-path($home-data, $tenant, $year))/Accounts/Account[lower-case(@id) = lower-case($id)]
	return
		<AccountRecord id="{$id}" year="{$year}">
			<Book>{$book}</Book>
			<Year>{($row, account:slim($joined))[1]}</Year>
		</AccountRecord>
};

declare function account:project-year($home-data as xs:string, $tenant as xs:string, $from-year as xs:integer, $to-year as xs:integer) as element(Accounts) {
	let $root := if (doc-available(account:year-path($home-data, $tenant, $from-year))) then doc(account:year-path($home-data, $tenant, $from-year))/Accounts else ()
	let $previous := $root/Account
	return
		<Accounts>
			{$root/@chart}
			{$root/@personNumbers}
			{
			if (not(account:has-book($home-data, $tenant))) then $previous
			else
				for $entry in doc(account:book-path($home-data, $tenant))/Contacts/Contact
				where account:node-in-year($entry, $to-year)
				for $old in $previous[lower-case(account:contacts-ref(.)) = lower-case($entry/@id) or lower-case(@id) = lower-case($entry/@id)]
				let $opening := (string($old/Accounting/@closingBalance)[. != ''], '0')[1]
				let $categories := $old/BudgetCategories/BudgetCategory[account:in-year(string(Period/@valid-from), string(Period/@valid-till), $to-year)]
				return
					<Account id="{$old/@id}" kto="{$old/@kto}" type="{($old/@type, 'ledger_account')[1]}" classes="{string($old/@classes)}" contactsRef="{$entry/@id}" banksRef="{string($old/@banksRef)}">
						<Name>{string($old/Name)}</Name>
						<Notes/>
						<BudgetCategories>{$categories}</BudgetCategories>
						<Accounting openingBalance="{$opening}" closingBalance="0" debitSum="0" creditSum="0"/>
					</Account>
			}
		</Accounts>
};

declare %private function account:number-spans($rows as element(Hit)*) as element(Number)* {
	fold-left($rows, (), function($acc as element(Number)*, $hit as element(Hit)) as element(Number)* {
		let $kto := string($hit/Account/@kto)
		let $year := xs:integer($hit/@year)
		let $from := concat($year, '-01-01')
		let $till := concat($year, '-12-31')
		let $last := $acc[last()]
		let $continues := exists($last) and string($last/@kto) = $kto and xs:date($last/@valid-till) + xs:dayTimeDuration('P1D') = xs:date($from)
		return
			if ($continues) then (
				$acc[position() lt last()],
				<Number kto="{$kto}" valid-from="{$last/@valid-from}" valid-till="{$till}"/>
			) else (
				$acc,
				<Number kto="{$kto}" valid-from="{$from}" valid-till="{$till}"/>
			)
	})
};

declare %private function account:book-banks($rows as element(Hit)*, $latest as xs:integer) as element(BankAccount)* {
	let $newest := $rows[last()]/Account
	for $bank in $newest/BankAccounts/BankAccount
	let $iban := normalize-space(string($bank/@iban))
	let $seen :=
		for $hit in $rows
		where $hit/Account/BankAccounts/BankAccount[if ($iban = '') then deep-equal(@*, $bank/@*) else @iban = $iban]
		order by xs:integer($hit/@year)
		return $hit
	let $first := if ($seen) then xs:integer($seen[1]/@year) else $latest
	let $last := if ($seen) then xs:integer($seen[last()]/@year) else $latest
	return
		<BankAccount>
			{$bank/@*[not(local-name() = ('valid-from', 'valid-till'))]}
			{attribute valid-from {if ($bank/@valid-from castable as xs:date) then string($bank/@valid-from) else concat($first, '-01-01')}}
			{if ($bank/@valid-till castable as xs:date) then attribute valid-till {string($bank/@valid-till)} else if ($last lt $latest) then attribute valid-till {concat($last, '-12-31')} else ()}
		</BankAccount>
};

(: Einmal je Mandant. Erweiterte Daten nach contacts.dm.xml, Jahresdatei wird schmal. Zweiter Lauf lässt die Jahresdateien stehen. :)
declare function account:split($home-data as xs:string, $tenant as xs:string) as element(Split) {
	let $col := concat($home-data, '/', $tenant)
	let $years :=
		for $name in xmldb:get-child-collections($col)
		where $name castable as xs:integer
		order by xs:integer($name)
		return xs:integer($name)
	let $backed :=
		every $year in $years satisfies
			not(xmldb:get-child-resources(concat($col, '/', $year)) = 'accounts.dm.xml')
			or xmldb:get-child-resources(concat($col, '/', $year)) = 'accounts.dm.xml.bak'
	return
		if (account:has-book($home-data, $tenant) and exists($years) and $backed) then
			<Split tenant="{$tenant}" status="unchanged" years="{count($years)}" contacts="{count(doc(account:book-path($home-data, $tenant))/Contacts/Contact)}"/>
		else
			let $sources :=
				for $year in $years
				let $dir := concat($col, '/', $year)
				let $bak := concat($dir, '/accounts.dm.xml.bak')
				let $xml := concat($dir, '/accounts.dm.xml')
				let $path := if (doc-available($bak)) then $bak else if (doc-available($xml)) then $xml else ()
				where exists($path)
				return <Source year="{$year}" path="{$path}" dir="{$dir}">{doc($path)/Accounts/Account}</Source>
			let $latest := max($years)
			let $ids := distinct-values($sources/Account[account:person(.) or account:extended(.)]/@id)
			let $built :=
				for $id in $ids
				let $rows :=
					for $source in $sources
					let $account := $source/Account[@id = $id][1]
					where exists($account)
					order by xs:integer($source/@year)
					return <Hit year="{$source/@year}">{$account}</Hit>
				let $newest := $rows[last()]/Account
				let $first-year := xs:integer($rows[1]/@year)
				let $last-year := xs:integer($rows[last()]/@year)
				let $names := distinct-values($rows/Account/Name ! normalize-space(string(.)))[. != '']
				let $open := $last-year = $latest
				return
					<Built>
						{if (count($names) gt 1) then <Conflict id="{$id}" names="{string-join($names, ' | ')}"/> else ()}
						<Contact id="{$id}" valid-from="{concat($first-year, '-01-01')}">
							{$newest/@debtee}
							{if (normalize-space(string($newest/@iban)) != '') then attribute iban {normalize-space(string($newest/@iban))} else ()}
							{if (not($open)) then attribute valid-till {concat($last-year, '-12-31')} else ()}
							<Name>{normalize-space(string($newest/Name))}</Name>
							{$newest/CustomerID}
							{$newest/Service}
							{account:chosen-party($newest)}
							{account:channels-from($newest)}
							{$newest/Notes}
							<BankAccounts>{account:book-banks($rows, $last-year)}</BankAccounts>
							{$newest/ProcessTemplates}
							{$newest/PeriodicPayments}
							{$newest/FieldHints}
						</Contact>
					</Built>
			let $stored := xmldb:store($col, 'contacts.dm.xml', <Contacts>{$built/Contact}</Contacts>)
			let $slimmed :=
				for $source in $sources
				let $resources := xmldb:get-child-resources($source/@dir)
				where not($resources = 'accounts.dm.xml.bak') and doc-available(concat($source/@dir, '/accounts.dm.xml'))
				let $backup := xmldb:store($source/@dir, 'accounts.dm.xml.bak', doc(concat($source/@dir, '/accounts.dm.xml')))
				let $numbering := doc(concat($source/@dir, '/accounts.dm.xml'))/Accounts/(@chart, @personNumbers)
				let $replaced := xmldb:store($source/@dir, 'accounts.dm.xml', <Accounts>{$numbering}{$source/Account ! account:slim(.)}</Accounts>)
				return <Year year="{$source/@year}" count="{count($source/Account)}" backup="{$backup}"/>
			let $banks :=
				for $year in $years
				let $dir := concat($col, '/', $year)
				for $file in xmldb:get-child-resources($dir)[matches(., '^bank-account_.+\.dm\.xml$')]
				let $detail := doc(concat($dir, '/', $file))/BankAccount/BankAccountDetail
				let $kto := string(doc(concat($dir, '/', $file))/BankAccount/@kto)
				let $first :=
					min(
						for $candidate in $years
						let $cdir := concat($col, '/', $candidate)
						where some $name in xmldb:get-child-resources($cdir)[matches(., '^bank-account_.+\.dm\.xml$')]
							satisfies string(doc(concat($cdir, '/', $name))/BankAccount/@kto) = $kto
						return $candidate
					)
				where exists($detail) and not($detail/@valid-from castable as xs:date) and exists($first)
				return update insert attribute valid-from {concat($first, '-01-01')} into $detail
			return
				<Split tenant="{$tenant}" status="done" years="{count($sources)}" contacts="{count($built/Contact)}">
					{$slimmed}
					<Conflicts>{count($built/Conflict)}{$built/Conflict}</Conflicts>
				</Split>
};

declare %private function account:contact-from-year($account as element(Account)) as element(Contact) {
	<Contact id="{$account/@id}">
		{$account/@debtee}
		{if (normalize-space(string($account/@iban)) != '') then attribute iban {normalize-space(string($account/@iban))} else ()}
		<Name>{string($account/Name)}</Name>
		{$account/Alias}
		{$account/CustomerID}
		{$account/Service}
		{account:chosen-party($account)}
		{account:channels-from($account)}
		{$account/Notes}
		{$account/BankAccounts}
		{$account/ProcessTemplates}
		{$account/PeriodicPayments}
		{$account/FieldHints}
	</Contact>
};

(: Erstes Speichern legt die Kontaktdatei an und übernimmt die übrigen Kontakte des Jahres, ohne die Jahresdatei umzuschreiben. :)
declare %private function account:ensure-book($home-data as xs:string, $tenant as xs:string, $year as xs:integer) as document-node() {
	if (account:has-book($home-data, $tenant)) then doc(account:book-path($home-data, $tenant))
	else
		let $seed := account:contacts($home-data, $tenant, $year, true())
		let $stored := xmldb:store(concat($home-data, '/', $tenant), 'contacts.dm.xml', <Contacts>{$seed}</Contacts>)
		return doc(account:book-path($home-data, $tenant))
};

declare function account:contacts($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $include-ended as xs:boolean) as element(Contact)* {
	if (account:has-book($home-data, $tenant)) then
		for $entry in doc(account:book-path($home-data, $tenant))/Contacts/Contact
		where $include-ended or account:node-in-year($entry, $year)
		order by $entry/Name
		return $entry
	else
		for $account in account:year-accounts($home-data, $tenant, $year)
		where account:person($account) or account:extended($account)
		order by $account/Name
		return account:contact-from-year($account)
};

declare function account:contact($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $id as xs:string) as element(Contact)? {
	account:contacts($home-data, $tenant, $year, true())[lower-case(@id) = lower-case($id)][1]
};

declare function account:contact-accounts($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $id as xs:string) as element(Account)* {
	account:year-accounts($home-data, $tenant, $year)[lower-case(account:contacts-ref(.)) = lower-case($id) or lower-case(@id) = lower-case($id)]
};

(: Frühere Jahreszeilen dieses Kontakts, für den Übernahme-Vorschlag der Kontonummer. :)
declare function account:contact-past-accounts($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $id as xs:string) as element(Account)* {
	let $col := concat($home-data, '/', $tenant)
	let $wanted := lower-case($id)
	for $name in xmldb:get-child-collections($col)
	where $name castable as xs:integer and xs:integer($name) != $year
	let $past := xs:integer($name)
	let $path := account:year-path($home-data, $tenant, $past)
	where doc-available($path)
	for $row in doc($path)/Accounts/Account[lower-case(account:contacts-ref(.)) = $wanted or lower-case(@id) = $wanted]
	order by $past descending
	return
		<Account year="{$past}" id="{$row/@id}" kto="{$row/@kto}" type="{($row/@type, 'ledger_account')[1]}" classes="{string($row/@classes)}" contactsRef="{account:contacts-ref($row)}">
			<Name>{string($row/Name)}</Name>
			{($row/Accounting, <Accounting openingBalance="0" closingBalance="0" debitSum="0" creditSum="0"/>)[1]}
		</Account>
};

declare %private function account:composed-contact($incoming as element(), $previous as element()?, $kept-id as xs:string, $year as xs:integer, $own as xs:boolean) as element(Contact) {
	let $from := normalize-space(string(if ($incoming/@valid-from) then $incoming/@valid-from else $previous/@valid-from))
	let $opened := if ($from castable as xs:date) then $from else concat($year, '-01-01')
	let $incoming-till := if ($incoming/@valid-till) then normalize-space(string($incoming/@valid-till)) else ()
	let $till := if ($own) then '' else if (exists($incoming-till)) then string($incoming-till) else normalize-space(string($previous/@valid-till))
	return
		<Contact id="{$kept-id}" valid-from="{$opened}">
			{if ($till castable as xs:date) then attribute valid-till {$till} else ()}
			{($incoming/@debtee, $previous/@debtee)[1]}
			{if (normalize-space(string(($incoming/@iban, $previous/@iban)[1])) != '') then attribute iban {normalize-space(string(($incoming/@iban, $previous/@iban)[1]))} else ()}
			<Name>{normalize-space(string(($incoming/Name, $previous/Name)[1]))}</Name>
			{account:kept($incoming, $previous, 'Alias')}
			{account:kept($incoming, $previous, 'CustomerID')}
			{account:kept($incoming, $previous, 'Service')}
			{account:party-kept($incoming, $previous)}
			{if ($incoming/contacts or $incoming/Contact) then account:channels-from($incoming) else account:channels-from($previous)}
			{account:kept($incoming, $previous, 'Notes')}
			{account:kept($incoming, $previous, 'BankAccounts')}
			{account:kept($incoming, $previous, 'ProcessTemplates')}
			{account:kept($incoming, $previous, 'PeriodicPayments')}
			{account:kept($incoming, $previous, 'FieldHints')}
		</Contact>
};

declare function account:store-contact($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $id as xs:string, $contact as item()) as element(Contact) {
	let $incoming := if ($contact instance of document-node()) then $contact/*[1] else $contact
	let $book := account:ensure-book($home-data, $tenant, $year)
	let $path-id := normalize-space($id)
	let $previous :=
		if (account:is-uuid($path-id)) then $book/Contacts/Contact[lower-case(@id) = lower-case($path-id)]
		else if (account:is-uuid(string($incoming/@id))) then $book/Contacts/Contact[lower-case(@id) = lower-case($incoming/@id)]
		else ()
	let $kept-id :=
		if ($previous) then string($previous/@id)
		else if (account:is-uuid(string($incoming/@id))) then lower-case(normalize-space(string($incoming/@id)))
		else if (account:is-uuid($path-id)) then lower-case($path-id)
		else account:fresh-contact-id()
	let $incoming-till := if ($incoming/@valid-till) then normalize-space(string($incoming/@valid-till)) else ()
	let $own := lower-case($kept-id) = (account:own-contact-ids($home-data, $tenant) ! lower-case(.))
	let $entry := account:composed-contact($incoming, $previous, $kept-id, $year, $own)
	return
		if ($own and $incoming-till castable as xs:date) then
			error(xs:QName('docman:OwnFirm'), 'Die eigene Firma bleibt gültig.')
		else if ($previous) then
			(update replace $previous with $entry, $entry)
		else
			(update insert $entry into $book/Contacts, $entry)
};

(: Neuer Debitor oder Kreditor: Kontakt-UUID, Jahreskonto mit sprechender Id und contactsRef. :)
declare function account:create-party($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $incoming as element()) as element(Account) {
	let $contact-id :=
		if (account:is-uuid(string($incoming/@contactsRef))) then lower-case(normalize-space(string($incoming/@contactsRef)))
		else if (account:is-uuid(string($incoming/@id))) then lower-case(normalize-space(string($incoming/@id)))
		else account:fresh-contact-id()
	let $name := normalize-space(string($incoming/Name))
	let $kto := normalize-space(string($incoming/@kto))
	let $slug := account:speaking-id($name, $kto)
	let $year-doc := account:ensure-year($home-data, $tenant, $year)
	let $taken := $year-doc/Accounts/Account[lower-case(@id) = lower-case($slug)]
	let $account-id := if (exists($taken)) then concat($slug, '_', $kto) else $slug
	let $book := account:ensure-book($home-data, $tenant, $year)
	let $entry := account:composed-contact($incoming, (), $contact-id, $year, false())
	let $row :=
		<Account id="{$account-id}" kto="{$kto}" type="ledger_account" classes="{$incoming/@classes}" contactsRef="{$contact-id}">
			<Name>{normalize-space(string($entry/Name))}</Name>
			{($incoming/Notes, <Notes/>)[1]}
			<BudgetCategories/>
			{($incoming/Accounting, <Accounting openingBalance="0" closingBalance="0" debitSum="0" creditSum="0"/>)[1]}
		</Account>
	let $contact-write := update insert $entry into $book/Contacts
	let $account-write := update insert $row into $year-doc/Accounts
	return ($contact-write, $account-write, $row)[last()]
};

declare function account:end-contact($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $id as xs:string) as element() {
	let $book := account:ensure-book($home-data, $tenant, $year)
	let $entry := $book/Contacts/Contact[lower-case(@id) = lower-case($id)]
	let $till := xs:date(concat($year, '-01-01')) - xs:dayTimeDuration('P1D')
	return
		if (empty($entry)) then <error>Kein Kontakt vorhanden</error>
		else if (lower-case(string($entry/@id)) = (account:own-contact-ids($home-data, $tenant) ! lower-case(.))) then
			error(xs:QName('docman:OwnFirm'), 'Die eigene Firma bleibt im Kontaktbuch.')
		else
			let $closed := account:close($entry, $till)
			return <Contact id="{$entry/@id}" valid-till="{string($till)}" retired="true"/>
};

(: Konto 1 ist die eigene Firma. Der Vergleich bleibt zeichenweise, damit 0001 nicht als 1 gilt. :)
declare function account:own-contact-ids($home-data as xs:string, $tenant as xs:string) as xs:string* {
	let $col := concat($home-data, '/', $tenant)
	for $name in xmldb:get-child-collections($col)
	where $name castable as xs:integer
	let $path := account:year-path($home-data, $tenant, xs:integer($name))
	where doc-available($path)
	for $row in doc($path)/Accounts/Account[normalize-space(string(@kto)) = '1']
	let $ref := normalize-space(string(($row/@contactsRef[normalize-space(.) != ''], $row/@id)[1]))
	where $ref != ''
	return $ref
};

declare %private function account:own-firm-error($incoming as element(), $existing as element(Account)?) as xs:string {
	let $kto := normalize-space(string($incoming/@kto))
	let $tokens := tokenize(normalize-space(string($incoming/@classes)), '\s+')[. != '']
	let $only-self := count($tokens) = 1 and $tokens = 'self'
	let $was-own := normalize-space(string($existing/@kto)) = '1'
	return
		if ($kto = '1' and not($tokens = 'self')) then 'Kontonummer 1 gehört zur eigenen Firma und braucht die Klasse self.'
		else if ($only-self and $kto != '1') then 'Die eigene Firma ist auf Kontonummer 1 festgelegt.'
		else if ($was-own and $kto != '1') then 'Die Kontonummer der eigenen Firma bleibt 1.'
		else if ($was-own and not($tokens = 'self')) then 'Die eigene Firma behält die Klasse self.'
		else ''
};

(: Entfernt Kontenattribute und Nummernspannen aus dem Kontaktbuch. Jahresdateien bleiben stehen. :)
declare function account:tidy-contacts($home-data as xs:string, $tenant as xs:string) as element(Tidy) {
	let $path := account:book-path($home-data, $tenant)
	return
		if (not(doc-available($path))) then <Tidy tenant="{$tenant}" status="missing"/>
		else
			let $nodes := doc($path)/Contacts/Contact
			let $cleared :=
				for $contact in $nodes
				return (
					if ($contact/@type) then update delete $contact/@type else (),
					if ($contact/@classes) then update delete $contact/@classes else (),
					for $numbers in $contact/Numbers return update delete $numbers
				)
			return <Tidy tenant="{$tenant}" status="done" contacts="{count($nodes)}" steps="{count($cleared)}"/>
};

(: Contact wird zur Liste contacts/contact. Firma und Person bleiben nur als eine von beiden. :)
declare function account:reshape-contacts($home-data as xs:string, $tenant as xs:string) as element(Reshape) {
	let $path := account:book-path($home-data, $tenant)
	return
		if (not(doc-available($path))) then <Reshape tenant="{$tenant}" status="missing"/>
		else
			let $nodes := doc($path)/Contacts/Contact[Contact or (Company and Person)]
			let $done :=
				for $entry in $nodes
				return update replace $entry with account:reshaped($entry)
			return <Reshape tenant="{$tenant}" status="done" changed="{count($nodes)}" steps="{count($done)}"/>
};

declare %private function account:reshaped($entry as element()) as element(Contact) {
	<Contact id="{$entry/@id}">
		{$entry/@*[not(local-name() = ('id', 'type', 'classes'))]}
		<Name>{normalize-space(string($entry/Name))}</Name>
		{$entry/Alias}
		{$entry/CustomerID}
		{$entry/Service}
		{account:chosen-party($entry)}
		{if (exists($entry/Contact)) then account:channels-from($entry) else $entry/contacts}
		{$entry/Notes}
		{$entry/BankAccounts}
		{$entry/ProcessTemplates}
		{$entry/PeriodicPayments}
		{$entry/FieldHints}
	</Contact>
};

(: Kontakt-Ids auf UUID umstellen und contactsRef in allen Jahresdateien nachziehen. :)
declare function account:uuid-contacts($home-data as xs:string, $tenant as xs:string) as element(UuidContacts) {
	let $path := account:book-path($home-data, $tenant)
	return
		if (not(doc-available($path))) then <UuidContacts tenant="{$tenant}" status="missing"/>
		else
			let $col := concat($home-data, '/', $tenant)
			let $changed :=
				for $contact in doc($path)/Contacts/Contact
				let $old := normalize-space(string($contact/@id))
				where $old != '' and not(account:is-uuid($old))
				let $new := account:fresh-contact-id()
				let $id-write := update value $contact/@id with $new
				let $years :=
					for $name in xmldb:get-child-collections($col)
					where $name castable as xs:integer
					let $year-path := account:year-path($home-data, $tenant, xs:integer($name))
					where doc-available($year-path)
					for $row in doc($year-path)/Accounts/Account
					let $ref := normalize-space(string($row/@contactsRef))
					let $row-id := normalize-space(string($row/@id))
					where lower-case($ref) = lower-case($old)
						or ($ref = '' and lower-case($row-id) = lower-case($old))
						or (account:person($row) and lower-case($row-id) = lower-case($old))
					return
						if ($row/@contactsRef) then update value $row/@contactsRef with $new
						else update insert attribute contactsRef {$new} into $row
				return <Contact old="{$old}" new="{$new}" accounts="{count($years)}">{$id-write, $years}</Contact>
			return
				<UuidContacts tenant="{$tenant}" status="done" changed="{count($changed)}">
					{$changed}
				</UuidContacts>
};

declare function account:uuid-contacts-all($home-data as xs:string) as element(UuidContactsAll) {
	<UuidContactsAll>{
		for $tenant in xmldb:get-child-collections($home-data)
		where doc-available(account:book-path($home-data, $tenant))
			or exists(
				for $year in xmldb:get-child-collections(concat($home-data, '/', $tenant))[. castable as xs:integer]
				where doc-available(account:year-path($home-data, $tenant, xs:integer($year)))
				return 1
			)
		order by $tenant
		return
			if (doc-available(account:book-path($home-data, $tenant))) then
				account:uuid-contacts($home-data, $tenant)
			else
				<UuidContacts tenant="{$tenant}" status="no-book"/>
	}</UuidContactsAll>
};


