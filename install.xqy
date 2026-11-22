xquery version "3.1";

(:
Einrichtung von Document Intelligence, getrennt von initialize.xqy.
https://localhost:8443/exist/rest/db/apps/docman/install.xqy

Legt die Quellen nach /tmp/docman-intelligence und startet den Hintergrundjob.
apt und pip laufen nicht hier. Das macht root mit dem exportierten Skript.
:)

declare namespace file = "http://exist-db.org/xquery/file";

import module namespace scheduler = "http://exist-db.org/xquery/scheduler";
import module namespace di = "http://bintellix.com/docman/document-intelligence" at "/db/apps/docman/modules/module_document-intelligence.xqm";
import module namespace process = "http://exist-db.org/xquery/process";

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
		'docman_intelligence/vocab.py',
		'docman_intelligence/vocab.xml',
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

declare function local:permission($uri as xs:string) as element() {
	try {
		let $p := sm:get-permissions(xs:anyURI($uri))/sm:permission
		return <Permission path="{$uri}" owner="{$p/@owner}" mode="{$p/@mode}"/>
	} catch * {
		<Permission path="{$uri}" error="{$err:description}"/>
	}
};

let $root := local:root()
let $home := $root || '/data'
let $export := '/tmp/docman-intelligence'
let $files := local:export-sources($root, $export)
let $script := exists($files[self::file][@path = $export || '/install-linux.sh'])
let $command := local:command($root)
let $present := local:command-present($command)
let $job-uri := $root || '/modules/functions/document_intelligence_process.xqy'
let $check-uri := $root || '/modules/functions/document_intelligence_check.xqy'
let $mod-uri := $root || '/modules/module_document-intelligence.xqm'
let $functions-col := $root || '/modules/functions'
let $rights :=
	try {
		let $_ := (
			sm:chmod(xs:anyURI($functions-col), 'rwxr-xr-x'),
			for $uri in (
				xs:anyURI($mod-uri),
				xs:anyURI($job-uri),
				xs:anyURI($check-uri),
				xs:anyURI($root || '/install.xqy')
			)
			return (
				sm:chown($uri, 'admin'),
				sm:chmod($uri, 'rwsr-xr-x')
			)
		)
		return ()
	} catch * {
		<error>setuid nicht gesetzt: {$err:description}</error>
	}
let $job :=
	if (not($script)) then false()
	else
		try {
			let $drop := scheduler:delete-scheduled-job('docman-intelligence')
			(: unschedule=false: Exception darf den Job nicht aus dem Plan nehmen. :)
			let $schedule := scheduler:schedule-xquery-periodic-job(
				$job-uri,
				60000,
				'docman-intelligence',
				<parameters/>,
				2000,
				-1,
				false()
			)
			return $schedule
		} catch * {
			false()
		}
(: Marker unabhängig von file:exists — die Whitelist lügt oft. Job + exportierte Quellen reichen. :)
let $marker :=
	try {
		if (not($job)) then
			<marker ok="false"/>
		else
			let $path := xmldb:store(
				$home,
				'document-intelligence.xml',
				<DocumentIntelligence command="{$command}" installed="true" installed-at="{current-dateTime()}"/>
			)
			return <marker ok="true" path="{$path}"/>
	} catch * {
		<marker ok="false">{$err:description}</marker>
	}
let $probe :=
	try {
		let $run := process:execute(($command, '--version'), <options/>)
		return
			<Probe
				who="{di:who()}"
				queued="{count(di:queue($home))}"
				exit="{string($run/@exitCode)}"
				out="{substring(normalize-space(string-join(($run/stdout/line, $run/stderr/line), ' ')), 1, 200)}"/>
	} catch * {
		<Probe who="{di:who()}" queued="{count(di:queue($home))}" error="{substring($err:description, 1, 300)}"/>
	}
let $right-errors := $rights[self::error]
let $root-cmd := 'sudo sh ' || $export || '/install-linux.sh'
let $version := normalize-space(string(($probe/@out, '')[1]))
let $version-ok := contains($version, '0.1.7')
let $hint :=
	if (not($script)) then
		'Die Quellen fehlen unter /db/apps/docman/intelligence.'
	else if (exists($right-errors)) then
		string($right-errors[1]) || ' Anschließend als root: ' || $root-cmd
	else if (not($job)) then
		'Der Hintergrundjob konnte nicht eingetragen werden. Quellen liegen unter ' || $export || '. Als root: ' || $root-cmd
	else if (exists($probe/@error)) then
		'Job eingetragen, aber process:execute schlug fehl: ' || string($probe/@error) || ' Als root trotzdem: ' || $root-cmd
	else if (not($version-ok)) then
		'Programm-Version ist "' || $version || '" (nötig 0.1.7). Als root ausführen: ' || $root-cmd || ' — die Datei nicht direkt starten (/tmp ist oft noexec).'
	else if (xs:integer(($probe/@queued, '0')[1]) = 0) then
		'Job läuft, Programm 0.1.7 ok. Warteschlange leer. Bei Code-Änderungen erneut: ' || $root-cmd
	else
		'Job läuft, Programm 0.1.7 ok. ' || string($probe/@queued) || ' Datei(en) in der Warteschlange. Bei Code-Änderungen erneut: ' || $root-cmd

return
<result>
	<Export path="{$export}" files="{count($files[self::file])}"/>
	<Command path="{$command}" present="{$present}" version="{$version}" version-ok="{$version-ok}"/>
	<Job scheduled="{$job}"/>
	<Installed>{exists($marker[@ok = 'true'])}</Installed>
	{
		if ($script) then
			<RootInstall required="{not($version-ok) or exists($probe/@error) or not($present)}">
				{$root-cmd}
			</RootInstall>
		else
			()
	}
	{local:permission($job-uri)}
	{local:permission($mod-uri)}
	{local:permission($functions-col)}
	{$probe}
	{$marker}
	<Hint>{$hint}</Hint>
	{$files[self::error]}
	{$right-errors}
</result>
