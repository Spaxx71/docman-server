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

module namespace email = "http://bintellix.com/docman/email";

import module namespace process="http://exist-db.org/xquery/process";
import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";

declare namespace mail = "http://exist-db.org/xquery/mail";


declare function local:replaceAttributeValue($node as item(), $attributeName as xs:string, $attributeOldValue as xs:string, $attributeNewValue as xs:string) {

	if ($node instance of document-node()) then
		local:replaceAttributeValue($node/*, $attributeName, $attributeOldValue, $attributeNewValue)
	else if ($node instance of element()) then
		element {$node/name()} {
			for $attribute in $node/@*
			return
				if ($attribute/name()=$attributeName and $attribute/data() = $attributeOldValue) then
					attribute {$attributeName} {$attributeNewValue}
				else
					$attribute
			,
			for $subnode in $node/node()
			return
				local:replaceAttributeValue($subnode, $attributeName, $attributeOldValue, $attributeNewValue)
		}
	else if($node instance of comment()) then 
		comment { ' ' }
	else if($node instance of text()) then 
		$node
	else
		$node
};


declare function local:cleanupNamespace($n as node()) as node() {
	if($n instance of element()) then (
		element { if (namespace-uri($n) = '') then local-name($n) else node-name($n) } 
		{
			for $attribute in $n/@*
			return 
				attribute { if (namespace-uri($attribute) = '') then replace(local-name($attribute),'[^A-Za-z0-9+]','-') else replace(node-name($attribute),'[^A-Za-z0-9+]','-') } { $attribute/data() }
			,
			for $node in $n/node()
			return
				local:cleanupNamespace($node)
		}
	) else if($n instance of document-node()) then (
		document { local:cleanupNamespace($n/node()) }
	) else if($n instance of comment()) then (
		comment { ' ' }
	) else if($n instance of text()) then (
		$n
    ) else (
		$n
	)
};

(: Liest IMAP-Zugang aus tenant.dm.xml/EmailAccount; Fallback für bisher hartcodierte Mandanten. :)
declare function local:mailbox($tenant as xs:string) as element()? {
	let $email := doc($main:home-data||'/'||$tenant||'/tenant.dm.xml')/Tenant/EmailAccount
	let $host := normalize-space(string($email/Hostname))
	let $user := normalize-space(string($email/Username))
	let $password := string($email/Password)
	let $tls :=
		let $mode := lower-case(normalize-space(string($email/TlsMode)))
		return
			if ($mode = ('tls', 'starttls', 'none')) then $mode
			else 'tls'
	let $port :=
		let $raw := normalize-space(string($email/Port))
		return
			if ($raw castable as xs:integer) then $raw
			else if ($tls = 'tls') then '993'
			else '143'
	let $protocol := if ($tls = 'tls') then 'imaps' else 'imap'
	return
		if ($host != '' and $user != '' and normalize-space($password) != '') then
			<mailbox host="{$host}" port="{$port}" user="{$user}" password="{$password}" protocol="{$protocol}" tls="{$tls}"/>
		else if ($tenant = ('bintellix', 'intersecurity')) then
			(: Legacy-Fallback bis die Einstellungen gespeichert sind :)
			let $CryptoValue := "dTNqS0x1M2ozaDNmbjJqbjNKa2wx"
			return
				<mailbox host="imap.bintellix.com" port="993" user="accounting@bintellix.com" password="{util:base64-decode($CryptoValue)}" protocol="imaps" tls="tls"/>
		else
			()
};

declare function local:mail-properties($tenant as xs:string) as element(properties)? {
	let $box := local:mailbox($tenant)
	return
		if (empty($box)) then
			()
		else
			let $tls := string($box/@tls)
			let $proto := string($box/@protocol)
			let $port := string($box/@port)
			return
				<properties>
					<property name="mail.debug" value="false"/>
					<property name="mail.store.protocol" value="{$proto}"/>
					{
						if ($tls = 'tls') then (
							<property name="mail.imaps.host" value="{string($box/@host)}"/>,
							<property name="mail.imaps.port" value="{$port}"/>,
							<property name="mail.imaps.user" value="{string($box/@user)}"/>,
							<property name="mail.imaps.password" value="{string($box/@password)}"/>,
							<property name="mail.imaps.ssl.enable" value="true"/>
						)
						else if ($tls = 'starttls') then (
							<property name="mail.imap.host" value="{string($box/@host)}"/>,
							<property name="mail.imap.port" value="{$port}"/>,
							<property name="mail.imap.user" value="{string($box/@user)}"/>,
							<property name="mail.imap.password" value="{string($box/@password)}"/>,
							<property name="mail.imap.ssl.enable" value="false"/>,
							<property name="mail.imap.starttls.enable" value="true"/>,
							<property name="mail.imap.starttls.required" value="true"/>
						)
						else (
							<property name="mail.imap.host" value="{string($box/@host)}"/>,
							<property name="mail.imap.port" value="{$port}"/>,
							<property name="mail.imap.user" value="{string($box/@user)}"/>,
							<property name="mail.imap.password" value="{string($box/@password)}"/>,
							<property name="mail.imap.ssl.enable" value="false"/>,
							<property name="mail.imap.starttls.enable" value="false"/>
						)
					}
				</properties>
};

declare function local:folder-name($folder as xs:string?) as xs:string {
	let $name := if (normalize-space(string($folder)) = '') then 'INBOX' else normalize-space(string($folder))
	return
		if (matches($name, '^[A-Za-z0-9][A-Za-z0-9_./\-]*$') and not(contains($name, '..'))) then
			$name
		else
			error(xs:QName('email:invalid-folder'), concat('Ungültiger Ordnername: ', $name))
};

declare function local:flag-value($value as xs:string?) as xs:boolean? {
	let $text := lower-case(normalize-space(string($value)))
	return
		if ($text = '') then
			()
		else if ($text = ('true', '1', 'yes', 'ja')) then
			true()
		else if ($text = ('false', '0', 'no', 'nein')) then
			false()
		else
			error(xs:QName('email:invalid-flag'), concat('Flagwert muss true oder false sein: ', $value))
};

declare function local:imap-escape($value as xs:string) as xs:string {
	replace(replace($value, '\\', '\\\\'), '"', '\\"')
};

declare function local:imap-quote($value as xs:string) as xs:string {
	concat('"', local:imap-escape($value), '"')
};

declare function local:imap-unquote($value as xs:string) as xs:string {
	let $raw := normalize-space($value)
	return
		if (starts-with($raw, '"') and ends-with($raw, '"') and string-length($raw) ge 2) then
			replace(replace(substring($raw, 2, string-length($raw) - 2), '\\"', '"'), '\\\\', '\\')
		else
			$raw
};

(: SELECT "INBOX" merkt sich den Ordner für die folgenden Befehle. :)
declare function local:selected-mailbox($command as xs:string) as xs:string? {
	if (not(matches($command, '^(SELECT|EXAMINE)\s+\S'))) then
		()
	else
		local:imap-unquote(replace($command, '^(SELECT|EXAMINE)\s+', ''))
};

(: Diese Befehle gelten nur in einer bereits gewählten Mailbox. :)
declare function local:needs-selected-mailbox($command as xs:string) as xs:boolean {
	matches($command, '^(UID\s+)?(STORE|FETCH|COPY|EXPUNGE|SEARCH|MOVE)\s')
};

declare function local:imap-url($box as element(mailbox), $mailbox as xs:string?) as xs:string {
	let $scheme := if (string($box/@protocol) = 'imap') then 'imap' else 'imaps'
	let $port := normalize-space(string($box/@port))
	let $authority :=
		if ($port = '') then string($box/@host)
		else concat(string($box/@host), ':', $port)
	return
		if (normalize-space(string($mailbox)) = '') then
			concat($scheme, '://', $authority, '/')
		else
			concat($scheme, '://', $authority, '/', $mailbox)
};

(:
	curl wertet nur ein --request aus und wählt die Mailbox nur, wenn sie im URL-Pfad steht.
	Jeder Befehl läuft deshalb einzeln. Sonst antwortet der Server mit NO und curl mit Fehler 21.
:)
declare function local:imap-exec($box as element(mailbox), $mailbox as xs:string?, $command as xs:string) as element(imap) {
	let $user-line := concat('user = "', local:imap-escape(string($box/@user)), ':', local:imap-escape(string($box/@password)), '"')
	let $selected := if (local:needs-selected-mailbox($command)) then $mailbox else ()
	let $args := (
		'curl', '--silent', '--show-error', '--max-time', '30', '--config', '-',
		'--url', local:imap-url($box, $selected),
		'--request', $command
	)
	let $run := process:execute($args, <options><stdin><line>{$user-line}</line></stdin></options>)
	let $lines := (
		for $line in $run/stdout/line return string($line),
		for $line in $run/stderr/line return string($line)
	)
	let $safe :=
		for $line in $lines
		where not(contains($line, string($box/@password))) and not(contains($line, string($box/@user)))
		return $line
	let $failure :=
		for $line in $safe
		where matches($line, '(^|[ *])(NO|BAD)( |$)')
		return $line
	return
		if (xs:integer($run/@exitCode) ne 0 or exists($failure)) then
			<imap ok="false"><error>{concat($command, ': ', string(($failure, $safe, 'IMAP-Befehl fehlgeschlagen')[1]))}</error></imap>
		else
			<imap ok="true">{
				for $line in $safe
				return <line>{$line}</line>
			}</imap>
};

declare function local:imap-chain($box as element(mailbox), $mailbox as xs:string?, $commands as xs:string*) as element(imap) {
	if (empty($commands)) then
		<imap ok="true"/>
	else
		let $command := string($commands[1])
		let $opened := local:selected-mailbox($command)
		let $active := ($opened, $mailbox)[1]
		let $run :=
			if (local:needs-selected-mailbox($command) and normalize-space(string($active)) = '') then
				<imap ok="false"><error>IMAP-Befehl benötigt einen ausgewählten Ordner: {$command}</error></imap>
			else
				local:imap-exec($box, $active, $command)
		return
			if ($run/@ok = 'false') then
				$run
			else
				let $rest := local:imap-chain($box, $active, subsequence($commands, 2))
				return
					if ($rest/@ok = 'false') then
						$rest
					else
						<imap ok="true">{
							$run/line,
							$rest/line
						}</imap>
};

declare function local:imap($box as element(mailbox), $commands as xs:string+) as element(imap) {
	local:imap-chain($box, (), $commands)
};

declare function local:flag-command($number as xs:integer, $flag as xs:string, $value as xs:boolean?) as xs:string? {
	if (empty($value)) then
		()
	else
		concat('STORE ', $number, if ($value) then ' +FLAGS (' else ' -FLAGS (', $flag, ')')
};

declare function local:list-name($line as xs:string) as xs:string? {
	if (not(starts-with($line, '* LIST '))) then
		()
	else
		let $raw := replace($line, '^\* LIST \(.*\) \S+ ', '')
		return
			if (starts-with($raw, '"')) then
				replace(substring($raw, 2, string-length($raw) - 2), '\\"', '"')
			else
				normalize-space($raw)
};

declare function email:read-emails($tenant as xs:string) as item() {
	email:read-emails($tenant, 'INBOX')
};

declare function email:read-emails($tenant as xs:string, $folder as xs:string) as item() {
	let $MailProperties := local:mail-properties($tenant)
	return
		if (empty($MailProperties)) then
			<error>Kein Postfach für Mandant {$tenant} konfiguriert.</error>
		else
			let $lMailSessionHandle := mail:get-mail-session($MailProperties)

	let $lMailStoreHandle := mail:get-mail-store($lMailSessionHandle)

	let $folder-name := local:folder-name($folder)
	let $lMailFolderHandle := mail:get-mail-folder($lMailStoreHandle, $folder-name) 

	let $lMessageListHandle := mail:get-message-list($lMailFolderHandle)

	let $MessageList := mail:get-message-list-as-xml($lMessageListHandle, false())

	return 
	(: 
		mail:search-message-list()
	:)
		<result folder="{$folder-name}">	
			{$MessageList}

			{mail:close-message-list($lMessageListHandle)}
			{mail:close-mail-folder($lMailFolderHandle, false())}
			{mail:close-mail-store($lMailStoreHandle)}
		</result>	
};

declare function local:sent-by-servers($folder as xs:long, $message as element()?) as xs:string* {
	let $sent := normalize-space(string($message/*:sent[1]))
	let $number := string($message/@number)
	where $message and $sent and $number
	return
		try {
			let $search := <searchTerm type="sent" comparison="eq" format="yyyy-MM-dd" date="{substring($sent, 1, 10)}"/>
			let $handle := mail:search-message-list($folder, $search)
			let $listed := mail:get-message-list-as-xml($handle, true())
			let $hosts :=
				for $header in $listed//*:message[string(@number) = $number]/*:headers/*:header[lower-case(string(@name)) = 'received']
				let $after := tokenize(concat(' ', string($header/@value)), '\sby\s+')[2]
				let $host := replace(tokenize(normalize-space($after), '[^A-Za-z0-9.\-]+')[1], '^\.+|\.+$', '')
				where $host and matches($host, '[A-Za-z]')
				return $host
			let $unique := fold-left($hosts, (), function($found, $host) {
				if ($host = $found) then $found else ($found, $host)
			})
			return (mail:close-message-list($handle), $unique)
		} catch * {
			()
		}
};

declare function local:with-sent-by($node as node(), $servers as xs:string*) as node() {
	if (empty($servers)) then
		$node
	else if ($node instance of document-node()) then
		document {
			for $child in $node/node()
			return local:with-sent-by($child, $servers)
		}
	else if ($node instance of element() and local-name($node) = 'message') then
		element { node-name($node) } {
			$node/@*,
			$node/node(),
			element { QName(namespace-uri($node), 'received-by') } {
				for $server in $servers
				return element { QName(namespace-uri($node), 'server') } { $server }
			}
		}
	else if ($node instance of element()) then
		element { node-name($node) } {
			$node/@*,
			for $child in $node/node()
			return local:with-sent-by($child, $servers)
		}
	else
		$node
};

declare function email:read-message($tenant as xs:string, $id as xs:integer) as item() {
	email:read-message($tenant, $id, 'INBOX')
};

declare function email:read-message($tenant as xs:string, $id as xs:integer, $folder as xs:string) as item() {
	let $MailProperties := local:mail-properties($tenant)
	return
		if (empty($MailProperties)) then
			<error>Kein Postfach für Mandant {$tenant} konfiguriert.</error>
		else
			let $lMailSessionHandle := mail:get-mail-session($MailProperties)

	let $lMailStoreHandle := mail:get-mail-store($lMailSessionHandle)

	let $folder-name := local:folder-name($folder)
	let $lMailFolderHandle := mail:get-mail-folder($lMailStoreHandle, $folder-name) 

	let $lMessageListHandle := mail:get-message-list($lMailFolderHandle)

	let $cleaned := local:replaceAttributeValue(local:cleanupNamespace(mail:get-messages($lMailFolderHandle, ($id))), 'mime-type', 'application/octet-stream', 'application/pdf')
	let $message := if ($cleaned instance of document-node()) then $cleaned//*:message[1] else $cleaned//*:message[1]
	let $servers := local:sent-by-servers($lMailFolderHandle, $message)

	return 
		<result i="{$id}" folder="{$folder-name}">	
			{local:with-sent-by($cleaned, $servers)}

			{mail:close-message-list($lMessageListHandle)}
			{mail:close-mail-folder($lMailFolderHandle, false())}
			{mail:close-mail-store($lMailStoreHandle)}
		</result>	
};


declare function email:read-attachment($tenant as xs:string, $mail-id as xs:integer, $att-number as xs:integer) as item() {
	email:read-attachment($tenant, $mail-id, $att-number, 'INBOX')
};

declare function email:read-attachment($tenant as xs:string, $mail-id as xs:integer, $att-number as xs:integer, $folder as xs:string) as item() {
	let $MailProperties := local:mail-properties($tenant)
	return
		if (empty($MailProperties)) then
			<error>Kein Postfach für Mandant {$tenant} konfiguriert.</error>
		else
			let $lMailSessionHandle := mail:get-mail-session($MailProperties)

	let $lMailStoreHandle := mail:get-mail-store($lMailSessionHandle)

	let $folder-name := local:folder-name($folder)
	let $lMailFolderHandle := mail:get-mail-folder($lMailStoreHandle, $folder-name) 

	let $lMessageListHandle := mail:get-message-list($lMailFolderHandle)

	let $Messages := local:cleanupNamespace(mail:get-messages($lMailFolderHandle, ($mail-id)))

	return 
		<result id="{$mail-id}" att-number="{$att-number}" folder="{$folder-name}">
			{local:replaceAttributeValue($Messages/mail:message/mail:attachment[$att-number], 'mime-type', 'application/octet-stream', 'application/pdf')}

			{mail:close-message-list($lMessageListHandle)}
			{mail:close-mail-folder($lMailFolderHandle, false())}
			{mail:close-mail-store($lMailStoreHandle)}
		</result>	
};

declare function email:list-folders($tenant as xs:string) as element() {
	let $box := local:mailbox($tenant)
	return
		if (empty($box)) then
			<error>Kein Postfach für Mandant {$tenant} konfiguriert.</error>
		else
			let $listed := local:imap($box, ('LIST "" "*"'))
			return
				if ($listed/@ok = 'false') then
					<error>{string($listed/error)}</error>
				else
					<folders>{
						for $name in distinct-values(
							for $line in $listed/line
							return local:list-name(string($line))
						)
						where $name != ''
						order by $name
						return <folder>{$name}</folder>
					}</folders>
};

declare function local:imap-day($year as xs:integer, $month as xs:integer, $day as xs:integer) as xs:string {
	let $months := ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec')
	return concat(string($day), '-', $months[$month], '-', string($year))
};

(: Offene Nachrichten des Jahres: im Posteingang, ohne Kennzeichen erledigt. :)
declare function email:count-unfinished($tenant as xs:string, $year as xs:integer) as xs:integer {
	let $box := local:mailbox($tenant)
	let $search := concat(
		'SEARCH UNKEYWORD erledigt SINCE ', local:imap-day($year, 1, 1),
		' BEFORE ', local:imap-day($year + 1, 1, 1)
	)
	return
		if (empty($box)) then
			0
		else
			try {
				let $found := local:imap($box, ('SELECT "INBOX"', $search))
				let $text := normalize-space(string-join($found/line[contains(., 'SEARCH')], ' '))
				let $ids := tokenize(substring-after($text, 'SEARCH'), '\s+')[matches(., '^\d+$')]
				return
					if ($found/@ok = 'false') then
						0
					else
						count($ids)
			} catch * {
				0
			}
};

declare function email:set-flags($tenant as xs:string, $folder as xs:string, $number as xs:integer, $seen as xs:string?, $flagged as xs:string?, $erledigt as xs:string?) as element() {
	let $box := local:mailbox($tenant)
	let $folder-name := local:folder-name($folder)
	let $seen-value := local:flag-value($seen)
	let $flagged-value := local:flag-value($flagged)
	let $erledigt-value := local:flag-value($erledigt)
	return
		if (empty($box)) then
			<error>Kein Postfach für Mandant {$tenant} konfiguriert.</error>
		else if ($number lt 1) then
			<error>Die Nachrichtennummer muss größer als 0 sein.</error>
		else if (empty(($seen-value, $flagged-value, $erledigt-value))) then
			<error>Mindestens eines der Flags seen, flagged oder erledigt muss gesetzt werden.</error>
		else
			let $selected := local:imap($box, (concat('SELECT ', local:imap-quote($folder-name))))
			let $permanent := string-join($selected/line, ' ')
			return
				if ($selected/@ok = 'false') then
					<error>{string($selected/error)}</error>
				else if (exists($erledigt-value) and not(contains($permanent, '\*'))) then
					<error>Das Postfach erlaubt keine eigenen IMAP-Kennzeichen. Erledigt kann nicht gespeichert werden.</error>
				else
					let $done := local:imap($box, (
						concat('SELECT ', local:imap-quote($folder-name)),
						local:flag-command($number, '\Seen', $seen-value),
						local:flag-command($number, '\Flagged', $flagged-value),
						local:flag-command($number, 'erledigt', $erledigt-value),
						concat('FETCH ', $number, ' (FLAGS)')
					))
					let $flags := string($done/line[matches(string(.), '^\* \d+ FETCH \(FLAGS')][last()])
					return
						if ($done/@ok = 'false') then
							<error>{string($done/error)}</error>
						else
							<result folder="{$folder-name}" number="{$number}" reload="true">
								<flag name="seen" value="{matches($flags, '\\Seen(\s|\)|$)')}"/>
								<flag name="flagged" value="{matches($flags, '\\Flagged(\s|\)|$)')}"/>
								<flag name="erledigt" value="{matches($flags, '(^|[ (\(])erledigt(\s|\)|$)')}"/>
							</result>
};

declare function email:move-message($tenant as xs:string, $folder as xs:string, $number as xs:integer, $to as xs:string) as element() {
	let $box := local:mailbox($tenant)
	let $source-name := local:folder-name($folder)
	let $target-name := local:folder-name($to)
	return
		if (empty($box)) then
			<error>Kein Postfach für Mandant {$tenant} konfiguriert.</error>
		else if ($number lt 1) then
			<error>Die Nachrichtennummer muss größer als 0 sein.</error>
		else if ($target-name = $source-name) then
			<error>Quell- und Zielordner sind identisch.</error>
		else
			let $capability := local:imap($box, ('CAPABILITY'))
			let $target-quote := local:imap-quote($target-name)
			let $source-quote := local:imap-quote($source-name)
			return
				if ($capability/@ok = 'false') then
					<error>{string($capability/error)}</error>
				else if (not(contains(string-join($capability/line, ' '), 'UIDPLUS'))) then
					<error>Das Postfach unterstützt kein UIDPLUS. Die Nachricht kann nicht einzeln aus dem Quellordner gelöscht werden.</error>
				else
					let $source-present := local:imap($box, (concat('LIST "" ', $source-quote)))
					let $source-exists := some $line in $source-present/line satisfies starts-with(normalize-space(string($line)), '* LIST')
					return
						if ($source-present/@ok = 'false' or not($source-exists)) then
							<error>Ordner "{$source-name}" existiert nicht.</error>
						else
							let $present := local:imap($box, (concat('LIST "" ', $target-quote)))
							let $created := not(some $line in $present/line satisfies starts-with(normalize-space(string($line)), '* LIST'))
							let $make :=
								if ($present/@ok = 'false') then
									$present
								else if (not($created)) then
									<imap ok="true"/>
								else
									local:imap($box, (concat('CREATE ', $target-quote)))
							return
								if ($make/@ok = 'false') then
									<error>Zielordner "{$target-name}" konnte nicht angelegt werden. {string($make/error)}</error>
								else
									let $copied := local:imap($box, (
										concat('SELECT ', $source-quote),
										concat('COPY ', $number, ' ', $target-quote),
										concat('FETCH ', $number, ' (UID)')
									))
									let $uid := replace(string($copied/line[contains(., 'FETCH') and contains(., 'UID')][1]), '^.*\(UID\s+(\d+).*$', '$1')
									return
										if ($copied/@ok = 'false') then
											<error>{string($copied/error)}</error>
										else if (not(matches($uid, '^\d+$'))) then
											<error>Die Nachricht wurde kopiert, die UID fehlt aber. Sie wurde im Quellordner nicht gelöscht.</error>
										else
											let $removed := local:imap($box, (
												concat('SELECT ', $source-quote),
												concat('UID STORE ', $uid, ' +FLAGS (\Deleted)'),
												concat('UID EXPUNGE ', $uid)
											))
											return
												if ($removed/@ok = 'false') then
													<error>Die Nachricht liegt im Zielordner, konnte im Quellordner aber nicht gelöscht werden. {string($removed/error)}</error>
												else
													<result folder="{$source-name}" number="{$number}" to="{$target-name}" status="moved" created="{$created}" reload="true">
														Die Nachrichtennummer gilt nur im Ordner "{$source-name}" und kann sich im Zielordner ändern.
													</result>
};


