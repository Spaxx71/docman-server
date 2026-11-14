xquery version "3.1";

(:
Einrichtung von Document Intelligence, getrennt von initialize.xqy.
https://localhost:8443/exist/rest/db/apps/docman/install.xqy

Legt die Quellen nach /tmp/docman-intelligence und startet den Hintergrundjob.
apt und pip laufen nicht hier. Das macht root mit dem exportierten Skript.
:)

declare namespace file = "http://exist-db.org/xquery/file";

import module namespace scheduler = "http://exist-db.org/xquery/scheduler";

declare function local:root() as xs:string {
	let $raw := system:get-module-load-path()
	let $without-scheme := replace($raw, '^xmldb:exist://', '')
	let $without-server := replace($without-scheme, '^embedded-eXist-server', '')
	let $without-suffix := replace($without-server, '/general/functions$', '')
	let $path := replace($without-suffix, '/$', '')
	return
		if (starts-with($path, '/db/')) then $path
		else '/db/apps/docman'
};

declare function local:export-file($uri as xs:string, $path as xs:string) as element() {
	try {
		if (util:binary-doc-available($uri)) then
			let $write := file:serialize-binary(util:binary-doc($uri), $path)
			return <file path="{$path}"/>
		else
			let $write := file:serialize(doc($uri), $path, ())
			return <file path="{$path}"/>
	} catch * {
		<error path="{$path}">{$err:description}</error>
	}
};

declare function local:export-sources($root as xs:string, $dest as xs:string) as element()* {
	let $names := (
		'install-linux.sh',
		'pyproject.toml',
		'requirements.txt',
		'docman_intelligence/__init__.py',
		'docman_intelligence/__main__.py',
		'docman_intelligence/assign.py',
		'docman_intelligence/cli.py',
		'docman_intelligence/pdf.py',
		'docman_intelligence/train.py',
		'docman_intelligence/xmlout.py',
		'docman_intelligence/zugferd.py'
	)
	let $mkdir := (
		file:mkdirs($dest),
		file:mkdirs($dest || '/docman_intelligence')
	)
	for $name in $names
	let $uri := $root || '/intelligence/' || $name
	return
		if (util:binary-doc-available($uri) or doc-available($uri)) then
			local:export-file($uri, $dest || '/' || $name)
		else
			<error path="{$dest || '/' || $name}">Quelle fehlt in der Datenbank: {$uri}</error>
};

declare function local:command($root as xs:string) as xs:string {
	let $config := $root || '/data/document-intelligence.xml'
	return
		if (doc-available($config) and string(doc($config)/DocumentIntelligence/@command) != '') then
			string(doc($config)/DocumentIntelligence/@command)
		else
			'/opt/docman-intelligence/.venv/bin/docman-intelligence'
};

declare function local:command-present($command as xs:string) as xs:boolean {
	try { file:exists($command) } catch * { false() }
};

let $root := local:root()
let $export := '/tmp/docman-intelligence'
let $files := local:export-sources($root, $export)
let $script := exists($files[self::file][@path = $export || '/install-linux.sh'])
let $command := local:command($root)
let $present := local:command-present($command)
let $rights :=
	try {
		for $uri in (
			xs:anyURI('/db/apps/docman/modules/module_document-intelligence.xqm'),
			xs:anyURI('/db/apps/docman/modules/functions/document_intelligence_process.xqy'),
			xs:anyURI($root || '/install.xqy')
		)
		return (
			sm:chown($uri, 'admin'),
			sm:chmod($uri, 'rwsrwx--x')
		)
	} catch * {
		<error>setuid nicht gesetzt: {$err:description}</error>
	}
let $job :=
	if (not($script)) then false()
	else
		try {
			let $drop := scheduler:delete-scheduled-job('docman-intelligence')
			(: Viertes Argument ist ein Parameter-Element, kein Benutzer. -1 wiederholt ohne Ende. Der Job startet als guest und erbt über setuid den Besitzer. :)
			let $schedule := scheduler:schedule-xquery-periodic-job(
				'/db/apps/docman/modules/functions/document_intelligence_process.xqy',
				60000,
				'docman-intelligence',
				<parameters/>,
				5000,
				-1
			)
			return true()
		} catch * {
			false()
		}
let $hint :=
	if (not($script)) then
		'Die Quellen fehlen unter /db/apps/docman/intelligence. Den Ordner intelligence ohne .venv per WebDAV dorthin legen, danach install.xqy erneut aufrufen.'
	else if (exists($rights/self::error)) then
		string($rights/self::error[1])
	else if (not($job)) then
		'Der Hintergrundjob konnte nicht eingetragen werden.'
	else if (not($present)) then
		'Job eingetragen. Als root, falls das Programm noch fehlt: sh ' || $export || '/install-linux.sh — die Datei nicht direkt starten.'
	else
		'Das Programm ist installiert. Der Hintergrundjob läuft mit dem setuid-Recht von admin.'

return
<result>
	<Export path="{$export}" files="{count($files/self::file)}"/>
	<Command path="{$command}" present="{$present}"/>
	<Job scheduled="{$job}"/>
	<Hint>{$hint}</Hint>
	{$files/self::error}
</result>
