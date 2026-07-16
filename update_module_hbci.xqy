xquery version "3.1";

declare namespace file = "http://exist-db.org/xquery/file";

(:
This script might be tested at:
/exist/rest/db/apps/docman/update_module_hbci.xqy

needs to have app/packageservice to be given
https://github.com/eXist-db/existdb-packageservice

:)

(:
<repo-app url="http://exist-db.org/library/hbci4java" abbrev="hbci4java" type="library" version="0.5.4" status="installed" path="/exist/hbci4java/" readonly="false">
	<repo-icon src="/exist/apps/packageservice/resources/images/package.png"> </repo-icon>
	<repo-type>library</repo-type>
	<repo-title>HBCI and FinTS Online Banking module</repo-title>
	<repo-version>0.5.4</repo-version>
	<repo-url>/exist/hbci4java/</repo-url>
	<repo-name>http://exist-db.org/library/hbci4java</repo-name>
	<repo-description>HBCI and FinTS Online Banking module</repo-description>
	<repo-authors>
		<repo-author>hbci4java</repo-author>
	</repo-authors>
	<repo-abbrev>hbci4java</repo-abbrev>
	<repo-website>https://github.com/hbci4j/hbci4java</repo-website>
	<repo-license>GNU Lesser General Public License v2.1</repo-license>
</repo-app>

:)

import module namespace functx="http://www.functx.com";


import module namespace packages = "http://exist-db.org/apps/existdb-packages" at "/db/apps/packageservice/modules/packages.xqm";
import module namespace apputil = "http://exist-db.org/xquery/apps" at "/db/apps/packageservice/modules/apputil.xql";

declare namespace expath = "http://expath.org/ns/pkg";

let $repro-name := "http://exist-db.org/library/hbci4java"

(: cleanup HBCI / FinTS files :)
let $cleanupFilesPassport := for $file in file:directory-list('/tmp/', 'passport*.dat')//file:file
return
	<file name="{$file/@name}">
		{file:delete('/tmp/'||$file/@name)}
	</file>

return
	<result>
		<passport>
		{

		}
		</passport>

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
			<install>{repo:install-and-deploy-from-db('/db/apps/docman/resources/hbci4java-0.5.xar')}</install>

			<!-- 
			repo:install-and-deploy($pkgName as xs:string, $publicRepoURL as xs:string)  
			repo:install-and-deploy($pkgName as xs:string, $version as xs:string?, $publicRepoURL as xs:string)
			repo:install-and-deploy-from-db($path as xs:string, $publicRepoURL as xs:string) as element()
			repo:deploy($pkgName as xs:string)
			repo:install($pkgName as xs:string) -->
			<!--
			<install>{apputil:install-from-repo('hbci4java-0.5.xar', (), '/exist/autodeploy')}</install>
			-->
		</hbci4java>

		<!-- <root>{repo:get-root()}</root> -->
		<!-- 
		{repo:get-root()}
		{repo:get-local('application')}
		{repo:get-local('library')}
		-->
	</result>