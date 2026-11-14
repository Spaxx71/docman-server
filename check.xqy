xquery version "3.1";

(:
Schneller Zustandstest für Document Intelligence.
https://docman.bintellix.com/exist-backend/rest/db/apps/docman/check.xqy

Kein OCR, kein Export, kein Reindex.
Wichtig: Diese Datei braucht mode rwsr-xr-x (setuid admin). Sonst schlägt nur der Probe in check.xqy fehl —
der Hintergrundjob kann trotzdem als admin laufen. initialize.xqy setzt das Bit.
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

declare function local:permission($uri as xs:string) as element() {
	try {
		let $p := sm:get-permissions(xs:anyURI($uri))/sm:permission
		return <Permission path="{$uri}" owner="{$p/@owner}" mode="{$p/@mode}"/>
	} catch * {
		<Permission path="{$uri}" error="{$err:description}"/>
	}
};

declare function local:command($root as xs:string) as xs:string {
	let $config := $root || '/data/document-intelligence.xml'
	return
		if (doc-available($config) and string(doc($config)/DocumentIntelligence/@command) != '') then
			string(doc($config)/DocumentIntelligence/@command)
		else
			'/opt/docman-intelligence/.venv/bin/docman-intelligence'
};

declare function local:has-setuid($mode as xs:string?) as xs:boolean {
	contains(string($mode), 's') or contains(string($mode), 'S')
};

let $root := local:root()
let $home := $root || '/data'
let $job-uri := $root || '/modules/functions/document_intelligence_process.xqy'
let $mod-uri := $root || '/modules/module_document-intelligence.xqm'
let $check-uri := $root || '/check.xqy'
let $command := local:command($root)
let $check-perm := local:permission($check-uri)
let $job-perm := local:permission($job-uri)
let $installed :=
	doc-available($home || '/document-intelligence.xml')
	and string(doc($home || '/document-intelligence.xml')/DocumentIntelligence/@installed) = 'true'
let $status :=
	if (doc-available($home || '/document-intelligence-status.xml')) then
		doc($home || '/document-intelligence-status.xml')/*
	else
		<DocumentIntelligenceStatus state="missing">Noch kein Heartbeat.</DocumentIntelligenceStatus>
let $status-age :=
	try {
		if ($status/@at castable as xs:dateTime) then
			string(current-dateTime() - xs:dateTime($status/@at))
		else
			'?'
	} catch * {
		'?'
	}
let $queue :=
	try { di:queue($home) }
	catch * { () }
let $active :=
	try { di:active-runs($home) }
	catch * { () }
let $scheduled :=
	try {
		scheduler:get-scheduled-jobs()//*:job[@name = 'docman-intelligence']
	} catch * {
		<error>{$err:description}</error>
	}
let $probe :=
	try {
		let $run := process:execute(($command, '--version'), <options/>)
		return
			<Probe
				who="{di:who()}"
				exit="{string($run/@exitCode)}"
				out="{substring(normalize-space(string-join(($run/stdout/line, $run/stderr/line), ' ')), 1, 200)}"/>
	} catch * {
		<Probe who="{di:who()}" error="{substring($err:description, 1, 400)}"/>
	}
let $job-setuid-ok := local:has-setuid($job-perm/@mode)
let $check-setuid-ok := local:has-setuid($check-perm/@mode)
let $job-ran-as-admin := contains(string($status/@who), 'admin')
let $probe-version := string($probe/@out)
let $verdict :=
	if (not($check-setuid-ok)) then
		'check.xqy hat kein setuid (mode ohne s). initialize.xqy ausführen.'
	else if (exists($probe/@error)) then
		'process:execute schlägt fehl: ' || string($probe/@error)
	else if (not(starts-with($probe-version, '0.1.1')) and not(contains($probe-version, '0.1.1'))) then
		'Programm-Version ist "' || $probe-version || '", nötig ist 0.1.1 (FILEPATH/Pfad-Argument). install.xqy, dann als root: sh /tmp/docman-intelligence/install-linux.sh — sonst bleibt Fehler Keine Datei.'
	else if (not($job-setuid-ok)) then
		'Job-Datei ohne setuid. install.xqy oder initialize.xqy ausführen.'
	else if (not($installed)) then
		'Marker fehlt. install.xqy ausführen.'
	else if (empty($scheduled) or exists($scheduled/self::error)) then
		'Job steht nicht im Scheduler. install.xqy ausführen.'
	else if (exists($active)) then
		'Ein Lesevorgang läuft (status=running). Status-at und Sidecar beobachten.'
	else if (count($queue) = 0) then
		'Job und Programm ok, Warteschlange leer.'
	else
		'Bereit (0.1.1): ' || count($queue) || ' in der Queue. Status-at=' || string($status/@at)

return
<check>
	<Who>{di:who()}</Who>
	<Installed>{$installed}</Installed>
	<Command path="{$command}"/>
	{$probe}
	{$job-perm}
	{local:permission($mod-uri)}
	{local:permission($root || '/modules/functions')}
	{$check-perm}
	<Setuid job="{$job-setuid-ok}" check="{$check-setuid-ok}" status-who-admin="{$job-ran-as-admin}"/>
	<Scheduled count="{count($scheduled[not(self::error)])}">{$scheduled}</Scheduled>
	<Active count="{count($active)}">{$active}</Active>
	<Queue count="{count($queue)}">{
		for $item at $pos in $queue[position() le 10]
		return <Item position="{$pos}" tenant="{$item/@tenant}" year="{$item/@year}" file="{$item/@source}" status="{$item/@status}" updated="{$item/@updated}"/>
	}</Queue>
	<StatusAge>{$status-age}</StatusAge>
	{$status}
	<Verdict>{$verdict}</Verdict>
</check>
