xquery version "3.1";

(:
Schedule or refresh the FinTS auto-update job.
Call: /exist/rest/db/apps/docman/modules/functions/banking_auto_schedule.xqy
:)

import module namespace scheduler="http://exist-db.org/xquery/scheduler";

let $root := '/db/apps/docman'
let $job-uri := $root || '/modules/functions/banking_auto_update_process.xqy'
let $name := 'docman-fints-auto-update'
(: every 6 hours :)
let $period := 6 * 60 * 60 * 1000
let $drop :=
	try { scheduler:delete-scheduled-job($name) } catch * { () }
let $ok :=
	scheduler:schedule-xquery-periodic-job(
		$job-uri,
		$period,
		$name,
		<parameters/>,
		60000,
		-1,
		false()
	)
return
	<result job="{$name}" scheduled="{$ok}" period-ms="{$period}" script="{$job-uri}"/>
