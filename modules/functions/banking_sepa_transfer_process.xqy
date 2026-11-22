xquery version "3.1";

(:
Execute draft SepaTransferTask after process save:
FinTS transfer + Eigen-PDF TransferVoucherTask.
:)

import module namespace main="http://bintellix.com/docman/main" at "/db/apps/docman/modules/module_main.xqm";
import module namespace banking="http://bintellix.com/docman/banking" at "/db/apps/docman/modules/module_banking.xqm";
import module namespace document="http://bintellix.com/docman/document" at "/db/apps/docman/modules/module_document.xqm";
import module namespace xfo="http://bintellix.com/docman/xslfo" at "/db/apps/docman/modules/module_xfo.xqm";

declare namespace fo="http://www.w3.org/1999/XSL/Format";

let $home-data := request:get-attribute('home-data')
let $tenant := request:get-attribute('tenant')
let $year := xs:integer(request:get-attribute('year'))
let $binder := request:get-attribute('binder')
let $process-id := request:get-attribute('process-id')
let $username := (request:get-attribute('username'), 'system')[1]

let $doc-uri := $home-data || '/' || $tenant || '/' || $year || '/' || $binder || '/' || $process-id || '.dm.xml'
let $process := doc($doc-uri)/Process
let $task := $process/Tasks/SepaTransferTask[not(@status) or @status = ('', 'draft', 'pending')][1]

return
	if (empty($process)) then
		<result ok="false"><error>Process not found: {$process-id}</error></result>
	else if (empty($task)) then
		<result ok="true"><info>No draft/pending SepaTransferTask</info></result>
	else
		let $mark-pending :=
			(
				update value $task/@status with 'pending',
				update value $task/StatusMessage with 'Überweisung gestartet…'
			)
		let $kto := normalize-space(string($task/SourceAccount))
		let $country := (normalize-space(string($task/RecipientCountry)), 'DE')[1]
		let $bic := normalize-space(string($task/RecipientBic))
		let $iban := normalize-space(string($task/RecipientIban))
		let $name := normalize-space(string($task/RecipientName))
		let $amount := xs:double(($task/Amount/@value, 0)[1])
		let $unit := (string($task/Amount/@unit), 'EUR')[1]
		let $usage := string($task/UsageText)
		let $date :=
			if ($task/ExecutionDate castable as xs:date) then xs:date($task/ExecutionDate)
			else current-date()
		let $transfer :=
			try {
				banking:transferViaFinTS($home-data, $tenant, $year, $kto, $country, $bic, $iban, $name, $date, $amount, $unit, $usage)
			} catch * {
				<result><error>{$err:code}: {$err:description}</error></result>
			}
		let $transfer-text := string($transfer)
		let $ok := contains($transfer-text, 'ok="true"') or contains($transfer-text, "ok='true'")
			or (contains($transfer-text, 'TransferResult') and not(contains($transfer-text, 'ok="false"')))
		let $failed := contains($transfer-text, 'SCA_REQUIRED') or contains($transfer-text, '<error')
			or contains(lower-case($transfer-text), 'exception')
		return
			if ($failed or not($ok)) then
				let $_ := (
					update value $task/@status with 'failed',
					update value $task/StatusMessage with string($transfer)
				)
				return
					<result ok="false">
						<transfer>{$transfer}</transfer>
						<task-id>{$task/@id/string()}</task-id>
					</result>
			else
				let $voucher-id := 'ACC' || util:uuid()
				let $file-name := $process-id || '_sepa_' || $voucher-id
				let $collection := $home-data || '/' || $tenant || '/' || $year || '/' || $binder
				let $fo :=
					<fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format">
						<fo:layout-master-set>
							<fo:simple-page-master master-name="A4" page-height="297mm" page-width="210mm" margin="20mm">
								<fo:region-body/>
							</fo:simple-page-master>
						</fo:layout-master-set>
						<fo:page-sequence master-reference="A4">
							<fo:flow flow-name="xsl-region-body" font-family="Helvetica" font-size="11pt">
								<fo:block font-size="16pt" font-weight="bold" space-after="12pt">SEPA-Überweisungsbestätigung</fo:block>
								<fo:block>Vorgang: {$process-id}</fo:block>
								<fo:block>Zeitpunkt: {string(current-dateTime())}</fo:block>
								<fo:block space-before="8pt">Auftraggeber-Konto: {$kto}</fo:block>
								<fo:block>Empfänger: {$name}</fo:block>
								<fo:block>IBAN: {$iban}</fo:block>
								<fo:block>BIC: {$bic}</fo:block>
								<fo:block>Betrag: {$amount} {$unit}</fo:block>
								<fo:block>Verwendungszweck: {$usage}</fo:block>
								<fo:block space-before="8pt">Bankstatus:</fo:block>
								<fo:block white-space-collapse="false">{string($transfer)}</fo:block>
							</fo:flow>
						</fo:page-sequence>
					</fo:root>
				let $pdf := xfo:createPDF($fo)
				let $store :=
					if ($pdf instance of xs:base64Binary or $pdf instance of xs:hexBinary) then
						xmldb:store($collection, $file-name || '.pdf', $pdf, 'application/pdf')
					else if ($pdf instance of node()) then
						() (: error node :)
					else
						xmldb:store($collection, $file-name || '.pdf', $pdf, 'application/pdf')
				let $rel := '/' || $tenant || '/' || $year || '/' || $binder || '/' || $file-name || '.pdf'
				let $voucher :=
					<TransferVoucherTask type="transfer-voucher" id="{$voucher-id}" date="{current-date()}" created="{current-dateTime()}" isMaster="false" user="{$username}">
						<Notes>Automatisch erzeugt nach SEPA-Überweisung</Notes>
						<Files>
							<File src="{$rel}" uploadSrc="{$rel}" fileName="{$file-name}" fileExtension=".pdf" uploadName="{$file-name}.pdf" mimeType="application/pdf" type="doc-bank-transfer" doctype="digital" archived="false">
								{ let $hash := document:hashcode($home-data, $rel) return if ($hash) then attribute hashcode { $hash } else () }
							</File>
						</Files>
						<Bookings/>
						<Amount value="{$amount}" unit="{$unit}"/>
						<RefID>{$task/@id/string()}</RefID>
						<Description>SEPA an {$name} / {$iban}</Description>
					</TransferVoucherTask>
				let $_ := (
					update insert $voucher into $process/Tasks,
					update value $task/@status with 'sent',
					update value $task/VoucherTaskId with $voucher-id,
					update value $task/StatusMessage with 'Überweisung erfolgreich, Beleg erzeugt'
				)
				return
					<result ok="true">
						<transfer>{$transfer}</transfer>
						<voucher-id>{$voucher-id}</voucher-id>
						<pdf>{$rel}</pdf>
						<store>{$store}</store>
					</result>
