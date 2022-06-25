xquery version "3.1";

(:
This script might be tested at:

/exist-backend/rest/db/apps/docman/modules/functions/automatic/automatic_periodic-payments.xqy
:)

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace banking="http://bintellix.com/docman/banking" at "/db/apps/docman/modules/module_banking.xqm";
import module namespace document="http://bintellix.com/docman/document" at "/db/apps/docman/modules/module_document.xqm";

import module namespace packages = "http://exist-db.org/apps/existdb-packages" at "/db/apps/packageservice/modules/packages.xqm";
import module namespace functx = "http://www.functx.com";


declare namespace docman = "http://docman.bintellix.com";

declare option output:indent "yes";

let $home-data := '/db/apps/docman/data'
let $tenant := 'bintellix'
let $year := '2022'
let $bank-account-id := "222971400"

let $createPeriodicPayments := banking:createPeriodicPayments ($home-data, $tenant, $year, $bank-account-id)

return
	<result>
		{$createPeriodicPayments}
	</result>


(:
<repo-app url="http://exist-db.org/hbci4java" abbrev="hbci4java" type="library" version="0.5" status="installed" path="/exist/hbci4java/" readonly="false"> 
<repo-app url="http://exist-db.org/apps/xsltforms" abbrev="xsltforms" type="library" version="594" status="installed" path="/exist/xsltforms/" readonly="false">
<repo-app url="http://exist-db.org/apps/docman" abbrev="docman" type="application" version="0.5" status="installed" path="/exist/docman/" readonly="false">

<result>
	<!-- {apputil:remove("http://exist-db.org/apps/docman")} -->
	<!-- {apputil:remove("http://exist-db.org/hbci4java")} -->
	<libraries>
	{
		packages:get-local-libraries()
	}
	</libraries>
	<packages>
	{
		packages:get-local-packages()
	}
	</packages>
	<!-- apputil:deploy-upload --> 
</result>
:)