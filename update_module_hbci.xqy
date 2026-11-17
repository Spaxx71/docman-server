xquery version "3.1";

declare namespace file = "http://exist-db.org/xquery/file";

(:
This script might be tested at:
/exist/rest/db/apps/docman/update_module_hbci.xqy

Optional: ?resetPassports=true to delete persisted passport files.
:)

import module namespace functx="http://www.functx.com";
import module namespace packages = "http://exist-db.org/apps/existdb-packages" at "/db/apps/packageservice/modules/packages.xqm";
import module namespace apputil = "http://exist-db.org/xquery/apps" at "/db/apps/packageservice/modules/apputil.xql";

declare namespace expath = "http://expath.org/ns/pkg";

let $repro-name := "http://exist-db.org/library/hbci4java"
let $resetPassports := request:get-parameter("resetPassports", "false") = "true"

(: Passports are persisted access media. Only delete when explicitly requested. :)
let $cleanupFilesPassport :=
	if ($resetPassports) then
		(
			for $file in file:directory-list('/tmp/', 'passport*.dat')//file:file
			return
				<file name="{$file/@name}" area="tmp">{file:delete('/tmp/'||$file/@name)}</file>
			,
			let $home := system:get-exist-home() || '/docman-passports'
			return
				if (file:exists($home)) then
					for $file in file:directory-list($home, 'passport*.dat')//file:file
					return
						<file name="{$file/@name}" area="docman-passports">{file:delete($home||'/'||$file/@name)}</file>
				else
					()
		)
	else
		<skipped reason="Passports are kept. Use ?resetPassports=true to delete."/>

return
	<result>
		<passport reset="{$resetPassports}">{$cleanupFilesPassport}</passport>
		<applications>{ packages:get-local-applications() }</applications>
		<libraries>{ packages:get-local-libraries() }</libraries>
		<version>{ packages:get-version() }</version>
		<installed>{apputil:is-installed($repro-name, ())}</installed>
		<hbci4java>
			{
				let $installed := apputil:is-installed($repro-name, ())
				return
					if ($installed[@name=$repro-name]) then
						<uninstall>
							<undeploy>{repo:undeploy($repro-name)}</undeploy>
							<remove>{repo:remove($repro-name)}</remove>
						</uninstall>
					else
						<not-installed>{$repro-name}</not-installed>
			}
			<install>{repo:install-and-deploy-from-db('/db/apps/docman/resources/hbci4java-0.6.0.xar')}</install>
		</hbci4java>
	</result>
