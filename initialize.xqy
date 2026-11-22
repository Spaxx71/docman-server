xquery version "3.1";

(:
This script might be tested at:
https://localhost:8443/exist/rest/db/apps/docman/initialize.xqy


Needs to have C:\tmp\
:)

(: repo:install-and-deploy-from-db  :)

declare namespace exist = "http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace xmldb = "http://exist-db.org/xquery/xmldb";
declare namespace expath = "http://expath.org/ns/pkg";
declare namespace file = "http://exist-db.org/xquery/file";

import module namespace repair="http://exist-db.org/xquery/repo/repair" 
	at "resource:org/exist/xquery/modules/expathrepo/repair.xql";
import module namespace scheduler = "http://exist-db.org/xquery/scheduler";
import module namespace user = "http://bintellix.com/docman/user" at "xmldb:exist:///db/apps/docman/modules/module_user.xqm";



declare function local:list-collections($Collection as xs:string) as xs:string* {

    for $child in xmldb:get-child-collections($Collection)
    let $childCollection := concat($Collection, '/', $child)
    return
	if (xmldb:collection-available($childCollection)) then
        	(local:list-collections($childCollection), $childCollection)
	else
		"Error: Collection " || $childCollection || " is listed but does not exist."
};


declare function local:set-users($RootCollection as xs:string, $Owner as xs:string, $Group as xs:string) as node() {

	<collections>
	{
	for $Collection in (local:list-collections($RootCollection), xs:anyURI($RootCollection))
	return
		<collection>
		{ sm:chown ($Collection, $Owner) }
		{ sm:chgrp ($Collection, $Group) }
		{
			for $FileName in xmldb:get-child-resources($Collection)
			return 
				( 
					sm:chown (xs:anyURI($Collection||'/'||$FileName), $Owner)
				,
					sm:chgrp (xs:anyURI($Collection||'/'||$FileName), $Group) 
				)
		}
		</collection>
	}
	</collections>
};



