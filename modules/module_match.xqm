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
	let $groups := local:groups($model, $days-before, $days-after, $payment-id, $process-id, $tolerance)
	let $filtered := local:filter($groups, $bank, $payment-id, $process-id)
	let $anchor-pay := $model/Pay[@id = $payment-id]
	let $anchor-proc := $model/Proc[@id = $process-id]
	let $cluster :=
		if ($anchor-pay) then count($model/Proc[local:related($anchor-pay, .)])
		else if ($anchor-proc) then count($model/Pay[local:related(., $anchor-proc)])
		else count($model/Proc)
	return
		<Suggestions days-before="{$days-before}" days-after="{$days-after}" tolerance="{format-number($tolerance, '0.00')}" cluster="{$cluster}">
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
		if (local:contains($pay/@purpose, $proc/@employee, 4)) then 'done'
		else if (local:contains($pay/@purpose, $proc/@month, 2)) then 'part'
		else 'none'
	else if (local:any-contains($pay/@purpose, $proc/Text, 6)) then 'done'
	else if (local:word-hit($pay/@purpose, $proc/Text)) then 'part'
	else 'none'
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
	let $date-level := if ($days = 0) then 'done' else if ($window) then 'part' else 'none'
	return (
		<Mark field="amount" level="{$amount-level}"/>,
		<Mark field="date" level="{$date-level}" days="{$days}"/>,
		if ($proc/@salary = 'true') then ()
		else (
			<Mark field="reference" level="{if (local:any-contains($pay/@purpose, $proc/Ref, 6)) then 'done' else 'none'}"/>,
			<Mark field="transaction" level="{if (local:any-contains($pay/@purpose, $proc/Trans, 6)) then 'done' else 'none'}"/>
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
		where $hit or $window or abs($diff) le 1
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
