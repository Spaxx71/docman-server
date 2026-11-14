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

xquery version "3.0";


(:

https://dev.bintellix.com/exist-backend/rest/db/apps/docman/modules/mail/mail_index.xqy

:)

import module namespace email="http://bintellix.com/docman/email" at "/db/apps/docman/modules/module_email.xqm";

declare namespace mail = "http://exist-db.org/xquery/mail";

declare function local:host($value as xs:string?) as xs:string {
	let $raw := lower-case(normalize-space(string($value)))
	let $without-scheme := replace($raw, '^https?://', '')
	let $host := tokenize(tokenize($without-scheme, '/')[1], ':')[1]
	return replace($host, '^www\.', '')
};

declare function local:sender-email($from as xs:string) as xs:string {
	let $found := analyze-string($from, '[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}')
	return lower-case(string(($found//fn:match)[1]))
};

declare function local:role($account as element(Account)) as xs:string {
	let $classes := tokenize(normalize-space(string($account/@classes)), '\s+')
	return
		if ($classes = 'debitor' and $classes = 'creditor') then 'Debitor/Kreditor'
		else if ($classes = 'debitor') then 'Debitor'
		else if ($classes = 'creditor') then 'Kreditor'
		else 'Personenkonto'
};

declare function local:party($account as element(Account)) as element(party) {
	<party id="{string($account/@id)}" name="{string($account/Name)}" role="{local:role($account)}" email="{string($account/Contact/Email)}" website="{string($account/Contact/Website)}">{
		lower-case(string-join((
			$account/@id, $account/Name, $account/Company/Name, $account/Person/Vorname, $account/Person/Nachname,
			$account/Contact/Email, $account/Contact/Website, local:role($account)
		), ' '))
	}</party>
};

declare function local:people($home-data as xs:string, $tenant as xs:string, $year as xs:string) as element(party)* {
	let $doc := doc($home-data || '/' || $tenant || '/' || $year || '/accounts.dm.xml')
	for $account in $doc/Accounts/Account[@type = 'ledger_account' or tokenize(normalize-space(string(@classes)), '\s+') = ('creditor', 'debitor')]
	order by string($account/Name)
	return local:party($account)
};

declare function local:match($email as xs:string, $parties as element(party)*) as element(party)? {
	let $domain := substring-after($email, '@')
	where $email != ''
	let $exact := $parties[local:emails-of(.) = $email][1]
	let $by-domain :=
		if ($domain = '') then ()
		else $parties[local:host(@website) = $domain or local:host(@email) = $domain or (some $known in local:emails-of(.) satisfies substring-after($known, '@') = $domain)][1]
	return ($exact, $by-domain)[1]
};

declare function local:emails-of($party as element(party)) as xs:string* {
	for $part in tokenize(lower-case(string($party/@email)), '[;,\s]+')
	let $email := local:sender-email($part)
	where $email != ''
	return $email
};

declare function local:annotate($message as element(), $parties as element(party)*) as element() {
	let $types :=
		for $type in $message/*:flags/*:flag/@type
		return lower-case(string($type))
	let $from := string($message/*:from[1])
	let $address := local:sender-email($from)
	let $matched := local:match($address, $parties)
	return
		element { node-name($message) } {
			$message/@*,
			attribute unread { not($types = 'seen') },
			attribute flagged { $types = 'flagged' },
			attribute erledigt { $types = 'erledigt' },
			$message/node(),
			<party email="{$address}" domain="{substring-after($address, '@')}" matched="{exists($matched)}" id="{string($matched/@id)}" name="{string($matched/@name)}" role="{string($matched/@role)}"/>
		}
};

declare function local:remember-email($account as element(Account), $address as xs:string) as element() {
	let $known :=
		for $part in tokenize(lower-case(string($account/Contact/Email)), '[;,\s]+')
		return local:sender-email($part)
	return
		if ($address = $known) then
			<ok/>
		else if (exists($account/Contact/Email)) then
			if (normalize-space(string($account/Contact/Email)) = '') then (
				update value $account/Contact/Email with $address,
				<ok/>
			) else (
				update value $account/Contact/Email with concat(string($account/Contact/Email), '; ', $address),
				<ok/>
			)
		else if (exists($account/Contact)) then (
			update insert <Email>{$address}</Email> into $account/Contact,
			<ok/>
		) else (
			update insert <Contact><Vorname/><Nachname/><Email>{$address}</Email><Website/><Telefon/></Contact> into $account,
			<ok/>
		)
};

declare function local:link($home-data as xs:string, $tenant as xs:string, $year as xs:string) as element()? {
	if (request:get-method() != 'POST') then
		()
	else
		let $id := normalize-space(request:get-parameter('link-account', ''))
		let $address := local:sender-email(request:get-parameter('link-email', ''))
		let $account :=
			if ($id = '' or $address = '') then ()
			else
				try {
					doc($home-data || '/' || $tenant || '/' || $year || '/accounts.dm.xml')/Accounts/Account[string(@id) = $id][@type = 'ledger_account' or tokenize(normalize-space(string(@classes)), '\s+') = ('creditor', 'debitor')]
				} catch * { () }
		return
			if (empty($account)) then
				<error>Das Personenkonto wurde nicht gefunden.</error>
			else
				local:remember-email($account, $address)
};

let $tenant := string(request:get-attribute('tenant'))
let $year := string(request:get-attribute('year'))
let $home-data := string(request:get-attribute('home-data'))
let $gui := string(request:get-attribute('home-web-gui'))
let $linked := local:link($home-data, $tenant, $year)
return
	if ($linked/self::ok) then
		response:redirect-to(xs:anyURI(concat($gui, '/', $tenant, '/', $year, '/mail/index.html')))
	else
		let $mail := email:read-emails($tenant)
		let $parties := try { local:people($home-data, $tenant, $year) } catch * { () }
		let $messages := $mail//*:messages[1]
		return
			if ($mail/self::error) then
				$mail
			else
				<result folder="{string($mail/@folder)}">{
					$linked/self::error,
					<parties>{$parties}</parties>,
					if (empty($messages)) then ()
					else
						element { node-name($messages) } {
							$messages/@*,
							for $message in $messages/*:message
							return local:annotate($message, $parties)
						}
				}</result>