declare function local:set-rights($RootCollection as xs:string) as element(SetRights) {
	(: Rechte setzen; Antwort nur Zähler und Fehler — kein sm:get-permissions-Dump. :)
	let $collections := (local:list-collections($RootCollection), xs:anyURI($RootCollection))
	let $results :=
		for $Collection in $collections
		return
			if (starts-with($Collection, 'Error:')) then
				<error>{$Collection}</error>
			else
				let $_collection :=
					if (matches($Collection, '^$')) then
						sm:chmod($Collection, 'rwxr-xr-x')
					else if (matches($Collection, $RootCollection||'/modules$')) then
						sm:chmod($Collection, 'rwxr-xr-x')
					(: guest muss den Job-Pfad übersetzen können, setuid greift erst danach :)
					else if (matches($Collection, $RootCollection||'/modules/functions$')) then
						sm:chmod($Collection, 'rwxr-xr-x')
					else if (starts-with($Collection, $RootCollection||'/data')) then
						sm:chmod($Collection, 'rwxrwx---')
					else
						sm:chmod(xs:anyURI($Collection), 'rwxrwx--x')
				let $WebUri := substring-after($Collection, $RootCollection)
				for $FileName in xmldb:get-child-resources($Collection)
				let $FileUri := xs:anyURI($Collection||'/'||$FileName)
				let $_clear := sm:clear-acl($FileUri)
				return
					if (matches($FileName, '__contents__.xml$')) then
						let $_ := xmldb:remove($Collection, $FileName)
						return ()
					else if (matches($FileName, '.DS_Store$')) then
						let $_ := xmldb:remove($Collection, $FileName)
						return ()
					else
						let $error :=
							if (matches($WebUri, '^$') and matches($FileName, '^controller.xql$')) then
								let $_ := sm:chmod($FileUri, 'rwxr-xr-x')
								return ()
							else if (matches($WebUri, '^$')) then
								if (matches($FileName, '^(initialize|install)\.xqy$')) then
									let $_ := sm:chmod($FileUri, 'rwsr-xr-x')
									return ()
								else if (matches($FileName, '^update_module_hbci.xqy$')) then
									let $_ := sm:chmod($FileUri, 'rwsr-xr-x')
									return ()
								else if (matches($FileName, '\.(ico|txt)$')) then
									let $_ := sm:chmod($FileUri, 'rwxrwxr-x')
									return ()
								else if (matches($FileName, '\.(xml)$')) then
									let $_ := sm:chmod($FileUri, 'rwxrwxr-x')
									return ()
								else
									let $_ := sm:chmod($FileUri, 'rwxr-xr-x')
									return <error type="2" weburi="{$WebUri}" file="{$FileName}">File type not supported!</error>
							else if (matches($WebUri, '^/modules') and matches($FileName, '^(restxq-email\.xqy|module_email\.xqm)$')) then
								let $_ := sm:chmod($FileUri, 'rwsrwx--x')
								return ()
							else if (matches($WebUri, '^/modules') and matches($FileName, '^(module_document-intelligence\.xqm|document_intelligence_process\.xqy|document_intelligence_check\.xqy)$')) then
								let $_ := sm:chmod($FileUri, 'rwsr-xr-x')
								return ()
							else if (matches($WebUri, '^/modules') and matches($FileName, '^restxq-[a-z\-]+\.xqy$')) then
								let $_ := sm:chmod($FileUri, 'rwxrwx--x')
								return ()
							else if (matches($WebUri, '^/modules') and matches($FileName, '^module_[a-z\-]+\.xqm$')) then
								let $_ := sm:chmod($FileUri, 'rwxrwxr-x')
								return ()
							else if (matches($WebUri, '^/modules')) then
								let $_ := sm:chmod($FileUri, 'rwxrwx--x')
								return ()
							else if (matches($WebUri, '^/views')) then
								let $_ := sm:chmod($FileUri, 'rwxr-xr-x')
								return ()
							else if (matches($WebUri, '^/recources')) then
								let $_ := sm:chmod($FileUri, 'rwxr-xr-x')
								return ()
							else if (matches($WebUri, '^/data') and matches($FileName, '^search.xml$')) then
								let $_ := sm:chmod($FileUri, 'rw-rw----')
								return ()
							else if (matches($WebUri, '^/data')) then
								let $_ :=
									if (matches($FileName, '(bank-account_.*|accounts)\.dm\.xml$')) then
										sm:chmod($FileUri, 'rwxrw----')
									else if (matches($FileName, '\.(xml)$')) then
										sm:chmod($FileUri, 'rwxrw----')
									else
										sm:chmod($FileUri, 'rwxrw----')
								return ()
							else
								let $_ := sm:chmod($FileUri, 'rwxr-xr-x')
								return <error type="4" weburi="{$WebUri}" file="{$FileName}">File is not part of list!</error>
						return ($error, <file/>)
	let $errors := $results[self::error]
	let $files := count($results[self::file])
	let $collections-count := count($collections[not(starts-with(., 'Error:'))])
	return
		<SetRights collections="{$collections-count}" files="{$files}" errors="{count($errors)}">
			{$errors}
		</SetRights>
};

(: Nur wenn install.xqy das gesetzt hat. Sonst keinen Job anfassen außer Löschen. :)
declare function local:intelligence-ready($root as xs:string) as xs:boolean {
	try {
		let $config := $root || '/data/document-intelligence.xml'
		let $job := $root || '/modules/functions/document_intelligence_process.xqy'
		return
			doc-available($config)
			and string(doc($config)/DocumentIntelligence/@installed) = 'true'
			and (util:binary-doc-available($job) or doc-available($job))
	} catch * {
		false()
	}
};

declare function local:intelligence-stop() as xs:boolean {
	try {
		scheduler:delete-scheduled-job('docman-intelligence')
	} catch * {
		true()
	}
};

(: Ein bereits laufender Tick hält /data auch nach delete-scheduled-job. Dann kein reindex. :)
declare function local:intelligence-busy() as xs:boolean {
	try {
		let $jobs := system:get-running-jobs()
		let $queries := system:get-running-xqueries()
		return
			exists($jobs//*:job[
				contains(lower-case(string-join((@action, @info, @id), ' ')), 'document_intelligence')
				or contains(lower-case(string-join((@action, @info, @id), ' ')), 'docman-intelligence')
			])
			or exists($queries//*[contains(lower-case(string(.)), 'document_intelligence')])
	} catch * {
		false()
	}
};

