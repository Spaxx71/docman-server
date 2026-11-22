xquery version "3.1";

module namespace match = "http://bintellix.com/docman/match";

declare function match:suggestions(
	$home-data as xs:string,
	$tenant as xs:string,
	$year as xs:integer,
	$bank as xs:string?,
	$payment-id as xs:string?,
	$process-id as xs:string?,
	$days-before as xs:integer,
	$days-after as xs:integer,
	$tolerance as xs:decimal
) as element(Suggestions) {
	let $model := local:model($home-data, $tenant, $year)
	let $accounts := local:accounts($home-data, $tenant, $year)
	let $past := local:history($home-data, $tenant, $year)
	let $groups := local:field-groups($model, $accounts, $past, $days-before, $days-after, $payment-id, $process-id, $tolerance)
	let $filtered := local:finish($groups, $bank, $payment-id, $process-id)
	let $anchor-pay := ($model/Pay[@id = $payment-id])[1]
	let $anchor-proc := ($model/Proc[@id = $process-id])[1]
	let $cluster :=
		if ($anchor-pay) then count($model/Proc[local:related($anchor-pay, .)])
		else if ($anchor-proc) then count($model/Pay[local:related(., $anchor-proc)])
		else count($model/Proc)
	let $later :=
		if ($anchor-pay) then
			for $other in $model/Pay[@bank = $anchor-pay/@bank][not(@id = $anchor-pay/@id)]
			order by xs:date($other/@date), string($other/@id)
			return $other
		else if ($anchor-proc) then
			for $other in $model/Proc[@binder = $anchor-proc/@binder][not(@id = $anchor-proc/@id)]
			order by xs:date($other/@date), string($other/@id)
			return $other
		else ()
	let $anchor-date := if ($anchor-pay) then xs:date($anchor-pay/@date) else if ($anchor-proc) then xs:date($anchor-proc/@date) else ()
	let $next := if (empty($anchor-date)) then () else ($later[xs:date(@date) ge $anchor-date][1], $later[1])[1]
	return
		<Suggestions days-before="{$days-before}" days-after="{$days-after}" tolerance="{format-number($tolerance, '0.00')}" cluster="{$cluster}" next="{string($next/@id)}" remaining="{count($later)}">
			{$filtered}
		</Suggestions>
};

declare function match:apply(
	$home-data as xs:string,
	$tenant as xs:string,
	$year as xs:integer,
	$bank as xs:string,
	$payment-id as xs:string,
	$days-before as xs:integer,
	$days-after as xs:integer,
	$tolerance as xs:decimal,
	$user as xs:string
) as element(Suggestions) {
	let $suggestions := match:suggestions($home-data, $tenant, $year, $bank, $payment-id, (), $days-before, $days-after, $tolerance)
	let $actor := local:actor($user)
	let $applied :=
		for $group in $suggestions/Group[@auto = 'true'][Payment/@id = $payment-id]
		for $proc in $group/Process
		return local:write-task($home-data, $tenant, $year, $group/Payment, $proc, $actor)
	return
		<Suggestions days-before="{$days-before}" days-after="{$days-after}" tolerance="{format-number($tolerance, '0.00')}" cluster="{$suggestions/@cluster}">
			{$suggestions/Group}
			<Applied>{count($applied[not(@error)])}</Applied>
			{$applied}
		</Suggestions>
};

declare function local:actor($user as xs:string) as xs:string {
	let $given := normalize-space($user)
	let $session :=
		try { normalize-space(string(sm:id()/sm:id/sm:real/sm:username)) }
		catch * { '' }
	return
		if ($given != '' and $given != 'Guest') then $given
		else if ($session != '') then $session
		else 'automate'
};

declare function local:money($value) as xs:decimal? {
	let $text := translate(normalize-space(string($value)), ',', '.')
	return if ($text castable as xs:decimal) then xs:decimal($text) else ()
};

declare function local:sum($values as xs:decimal*) as xs:decimal {
	if (empty($values)) then xs:decimal(0) else sum($values)
};

(: Halber Cent je Einzelbetrag, nur gegen Rundung. Die Toleranz gilt für Summen. :)
declare function local:same($left as xs:decimal, $right as xs:decimal) as xs:boolean {
	abs($left - $right) lt 0.005
};

declare function local:within($left as xs:decimal, $right as xs:decimal, $tolerance as xs:decimal) as xs:boolean {
	abs($left - $right) le $tolerance
};

(: in = Geld kommt herein, out = Geld geht hinaus. :)
declare function local:pay-direction($type as xs:string, $amount as xs:decimal) as xs:string {
	if ($type = 'DEBIT') then 'out'
	else if ($type = 'CREDIT') then 'in'
	else if ($amount lt 0) then 'out'
	else 'in'
};

declare function local:proc-direction($task as xs:string, $storno as xs:boolean) as xs:string {
	let $natural := if ($task = 'InvoiceOutTask') then 'in' else 'out'
	return if ($storno) then (if ($natural = 'in') then 'out' else 'in') else $natural
};

declare function local:signed($direction as xs:string, $amount as xs:decimal) as xs:decimal {
	if ($direction = 'out') then -abs($amount) else abs($amount)
};

declare function local:proc-label($proc as element(Proc)) as xs:string {
	if ($proc/@salary = 'true') then
		if ($proc/@storno = 'true') then 'einer Gehaltsgutschrift' else 'einem Gehalt'
	else if ($proc/@task = 'InvoiceOutTask') then
		if ($proc/@storno = 'true') then 'einer Gutschrift einer ausgehenden Rechnung' else 'einer ausgehenden Rechnung'
	else
		if ($proc/@storno = 'true') then 'einer Gutschrift einer eingehenden Rechnung' else 'einer eingehenden Rechnung'
};

declare function local:euro($value as xs:decimal) as xs:string {
	replace(format-number(abs($value), '0.00'), '\.', ',')
};

declare function local:date($value) as xs:date? {
	let $text := substring(normalize-space(string($value)), 1, 10)
	return if ($text castable as xs:date) then xs:date($text) else ()
};

declare function local:contains($hay, $needle, $min as xs:integer) as xs:boolean {
	let $token := upper-case(normalize-space(string($needle)))
	return string-length($token) ge $min and contains(upper-case(string($hay)), $token)
};

declare function local:day-count($proc as element(Proc), $pay as element(Pay)) as xs:integer {
	days-from-duration(xs:date($pay/@date) - xs:date($proc/@date))
};

declare function local:in-window($proc-date as xs:date, $pay-date as xs:date, $before as xs:integer, $after as xs:integer) as xs:boolean {
	$pay-date ge ($proc-date - xs:dayTimeDuration(concat('P', string($before), 'D')))
	and $pay-date le ($proc-date + xs:dayTimeDuration(concat('P', string($after), 'D')))
};

declare function local:any-contains($hay, $needles as xs:string*, $min as xs:integer) as xs:boolean {
	some $needle in $needles satisfies local:contains($hay, $needle, $min)
};

declare function local:word-hit($hay, $texts as xs:string*) as xs:boolean {
	some $word in tokenize(string-join($texts, ' '), '[^A-Za-z0-9ÄÖÜäöüß]+')
	satisfies local:contains($hay, $word, 4)
};

declare function local:text-ok($proc as element(Proc), $pay as element(Pay)) as xs:boolean {
	if ($proc/@salary = 'true') then
		local:contains($pay/@purpose, $proc/@employee, 4)
	else
		local:any-contains($pay/@purpose, $proc/Ref, 6) or local:any-contains($pay/@purpose, $proc/Trans, 6)
};

declare function local:purpose-level($proc as element(Proc), $pay as element(Pay)) as xs:string {
	if ($proc/@salary = 'true') then
		local:phrase-level($pay/@purpose, ($proc/@employee, $proc/@month))
	else
		local:phrase-level($pay/@purpose, ($proc/Text, $proc/Note, $proc/Posten/@text))
};

(: done = gemeinsames Konto oder IBAN, part = der Name steht im Zahlungstext. :)
declare function local:giver-level($proc as element(Proc), $pay as element(Pay)) as xs:string {
	if ($proc/Key = $pay/Key) then 'done'
	else if (
		some $name in ($proc/Name, $proc/@ownerName, $proc/@employee) satisfies (
			local:contains($pay/@purpose, $name, 4) or local:contains($pay/@recipient, $name, 4)
		)
	) then 'part'
	else 'none'
};

declare function local:marks($proc as element(Proc), $pay as element(Pay), $before as xs:integer, $after as xs:integer, $amount-level as xs:string) as element(Mark)* {
	let $days := local:day-count($proc, $pay)
	let $window := local:in-window(xs:date($proc/@date), xs:date($pay/@date), $before, $after)
	let $date-level := if ($window) then 'done' else 'none'
	return (
		<Mark field="amount" level="{$amount-level}"/>,
		<Mark field="date" level="{$date-level}" days="{$days}"/>,
		if ($proc/@salary = 'true') then ()
		else (
			<Mark field="reference" level="{if (exists(($proc/Ref, $proc/Posten/@ref)[local:number-hit($pay/@purpose, string(.))])) then 'done' else 'none'}"/>,
			<Mark field="transaction" level="{if (exists(($proc/Trans, $proc/Posten/@trans)[local:number-hit($pay/@purpose, string(.))])) then 'done' else 'none'}"/>
		),
		<Mark field="purpose" level="{local:purpose-level($proc, $pay)}"/>,
		<Mark field="counterparty" level="{local:giver-level($proc, $pay)}"/>
	)
};

declare function local:selection-level($group as element(Group)) as xs:string {
	let $amount :=
		if ($group/Sum) then string($group/Sum/@level)
		else string(($group/Process/Mark[@field = 'amount']/@level)[1])
	let $fields := (
		$group/Process/Mark[@field = ('date', 'reference', 'transaction', 'purpose', 'counterparty')]/@level,
		$amount
	)
	return
		if ($fields = 'none') then 'none'
		else if ($fields = 'part') then 'part'
		else if (exists($fields[. != ''])) then 'done'
		else 'none'
};

declare function local:model($home-data as xs:string, $tenant as xs:string, $year as xs:integer) as element(Model) {
	let $collection := concat($home-data, '/', $tenant, '/', $year)
	let $accounts :=
		if (doc-available(concat($collection, '/accounts.dm.xml'))) then
			doc(concat($collection, '/accounts.dm.xml'))/Accounts/Account
		else ()
	let $parties :=
		for $account in $accounts
		return
			<Party kto="{string($account/@kto)}" name="{normalize-space(string($account/Name))}">
				{local:party-keys($account)}
			</Party>
	let $tasks := collection($collection)/Process/Tasks/PaymentTask
	let $pays :=
		for $bank in collection($collection)/BankAccount
		for $accounting in $bank/Accountings/Accounting
		let $face := local:money($accounting/Amount)
		let $booked := local:sum(
			for $value in $tasks[normalize-space(RefID) = $accounting/@id]/Amount/@value
			let $number := local:money($value)
			where exists($number)
			return $number
		)
		let $open := if (exists($face)) then $face - $booked else ()
		let $date := local:date($accounting/ValueDate)
		where exists($open) and exists($date) and abs($open) ge 0.005
		return local:pay($bank, $accounting, $open, $date, $parties)
	let $procs :=
		for $process in collection($collection)/Process
		let $master := (
			$process/Tasks/(InvoiceInTask|InvoiceOutTask|EmployeeSalaryTask)[@isMaster = 'true'],
			$process/Tasks/(InvoiceInTask|InvoiceOutTask|EmployeeSalaryTask)
		)[1]
		let $face := if ($master) then local:face($process, $master) else ()
		let $booked := local:sum(
			for $value in $process/Tasks/PaymentTask/Amount/@value
			let $number := local:money($value)
			where exists($number)
			return $number
		)
		let $open := if (exists($face)) then $face - $booked else ()
		let $date := local:date($process/@date)
		where exists($master) and exists($open) and exists($date) and abs($open) ge 0.005
		return local:proc($process, $master, $open, $date, $parties)
	return
		<Model>
			{$pays}
			{$procs}
		</Model>
};

