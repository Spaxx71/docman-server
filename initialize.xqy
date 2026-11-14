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



declare function local:set-rights($RootCollection as xs:string) as node() {
 (: "u+r,g+r,o+r" :)

	<collections>
	{
		for $Collection in (local:list-collections($RootCollection), xs:anyURI($RootCollection))
		return
			if (starts-with($Collection, 'Error:')) then
		let $clear := sm:clear-acl($Collection)
return
			<error>{$Collection}</error>
			else
			<collection name="{$Collection}">
				{
					if (matches($Collection, '^$')) then
						sm:chmod($Collection, 'rwxr-xr-x')
					else if (matches($Collection, $RootCollection||'/modules$')) then
						sm:chmod($Collection, 'rwxr-xr-x')
					else if (starts-with($Collection, $RootCollection||'/data')) then
						sm:chmod($Collection, 'rwxrwx---')
					else
						sm:chmod(xs:anyURI($Collection), 'rwxrwx--x')
				}
				{sm:get-permissions($Collection)}
				<files>
				{
					let $WebUri := substring-after($Collection, $RootCollection)
					for $FileName in xmldb:get-child-resources($Collection)
					return 
						let $FileUri := xs:anyURI($Collection||'/'||$FileName)
						let $clear := sm:clear-acl($FileUri)
						return
							<file collection="{$WebUri}" name="{$FileName}">
							<!-- {sm:chgrp($FileUri,'docman')} -->
							{

								(: cleanup rule for __contents__.xml files :)
								if (matches($FileName, '__contents__.xml$')) then 
									xmldb:remove($Collection, $FileName)

								(: cleanup rule for .DS_Store files :)
								else if (matches($FileName, '.DS_Store$')) then 
									xmldb:remove($Collection, $FileName)

								else 
								(

									(: special condition for controller.xql :)
									if (matches($WebUri, '^$') and matches($FileName, '^controller.xql$')) then 
										sm:chmod($FileUri, 'rwxr-xr-x')


									(: all files in root directory :)
									else if (matches($WebUri, '^$')) then 
										(: special conditions for the /initialize.xqy file :)
										if (matches($FileName, '^(initialize|install)\.xqy$')) then 
											sm:chmod($FileUri, 'rwsr-xr-x') (: setuid bit :)
										else if (matches($FileName, '^update_module_hbci.xqy$')) then
											sm:chmod($FileUri, 'rwsr-xr-x')
										else if (matches($FileName, '\.(ico|txt)$')) then
											sm:chmod($FileUri, 'rwxrwxr-x')
										else if (matches($FileName, '\.(xml)$')) then
											sm:chmod($FileUri, 'rwxrwxr-x')
										else
											(sm:chmod($FileUri, 'rwxr-xr-x'),<error type="2" weburi="{$WebUri}" file="{$FileName}">File type not supported!</error>)

									(: special conditions for all files in /modules/ and sup-directories :)
									(: email calls process:execute and must run as the owner :)
									else if (matches($WebUri, '^/modules') and matches($FileName, '^(restxq-email\.xqy|module_email\.xqm|module_document-intelligence\.xqm|document_intelligence_process\.xqy)$')) then
										sm:chmod($FileUri, 'rwsrwx--x')

									else if (matches($WebUri, '^/modules') and matches($FileName, '^restxq-[a-z\-]+\.xqy$')) then
										sm:chmod($FileUri, 'rwxrwx--x') 

									else if (matches($WebUri, '^/modules') and matches($FileName, '^module_[a-z\-]+\.xqm$')) then
										sm:chmod($FileUri, 'rwxrwxr-x') 

									else if (matches($WebUri, '^/modules')) then 
										sm:chmod($FileUri, 'rwxrwx--x') 

									(: special conditions for all files in /views/ and sup-directories :)
									else if (matches($WebUri, '^/views')) then 
										sm:chmod($FileUri, 'rwxr-xr-x') 

									(: special conditions for all files in /resouces/ and sup-directories :)
									else if (matches($WebUri, '^/recources')) then 
										sm:chmod($FileUri, 'rwxr-xr-x') 

									else if (matches($WebUri, '^/data') and matches($FileName, '^search.xml$')) then
										sm:chmod($FileUri, 'rw-rw----')

									else if (matches($WebUri, '^/data')) then 
										if (matches($FileName, '(bank-account_.*|accounts)\.dm\.xml$')) then
											sm:chmod($FileUri, 'rwxrw----')
										else if (matches($FileName, '\.(xml)$')) then
											sm:chmod($FileUri, 'rwxrw----')
										else
											(sm:chmod($FileUri, 'rwxrw----'))
									else 
										(sm:chmod($FileUri, 'rwxr-xr-x'),<error type="4" weburi="{$WebUri}" file="{$FileName}">File is not part of list!</error>)
								
									,
										sm:clear-acl($FileUri)
									,
										sm:get-permissions($FileUri)
									
								)
							}
							</file>
				}
				</files>
			</collection>
	}
	</collections>
};

let $targetPathPrefix := '/var/www/'
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

(: add users to the access groups :)
(: sm:add-group-manager :)
(: sm:remove-group-member :)
let $tenants := 
	for $Tenant in (xmldb:get-child-collections($CurrentRoot || '/data/'))
	let $Access := doc($CurrentRoot || '/data/' || $Tenant || '/tenant.dm.xml')/Tenant/Access
	let $userAccess	:= local:set-users($CurrentRoot||'/data/'||$Tenant, 'admin', $Access/Group/@id)
	return 
		<Tenant id="{$Tenant}">
			{	(: remove all current given members :)
				for $group-member in sm:get-group-members($Access/Group/@id)
				return
					try {
						sm:remove-group-member($Access/Group/@id, $group-member)
					}
					catch * {
						()
					}
			}
			<Name>{$Access/../Name}</Name>
			<Access>
				<Group id="{$Access/Group/@id}"/>
				{	(: add user to group :)
					for $User at $pos in $Access/Users/User
					return
						if (sm:get-group-members($Access/Group/@id) = $User/@id) then () else sm:add-group-member($Access/Group/@id, $User/@id)
				}
				<Users>
				{
					for $group-member in sm:get-group-members($Access/Group/@id)
					return 
						<User id="{$group-member}"/>
				}
				</Users>
			</Access>
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


(: reindex database :)
let $reindex := xmldb:reindex($CurrentRoot||'/data')

(: cleanup HBCI / FinTS files 
let $cleanupFilesPassportRoot := for $file in file:directory-list('/tmp/', 'passport*.dat')//file:file
return
	<file name="{$file/@name}">
		{file:delete('/tmp/'||$file/@name)}
	</file>
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
	<ReIndex>{$reindex}</ReIndex>
	<Intelligence job="stopped">Der Hintergrundjob wurde aus dem Plan genommen. Ein bereits laufender Lesevorgang hält die Sperre noch bis er endet; danach initialize.xqy erneut aufrufen und anschließend install.xqy.</Intelligence>
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
	<SetRights>
		{$resSetRights}
	</SetRights>
	<RestXq>
		{$restXqModules}
		{$invalidRestXqModules}
		{exrest:invalid-modules()}
		<MissingDependencies>{exrest:missing-dependencies()}</MissingDependencies>
	</RestXq>
	<CleanupFiles>

	</CleanupFiles>
</result>