declare function local:intelligence-start($root as xs:string) as xs:string {
	if (not(local:intelligence-ready($root))) then
		'skipped'
	else
		try {
			let $job-uri := xs:anyURI($root || '/modules/functions/document_intelligence_process.xqy')
			let $check-uri := xs:anyURI($root || '/modules/functions/document_intelligence_check.xqy')
			let $mod-uri := xs:anyURI($root || '/modules/module_document-intelligence.xqm')
			let $rights := (
				sm:chown($job-uri, 'admin'),
				sm:chmod($job-uri, 'rwsr-xr-x'),
				sm:chown($check-uri, 'admin'),
				sm:chmod($check-uri, 'rwsr-xr-x'),
				sm:chown($mod-uri, 'admin'),
				sm:chmod($mod-uri, 'rwsr-xr-x')
			)
			let $ok := scheduler:schedule-xquery-periodic-job(
				$root || '/modules/functions/document_intelligence_process.xqy',
				60000,
				'docman-intelligence',
				<parameters/>,
				5000,
				-1,
				false()
			)
			return if ($ok) then 'scheduled' else 'failed'
		} catch * {
			'skipped'
		}
};

let $targetPathPrefix := '/var/www/'
(: Frische Installation: kein Marker, kein Job. Sonst Job aus dem Plan, bevor /data gesperrt wird. :)
let $stop-intelligence := local:intelligence-stop()
let $intelligence-busy := local:intelligence-busy()
let $CurrentRootPath := replace(system:get-module-load-path(), '^(xmldb:exist://)?(embedded-eXist-server)?(.+)(general/functions)$','$3')
let $CurrentRoot := replace($CurrentRootPath,'/$','') (: /db/apps/docman :) (: xmldb:exist://embedded-eXist-server/ :)

(:
let $login := xmldb:login ($CurrentRoot, 'admin', 'xxxxxx')
:)

(: let $passwd := sm:passwd('admin', 'Geheim') :)

(: note, that new users need to be added to Nginx proxy.
printf "extern.vorname.nachname:$(openssl passwd -apr1 Geheim)\n" >>  /etc/nginx/sites-available/.htpasswd ; systemctl restart nginx
:)
(:
let $create := sm:create-account('extern.vorname.nachname', 'Geheim','docman',('bintellix','intersecurity','test'))
let $remove := sm:remove-account($username)
let $passwd := sm:passwd('admin', 'Geheim')
:)

let $newGroup := if (sm:group-exists('docman')) then () else sm:create-group ('docman', 'The usergroup for the DocMan App')

let $newuser := if (sm:list-users() = 'bix-accounting') then () else sm:create-account('bix-accounting','bix-acc','docman',())
(: let $newuser := if (sm:list-users() = 'extern.steuerberater') then () else sm:create-account('extern.steuerberater','abc-123','docman',()) :)
(: let $deleteuser := sm:remove-account('username') :)

let $repair := repair:repair($CurrentRoot)

let $FolderData 	:= xmldb:create-collection($CurrentRoot, 'data')

let $FolderCrm0 	:= xmldb:create-collection($CurrentRoot||'/data', 'test')
let $FolderData		:= if (sm:list-groups() = 'test') then () else sm:create-group('test')


let $resSetRights := local:set-rights($CurrentRoot)

let $userAccess	:= local:set-users($CurrentRoot||'/','admin','docman')

(: Access normalisieren (Group/Users) und SM-Gruppe per user:syncGroupMembers abgleichen — kein Leeren der Gruppe. :)
let $tenants := 
	for $Tenant in (xmldb:get-child-collections($CurrentRoot || '/data/'))
	let $tenant-doc := doc($CurrentRoot || '/data/' || $Tenant || '/tenant.dm.xml')/Tenant
	let $Access := $tenant-doc/Access
	let $group-id := user:groupId($Access, $Tenant)
	let $userAccess := local:set-users($CurrentRoot||'/data/'||$Tenant, 'admin', $group-id)
	let $normalized :=
		if (empty($Access)) then
			()
		else
			user:storeAccess($CurrentRoot || '/data', $Tenant, $Access)
	return 
		<Tenant id="{$Tenant}">
			<Name>{$tenant-doc/Name}</Name>
			{$normalized}
			<smMembers>{string-join(sm:get-group-members($group-id), ', ')}</smMembers>
		</Tenant>


(: let $rename := xmldb:rename($CurrentRoot||'/data/bintellix/2019/01/','.dm.xml', 'xxx.dm.xml') :)
(: let $remove := xmldb:remove($CurrentRoot||'/data/bix') :)
(: let $move := xmldb:move($CurrentRoot||'/crm', $CurrentRoot||'/data') :)


(: rebuild restxq modules :)
let $restXqModules := for $FileName in xmldb:get-child-resources($CurrentRoot||'/modules')
	where starts-with($FileName,'restxq-')
	return
		<RestXqModule name="{$CurrentRoot||'/modules/'||$FileName}">
		{ exrest:register-module(xs:anyURI($CurrentRoot||'/modules/'||$FileName)) }
		{ exrest:find-resource-functions(xs:anyURI($CurrentRoot||'/modules/'||$FileName)) }
		</RestXqModule>

let $invalidRestXqModules := if (exrest:invalid-modules() != ()) then
		<error>Ivalid RestXqModules: {exrest:invalid-modules()}</error>
	else
		()


(: reindex nur wenn kein Intelligence-Lauf mehr /data hält. Sonst wartet initialize bis zum Proxy-Timeout. :)
let $reindex :=
	if ($intelligence-busy) then
		false()
	else
		xmldb:reindex($CurrentRoot||'/data')

(: Job nur zurück, wenn install.xqy den Marker gesetzt hat. Nie bei frischer Installation. :)
let $start-intelligence :=
	if ($intelligence-busy) then
		'deferred'
	else
		local:intelligence-start($CurrentRoot)

(: Passports are persistent FinTS access media. Do NOT delete them during initialize.
   Explicit reset: update_module_hbci.xqy?resetPassports=true
:)


(: cleanup error logfiles
let $cleanupFilesLogDocker := for $file in file:directory-list('/', 'hs_err_*.log')//*
				return
					<file name="{$file/@name}">
						{file:delete('/'||$file/@name)}
					</file>
:)


return
<result>
	<ReIndex done="{$reindex}" skipped-because-busy="{$intelligence-busy}"/>
	<Intelligence status="{$start-intelligence}" was-busy="{$intelligence-busy}">
		{
			if ($start-intelligence = 'scheduled') then
				'Hintergrundjob wieder eingetragen.'
			else if ($start-intelligence = 'deferred') then
				'Ein Intelligence-Lauf hält noch /data. Reindex und Job-Neustart übersprungen. Kurz warten und initialize.xqy erneut aufrufen — kein eXist-Neustart nötig.'
			else if ($start-intelligence = 'failed') then
				'Installation erkannt, Eintrag in den Plan fehlgeschlagen. install.xqy aufrufen.'
			else
				'Document Intelligence ist nicht installiert. Job bleibt aus. Reihenfolge: initialize.xqy, danach install.xqy.'
		}
	</Intelligence>
	<Environment>
		<CurrentRoot>{$CurrentRoot}</CurrentRoot>
		<ModuleLoadPath>{system:get-module-load-path()}</ModuleLoadPath>
		<RepoRoot>{repo:get-root()}</RepoRoot>
		<!-- <ModuleInfo>{util:get-module-info()}</ModuleInfo> -->
		<!-- <Packages>{collection(repo:get-root())//expath:package}</Packages> -->
	</Environment>
	<Tenants>
		{$tenants}
	</Tenants>
	{$resSetRights}
	<RestXq>
		{$restXqModules}
		{$invalidRestXqModules}
		{exrest:invalid-modules()}
		<MissingDependencies>{exrest:missing-dependencies()}</MissingDependencies>
	</RestXq>
	<CleanupFiles>

	</CleanupFiles>
</result>