declare function local:party-keys($account as element(Account)) as element(Key)* {
	let $ibans := distinct-values((
		tokenize(string($account/@iban), '[,\s]+')[normalize-space(.) != ''],
		for $iban in $account/BankAccounts/BankAccount/@iban return normalize-space(string($iban))
	))
	let $debtees := tokenize(string($account/@debtee), '[,\s]+')[normalize-space(.) != '']
	return (
		<Key>kto:{string($account/@kto)}</Key>,
		for $iban in $ibans[. != '']
		return <Key>iban:{upper-case(replace($iban, '\s', ''))}</Key>,
		for $debtee in $debtees
		return <Key>creditor:{upper-case($debtee)}</Key>
	)
};

declare function local:face($process as element(Process), $master as element()) as xs:decimal? {
	if (local-name($master) = 'EmployeeSalaryTask') then
		let $paid := (local:money($master/AmountPaid), local:money($master/Amount/@value))[1]
		return
			if (empty($paid)) then ()
			else if ($master/@isStorno = 'true') then $paid
			else -$paid
	else
		(local:money($process/TotalAmount/@value), local:money($master/Amount/@value))[1]
};

declare function local:pay($bank as element(BankAccount), $accounting as element(Accounting), $open as xs:decimal, $date as xs:date, $parties as element(Party)*) as element(Pay) {
	let $iban := upper-case(replace(normalize-space(string($accounting/IBAN)), '\s', ''))
	let $creditor := upper-case(normalize-space(string($accounting/CreditorID)))
	let $matched := $parties[
		($iban != '' and Key = concat('iban:', $iban))
		or ($creditor != '' and Key = concat('creditor:', $creditor))
	]
	let $type := normalize-space(string($accounting/Amount/@type))
	let $direction := local:pay-direction($type, $open)
	let $match := local:signed($direction, $open)
	let $customer := normalize-space(string($accounting/CustomerRef))
	let $endtoend := normalize-space(string($accounting/EndToEndRef))
	let $purpose := normalize-space(string-join((
		$accounting/CustomerRef[normalize-space(.) != '' and . != 'NONREF'],
		$accounting/EndToEndRef[normalize-space(.) != '' and . != 'NOTPROVIDED'],
		$accounting/PaymentDetail,
		$accounting/Usage,
		$accounting/PaymentDetails/PaymentDetail
	), ' '))
	let $unit := normalize-space(string($accounting/CurrencyUnit))
	return
		<Pay id="{$accounting/@id}" bank="{string($bank/@kto)}" amount="{format-number($open, '0.00')}" match="{format-number($match, '0.00')}" direction="{$direction}" date="{string($date)}" unit="{if ($unit = ('EUR', 'USD')) then $unit else 'EUR'}" customer="{if ($customer = ('NONREF', '')) then '' else $customer}" endtoend="{if ($endtoend = ('NOTPROVIDED', '')) then '' else $endtoend}" purpose="{$purpose}" iban="{$iban}" creditor="{$creditor}" recipient="{normalize-space(string($accounting/Recipient))}">
			{
				if ($iban != '') then <Key>iban:{$iban}</Key> else (),
				if ($creditor != '') then <Key>creditor:{$creditor}</Key> else (),
				$matched/Key
			}
		</Pay>
};

declare function local:proc($process as element(Process), $master as element(), $open as xs:decimal, $date as xs:date, $parties as element(Party)*) as element(Proc) {
	let $salary := local-name($master) = 'EmployeeSalaryTask'
	let $owner := normalize-space(string($master/Owner))
	let $tasks := $process/Tasks/(InvoiceInTask|InvoiceOutTask|EmployeeSalaryTask)
	let $owners := distinct-values($tasks/Owner[normalize-space(.) != ''])
	let $party := $parties[@kto = $owners]
	let $employee := normalize-space(string(($tasks/EmployeeName[normalize-space(.) != ''])[1]))
	let $month := normalize-space(string(($tasks/SalaryMonth[normalize-space(.) != ''])[1]))
	let $description :=
		if ($salary) then string-join(($employee, $month)[normalize-space(.) != ''], ', ')
		else normalize-space(string(($tasks/Description[normalize-space(.) != ''])[1]))
	let $direction := local:proc-direction(local-name($master), $master/@isStorno = 'true')
	let $match := local:signed($direction, $open)
	return
		<Proc id="{$process/@id}" binder="{string($process/@binder)}" name="{string($process/@name)}" owner="{$owner}" ownerName="{string(($party/@name)[1])}" amount="{format-number($open, '0.00')}" match="{format-number($match, '0.00')}" direction="{$direction}" date="{string($date)}" ref="{if ($salary) then '' else normalize-space(string($master/RefID))}" trans="{if ($salary) then '' else normalize-space(string($master/TransactionID))}" description="{$description}" task="{local-name($master)}" storno="{if ($master/@isStorno = 'true') then 'true' else 'false'}" salary="{if ($salary) then 'true' else 'false'}" employee="{$employee}" month="{$month}">
			{for $kto in $owners return <Key>kto:{$kto}</Key>}
			{$party/Key}
			{for $name in distinct-values($party/@name[normalize-space(.) != '']) return <Name>{normalize-space(string($name))}</Name>}
			{for $ref in distinct-values($tasks/RefID[normalize-space(.) != '']) return <Ref>{normalize-space($ref)}</Ref>}
			{for $ref in distinct-values($tasks/TransactionID[normalize-space(.) != '']) return <Trans>{normalize-space($ref)}</Trans>}
			{for $text in distinct-values($tasks/Description[normalize-space(.) != '']) return <Text>{normalize-space($text)}</Text>}
			{if (normalize-space(string($process/Notes)) != '') then <Note>{normalize-space(string($process/Notes))}</Note> else ()}
			{for $note in $process/Tasks/*/Notes[normalize-space(.) != ''] return <Note>{normalize-space(string($note))}</Note>}
			{local:posten($process)}
			{
				for $ref in $process/Tasks/PaymentTask/RefID
				return <Linked>{normalize-space(string($ref))}</Linked>
			}
		</Proc>
};

declare function local:related($pay as element(Pay), $proc as element(Proc)) as xs:boolean {
	not($proc/Linked = $pay/@id) and (
		$proc/Key = $pay/Key
		or local:text-ok($proc, $pay)
		or local:same(abs(xs:decimal($proc/@match)), abs(xs:decimal($pay/@match)))
	)
};

declare function local:groups($model as element(Model), $before as xs:integer, $after as xs:integer, $payment-id as xs:string?, $process-id as xs:string?, $tolerance as xs:decimal) as element(Group)* {
	let $payment := normalize-space(string($payment-id))
	let $process := normalize-space(string($process-id))
	let $focus := $model/Proc[@id = $process]
	let $pays :=
		if ($payment != '') then $model/Pay[@id = $payment]
		else if (exists($focus)) then $model/Pay[local:related(., $focus)]
		else $model/Pay[Key = $model/Proc/Key]
	let $exact := local:demote(
		for $pay in $pays
		return local:exact($pay, local:pool($pay, $model/Proc, $before, $after), $before, $after, $tolerance)
	)
	let $bundles := local:bundles($model/Pay, $model/Proc, $exact, $before, $after, $tolerance)
	let $parts :=
		for $pay in $pays
		return local:smaller($pay, $model/Proc, $exact, $before, $after, $tolerance)
	let $kept := ($exact, $bundles, $parts)
	let $near :=
		for $pay in $pays
		return local:near($pay, $model/Proc, $kept, $before, $after)
	let $crossed :=
		for $pay in $pays
		return local:crossed($pay, $model/Proc, $before, $after)
	return ($exact, $bundles, $parts, $near, $crossed)
};

declare function local:pool($pay as element(Pay), $procs as element(Proc)*, $before as xs:integer, $after as xs:integer) as element(Proc)* {
	let $close :=
		for $proc in $procs[@direction = $pay/@direction][not(Linked = $pay/@id)]
		let $window := local:in-window(xs:date($proc/@date), xs:date($pay/@date), $before, $after)
		where $window and local:same(abs(xs:decimal($proc/@match)), abs(xs:decimal($pay/@match)))
		order by abs(local:day-count($proc, $pay))
		return $proc
	let $ranked :=
		for $proc in $procs[@direction = $pay/@direction][local:related($pay, .)]
		let $hit := local:text-ok($proc, $pay)
		let $window := local:in-window(xs:date($proc/@date), xs:date($pay/@date), $before, $after)
		let $days := local:day-count($proc, $pay)
		order by (if ($hit or $window) then 0 else 1), abs($days)
		return $proc
	let $ids := distinct-values((
		for $proc in $close return string($proc/@id),
		for $proc in $ranked return string($proc/@id)
	))
	return subsequence(
		for $id in $ids
		return ($close, $ranked)[@id = $id][1],
		1,
		15
	)
};

declare function local:sets($items as element(Proc)*, $size as xs:integer) as element(Set)* {
	local:sets-from($items, $size, 1)
};

declare function local:sets-from($items as element(Proc)*, $size as xs:integer, $from as xs:integer) as element(Set)* {
	let $count := count($items)
	return
		if ($size lt 1 or $from gt $count) then ()
		else if ($size = 1) then
			for $index in ($from to $count)
			return <Set><Id>{string($items[$index]/@id)}</Id></Set>
		else
			for $index in ($from to $count - $size + 1)
			for $tail in local:sets-from($items, $size - 1, $index + 1)
			return <Set><Id>{string($items[$index]/@id)}</Id>{$tail/Id}</Set>
};

declare function local:exact($pay as element(Pay), $pool as element(Proc)*, $before as xs:integer, $after as xs:integer, $tolerance as xs:decimal) as element(Group)* {
	if (empty($pool)) then ()
	else
		for $size in (1 to min((3, count($pool))))
		for $set in local:sets($pool, $size)
		let $members := $pool[@id = $set/Id]
		let $total := local:sum($members/@match ! xs:decimal(.))
		let $pay-amount := xs:decimal($pay/@match)
		where if ($size = 1) then local:same($total, $pay-amount) else (
			local:within($total, $pay-amount, $tolerance)
			and local:same-giver($members)
			and local:giver-pays($pay, $members)
		)
		return local:exact-group($pay, $members, $before, $after)
};

declare function local:exact-group($pay as element(Pay), $members as element(Proc)*, $before as xs:integer, $after as xs:integer) as element(Group) {
	let $secure :=
		every $member in $members satisfies (
			local:in-window(xs:date($member/@date), xs:date($pay/@date), $before, $after)
			and local:text-ok($member, $pay)
		)
	let $amount-level := if (count($members) = 1) then 'done' else 'none'
	let $quality := if (count($members) = 1) then '0.9' else if (count($members) = 2) then '0.8' else '0.7'
	return
		<Group secure="{if ($secure) then 'true' else 'false'}" quality="{$quality}">
			{local:payment-view($pay)}
			{
				for $member in $members
				return local:process-view($member, $pay, $before, $after, $amount-level)
			}
			{if (count($members) gt 1) then <Sum amount="{format-number(local:sum($members/@match ! xs:decimal(.)), '0.00')}" level="done"/> else ()}
			{local:gate-reasons($pay, $members, $before, $after)}
			{if (every $member in $members satisfies not($member/Key = $pay/Key)) then <Reason field="counterparty">Kein gemeinsames Gegenkonto. Das Konto der Rechnung trägt diese IBAN nicht.</Reason> else ()}
		</Group>
};

declare function local:gate-reasons($pay as element(Pay), $members as element(Proc)*, $before as xs:integer, $after as xs:integer) as element(Reason)* {
	let $outside :=
		for $member in $members
		let $days := local:day-count($member, $pay)
		where not(local:in-window(xs:date($member/@date), xs:date($pay/@date), $before, $after))
		order by abs($days) descending
		return $days
	let $silent := $members[not(local:text-ok(., $pay))]
	let $label := if (abs($outside[1]) = 1) then '1 Tag' else concat(string(abs($outside[1])), ' Tage')
	return (
		if (exists($outside)) then
			<Reason field="date" days="{abs($outside[1])}">Das Datum liegt {$label} außerhalb des Fensters.</Reason>
		else (),
		if (empty($silent)) then ()
		else if (every $member in $silent satisfies $member/@salary = 'true') then
			<Reason field="content">Der Mitarbeitername steht nicht im Zahlungstext.</Reason>
		else
			<Reason field="content">Weder Belegnummer noch Vorgangsnummer steht im Zahlungstext.</Reason>
	)
};

declare function local:demote($groups as element(Group)*) as element(Group)* {
	let $secure := $groups[@secure = 'true']
	let $rebuilt :=
		for $group in $groups
		let $payment-id := string($group/Payment/@id)
		let $alone := count($secure[Payment/@id = $payment-id]) = 1
		let $clash := some $id in $group/Process/@id satisfies count($secure[Process/@id = $id]) gt 1
		let $auto := $group/@secure = 'true' and $alone and not($clash)
		return
			<Group auto="{if ($auto) then 'true' else 'false'}" kind="exact" quality="{$group/@quality}">
				{$group/Payment}
				{$group/Process}
				{$group/Sum}
				{$group/Reason}
				{if ($group/@secure = 'true' and not($auto)) then <Reason field="unique">Mehrere Gruppen gehen gleich gut auf.</Reason> else ()}
			</Group>
	let $auto-ids := $rebuilt[@auto = 'true']/Process/@id
	return $rebuilt[@auto = 'true' or not(Process/@id = $auto-ids)]
};

declare function local:bundles($pays as element(Pay)*, $procs as element(Proc)*, $exact as element(Group)*, $before as xs:integer, $after as xs:integer, $tolerance as xs:decimal) as element(Group)* {
	let $auto-payments := $exact[@auto = 'true']/Payment/@id
	let $tokens := distinct-values((
		$procs/@ref[string-length(.) ge 6],
		$procs/@trans[string-length(.) ge 6]
	))
	let $found :=
		for $token in $tokens
		let $members := $procs[@ref = $token or @trans = $token]
		let $sample := $members[1]
		let $payments := $pays[not(@id = $auto-payments)][@direction = $sample/@direction][Key = $sample/Key or local:contains(@purpose, $token, 6)][local:contains(@purpose, $token, 6)]
		let $free := $members[not(Linked = $payments/@id)]
		where count($payments) ge 2 and count($payments) le 6 and count($free) ge 1 and count($free) le 6
		let $key := string-join((
			for $id in $payments/@id order by $id return string($id),
			for $id in $free/@id order by $id return string($id)
		), '|')
		return local:bundle-group($payments, $free, $key, $before, $after, $tolerance)
	return
		for $key in distinct-values($found/@key)
		return $found[@key = $key][1]
};

declare function local:bundle-group($payments as element(Pay)*, $members as element(Proc)*, $key as xs:string, $before as xs:integer, $after as xs:integer, $tolerance as xs:decimal) as element(Group) {
	let $pay-sum := local:sum($payments/@match ! xs:decimal(.))
	let $proc-sum := local:sum($members/@match ! xs:decimal(.))
	let $equal := local:within($pay-sum, $proc-sum, $tolerance)
	return
		<Group auto="false" kind="bundle" quality="{if ($equal) then '0.6' else '0.3'}" key="{$key}">
			{for $pay in $payments return local:payment-view($pay)}
			{
				for $member in $members
				let $pay := local:closest($member, $payments)
				return local:process-view($member, $pay, $before, $after, 'part')
			}
			<Sum amount="{format-number($proc-sum, '0.00')}" level="{if ($equal) then 'done' else 'none'}"/>
			{
				if ($equal) then
					<Reason field="bundle">Mehrere Zahlungen gehen mit diesen Vorgängen zusammen auf.</Reason>
				else
					<Reason field="amount" difference="{local:euro($pay-sum - $proc-sum)}">Der Betrag geht um {local:euro($pay-sum - $proc-sum)} EUR nicht auf.</Reason>
			}
		</Group>
};

declare function local:closest($proc as element(Proc), $payments as element(Pay)*) as element(Pay) {
	(
		for $pay in $payments
		order by abs(local:day-count($proc, $pay))
		return $pay
	)[1]
};

declare function local:near($pay as element(Pay), $procs as element(Proc)*, $kept as element(Group)*, $before as xs:integer, $after as xs:integer) as element(Group)* {
	let $shown := $kept[Payment/@id = $pay/@id]/Process/@id
	let $hits :=
		for $proc in $procs[@direction = $pay/@direction][local:related($pay, .)][not(@id = $shown)]
		let $diff := xs:decimal($proc/@match) - xs:decimal($pay/@match)
		let $hit := local:text-ok($proc, $pay)
		let $window := local:in-window(xs:date($proc/@date), xs:date($pay/@date), $before, $after)
		where $hit or $window
		order by abs(local:day-count($proc, $pay))
		return $proc
	for $proc in subsequence($hits, 1, 8)
	let $diff := xs:decimal($proc/@match) - xs:decimal($pay/@match)
	let $amount-level := if (local:same($diff, 0)) then 'done' else if (abs(xs:decimal($proc/@match)) lt abs(xs:decimal($pay/@match))) then 'part' else 'none'
	let $kind := if ($amount-level = 'done') then 'exact' else if ($amount-level = 'part') then 'part' else 'near'
	return
		<Group auto="false" kind="{$kind}" quality="0">
			{local:payment-view($pay)}
			{local:process-view($proc, $pay, $before, $after, $amount-level)}
			{if (local:same($diff, 0)) then () else <Reason field="amount" difference="{local:euro($diff)}">Der Betrag geht um {local:euro($diff)} EUR nicht auf.</Reason>}
			{local:gate-reasons($pay, $proc, $before, $after)}
			{if ($proc/Key = $pay/Key) then () else <Reason field="counterparty">Kein gemeinsames Gegenkonto. Das Konto der Rechnung trägt diese IBAN nicht.</Reason>}
		</Group>
};

declare function local:crossed($pay as element(Pay), $procs as element(Proc)*, $before as xs:integer, $after as xs:integer) as element(Group)* {
	let $hits :=
		for $proc in $procs[not(@direction = $pay/@direction)][not(Linked = $pay/@id)]
		let $window := local:in-window(xs:date($proc/@date), xs:date($pay/@date), $before, $after)
		let $hit := local:text-ok($proc, $pay)
		where local:same(abs(xs:decimal($proc/@match)), abs(xs:decimal($pay/@match))) and ($window or $hit or $proc/Key = $pay/Key)
		order by abs(local:day-count($proc, $pay))
		return $proc
	for $proc in subsequence($hits, 1, 4)
	let $movement := if ($pay/@direction = 'in') then 'Ein Zahlungseingang' else 'Ein Zahlungsausgang'
	return
		<Group auto="false" kind="direction" quality="0">
			{local:payment-view($pay)}
			{local:process-view($proc, $pay, $before, $after, 'none')}
			<Reason field="direction">{$movement} passt nicht zu {local:proc-label($proc)}.</Reason>
			{if ($proc/Key = $pay/Key) then () else <Reason field="counterparty">Kein gemeinsames Gegenkonto. Das Konto der Rechnung trägt diese IBAN nicht.</Reason>}
		</Group>
};

declare function local:smaller($pay as element(Pay), $procs as element(Proc)*, $exact as element(Group)*, $before as xs:integer, $after as xs:integer, $tolerance as xs:decimal) as element(Group)* {
	let $target := abs(xs:decimal($pay/@match))
	let $ranked :=
		for $proc in $procs[@direction = $pay/@direction][not(Linked = $pay/@id)]
		let $size := abs(xs:decimal($proc/@match))
		let $window := local:in-window(xs:date($proc/@date), xs:date($pay/@date), $before, $after)
		where $window and $size gt 0 and $size lt $target and not(local:same($size, $target))
		order by
			(if ($proc/Key = $pay/Key or local:text-ok($proc, $pay)) then 0 else 1),
			$size descending,
			abs(local:day-count($proc, $pay))
		return $proc
	let $candidates := subsequence($ranked, 1, 12)
	let $covered :=
		for $group in $exact[Payment/@id = $pay/@id]
		return string-join(
			for $id in $group/Process/@id
			order by string($id)
			return string($id),
			'|'
		)
	let $combos :=
		for $size in (2 to min((3, count($candidates))))
		for $set in local:sets($candidates, $size)
		let $members := $candidates[@id = $set/Id]
		let $total := local:sum($members/@match ! xs:decimal(.))
		let $key := string-join(for $id in $members/@id order by string($id) return string($id), '|')
		where local:within($total, xs:decimal($pay/@match), $tolerance)
			and not($key = $covered)
			and local:same-giver($members)
			and local:giver-pays($pay, $members)
		order by
			count($members[not(Key = $pay/Key) and not(local:text-ok(., $pay))]),
			count($members),
			abs($total - xs:decimal($pay/@match))
		return local:part-bundle($pay, $members, $before, $after, $tolerance)
	let $kept := subsequence($combos, 1, 6)
	let $used := ($kept/Process/@id, $exact[Payment/@id = $pay/@id]/Process/@id)
	let $singles :=
		for $proc in $candidates[not(@id = $used)]
		return local:part-single($pay, $proc, $before, $after)
	return ($kept, subsequence($singles, 1, 8))
};

declare function local:part-bundle($pay as element(Pay), $members as element(Proc)*, $before as xs:integer, $after as xs:integer, $tolerance as xs:decimal) as element(Group) {
	let $total := local:sum($members/@match ! xs:decimal(.))
	let $gap := xs:decimal($pay/@match) - $total
	return
		<Group auto="false" kind="bundle" quality="0.45">
			{local:payment-view($pay)}
			{
				for $member in $members
				return local:process-view($member, $pay, $before, $after, 'part')
			}
			<Sum amount="{format-number($total, '0.00')}" level="done"/>
			<Reason field="bundle">Belege desselben Gebers erreichen die Zahlung gemeinsam, innerhalb der Toleranz von {local:euro($tolerance)} EUR.</Reason>
			{if (local:same($gap, 0)) then () else <Reason field="amount" difference="{local:euro($gap)}">Die Summe liegt {local:euro($gap)} EUR neben der Zahlung.</Reason>}
			{local:gate-reasons($pay, $members, $before, $after)}
			{if (some $member in $members satisfies $member/Key = $pay/Key) then () else <Reason field="counterparty">Kein gemeinsames Gegenkonto. Das Konto der Rechnung trägt diese IBAN nicht.</Reason>}
		</Group>
};

declare function local:part-single($pay as element(Pay), $proc as element(Proc), $before as xs:integer, $after as xs:integer) as element(Group) {
	let $gap := xs:decimal($pay/@match) - xs:decimal($proc/@match)
	return
		<Group auto="false" kind="part" quality="0.2">
			{local:payment-view($pay)}
			{local:process-view($proc, $pay, $before, $after, 'part')}
			<Reason field="amount" difference="{local:euro($gap)}">Der Betrag ist um {local:euro($gap)} EUR kleiner und kann mit weiteren Belegen die Zahlung erreichen.</Reason>
			{local:gate-reasons($pay, $proc, $before, $after)}
			{if ($proc/Key = $pay/Key) then () else <Reason field="counterparty">Kein gemeinsames Gegenkonto. Das Konto der Rechnung trägt diese IBAN nicht.</Reason>}
		</Group>
};

declare function local:same-giver($members as element(Proc)*) as xs:boolean {
	let $owner := distinct-values($members/@owner[normalize-space(.) != ''])
	let $name := distinct-values($members/@ownerName[normalize-space(.) != ''])
	let $shared :=
		some $key in distinct-values($members/Key)
		satisfies (every $member in $members satisfies $member/Key = $key)
	return count($members) ge 2 and (
		count($owner) = 1
		or (empty($owner) and count($name) = 1)
		or $shared
	)
};

declare function local:giver-pays($pay as element(Pay), $members as element(Proc)*) as xs:boolean {
	some $member in $members satisfies local:giver-level($member, $pay) = ('done', 'part')
};

declare function local:payment-view($pay as element(Pay)) as element(Payment) {
	<Payment bank="{$pay/@bank}" id="{$pay/@id}" amount="{$pay/@amount}" date="{$pay/@date}" unit="{$pay/@unit}" customer="{$pay/@customer}" endtoend="{$pay/@endtoend}" purpose="{$pay/@purpose}" iban="{$pay/@iban}" creditor="{$pay/@creditor}" recipient="{$pay/@recipient}"/>
};

declare function local:process-view($proc as element(Proc), $pay as element(Pay), $before as xs:integer, $after as xs:integer, $amount-level as xs:string) as element(Process) {
	<Process id="{$proc/@id}" binder="{$proc/@binder}" name="{$proc/@name}" owner="{$proc/@owner}" ownerName="{$proc/@ownerName}" amount="{$proc/@amount}" date="{$proc/@date}" ref="{$proc/@ref}" trans="{$proc/@trans}" description="{$proc/@description}" task="{$proc/@task}" storno="{$proc/@storno}" salary="{$proc/@salary}" distance="{local:day-count($proc, $pay)}">
		{local:marks($proc, $pay, $before, $after, $amount-level)}
		{$proc/Posten}
	</Process>
};

declare function local:filter($groups as element(Group)*, $bank as xs:string?, $payment-id as xs:string?, $process-id as xs:string?) as element(Group)* {
	let $payment := normalize-space(string($payment-id))
	let $process := normalize-space(string($process-id))
	let $account := normalize-space(string($bank))
	let $by-payment := if ($payment = '') then $groups else $groups[Payment/@id = $payment]
	let $by-bank := if ($account = '' or $payment != '') then $by-payment else $by-payment[Payment/@bank = $account]
	let $by-process := if ($process = '') then $by-bank else $by-bank[Process/@id = $process]
	for $group in $by-process
	let $rank := if ($group/@auto = 'true') then 0 else if ($group/@kind = 'exact') then 1 else if ($group/@kind = 'bundle') then 2 else if ($group/@kind = ('near', 'part')) then 3 else 4
	order by $rank
	return element Group {
		$group/@*,
		attribute level {local:selection-level($group)},
		$group/node()
	}
};

declare function local:write-task($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $pay as element(Payment), $proc as element(Process), $user as xs:string) as element(Applied) {
	let $node := collection(concat($home-data, '/', $tenant, '/', $year))/Process[@id = $proc/@id][1]
	let $owner := normalize-space(string($proc/@owner))
	let $bank := normalize-space(string($pay/@bank))
	return
		if (empty($node)) then
			<Applied process="{$proc/@id}" payment="{$pay/@id}" error="Vorgang nicht gefunden."/>
		else if (not($owner castable as xs:positiveInteger) or not($bank castable as xs:positiveInteger) or $owner = $bank) then
			<Applied process="{$proc/@id}" payment="{$pay/@id}" error="Buchung braucht zwei verschiedene Kontonummern."/>
		else
			try {
				let $task := local:task($tenant, $year, $pay, $proc, $user)
				let $insert := update insert $task into $node/Tasks
				let $touch :=
					if ($node/@changed) then update value $node/@changed with string(current-dateTime())
					else update insert attribute changed { string(current-dateTime()) } into $node
				return <Applied process="{$proc/@id}" payment="{$pay/@id}"/>
			} catch * {
				<Applied process="{$proc/@id}" payment="{$pay/@id}" error="{$err:description}"/>
			}
};

declare function local:task($tenant as xs:string, $year as xs:integer, $pay as element(Payment), $proc as element(Process), $user as xs:string) as element(PaymentTask) {
	let $portion := xs:decimal($proc/@amount)
	let $storno := $proc/@storno = 'true'
	let $booked := if ($storno) then $portion else $portion * -1
	let $unit := if ($pay/@unit = ('EUR', 'USD')) then string($pay/@unit) else 'EUR'
	let $src := concat('/api/xml/tenants/', $tenant, '/years/', $year, '/banks/', $pay/@bank, '/accountings/', $pay/@id, '.pdf')
	let $description := substring(normalize-space(string($pay/@purpose)), 1, 180)
	let $text := if ($description = '') then 'Zahlung' else $description
	return
		<PaymentTask type="payment-bank" id="{concat('ACC', util:uuid())}" date="{$pay/@date}" created="{current-dateTime()}" isMaster="false" user="{$user}" isStorno="{if ($storno) then 'true' else 'false'}">
			<Notes/>
			<Files>
				<File archived="true" doctype="digital" fileExtension=".pdf" fileName="{$pay/@id}" mimeType="application/pdf" src="{$src}" type="doc-payment-bank" uploadName="{$pay/@id}"/>
			</Files>
			<Bookings>
				<Booking date="{$pay/@date}" quality="3" amountValue="{format-number($booked, '0.00')}" amountUnit="{$unit}" credit="{if ($storno) then $pay/@bank else $proc/@owner}" debit="{if ($storno) then $proc/@owner else $pay/@bank}" taxKey="1" taxAmount="0" refID="{$pay/@id}" description="{$text}"/>
			</Bookings>
			<Amount value="{format-number($portion, '0.00')}" unit="{$unit}"/>
			<RefID>{$pay/@id}</RefID>
			<Description>{$text}</Description>
			<Trigger/>
		</PaymentTask>
};

(: —— Feldweises Mapping: Posten, Wortgrenzen, Full-match, Einladungen —— :)

declare variable $match:fillers := ('GMBH', 'AG', 'KG', 'SE', 'OHG', 'UG', 'EV', 'UND', 'ODER', 'DER', 'DIE', 'DAS', 'DEN', 'DEM', 'DES', 'EIN', 'EINE', 'FUER', 'FUR', 'VON', 'MIT', 'BEI', 'AUF', 'AUS', 'ZUM', 'ZUR', 'IM', 'IN', 'AM', 'AN', 'RECHNUNG', 'ZAHLUNG', 'GUTSCHRIFT', 'BELEG');

declare function local:accounts($home-data as xs:string, $tenant as xs:string, $year as xs:integer) as element(Account)* {
	let $path := concat($home-data, '/', $tenant, '/', $year, '/accounts.dm.xml')
	return if (doc-available($path)) then doc($path)/Accounts/Account else ()
};

declare function local:posten-amount($task as element()) as xs:decimal? {
	if (local-name($task) = 'EmployeeSalaryTask') then
		let $paid := (local:money($task/AmountPaid), local:money($task/Amount/@value))[1]
		return if (empty($paid)) then () else if ($task/@isStorno = 'true') then $paid else -$paid
	else local:money($task/Amount/@value)
};

declare function local:posten($process as element(Process)) as element(Posten)* {
	for $task in $process/Tasks/(CommodityTask|InvoiceInTask|InvoiceOutTask|EmployeeSalaryTask|DiscountTask|DunningFeeTask|DunningChargeTask)
	let $amount := local:posten-amount($task)
	where exists($amount) and abs($amount) ge 0.005
	let $direction := if ($amount lt 0) then 'out' else 'in'
	let $role := if ($task/@isStorno = 'true') then 'storno' else if ($direction = 'out') then 'cost' else 'revenue'
	let $other := normalize-space(string(($task/Other, $task/Bookings/Booking/@debit, $task/Bookings/Booking/@credit)[1]))
	return
		<Posten id="{string($task/@id)}" task="{local-name($task)}" role="{$role}" storno="{if ($task/@isStorno = 'true') then 'true' else 'false'}" direction="{$direction}" amount="{format-number($amount, '0.00')}" date="{string($task/@date)}" ref="{normalize-space(string($task/RefID))}" trans="{normalize-space(string($task/TransactionID))}" text="{normalize-space(string($task/Description))}" other="{$other}" tax="{normalize-space(string($task/Tax/@key))}"/>
};

declare function local:words($text) as xs:string* {
	let $split := replace(upper-case(normalize-space(string($text))), '(EREF|KREF|MREF|CRED|SVWZ|ABWA|ABWE)\+', ' ')
	let $tokens := tokenize($split, '[^0-9A-ZÄÖÜ]+')[normalize-space(.) != '']
	return $tokens[not(. = $match:fillers)][string-length(.) ge 2][not(matches(., '^(19|20)[0-9]{2}$'))]
};

declare function local:ordered($hay as xs:string*, $need as xs:string*) as xs:boolean {
	if (empty($need)) then true()
	else if (empty($hay)) then false()
	else if ($hay[1] = $need[1]) then local:ordered(subsequence($hay, 2), subsequence($need, 2))
	else local:ordered(subsequence($hay, 2), $need)
};

declare function local:compact($text) as xs:string {
	upper-case(replace(string($text), '[^0-9A-Z]', ''))
};

declare function local:number-hit($purpose, $number) as xs:boolean {
	let $token := local:compact($number)
	let $hay := local:compact($purpose)
	return string-length($token) ge 4 and (
		contains($hay, $token)
		or (string-length($token) ge 8 and contains($hay, substring($token, 1, 6)) and contains($hay, substring($token, string-length($token) - 3)))
	)
};

declare function local:phrase-level($purpose, $texts as xs:string*) as xs:string {
	let $need := local:words(string-join($texts, ' '))
	let $hay := local:words($purpose)
	return
		if (empty($need)) then 'none'
		else if (count($need) ge 1 and local:ordered($hay, $need)) then 'done'
		else if (exists($need[. = $hay])) then 'part'
		else 'none'
};

declare function local:rule-text($rule as element()) as xs:string {
	replace(normalize-space(string($rule)), '\s+', '\\s+')
};

declare function local:rule-holds($rule as element(), $pay as element(Pay)) as xs:boolean {
	let $type := string($rule/@type)
	let $text := normalize-space(string($rule))
	return
		if ($text = '') then false()
		else if ($type = ('SEPA_DIRECT-DEBIT_IBAN', 'SEPA_CREDIT-TRANSFER_IBAN')) then
			$pay/@iban = upper-case(replace($text, '\s', ''))
		else if ($type = 'SEPA_DIRECT-DEBIT_CREDITOR-ID') then
			contains(string($pay/@creditor), upper-case($text))
		else if ($type = 'PAYER_BANK-ACCOUNT_CONCERNED') then
			string($pay/@bank) = $text
		else if ($type = 'SEPA_PAYMENT-DETAILS_REGEX') then
			try { matches(string($pay/@purpose), local:rule-text($rule), 'i') } catch * { false() }
		else
			local:ordered(local:words($pay/@purpose), local:words($text))
};

declare function local:intervals($account as element(Account)?, $date as xs:date?) as element(PeriodicPayment)* {
	for $payment in $account/PeriodicPayments/PeriodicPayment
	let $from := normalize-space(string(subsequence($payment/Period/@valid-from, 1, 1)))
	let $till := normalize-space(string(subsequence($payment/Period/@valid-till, 1, 1)))
	let $started := $from = '' or not($from castable as xs:date) or empty($date) or xs:date($from) le $date
	let $open := $till = '' or not($till castable as xs:date) or empty($date) or xs:date($till) ge $date
	where $started and $open
	return $payment
};

declare function local:party-account($accounts as element(Account)*, $proc as element(Proc)) as element(Account)? {
	($accounts[@kto = $proc/@owner])[1]
};

declare function local:twin($pay as element(Pay), $pays as element(Pay)*, $before as xs:integer, $after as xs:integer) as element(Pay)? {
	(
		for $other in $pays[not(@id = $pay/@id)][not(@direction = $pay/@direction)]
		where local:same(abs(xs:decimal($other/@match)), abs(xs:decimal($pay/@match)))
			and (
				($pay/@iban != '' and $other/@iban = $pay/@iban)
				or ($pay/@recipient != '' and upper-case($other/@recipient) = upper-case($pay/@recipient))
			)
			and local:in-window(xs:date($other/@date), xs:date($pay/@date), $before, $after)
		order by abs(days-from-duration(xs:date($pay/@date) - xs:date($other/@date)))
		return $other
	)[1]
};

declare function local:learned($model as element(Model), $owner as xs:string) as element(Learned)? {
	let $ids := $model/Proc[@owner = $owner]/Linked
	let $pays := $model/Pay[@id = $ids]
	let $count := count($pays)
	where $count ge 3
	let $amounts := for $pay in $pays return abs(xs:decimal($pay/@match))
	let $words := local:words(string-join($pays/@purpose, ' '))
	let $stable :=
		for $word in distinct-values($words)
		where count($pays[local:words(@purpose) = $word]) ge 3
		return $word
	return
		<Learned owner="{$owner}" count="{$count}" amount-min="{format-number(min($amounts), '0.00')}" amount-max="{format-number(max($amounts), '0.00')}">
			{for $word in $stable[position() le 6] return <Word>{$word}</Word>}
		</Learned>
};

declare function local:purpose-of($proc as element(Proc), $pays as element(Pay)*) as xs:string {
	string-join($pays/@purpose, ' ')
};

declare function local:month-index($date as xs:date) as xs:integer {
	year-from-date($date) * 12 + month-from-date($date)
};

declare function local:period-holds($interval as xs:string, $doc as xs:date?, $pay as xs:date?) as xs:boolean {
	if ($interval = '' or empty($doc) or empty($pay)) then true()
	else
		let $delta := local:month-index($pay) - local:month-index($doc)
		return
			if ($interval = 'monthly') then $delta = (0, 1)
			else if ($interval = 'quarterly') then $delta ge 0 and $delta le 3
			else if ($interval = 'annually') then $delta ge 0 and $delta le 12
			else true()
};

declare function local:bounds($account as element(Account)?) as xs:decimal* {
	for $value in (
		$account/PeriodicPayments/PeriodicPayment/Period/@amount-min,
		$account/PeriodicPayments/PeriodicPayment/Period/@amount-max,
		$account/ProcessTemplates/ProcessTemplate/TotalAmount/@value
	)
	let $money := local:money($value)
	where exists($money) and abs($money) ge 0.005
	return abs($money)
};

declare function local:in-span($account as element(Account)?, $pay as element(Pay)) as xs:boolean {
	let $bounds := local:bounds($account)
	let $amount := abs(xs:decimal($pay/@match))
	return exists($bounds) and $amount ge min($bounds) and $amount le max($bounds)
};

declare function local:skonto-explains($proc as element(Proc), $pay as element(Pay)) as xs:boolean {
	let $gap := local:gap($proc, $pay)
	let $fee := abs($gap)
	let $base := abs(local:sum(for $amount in $proc/Posten[@direction = $pay/@direction][not(@role = 'storno')]/@amount return xs:decimal($amount)))
	let $notes := string-join(($proc/Note, $proc/Posten/@text, $pay/@purpose), ' ')
	return $proc/@direction = $pay/@direction and $fee gt 0.005 and (
		local:words($notes) = 'SKONTO'
		or ($base gt 0 and $fee le $base * 0.03)
	)
};

declare function local:named-fee($notes as xs:string) as xs:decimal? {
	try {
		let $hit := analyze-string($notes, '(mahnung|mahngebühr|mahngebuehr|mahnkosten|mahnspesen|verzugspauschale)\D{0,16}(\d+[.,]\d{2})', 'i')
		let $number := string($hit//*:group[@nr = '2'][1])
		let $value := local:money($number)
		return if (exists($value) and $value gt 0.005 and $value le 99.99) then $value else ()
	} catch * { () }
};

declare function local:dunning-word($notes as xs:string) as xs:boolean {
	exists(local:words($notes)[. = ('MAHNUNG', 'MAHNGEBUEHR', 'MAHNGEBÜHR', 'MAHNKOSTEN', 'MAHNSPESEN', 'VERZUGSPAUSCHALE')])
};

declare function local:field-view($proc as element(Proc), $pay as element(Pay), $also as element(Pay)*, $accounts as element(Account)*, $learned as element(Learned)?, $before as xs:integer, $after as xs:integer, $amount-level as xs:string) as element(Process) {
	<Process id="{$proc/@id}" binder="{$proc/@binder}" name="{$proc/@name}" owner="{$proc/@owner}" ownerName="{$proc/@ownerName}" amount="{$proc/@amount}" date="{$proc/@date}" ref="{$proc/@ref}" trans="{$proc/@trans}" description="{$proc/@description}" task="{$proc/@task}" storno="{$proc/@storno}" salary="{$proc/@salary}" distance="{local:day-count($proc, $pay)}">
		{local:field-marks($proc, $pay, $also, $accounts, $learned, $before, $after, $amount-level)}
		{$proc/Posten}
	</Process>
};

declare function local:field-marks($proc as element(Proc), $pay as element(Pay), $also as element(Pay)*, $accounts as element(Account)*, $learned as element(Learned)?, $before as xs:integer, $after as xs:integer, $amount-level as xs:string) as element(Mark)* {
	let $side := $proc/Posten[@direction = $pay/@direction]
	let $dates := for $post in ($side, $proc)[1] return local:date($post/@date)
	let $date := ($dates, local:date($proc/@date))[1]
	let $pay-date := local:date($pay/@date)
	let $account := local:party-account($accounts, $proc)
	let $interval := string((local:intervals($account, $pay-date)/Period/@interval)[1])
	let $window := exists($date) and exists($pay-date) and local:in-window($date, $pay-date, $before, $after) and local:period-holds($interval, $date, $pay-date)
	let $purpose := local:purpose-of($proc, ($pay, $also))
	let $refs := ($side/@ref, $proc/Ref, $proc/@ref)[normalize-space(.) != '']
	let $trans := ($side/@trans, $proc/Trans, $proc/@trans)[normalize-space(.) != '']
	let $rules := local:intervals($account, $pay-date)/PaymentRules/PaymentRule
	let $rule-hit := exists($rules[local:rule-holds(., $pay)])
	let $text-rule := exists($rules[@type = ('SEPA_PAYMENT-DETAILS_REGEX', 'SEPA_PAYMENT-DETAILS_ASCII')][local:rule-holds(., $pay)])
	let $phrase :=
		if ($proc/@salary = 'true') then local:phrase-level($purpose, ($proc/@employee, $proc/@month))
		else local:phrase-level($purpose, ($side/@text, $proc/Text, $proc/Note))
	let $template-level := local:phrase-level($purpose, $account/ProcessTemplates/ProcessTemplate/Description)
	let $learned-hit := exists($learned/Word[local:words($purpose) = string(.)])
	let $name-level := local:phrase-level($purpose, ($proc/@ownerName, $proc/@employee))
	return (
		<Mark field="amount" level="{$amount-level}"/>,
		<Mark field="date" level="{if ($window) then 'done' else 'none'}" days="{if (exists($date) and exists($pay-date)) then days-from-duration($pay-date - $date) else ''}"/>,
		if ($proc/@salary = 'true') then ()
		else (
			<Mark field="reference" level="{if (exists($refs[local:number-hit($purpose, string(.))])) then 'done' else 'none'}"/>,
			<Mark field="transaction" level="{if (exists($trans[local:number-hit($purpose, string(.))])) then 'done' else 'none'}"/>
		),
		<Mark field="purpose" level="{if ($text-rule or $phrase = 'done') then 'done' else if ($phrase = 'part' or $template-level = ('done', 'part') or $learned-hit) then 'part' else 'none'}"/>,
		<Mark field="counterparty" level="{if ($proc/Key = $pay/Key or $rule-hit) then 'done' else if ($name-level = ('done', 'part')) then 'part' else 'none'}"/>
	)
};

declare function local:amount-level($proc as element(Proc), $pay as element(Pay), $tolerance as xs:decimal) as xs:string {
	let $side := $proc/Posten[@direction = $pay/@direction][not(@role = 'storno') or @direction = $pay/@direction]
	let $sum := local:sum($side/@amount ! xs:decimal(.))
	let $target := xs:decimal($pay/@match)
	return
		if (empty($side)) then 'none'
		else if (count($side) = 1 and local:same($sum, $target)) then 'done'
		else if (count($side) gt 1 and local:within($sum, $target, $tolerance)) then 'done'
		else if (exists($side[local:same(xs:decimal(@amount), $target)])) then 'part'
		else if (abs($sum) gt 0 and abs($sum) lt abs($target)) then 'part'
		else 'none'
};

declare function local:gap($proc as element(Proc), $pay as element(Pay)) as xs:decimal {
	let $side := $proc/Posten[@direction = $pay/@direction]
	let $sum := local:sum($side/@amount ! xs:decimal(.))
	return xs:decimal($pay/@match) - $sum
};

declare function local:invites($proc as element(Proc), $pay as element(Pay), $twin as element(Pay)?) as element(Invite)* {
	let $gap := local:gap($proc, $pay)
	let $notes := string-join(($proc/Note, $proc/Posten/@text, $pay/@purpose), ' ')
	let $named := local:named-fee($notes)
	let $fee := if (exists($named)) then $named else abs($gap)
	let $dunning-word := local:dunning-word($notes) or exists($named)
	let $has-fee := $proc/Posten[@task = ('DunningFeeTask', 'DunningChargeTask')][local:same(abs(xs:decimal(@amount)), $fee)]
	let $skonto := local:skonto-explains($proc, $pay)
	return (
		if ($proc/@direction = $pay/@direction and $gap != 0 and $dunning-word and $fee gt 0.005 and $fee le 99.99 and empty($has-fee) and not($proc/Posten/@role = 'storno')) then
			<Invite task="DunningFeeTask" amount="{format-number(if (xs:decimal($pay/@match) lt 0) then -$fee else $fee, '0.00')}" limit="99.99" process="{$proc/@id}"/>
		else if ($dunning-word and $fee gt 99.99) then
			<Invite task="DunningFeeTask" amount="{format-number($fee, '0.00')}" limit="99.99" process="{$proc/@id}" blocked="true"/>
		else (),
		if ($proc/@direction = $pay/@direction and $gap != 0 and $skonto and $fee gt 0.005 and $fee le 99.99 and empty($proc/Posten[@task = 'DiscountTask'][local:same(abs(xs:decimal(@amount)), $fee)])) then
			<Invite task="DiscountTask" amount="{format-number(if (xs:decimal($pay/@match) lt 0) then -$fee else $fee, '0.00')}" process="{$proc/@id}"/>
		else (),
		if ($twin and $proc/Posten[@role = 'cost'] and not($proc/Posten[@role = 'cost']/@direction = $pay/@direction)) then
			let $cost := abs(xs:decimal(($proc/Posten[@role = 'cost'])[1]/@amount))
			let $refund := abs(xs:decimal($pay/@match))
			let $already := local:sum(for $post in $proc/Posten[@role = 'storno'] return abs(xs:decimal($post/@amount)))
			let $open-cost := $cost - $already
			let $by-name := local:phrase-level($pay/@purpose, ($proc/@ownerName, $proc/Text)) = ('done', 'part')
			let $by-ref := exists($proc/Ref[local:number-hit($pay/@purpose, string(.))])
			let $named := $by-name or $by-ref
			let $covered := exists($proc/Posten[@role = 'storno'][local:same(abs(xs:decimal(@amount)), $refund)])
			return
				if ($refund le $open-cost + 0.005 and $named and not($covered)) then
					<Invite task="CommodityTask" storno="true" amount="{format-number($refund, '0.00')}" process="{$proc/@id}" source="{string(($proc/Posten[@role = 'cost'])[1]/@id)}"/>
				else ()
		else ()
	)
};

declare function local:explain-amount($level as xs:string, $proc as element(Proc), $pay as element(Pay)) as element(Reason)* {
	let $gap := local:gap($proc, $pay)
	return
		if ($level = 'done' or local:same($gap, 0)) then ()
		else if ($level = 'part') then
			<Reason field="amount" difference="{local:euro($gap)}">Der Betrag trifft einen Posten oder die gleichgerichtete Summe noch nicht. Differenz {local:euro($gap)} EUR.</Reason>
		else ()
};

declare function local:one-group($proc as element(Proc), $pay as element(Pay), $offset as element(Pay)?, $accounts as element(Account)*, $learned as element(Learned)?, $before as xs:integer, $after as xs:integer, $tolerance as xs:decimal) as element(Group)? {
	let $template := if ($offset and not($proc/Posten/@direction = $pay/@direction) and $proc/Posten/@direction = $offset/@direction) then $offset else $pay
	let $other := if ($template is $pay) then $offset else $pay
	let $raw := local:amount-level($proc, $template, $tolerance)
	let $account := local:party-account($accounts, $proc)
	let $level := if ($raw = 'none' and (local:in-span($account, $template) or local:skonto-explains($proc, $template))) then 'part' else $raw
	let $invites := local:invites($proc, $pay, $offset)
	let $explained := $level = ('done', 'part') or exists($invites[not(@blocked = 'true')])
	where $explained and not($proc/Linked = $template/@id)
	let $kind := if ($other) then 'offset' else if ($level = 'done' and count($proc/Posten[@direction = $template/@direction][not(@role = 'storno')]) le 1) then 'exact' else if (count($proc/Posten[@direction = $template/@direction][not(@role = 'storno')]) gt 1 and $level = 'done') then 'bundle' else 'part'
	let $interval := string((local:intervals($account, local:date($template/@date))/Period/@interval)[1])
	let $doc-date := local:date(($proc/Posten[@direction = $template/@direction]/@date, $proc/@date)[1])
	return
		<Group kind="{$kind}" quality="0">
			{local:payment-view($template)}
			{if ($other) then <Offset id="{$other/@id}" amount="{$other/@amount}" date="{$other/@date}" direction="{$other/@direction}" recipient="{$other/@recipient}" purpose="{$other/@purpose}"/> else ()}
			{local:field-view($proc, $template, $other, $accounts, $learned, $before, $after, $level)}
			{$invites}
			{local:explain-amount($level, $proc, $template)}
			{if ($raw != 'done' and exists(local:bounds($account)) and not(local:in-span($account, $template))) then <Reason field="amount">Der Betrag liegt außerhalb der erwarteten Spanne des Kreditors.</Reason> else ()}
			{if ($interval != '' and not(local:period-holds($interval, $doc-date, local:date($template/@date)))) then <Reason field="date">Das Intervall {$interval} rechnet diese Zahlung einer anderen Periode zu.</Reason> else ()}
			{if ($other) then <Reason field="offset">Die Bewegung vom {string($other/@date)} über {local:euro(xs:decimal($other/@amount))} EUR hebt sich mit dieser auf. Verknüpft wird nur die passende Richtung.</Reason> else ()}
			{if (not($proc/Key = $template/Key) and empty(local:intervals($account, local:date($template/@date))/PaymentRules/PaymentRule[local:rule-holds(., $template)])) then <Reason field="counterparty">Kein gemeinsames Gegenkonto.</Reason> else ()}
			{
				let $expected := $account/ProcessTemplates/ProcessTemplate/Other/@kto[normalize-space(.) != '']
				let $used := $proc/Posten[@role = 'cost']/@other[normalize-space(.) != '']
				where exists($expected) and exists($used) and empty($used[. = $expected])
				return <Reason field="template">Das Aufwandskonto des Postens steht in keiner Buchungsvorlage des Kreditors.</Reason>
			}
			{if ($learned) then <Reason field="learned">Aus {string($learned/@count)} Zahlungen: {string($learned/@interval)}, Zahltag {string($learned/@payday)}, Betrag {string($learned/@amount-min)}–{string($learned/@amount-max)}. {string-join($learned/Word, ', ')}</Reason> else ()}
		</Group>
};

declare function local:learned-for($proc as element(Proc), $accounts as element(Account)*) as element(Learned)? {
	()
};

declare function local:field-groups($model as element(Model), $accounts as element(Account)*, $past as element(Past)*, $before as xs:integer, $after as xs:integer, $payment-id as xs:string?, $process-id as xs:string?, $tolerance as xs:decimal) as element(Group)* {
	let $payment := normalize-space(string($payment-id))
	let $process := normalize-space(string($process-id))
	let $focus-pay := ($model/Pay[@id = $payment])[1]
	let $focus-proc := ($model/Proc[@id = $process])[1]
	let $pays :=
		if ($focus-pay) then $focus-pay
		else if ($focus-proc) then $model/Pay[not($focus-proc/Linked = @id)][local:touches(., $focus-proc)][local:process-candidate(., $focus-proc)]
		else ()
	let $found :=
		for $pay in subsequence($pays, 1, 20)
		let $twin := local:twin($pay, $model/Pay, $before, $after)
		let $procs :=
			if ($focus-proc) then $focus-proc
			else $model/Proc[not(Linked = $pay/@id)][local:touches($pay, .) or ($twin and local:touches($twin, .))]
		for $proc in subsequence($procs, 1, 30)
		return local:one-group($proc, $pay, $twin, $accounts, local:learned-from($past, string($proc/@owner)), $before, $after, $tolerance)
	return (
		$found,
		if ($focus-pay) then local:missing-periodic($focus-pay, $model, $accounts, $found) else ()
	)
};

declare function local:missing-periodic($pay as element(Pay), $model as element(Model), $accounts as element(Account)*, $found as element(Group)*) as element(Group)* {
	for $account in $accounts
	let $hit := local:intervals($account, local:date($pay/@date))[
		exists(PaymentRules/PaymentRule)
		and empty(PaymentRules/PaymentRule[not(local:rule-holds(., $pay))])
	]
	let $owner := string($account/@kto)
	where exists($hit) and empty($found/Process[@owner = $owner]) and empty($model/Proc[@owner = $owner][local:touches($pay, .)])
	return
		<Group kind="part" quality="0">
			{local:payment-view($pay)}
			<Invite task="PeriodicPayment" amount="{format-number(abs(xs:decimal($pay/@match)), '0.00')}" process="" source="{$owner}"/>
			<Reason field="template">Zum Zahlungsintervall von {normalize-space(string($account/Name))} gibt es keinen Vorgang. Angelegt wird er nur auf Klick.</Reason>
		</Group>
};

declare function local:process-candidate($pay as element(Pay), $proc as element(Proc)) as xs:boolean {
	let $side := $proc/Posten[@direction = $pay/@direction][not(@role = 'storno')]
	let $sum := local:sum(for $amount in $side/@amount return xs:decimal($amount))
	let $target := xs:decimal($pay/@match)
	let $notes := string-join(($proc/Note, $proc/Posten/@text, $pay/@purpose), ' ')
	let $fee := abs($target - $sum)
	return exists($side) and (
		local:same($sum, $target)
		or exists($side[local:same(xs:decimal(@amount), $target)])
		or local:skonto-explains($proc, $pay)
		or (local:dunning-word($notes) and $fee gt 0.005 and $fee le 99.99)
	)
};

declare function local:touches($pay as element(Pay), $proc as element(Proc)) as xs:boolean {
	$proc/Posten/@direction = $pay/@direction and (
		$proc/Key = $pay/Key
		or local:phrase-level($pay/@purpose, ($proc/Text, $proc/Note, $proc/Posten/@text, $proc/@ownerName)) = ('done', 'part')
		or exists(($proc/Ref, $proc/@ref)[local:number-hit($pay/@purpose, string(.))])
		or exists($proc/Posten[local:same(abs(xs:decimal(@amount)), abs(xs:decimal($pay/@match)))])
	)
};

declare function local:finish($groups as element(Group)*, $bank as xs:string?, $payment-id as xs:string?, $process-id as xs:string?) as element(Group)* {
	let $payment := normalize-space(string($payment-id))
	let $process := normalize-space(string($process-id))
	let $kept := $groups[
		($payment = '' or Payment/@id = $payment or Offset/@id = $payment)
		and ($process = '' or Process/@id = $process)
	]
	let $ranked :=
		for $group in $kept
		let $level := local:selection-level($group)
		let $rank := if ($level = 'done') then 0 else if ($group/@kind = 'exact') then 1 else if ($group/@kind = 'bundle') then 2 else if ($group/@kind = 'offset') then 3 else 4
		order by $rank
		return element Group {
			$group/@*,
			attribute level {$level},
			attribute auto {'false'},
			$group/*
		}
	let $ready := $ranked[@level = 'done'][not(Invite)]
	let $unique := $ready[
		let $pay := string(Payment/@id)
		let $proc := string(Process/@id)
		return count($ready[Payment/@id = $pay]) = 1 and count($ready[Process/@id = $proc]) = 1
	]
	return
		for $group in $ranked
		return
			if ($group/Payment/@id = $unique/Payment/@id and $group/Process/@id = $unique/Process/@id and $group/@level = 'done' and not($group/Invite)) then
				element Group { $group/@*[not(local-name() = 'auto')], attribute auto {'true'}, $group/* }
			else $group
};

declare function match:check(
	$home-data as xs:string,
	$tenant as xs:string,
	$year as xs:integer,
	$payment-id as xs:string,
	$days-before as xs:integer,
	$days-after as xs:integer,
	$tolerance as xs:decimal,
	$body as element()
) as element(Check) {
	let $model := local:model($home-data, $tenant, $year)
	let $accounts := local:accounts($home-data, $tenant, $year)
	let $pay := $model/Pay[@id = $payment-id]
	let $ids := $body//Posten/string(@id)
	let $posten := $model/Proc/Posten[@id = $ids]
	let $sum := local:sum($posten/@amount ! xs:decimal(.))
	let $target := if ($pay) then xs:decimal($pay/@match) else xs:decimal(0)
	let $rest := $target - $sum
	let $partial := $body/@partial = 'true'
	let $procs := $model/Proc[Posten/@id = $ids]
	let $portions := if ($pay and $partial and not(local:same($rest, 0))) then local:allocate($posten, xs:decimal($pay/@match)) else for $post in $posten return <Portion id="{$post/@id}" amount="{string($post/@amount)}"/>
	return
		<Check payment="{$payment-id}" sum="{format-number($sum, '0.00')}" rest="{format-number($rest, '0.00')}" tolerance="{format-number($tolerance, '0.00')}" level="{if (local:same($rest, 0)) then 'done' else 'part'}" commit="{if ($pay and (local:same($rest, 0) or $partial)) then 'true' else 'false'}">
			{
				for $proc in $procs
				return local:one-group($proc, $pay, local:twin($pay, $model/Pay, $days-before, $days-after), $accounts, (), $days-before, $days-after, $tolerance)
			}
			{
				for $portion in $portions
				let $post := $posten[@id = $portion/@id][1]
				let $proc := $model/Proc[Posten/@id = $post/@id][1]
				let $storno := $post/@role = 'storno'
				let $amount := xs:decimal($portion/@amount)
				where exists($pay) and exists($proc)
				return <Preview process="{$proc/@id}" posten="{$post/@id}" amount="{format-number($amount, '0.00')}" debit="{if ($storno) then $proc/@owner else $pay/@bank}" credit="{if ($storno) then $pay/@bank else $proc/@owner}" description="{normalize-space(string($pay/@purpose))}"/>
			}
		</Check>
};

declare function match:commit(
	$home-data as xs:string,
	$tenant as xs:string,
	$year as xs:integer,
	$payment-id as xs:string,
	$tolerance as xs:decimal,
	$user as xs:string,
	$body as element()
) as element(Committed) {
	let $model := local:model($home-data, $tenant, $year)
	let $pay := ($model/Pay[@id = $payment-id])[1]
	let $ids := $body//Posten/string(@id)
	let $posten := $model/Proc/Posten[@id = $ids]
	let $sum := local:sum($posten/@amount ! xs:decimal(.))
	let $rest := if ($pay) then xs:decimal($pay/@match) - $sum else xs:decimal(1)
	let $partial := $body/@partial = 'true'
	let $actor := local:actor($user)
	let $portions := if ($partial and not(local:same($rest, 0))) then local:allocate($posten, xs:decimal($pay/@match)) else for $post in $posten return <Portion id="{$post/@id}" amount="{string($post/@amount)}"/>
	return
		if (empty($pay)) then <Committed error="Zahlung nicht gefunden."/>
		else if (not(local:same($rest, 0) or $partial)) then <Committed error="Der Rest ist nicht 0,00. Ohne Teilzahlung wird nicht geschrieben." rest="{format-number($rest, '0.00')}"/>
		else
			<Committed rest="{format-number($rest, '0.00')}">{
				for $portion in $portions
				let $post := $posten[@id = $portion/@id][1]
				let $proc := $model/Proc[Posten/@id = $post/@id][1]
				where exists($proc) and abs(xs:decimal($portion/@amount)) ge 0.005
				return local:write-portion($home-data, $tenant, $year, $pay, $proc, xs:decimal($portion/@amount), $post/@role = 'storno', $actor)
			}</Committed>
};

declare function local:write-portion($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $pay as element(Pay), $proc as element(Proc), $portion as xs:decimal, $storno as xs:boolean, $user as xs:string) as element(Applied) {
	let $view := <Process id="{$proc/@id}" owner="{$proc/@owner}" amount="{format-number($portion, '0.00')}" storno="{if ($storno) then 'true' else 'false'}"/>
	let $payment := local:payment-view($pay)
	return local:write-task($home-data, $tenant, $year, $payment, $view, $user)
};

declare function match:invite(
	$home-data as xs:string,
	$tenant as xs:string,
	$year as xs:integer,
	$user as xs:string,
	$body as element()
) as element(Invited) {
	let $process-id := string($body/@process)
	let $node := collection(concat($home-data, '/', $tenant, '/', $year))/Process[@id = $process-id][1]
	let $actor := local:actor($user)
	let $accounts := local:accounts($home-data, $tenant, $year)
	return
		if ($body/@blocked = 'true') then <Invited error="Über dem Limit wird nichts angelegt."/>
		else if ($body/@task = 'PeriodicPayment') then local:insert-periodic($home-data, $tenant, $year, $body, $actor)
		else if (empty($node)) then <Invited error="Vorgang nicht gefunden."/>
		else if ($body/@task = 'CommodityTask') then local:insert-credit($node, $accounts, $body, $actor)
		else if ($body/@task = ('DunningFeeTask', 'DiscountTask')) then local:insert-fee($node, $accounts, $body, $actor)
		else <Invited error="Unbekannter Task."/>
};

declare function local:matching-template($accounts as element(Account)*, $owner as xs:string, $hint as xs:string) as element(ProcessTemplate)? {
	let $account := ($accounts[@kto = $owner])[1]
	let $templates := $account/ProcessTemplates/ProcessTemplate
	let $named := $templates[local:words(Description) = local:words($hint)][normalize-space(Other/@kto) != '']
	return $named[1]
};

declare function local:insert-credit($process as element(Process), $accounts as element(Account)*, $body as element(), $user as xs:string) as element(Invited) {
	let $source := ($process/Tasks/*[@id = $body/@source])[1]
	let $amount := xs:decimal($body/@amount)
	let $owner := string(($process/Tasks/(InvoiceInTask|InvoiceOutTask)/Owner)[1])
	let $template := local:matching-template($accounts, $owner, string($body/@text))
	let $other := string(($template/Other/@kto[normalize-space(.) != ''], $source/Other)[1])
	let $tax := string(($template/Tax/@key[normalize-space(.) != ''], $source/Tax/@key, 'L-19')[1])
	let $booking := ($source/Bookings/Booking)[1]
	let $tax-key := string(($booking/@taxKey, '1')[1])
	let $ref := normalize-space(string($process/Tasks/(InvoiceInTask|InvoiceOutTask)/RefID))
	let $text := concat('Gutschrift ', normalize-space(string(($template/Description[normalize-space(.) != ''], $body/@text)[1])))
	let $task :=
		<CommodityTask type="invoice-in" id="{concat('ACC', util:uuid())}" date="{string($process/@date)}" created="{current-dateTime()}" isMaster="false" user="{$user}" isStorno="true">
			<Notes/>
			<Files/>
			<Bookings>
				<Booking date="{string($process/@date)}" quality="3" amountValue="{format-number($amount, '0.00')}" amountUnit="EUR" credit="{$owner}" debit="{$other}" taxKey="{$tax-key}" taxAmount="0" refID="{$ref}" description="{$text}"/>
			</Bookings>
			<Amount value="{format-number($amount, '0.00')}" unit="EUR"/>
			<Tax key="{$tax}" region="{string(($template/Tax/@region, $source/Tax/@region, 'inland')[1])}" type="{string(($template/Tax/@type, $source/Tax/@type, 'GOODS')[1])}"/>
			<Other>{$other}</Other>
			<Description>{$text}</Description>
		</CommodityTask>
	return
		try {
			let $insert := update insert $task into $process/Tasks
			return <Invited process="{$process/@id}" task="{string($task/@id)}"/>
		} catch * { <Invited error="{$err:description}"/> }
};

declare function local:insert-fee($process as element(Process), $accounts as element(Account)*, $body as element(), $user as xs:string) as element(Invited) {
	let $amount := xs:decimal($body/@amount)
	let $owner := string(($process/Tasks/(InvoiceInTask|InvoiceOutTask)/Owner)[1])
	let $name := string($body/@task)
	let $label := if ($name = 'DiscountTask') then 'Skonto' else 'Mahngebühr'
	let $template := local:matching-template($accounts, $owner, $label)
	let $other := string(($template/Other/@kto[normalize-space(.) != ''], '6430')[1])
	let $tax-key := '1'
	let $out := $amount lt 0
	let $task := element {$name} {
		attribute type { if ($name = 'DiscountTask') then 'discount' else 'dunning-fee' },
		attribute id { concat('ACC', util:uuid()) },
		attribute date { string($process/@date) },
		attribute created { string(current-dateTime()) },
		attribute isMaster { 'false' },
		attribute user { $user },
		attribute isStorno { 'false' },
		<Notes/>,
		<Files/>,
		<Bookings>
			<Booking date="{string($process/@date)}" quality="3" amountValue="{format-number(abs($amount), '0.00')}" amountUnit="EUR" credit="{if ($out) then $other else $owner}" debit="{if ($out) then $owner else $other}" taxKey="{$tax-key}" taxAmount="0" refID="#" description="{$label}"/>
		</Bookings>,
		<Amount value="{format-number($amount, '0.00')}" unit="EUR"/>,
		<RefID>#</RefID>,
		<Description>{$label}</Description>
	}
	return
		try {
			let $insert := update insert $task into $process/Tasks
			return <Invited process="{$process/@id}" task="{string($task/@id)}"/>
		} catch * { <Invited error="{$err:description}"/> }
};

declare function match:save-pattern(
	$home-data as xs:string,
	$tenant as xs:string,
	$year as xs:integer,
	$kto as xs:string,
	$body as element()
) as element(Saved) {
	let $path := concat($home-data, '/', $tenant, '/', $year, '/accounts.dm.xml')
	let $account := doc($path)/Accounts/Account[@kto = $kto][1]
	return
		if (empty($account)) then <Saved error="Kreditor nicht gefunden."/>
		else
			let $pattern :=
				<PeriodicPayment>
					<Name>{normalize-space(string($body/@name))}</Name>
					<Period interval="{string($body/@interval)}" min="1" max="12" amount-min="{string($body/@amount-min)}" amount-max="{string($body/@amount-max)}" valid-from="{string($body/@valid-from)}"/>
					<DocumentTemplate>
						<Section/>
						<Other kto=""/>
						<RefID/>
						<TransactionID/>
						<Description>{string-join($body/Word, ' ')}</Description>
						<Tax key="" region="" type=""/>
						<TotalAmount value="" unit="EUR"/>
						<Appointment date=""/>
						<Notes/>
					</DocumentTemplate>
					<PaymentRules>
						{for $word in $body/Word return <PaymentRule type="SEPA_PAYMENT-DETAILS_ASCII">{string($word)}</PaymentRule>}
					</PaymentRules>
					<Notes>{if (normalize-space(string($body/@payday)) = '') then () else concat('Zahltag ', string($body/@payday))}</Notes>
				</PeriodicPayment>
			return
				try {
					let $box :=
						if ($account/PeriodicPayments) then $account/PeriodicPayments
						else
							let $made := <PeriodicPayments/>
							let $add := update insert $made into $account
							return $account/PeriodicPayments
					let $insert := update insert $pattern into $account/PeriodicPayments
					return <Saved kto="{$kto}"/>
				} catch * { <Saved error="{$err:description}"/> }
};

declare function local:infer-interval($dates as xs:date*) as xs:string {
	let $sorted :=
		for $date in $dates
		order by $date
		return $date
	let $gaps :=
		for $date at $pos in $sorted
		where $pos > 1
		return days-from-duration($date - $sorted[$pos - 1])
	let $ordered :=
		for $gap in $gaps
		order by $gap
		return $gap
	let $mid := if (empty($ordered)) then 30 else $ordered[xs:integer((count($ordered) + 1) idiv 2)]
	return
		if ($mid ge 300) then 'annually'
		else if ($mid ge 70) then 'quarterly'
		else 'monthly'
};

declare function local:payday($dates as xs:date*) as xs:integer? {
	let $days := for $date in $dates return day-from-date($date)
	let $best :=
		for $day in distinct-values($days)
		order by count($days[. = $day]) descending, $day
		return $day
	return if (empty($best)) then () else xs:integer($best[1])
};

declare function local:history($home-data as xs:string, $tenant as xs:string, $year as xs:integer) as element(Past)* {
	let $collection := concat($home-data, '/', $tenant, '/', $year)
	let $index := map:merge(
		for $node in collection($collection)/BankAccount/Accountings/Accounting
		return map:entry(string($node/@id), $node),
		map {'duplicates': 'use-last'}
	)
	for $process in collection($collection)/Process
	let $owner := normalize-space(string(($process/Tasks/(InvoiceInTask|InvoiceOutTask|EmployeeSalaryTask)/Owner)[1]))
	where $owner != ''
	for $task in $process/Tasks/PaymentTask
	let $id := normalize-space(string($task/RefID))
	let $accounting := $index($id)
	let $amount := local:money($task/Amount/@value)
	where $id != '' and exists($accounting) and exists($amount)
	return
		<Past owner="{$owner}" date="{substring(normalize-space(string($accounting/ValueDate)), 1, 10)}" amount="{format-number(abs($amount), '0.00')}" purpose="{normalize-space(string-join(($accounting/CustomerRef[not(. = ('NONREF', 'NOTPROVIDED'))], $accounting/EndToEndRef[not(. = ('NONREF', 'NOTPROVIDED'))], $accounting/PaymentDetail, $accounting/Usage), ' '))}"/>
};

declare function local:learned-from($past as element(Past)*, $owner as xs:string) as element(Learned)? {
	let $rows := $past[@owner = $owner]
	let $count := count($rows)
	where $count ge 3
	let $amounts := for $row in $rows return xs:decimal($row/@amount)
	let $dates := for $row in $rows return local:date($row/@date)
	let $words := local:words(string-join($rows/@purpose, ' '))
	let $stable :=
		for $word in distinct-values($words)
		where count($rows[local:words(@purpose) = $word]) ge 3 and string-length($word) ge 4 and not(matches($word, '^[0-9]+$')) and not($word = ('NONREF', 'NOTPROVIDED'))
		return $word
	return
		<Learned owner="{$owner}" count="{$count}" interval="{local:infer-interval($dates)}" payday="{string(local:payday($dates))}" amount-min="{format-number(min($amounts), '0.00')}" amount-max="{format-number(max($amounts), '0.00')}">
			{for $word in $stable[position() le 6] return <Word>{$word}</Word>}
		</Learned>
};

declare function local:allocate($posten as element(Posten)*, $left as xs:decimal) as element(Portion)* {
	if (empty($posten) or abs($left) lt 0.005) then ()
	else
		let $post := $posten[1]
		let $amount := xs:decimal($post/@amount)
		let $same := ($amount lt 0 and $left lt 0) or ($amount gt 0 and $left gt 0)
		let $take := if (not($same)) then xs:decimal(0) else if (abs($amount) le abs($left)) then $amount else $left
		return (
			if (abs($take) ge 0.005) then <Portion id="{$post/@id}" amount="{format-number($take, '0.00')}"/> else (),
			local:allocate(subsequence($posten, 2), $left - $take)
		)
};

declare function local:insert-periodic($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $body as element(), $user as xs:string) as element(Invited) {
	let $kto := string($body/@source)
	let $payment-id := string($body/@payment)
	let $collection := concat($home-data, '/', $tenant, '/', $year)
	let $accounting := (collection($collection)/BankAccount/Accountings/Accounting[@id = $payment-id])[1]
	let $bank := $accounting/ancestor::BankAccount
	let $account := (local:accounts($home-data, $tenant, $year)[@kto = $kto])[1]
	let $date := local:date($accounting/ValueDate)
	let $open := local:money($accounting/Amount)
	return
		if (empty($accounting) or empty($date) or empty($open) or empty($account)) then <Invited error="Intervall oder Zahlung nicht gefunden."/>
		else
			let $pay := local:pay($bank, $accounting, $open, $date, ())
			let $periodic := (local:intervals($account, $date)[exists(PaymentRules/PaymentRule) and empty(PaymentRules/PaymentRule[not(local:rule-holds(., $pay))])])[1]
			return
				if (empty($periodic)) then <Invited error="Kein passendes Zahlungsintervall."/>
				else
					let $direction := local:pay-direction(normalize-space(string($accounting/Amount/@type)), $open)
					let $signed := local:signed($direction, abs($open))
					let $template := $periodic/DocumentTemplate
					let $other := string(($template/Other/@kto[normalize-space(.) != ''], '6850')[1])
					let $tax := string(($template/Tax/@key[normalize-space(.) != ''], 'L-19')[1])
					let $region := string(($template/Tax/@region[normalize-space(.) != ''], 'inland')[1])
					let $kind := string(($template/Tax/@type[normalize-space(.) != ''], 'GOODS')[1])
					let $text := normalize-space(string(($template/Description[normalize-space(.) != ''], $account/Name, 'Dauerbezug')[1]))
					let $binder := format-date($date, '[M01]')
					let $id := concat('PRO', util:uuid())
					let $name := substring(replace(concat(string($date), '_Dauerbezug_', $kto), '[^A-Za-z0-9_\-]', '-'), 1, 80)
					let $out := $direction = 'out'
					let $process :=
						<Process id="{$id}" name="{$name}" binder="{$binder}" date="{string($date)}" user="{$user}" created="{current-dateTime()}">
							<Section/>
							<TotalAmount value="{format-number($signed, '0.00')}"/>
							<Tasks>
								<InvoiceInTask type="invoice-in" id="{concat('ACC', util:uuid())}" date="{string($date)}" created="{current-dateTime()}" isMaster="true" user="{$user}" isStorno="false">
									<Notes/>
									<Files>
										<File archived="false" doctype="digital" fileExtension=".pdf" fileName="{$payment-id}" mimeType="application/pdf" src="{concat('/', $tenant, '/', $year, '/banking/', $bank/@kto, '/', $payment-id, '/periodic-payment.pdf')}" type="doc-periodic-payment" uploadName="{$payment-id}"/>
									</Files>
									<Bookings/>
									<Amount value="{format-number($signed, '0.00')}" unit="EUR"/>
									<Owner>{$kto}</Owner>
									<RefID>{normalize-space(string($template/RefID))}</RefID>
									<TransactionID>{normalize-space(string($template/TransactionID))}</TransactionID>
									<Description>{$text}</Description>
								</InvoiceInTask>
								<CommodityTask type="invoice-in" id="{concat('ACC', util:uuid())}" date="{string($date)}" created="{current-dateTime()}" isMaster="false" user="{$user}" isStorno="false">
									<Notes/>
									<Files/>
									<Bookings>
										<Booking date="{string($date)}" quality="3" amountValue="{format-number(abs($signed), '0.00')}" amountUnit="EUR" credit="{if ($out) then $other else $kto}" debit="{if ($out) then $kto else $other}" taxKey="1" taxAmount="0" refID="{normalize-space(string($template/RefID))}" description="{$text}"/>
									</Bookings>
									<Amount value="{format-number($signed, '0.00')}" unit="EUR"/>
									<Tax key="{$tax}" region="{$region}" type="{$kind}"/>
									<Other>{$other}</Other>
									<Description>{$text}</Description>
								</CommodityTask>
							</Tasks>
							<Notes>Dauerbezug aus dem Zahlungsintervall. Zahltag noch nicht verbucht.</Notes>
						</Process>
					return
						try {
							let $path := concat($collection, '/', $binder)
							let $file := concat($name, '.dm.xml')
							let $stored := xmldb:store($path, $file, $process)
							let $uri := xs:anyURI(concat($path, '/', $file))
							let $mode := sm:chmod($uri, 'rwxrwxr-x')
							let $group := sm:chgrp($uri, 'docman')
							return <Invited process="{$id}" task="PeriodicPayment"/>
						} catch * { <Invited error="{$err:description}"/> }
};

declare function match:pattern-preview($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $kto as xs:string) as element(Pattern) {
	let $learned := local:learned-from(local:history($home-data, $tenant, $year), $kto)
	return
		<Pattern kto="{$kto}" count="{string($learned/@count)}" interval="{if ($learned) then string($learned/@interval) else 'monthly'}" payday="{string($learned/@payday)}" amount-min="{string($learned/@amount-min)}" amount-max="{string($learned/@amount-max)}" valid-from="{substring(string(current-date()), 1, 10)}">
			{$learned/Word}
		</Pattern>
};
