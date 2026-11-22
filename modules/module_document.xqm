(:
========================================================================
LICENSE AGREEMENT:
This software is distributed WITHOUT ANY WARRANTY and without even the
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
========================================================================
This copy of Docman (a Document managgement an accounting system) 
is licensed under the Server Side Public License (SSPL), v 1 ("the License").

See the License for details about distribution rights, 
modification and transformation of it.

========================================================================
All rights reserved by bintellix GmbH, Germany
========================================================================
@Author: Eduard Huber
@Version: 1.0
======================================================================== 
:)

xquery version "3.1";

(: 
/rest/db/apps/docman/modules/module_document.xqm
:)

module namespace document = "http://bintellix.com/docman/document";

(: banking imports document — do not import banking here (circular dependency breaks RESTXQ registration). :)
import module namespace email="http://bintellix.com/docman/email" at "/db/apps/docman/modules/module_email.xqm";
import module namespace di="http://bintellix.com/docman/document-intelligence" at "/db/apps/docman/modules/module_document-intelligence.xqm";

declare namespace docman = "http://docman.bintellix.com";

(: ############  public functions  ########### :)

declare function document:listDocuments ($dm-home-data as xs:string, $tenant as xs:string, $year as xs:integer, $owner as xs:string?) {
	<Binders version="1.0" tenantId="{$tenant}">
	{
		let $year-col := $dm-home-data||'/'||$tenant||'/'||$year
		let $prepared :=
			for $process in local:year-processes($year-col)
			return document:stamp-file-hashes($dm-home-data, $process, true())
		return local:file-twins($year-col)
	}
	{ 
		let $document-collections := 
			for $collection in xmldb:get-child-collections($dm-home-data||'/'||$tenant||'/'||$year||'/')
				return
					$dm-home-data||'/'||$tenant||'/'||$year||'/'||$collection

		for $document-collection in $document-collections
		let $name := replace($document-collection,'.*/','')
		order by $name
		return
			<Binder name="{$name}">
				{
					if ($name = ('01','02','03','04','05','06','07','08','09','10','11','12')) then
						attribute {"type"} {"MONTH"}
					else
						attribute {'type'} {"ARCHIVE"}
				}
				{
					let $documents := xmldb:get-child-resources($document-collection)
					for $document in $documents
					where ends-with($document,'.dm.xml')
					let $doc-uri := $document-collection||'/'||$document
					let $doc := doc($doc-uri)/Process
					order by $doc/@date, $doc/@name
					let $mainTask := $doc/Tasks/*[@isMaster=true()][1]
					return
						if (not($owner) or $mainTask/Owner=$owner) then
							<Process id="{$doc/@id/data()}" mainTask="{name($mainTask)}" name="{substring-before($document,'.dm.xml')}" binder="{$doc/@binder/data()}" date="{$doc/@date/data()}" created="{$doc/@created/data()}" type="{$doc/@type}" user="{$doc/@user}">
								{$mainTask/Owner}
								{$mainTask/RefID}
								{$mainTask/TransactionID}
								{$mainTask/Description}
								{$doc/TotalAmount}
								{$doc/Notes}
								<Files>
								{ for $file in doc($document-collection||'/'||$document)/Process/Tasks/*/Files/File
									return
										$file
								}
								</Files>
								<Payments>
								{
									for $payment in $doc/Tasks/PaymentTask
									return
										<Payment refID="{$payment/RefID}" amountValue="{$payment/Amount/@value}" amountUnit="{$payment/Amount/@unit}" date="{$payment/@date}"/>
								}
								</Payments>
							</Process>
						else
							()
				}
			</Binder>
	}
	</Binders>
};


(:
declare function document:listDocumentsForOwner ($dm-home-data as xs:string, $tenant as xs:string, $year as xs:integer, $owner as xs:string) {
	<Binders version="1.0" tenantId="{$tenant}">
	{
		let $Processes := collection($dm-home-data||'/'||$tenant||'/'||$year||'/')/Process[Tasks/*/Owner = $owner]
		for $Binder in $Processes/@binder
		group by $Binder
		return
			<Binder name="{$Binder}">	
			{ 
				let $document-collection := $dm-home-data||'/'||$tenant||'/'||$year||'/'||$Binder
				for $Process in $Processes[@binder=$Binder]
				order by $Process/@date, $Process/@name
				return
					<Process>
						{$Process/@*}
						{$Process/*}
					</Process>
			}
			</Binder>
	}
	</Binders>
};
:)

declare function document:listDocumentsForBinder ($dm-home-data as xs:string, $tenant as xs:string, $year as xs:integer, $binder as xs:string) {
	document:listDocumentsForBinder($dm-home-data, $tenant, $year, $binder, true())
};

(: $details=false() = Outline: nur Process/Tasks/Task, Tasks ohne Kind-Elemente. Tabellenfelder als Attribute. :)
declare function document:listDocumentsForBinder ($dm-home-data as xs:string, $tenant as xs:string, $year as xs:integer, $binder as xs:string, $details as xs:boolean) {
	let $year-col := $dm-home-data||'/'||$tenant||'/'||$year
	let $prepared :=
		for $process in local:year-processes($year-col)
		return document:stamp-file-hashes($dm-home-data, $process, true())
	return
	<Binders version="1.0" tenantId="{$tenant}" details="{if ($details) then 'true' else 'false'}">
		{ local:file-twins($year-col) }
		<Binder name="{$binder}" tenantId="{$tenant}" year="{$year}" binder="{$binder}">
		{
			let $document-collection := $year-col||'/'||$binder
			for $document in xmldb:get-child-resources($document-collection)
			where ends-with($document,'.dm.xml')
			let $doc := doc($document-collection||'/'||$document)/Process
			order by $doc/@date, $doc/@name
			return
				if ($details) then
					<Process>
						{$doc/@*}
						{$doc/*}
					</Process>
				else
					document:processOutline($doc)
		}
		</Binder>
	</Binders>
};

declare function document:processOutline($doc as element(Process)?) as element(Process)? {
	if (empty($doc)) then ()
	else
		let $master := ($doc/Tasks/*[@isMaster = 'true'], $doc/Tasks/*[1])[1]
		let $amount := $doc/TotalAmount
		let $paid := sum(
			for $value in $doc//PaymentTask/Amount/@value
			where $value castable as xs:double
			return xs:double($value)
		)
		let $notes := normalize-space(string($doc/Notes))
		let $files := string-join($doc//File/@type, ' ')
		let $type := normalize-space(string(($doc/@type, $master/@type)[normalize-space(string(.)) != ''][1]))
		return
			<Process
				id="{$doc/@id}"
				name="{$doc/@name}"
				date="{$doc/@date}"
				binder="{$doc/@binder}"
				user="{$doc/@user}"
				created="{$doc/@created}"
				mainTask="{$doc/@mainTask}"
				type="{$type}"
				amount="{string($amount/@value)}"
				unit="{string($amount/@unit)}"
				notes="{$notes}"
				paid="{$paid}"
				files="{$files}"
				outline="true">
				<Tasks>
				{
					for $task in $doc/Tasks/*
					return
						element { node-name($task) } {
							$task/@*,
							attribute owner { normalize-space(string($task/Owner)) },
							attribute description { normalize-space(string($task/Description)) },
							attribute refID { normalize-space(string($task/RefID)) },
							attribute transactionID { normalize-space(string($task/TransactionID)) },
							attribute notes { normalize-space(string($task/Notes)) },
							attribute amount { string($task/Amount/@value) },
							attribute unit { string($task/Amount/@unit) },
							attribute files { string-join($task/Files/File/@type, ' ') },
							<Files>
							{
								for $file in $task/Files/File
								return
									<File type="{string($file/@type)}" src="{string($file/@src)}" fileName="{string($file/@fileName)}">
										{ if (matches(string($file/@hashcode), '^[0-9a-f]{64}$')) then attribute hashcode { string($file/@hashcode) } else () }
									</File>
							}
							</Files>
						}
				}
				</Tasks>
			</Process>
};



declare function document:getNewDocumentTemplate($dm-home-data as xs:string, $tenant as xs:string, $task as xs:string, $type as xs:string) {
	let $user := sm:id()/sm:id/sm:real/sm:username/data()
	return
		<Process id="PRO{util:uuid()}" name="Neu" date="" binder="" user="{$user}" created="{current-dateTime()}">
			<Section/>
			<TotalAmount value=""/>
			<Tasks>
			{
				if ($task = "InvoiceInTask") then
					<InvoiceInTask id="ACC{util:uuid()}" type="invoice-in" date="" created="{current-dateTime()}" isMaster="true" user="{$user}" isStorno="{if ($type="STORNO") then 'true' else 'false'}">
						<Notes/>
						<Files/>
						<Bookings/>
						<Amount/>
						<Owner/>
						<RefID/>
						<TransactionID/>
						<Description/>
					</InvoiceInTask>
				else if ($task = "InvoiceOutTask") then
					<InvoiceOutTask id="ACC{util:uuid()}" type="invoice-out" date="" created="{current-dateTime()}" isMaster="true" user="{$user}" isStorno="{if ($type="STORNO") then 'true' else 'false'}">
						<Notes/>
						<Files/>
						<Bookings/>
						<Amount/>
						<Owner/>
						<RefID/>
						<TransactionID/>
						<Description/>
					</InvoiceOutTask>
				else if ($task = "SimpleTask") then
					<SimpleTask id="ACC{util:uuid()}" type="{if ($type='') then 'note' else $type}" date="" created="{current-dateTime()}" isMaster="true" user="{$user}">
						<Notes/>
						<Files/>
						<Bookings/>
						<Owner/>
						<RefID/>
						<Description/>
					</SimpleTask>
				else if ($task = "DocumentTask") then
					<DocumentTask id="ACC{util:uuid()}" type="{if ($type='') then 'doc-undefined' else $type}" date="" created="{current-dateTime()}" isMaster="true" user="{$user}">
						<Notes/>
						<Files/>
						<Bookings/>
						<Owner/>
						<DocName/>
						<RefID/>
						<Description/>
					</DocumentTask>
				else if ($task = "TaxTask") then
					<TaxTask id="ACC{util:uuid()}" type="doc-tax" date="" created="{current-dateTime()}" isMaster="true" user="{$user}" isStorno="{if ($type="STORNO") then 'true' else 'false'}">
						<Notes/>
						<Files/>
						<Bookings>
							<Booking date="" quality="3" amountValue="" amountUnit="EUR" credit="" debit="" taxKey="1" taxAmount="0" refID="" description="Steuerzahlung"/>
						</Bookings>
						<Amount value="" unit="EUR"/>
						<Owner/>
						<RefID/>
						<Tax typeOfTax="" period=""/>
						<Description/>
					</TaxTask>					
				else if ($task = "EmployeeSalaryTask") then
					<EmployeeSalaryTask id="ACC{util:uuid()}" date="" created="{current-dateTime()}" isMaster="true" user="{$user}">
						<Notes/>
						<Files/>
						<Bookings>
							<Booking date="" quality="3" amountValue="" amountUnit="EUR" credit="" debit="" taxKey="1" taxAmount="0" refID="A" description="A"/>
							<Booking date="" quality="3" amountValue="" amountUnit="EUR" credit="" debit="" taxKey="1" taxAmount="0" refID="B" description="B"/>
							<Booking date="" quality="3" amountValue="" amountUnit="EUR" credit="" debit="" taxKey="1" taxAmount="0" refID="C" description="C"/>
							<Booking date="" quality="3" amountValue="" amountUnit="EUR" credit="" debit="" taxKey="1" taxAmount="0" refID="D" description="D"/>
							<Booking date="" quality="3" amountValue="" amountUnit="EUR" credit="" debit="" taxKey="1" taxAmount="0" refID="E" description="E"/>
							<Booking date="" quality="3" amountValue="" amountUnit="EUR" credit="" debit="" taxKey="1" taxAmount="0" refID="F" description="F"/>
							<Booking date="" quality="3" amountValue="" amountUnit="EUR" credit="" debit="" taxKey="1" taxAmount="0" refID="G" description="G"/>
							<Booking date="" quality="3" amountValue="" amountUnit="EUR" credit="" debit="" taxKey="1" taxAmount="0" refID="H" description="H"/>
						</Bookings>
						<Amount value="" unit="EUR"/>
						<EmployeeID/>
						<EmployeeName/>
						<SalaryMonth/>
						<GrossSalary/>
						<TaxBasedComission/>
						<SozialSecurityCommission/>
						<AmountPaid/>
						<SozialSecurityEmloyeeContribution/>
						<SozialSecurityEmployeeAddition/>
						<OverallCosts/>
						<Owner/>
						<Description/>
					</EmployeeSalaryTask>
				else if ($task = "BankBalancingTask") then
					<BankBalancingTask id="ACC{util:uuid()}" date="" created="{current-dateTime()}" isMaster="true" user="{$user}" isStorno="{if ($type="STORNO") then 'true' else 'false'}">
						<Notes/>
						<Files/>
						<Bookings/>
						<Amount value="" unit="EUR"/>
                		<Owner/>
                		<Other/>
						<RefID/>
                		<TriggerDate/>
						<Description/>
					</BankBalancingTask>			
				else
					<error>module_document: Unknown Type</error>
			}
			</Tasks>
			<Notes/>
		</Process>    
};


declare function local:processById($collection as xs:string, $document as xs:string) as element()? {
	(
		for $name in xmldb:get-child-resources($collection)
		where ends-with($name, '.dm.xml')
		let $process := doc($collection || '/' || $name)/Process
		where $process/@id = $document
		return $process
	)[1]
};

declare function document:getDocument($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $binder as xs:string?, $document as xs:string) {
	let $process :=
		if (matches($document,'^PRO[0-9a-f\-]+$')) then
			if (not($binder)) then
				(
					for $folder in xmldb:get-child-collections(concat($home-data, '/', $tenant, '/', $year))
					return local:processById(concat($home-data, '/', $tenant, '/', $year, '/', $folder), $document)
				)[1]
			else
				local:processById(concat($home-data, '/', $tenant, '/', $year, '/', $binder), $document)
		else
			doc(concat($home-data,'/',$tenant,'/',$year,'/',$binder,'/',$document,'.dm.xml'))
	let $_ := document:stamp-file-hashes($home-data, $process, true())
	let $uri := if ($process) then document-uri(root($process)) else ()
	return
		if (not($uri)) then $process
		else if ($process instance of document-node()) then doc($uri)
		else doc($uri)/*
};

(: SHA-256 über den Dateiinhalt. $ref ist ein DB-Pfad oder ein Web-Pfad der Datei. :)
declare function document:hashcode($home-data as xs:string, $ref as xs:string?) as xs:string? {
	let $uri := local:binary-uris($home-data, $ref)[util:binary-doc-available(.)][1]
	return
		if (empty($uri)) then ()
		else local:content-hash($uri)
};

(: Schreibt @hashcode an Files/File. $missing-only lässt vorhandene Hashcodes stehen. :)
declare function document:stamp-file-hashes($home-data as xs:string, $node as node()?, $missing-only as xs:boolean) {
	for $file in $node//Files/File
	where not($missing-only) or not(matches(string($file/@hashcode), '^[0-9a-f]{64}$'))
	let $hash := (
		document:hashcode($home-data, string($file/@src)),
		document:hashcode($home-data, string($file/@uploadSrc))
	)[normalize-space(.) != ''][1]
	where exists($hash) and string($file/@hashcode) != $hash
	return
		try {
			if ($file/@hashcode) then
				update value $file/@hashcode with $hash
			else
				update insert attribute hashcode { $hash } into $file
		} catch * {
			()
		}
};


declare function document:createDocument($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $binder as xs:string, $filename as xs:string, $document-data) as element()
{
	let $user := sm:id()/sm:id/sm:real/sm:username/data()
	let $collection := concat($home-data,'/',$tenant,'/',$year,'/',$binder)
	let $resource-uri := concat('/',$tenant,'/',$year,'/binders/',$binder)
	let $document-id := concat('PRO',util:uuid())
	let $schema := doc('/db/apps/docman/resources/Process.xsd')
	return

	try {
		if ($filename='') then 
			error(xs:QName('docman:MissingFilename'),'No filename given')
		else if (matches($filename,'^PRO[a-f0-9\-]+$')) then 
			error(xs:QName('docman:IDinsteadOfFilename'),'to create a new file a filename has to be given')
		else if (not(validation:jaxv($document-data, $schema))) then
			error(xs:QName('docman:NotSchemaConform'),'The document can not be saved, as it is not schema conform.', validation:jaxv-report($document-data, $schema))
		else if (concat($filename,'.dm.xml')=xmldb:get-child-resources($collection)) then 
			error(xs:QName('docman:FileAlreadyExists'),'There is already a document with the name '||$filename||'.')
		else
			let $user := sm:id()/sm:id/sm:real/sm:username/data()
			let $store := xmldb:store($collection, $filename||'.dm.xml', $document-data)

			return
				if ($store = ()) then
					<error>Could not store {$filename||'.dm.xml'}</error>
				else 
					let $document := doc($collection||'/'||$filename||'.dm.xml')/Process
					let $setUser := update value $document/@user with $user
					let $setCreated := update value $document/@created with current-dateTime()
					let $setName := update value $document/@name with $filename
					let $setId := update value $document/@id with $document-id
					let $setTaskID := for $task in $document//Tasks/*[@id='ACCxxx']
						return
							update value $task/@id with concat('ACC',util:uuid())

					let $moveAttachements := for $attachment in $document/Tasks/*/Files/File[@uploadSrc]
								return local:moveAttachement($home-data, $tenant, $year, $binder, $attachment)
					let $hashes := document:stamp-file-hashes($home-data, $document, false())
					return
					<created resource="{$resource-uri}" document-id="{$document-id}" filename="{$filename||'.dm.xml'}">
						{$moveAttachements}
					</created>
	}
	catch * {
		<error>{$err:code, $err:value, $err:description, " module: ", $err:module, "(", $err:line-number, ",", $err:column-number, ") for ", $filename||'.dm.xml'}</error>
	}
};


declare function document:updateNotes($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $binder as xs:string, $document-id as xs:string, $text as xs:string) as element() {
	let $collection := concat($home-data, '/', $tenant, '/', $year, '/', $binder)
	let $process := collection($collection)/Process[@id = $document-id]
	return
		if (empty($process)) then
			error(xs:QName('docman:NoFileForID'), 'There is no file for the given document ID')
		else
			let $notes := $process/Notes
			let $_ :=
				if (exists($notes)) then
					update value $notes with $text
				else
					update insert <Notes>{$text}</Notes> into $process
			let $changed :=
				if (exists($process/@changed)) then
					update value $process/@changed with current-dateTime()
				else
					update insert attribute changed { current-dateTime() } into $process
			return
				<noted document-id="{$document-id}" binder="{$binder}"/>
};

(: Dokument-Intelligenz für Binder-PDFs neu lesen und in File/DocmanIntelligence schreiben. :)
declare function document:refreshIntelligence($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $binder as xs:string, $document-id as xs:string) as element() {
	let $collection := concat($home-data, '/', $tenant, '/', $year, '/', $binder)
	let $process := collection($collection)/Process[@id = $document-id]
	return
		if (empty($process)) then
			error(xs:QName('docman:NoFileForID'), 'There is no file for the given document ID')
		else
			let $accounts := di:accounts($home-data, $tenant, $year)
			let $results :=
				for $file in $process//Files/File
				let $name :=
					let $joined := normalize-space(string($file/@fileName) || string($file/@fileExtension))
					return
						if ($joined != '' and di:is-document($joined)) then $joined
						else
							let $from-src := tokenize(string($file/@src), '/')[last()]
							return if (di:is-document($from-src)) then $from-src else ''
				where $name != ''
				let $fresh :=
					try { di:run-at($home-data, $tenant, $year, $collection, $name, '', '') }
					catch * { <Error>{substring($err:description, 1, 500)}</Error> }
				let $shell := di:shell($name, '', '')
				let $intel :=
					if ($fresh/self::Error) then
						di:fail($shell, string($fresh))
					else if ($fresh/Error) then
						di:fail($shell, string($fresh/Error[1]))
					else if ($fresh//Error and empty($fresh/Fields) and empty($fresh/*/Fields)) then
						di:fail($shell, string(($fresh//Error)[1]))
					else
						let $payload :=
							if ($fresh/self::DocmanIntelligence) then $fresh
							else if ($fresh/DocmanIntelligence) then $fresh/DocmanIntelligence
							else $fresh/*
						return di:merge($shell, $payload, $accounts)
				let $_ := (
					if ($file/DocmanIntelligence) then update delete $file/DocmanIntelligence else (),
					update insert $intel into $file,
					if (string($intel/Source/@origin) = 'digital') then update value $file/@doctype with 'digital'
					else if (string($intel/Source/@origin) = 'scan') then update value $file/@doctype with 'paper'
					else ()
				)
				return
					<File name="{$name}" status="{$intel/@status}">
						{ if ($intel/@status = 'error') then $intel/Error else () }
					</File>
			let $changed :=
				if (exists($process/@changed)) then
					update value $process/@changed with current-dateTime()
				else
					update insert attribute changed { current-dateTime() } into $process
			return
				<IntelligenceRefresh document-id="{$document-id}" binder="{$binder}" files="{count($results)}" done="{count($results[@status='done'])}" error="{count($results[@status='error'])}">
					{$results}
				</IntelligenceRefresh>
};

declare function document:updateDocument($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $binder as xs:string, $document-id as xs:string, $document-data) as element()
{
	let $user := sm:id()/sm:id/sm:real/sm:username/data()
	let $collection := concat($home-data,'/',$tenant,'/',$year,'/',$binder)
	let $resource-uri := concat('/',$tenant,'/',$year,'/binders/',$binder)
	let $filename := xs:string(collection($collection)/Process[@id=$document-id]/@name)
	let $schema := doc('/db/apps/docman/resources/Process.xsd')
	let $currentBinder := if (collection($collection)/Process[@id=$document-id]/@binder) then collection($collection)/Process[@id=$document-id]/@binder else format-date(collection($collection)/Process[@id=$document-id]/@date,'[M00]')
	return

	try {
		if (not(matches($document-id,'^PRO[a-f0-9\-]+$'))) then 
			error(xs:QName('docman:InvalidDocumentID'),'Invalid Document ID &apos;'||$document-id||'&apos; given')
		else if (not(matches($filename,'^[A-Za-z0-9\-_\(\)]+$'))) then 
			error(xs:QName('docman:InvalidFilename'),'Invalid Filename &apos;'||$filename||'&apos; given')
		else if (string-length($filename) < 10) then
			error(xs:QName('docman:NoFileForID'),'There is no file for the given document ID')
		else if (not(validation:jaxv($document-data, $schema))) then
			error(xs:QName('docman:NotSchemaConform'),'The document can not be updated, as it is not schema conform.', validation:jaxv-report($document-data, $schema))
		else if ($binder != $currentBinder or $filename != $document-data/@name) then
			error(xs:QName('docman:MoveOfDocumentNotAllowed'),'The movement of a document is not supported. Current name: '||$currentBinder||'/'||$filename||', new name '||$binder||'/'||$document-data/@name||'.')
		else
			(: replace document-data :)
			let $update := xmldb:store($collection, $filename||'.dm.xml', $document-data)
			return
				if ($update = ()) then
					<error>Could not store {$filename||'.dm.xml'}</error>
				else 
					let $document := doc($collection||'/'||$filename||'.dm.xml')/Process
					let $setUser := update value $document/@user with $user
					let $setChanged := update value $document/@changed with current-dateTime()
					let $setTaskID := for $task in $document//Tasks/*[@id='ACCxxx']
						return
							update value $task/@id with concat('ACC',util:uuid())

					let $moveAttachements := for $attachment in $document/Tasks/*/Files/File[@uploadSrc]
						return local:moveAttachement($home-data, $tenant, $year, $binder, $attachment)
					let $hashes := document:stamp-file-hashes($home-data, $document, false())
					return
					<updated resource="{$resource-uri}" document-id="{$document-id}" filename="{$filename||'.dm.xml'}">
						{$moveAttachements}
					</updated>
		}
	catch * {
		<error>{$err:code, $err:value, $err:description, " module: ", $err:module, "(", $err:line-number, ",", $err:column-number, ") for ", $filename||'.dm.xml'}</error>
	}
};


declare function document:deleteDocument ($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $binder as xs:string, $document-id as xs:string) {
	let $collection := concat($home-data,'/',$tenant,'/',$year,'/',$binder)
	let $filename := if (matches($document-id,'^PRO[0-9a-f\-]+$')) then collection($collection)/Process[@id=$document-id]/@name else $document-id
	return
		if ($filename='') then 
			error(xs:QName('docman:MissingFilename'),'No filename given')
		else	
			let $files := 	<files>
				{
					for $file in doc($collection||'/'||$filename||'.dm.xml')/Process/Tasks/*/Files/File
					return
						try {
							(: let $delete := xmldb:remove($collection, $file) :)
							let $delete := xmldb:move($collection, concat($home-data,'/',$tenant,'/trash'), concat($file/@fileName, $file/@fileExtension))
							return
								<File name="{$file}" status="{$delete}"/>
						}
						catch * {
							<File name="{$file}" status="error"><error>Anhang konnte nicht geloescht werden</error></File>
						}
				}
				</files>


			(: soft delete :)
			let $remove_doc := xmldb:move($collection, concat($home-data,'/',$tenant,'/trash'), $filename||'.dm.xml')
			(: let $remove_doc := xmldb:remove($collection, $filename||'.dm.xml') :)
			return
				<delete version="1.0" resource="binder" resource-id="{$document-id}" status="{$remove_doc}">
				{
					$files
				}
				</delete>
};


declare function document:insertTask ($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $binder-t as xs:string?, $document-id as xs:string, $task) as node() {
	let $collection := concat($home-data,'/',$tenant,'/',$year) (: ,'/',$binder :)
	let $document := collection($collection)/Process[@id=$document-id]
	let $binder := if (not($binder-t)) then format-date($document/@date,'[M00]') else $binder-t
	let $resource-uri := concat('/',$tenant,'/',$year,'/binders/',$binder)
	let $schema := doc('/db/apps/docman/Process.xsd')
	return
	if (not(validation:jaxv($task, $schema))) then
			error(xs:QName('docman:NotSchemaConform'),'The task can not be saved, as it is not schema conform.', validation:jaxv-report($task, $schema))
	else
		let $insert := update insert $task into $document/Tasks
		let $updateTaskIDs := 
			for $accounting in $document/Tasks/*/Bookings/Booking[@id='']
			return 
				update value $accounting/@id with concat('ACC',util:uuid())
		let $moveAttachements := 
			for $attachment in $document/Tasks/*/Files/File[@uploadSrc]
			return local:moveAttachement($home-data, $tenant, $year, $binder, $attachment)
		let $hashes := document:stamp-file-hashes($home-data, $document, false())
		return
			<stored resource="{$resource-uri}" resource-id="{$document-id}">
				{$document}
				{$moveAttachements}
			</stored>
};


declare function document:insertFile ($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $document-id as xs:string, $file) as node() {
	let $collection := concat($home-data,'/',$tenant,'/',$year) (: ,'/',$binder :)
	let $document := collection($collection)/Process[@id=$document-id]
	let $insert := update insert $file into $document/Files
	return
		$document

};


declare function document:validateProcess ($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $process-id as xs:string) {
	let $data-collection := concat($home-data,'/',$tenant,'/',$year)
	let $process := collection($data-collection)/Process[@id = $process-id]
	return
	
	(: check that the date is taken from the bank account activity :)
	if ($prcess/PaymentTask/Bookings/Booking/@date != collection($collection)//Accounting[@id=$item/@refID]/ValueDate) then
		error(xs:QName('docman:ProcessValidation'),'The process &amp;'||$process-id||' does not have the bank movent date given as booking date')
	else
		()

};



(: ############# local functions ############# :)

declare function local:year-processes($year-col as xs:string) as element(Process)* {
	for $folder in xmldb:get-child-collections($year-col)
	return collection($year-col || '/' || $folder)/Process
};

declare function local:file-twins($year-col as xs:string) as element(Twins) {
	<Twins>
	{
		for $file in local:year-processes($year-col)//Files/File[matches(@hashcode, '^[0-9a-f]{64}$')]
		group by $hash := string($file/@hashcode)
		where count($file) gt 1
		return
			<Twin hash="{$hash}" count="{count($file)}">
			{
				for $name in distinct-values($file/ancestor::Process/@name)
				order by $name
				return <Name>{$name}</Name>
			}
			</Twin>
	}
	</Twins>
};

declare function local:strip-web($ref as xs:string) as xs:string {
	replace(replace(replace($ref, '^https?://[^/]+', ''), '^/exist/apps/docman', ''), '^/app', '')
};

(: Mögliche DB-Pfade zu einer Datei: Ablage, Transfer oder direkter Datenpfad. :)
declare function local:binary-uris($home-data as xs:string, $ref as xs:string?) as xs:string* {
	let $raw := normalize-space(string($ref))
	let $path := local:strip-web($raw)
	where $path != ''
	return
		distinct-values((
			if (starts-with($raw, '/db/')) then $raw else (),
			if (starts-with($path, '/db/')) then $path else (),
			if (matches($path, '^/[^/]+/[0-9]{4}/binders/.+')) then
				$home-data || replace($path, '^(/[^/]+/[0-9]{4})/binders/', '$1/')
			else (),
			if (starts-with($path, '/') and not(starts-with($path, '/db/'))) then
				$home-data || $path
			else ()
		))
};

declare function local:content-hash($uri as xs:string) as xs:string? {
	try {
		let $digest := function-lookup(xs:QName('util:binary-doc-content-digest'), 2)
		let $value :=
			if (exists($digest)) then
				lower-case(string($digest($uri, 'SHA-256')))
			else
				lower-case(util:hash(string(util:binary-doc($uri)), 'SHA-256', false()))
		return
			if (matches($value, '^[0-9a-f]{64}$')) then $value else ()
	} catch * {
		()
	}
};

declare function local:moveAttachement($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $binder as xs:string, $attachment) as element() {

	let $transfer-collection := concat($home-data,'/',$tenant,'/',$year,'/transfer')
	return
		if (contains($attachment/@uploadSrc,concat('/',$tenant,'/',$year,'/transfer/'))) then 
				let $move := local:moveFileFromTransfer($home-data, $tenant, $year, $binder, $attachment/@fileName, $attachment/@fileExtension, $attachment/@uploadName)
				return
					if ($move/self::error) then
						$move
					else
						let $transfer-file := replace(string($attachment/@uploadSrc), '.*/', '')
						let $intel-name := di:locate(di:collection($home-data, $tenant, $year), $transfer-file)
						let $intel := if ($intel-name = '') then () else doc(di:collection($home-data, $tenant, $year) || '/' || $intel-name)/DocmanIntelligence
						let $embed :=
							if (empty($intel)) then ()
							else (
								if ($attachment/DocmanIntelligence) then update delete $attachment/DocmanIntelligence else (),
								update insert $intel into $attachment,
								if (string($intel/Source/@origin) = 'digital') then update value $attachment/@doctype with 'digital'
								else if (string($intel/Source/@origin) = 'scan') then update value $attachment/@doctype with 'paper'
								else ()
							)
						let $setSrc := update value $attachment/@src with concat('/', $tenant, '/', $year, '/binders/', $binder, '/', $attachment/@fileName, $attachment/@fileExtension)
						let $dropUploadSrc := update delete $attachment/@uploadSrc
						let $archive := di:archive($home-data, $tenant, $year, $transfer-file, $attachment/ancestor::*[local-name() = 'Process'][1])
						return
							<Attachment status="moved">
							</Attachment>
		else if (matches($attachment/@uploadSrc, concat('.*/',$tenant,'/',$year,'/banking/([A-Za-z0-9]+)/(PAY[A-Za-z0-9-]+)\.pdf'))) then 
					<Attachment status="moved" location="{$attachment/@uploadSrc}">
					</Attachment>

		else if (matches($attachment/@uploadSrc, concat('.*/',$tenant,'/',$year,'/banking/([A-Za-z0-9]+)/(PAY[A-Za-z0-9-]+)/periodic-payment\.pdf'))) then 
				let $doc := util:binary-doc(concat('/app/',$attachment/@uploadSrc)) 
				return
					<Attachment status="moved" location="{$attachment/@uploadSrc}">
					</Attachment>

		else if (contains($attachment/@uploadSrc,concat('/',$tenant,'/',$year,'/mail/'))) then
				let $params := subsequence(analyze-string($attachment/@uploadSrc, '/'||$tenant||'/'||$year||'/mail/([0-9]+)/attachment/([0-9]+)/(.*)')//fn:group, 1)
				let $newBinder := concat('/', $tenant, '/', $year, '/', $binder, '/')
				let $emailattachment := email:read-attachment($tenant, $params[1], $params[2])/mail:attachment
				let $store := xmldb:store-as-binary($home-data||$newBinder, concat($attachment/@fileName, $attachment/@fileExtension), xs:base64Binary($emailattachment/text()))
				let $setSrc := update value $attachment/@src with concat($newBinder, $attachment/@fileName, $attachment/@fileExtension)
				return
					if (not($emailattachment/text())) then
						error(xs:QName('docman:NoAttachmentGiven'),'There is no valid email attachement &apos;'||concat($attachment/@fileName, $attachment/@fileExtension)||'&apos; given.')
					else if ($store = ()) then
						error(xs:QName('docman:EmailAttachmentCouldNotBeStored'),'The email attachement &apos;'||concat($attachment/@fileName, $attachment/@fileExtension)||'&apos; could not be stored.')
					else
						<Attachment status="stored" location="{$attachment/@uploadSrc}">
						</Attachment>

		(: todo: else if (src = ablage) then move file :)
		else
			error(xs:QName('docman:InvalidAttachmentType'), " The attachment source type '"||$attachment/@uploadSrc/data()||"' is unknown."||concat('.*/',$tenant,'/',$year,'/banking/([A-Za-z0-9]+)/(PAY[A-Za-z0-9-]+)/periodic-payment\.pdf'), $attachment)
};
 

(:
	$document-name - Neuer Name im Dokument Ordner
	$document-extension - Datei Endung für Dokument Ordner
	$file-id - Aktueller Name im Transfer Ordner
:)
declare function local:moveFileFromTransfer($home-data as xs:string, $tenant as xs:string, $year as xs:string, $binder as xs:string, $document-name as xs:string, $document-extension as xs:string, $file-id as xs:string) {

	let $filename-pattern as xs:string := '^[A-Za-z0-9ÄÖÜäöüß_\(\)\+\$_\-\. ]+\.(pdf|tif|tiff|png|gif|jpg|jpeg|txt|xml|csv)$' 

	let $document-id := concat($document-name,lower-case($document-extension))
	let $tenant-collection := $home-data||'/'||$tenant
	let $binder-collection := $home-data||'/'||$tenant||'/'||$year||'/'||$binder
	let $transfer-collection := $home-data||'/'||$tenant||'/'||$year||'/transfer' 
	return

	if ($tenant='' or $document-name='' or $document-extension='' or $file-id='') then
		<error>Pflichtfelder sind nicht vollständig gefüllt: $tenant='{$tenant}' or $document-name='{$document-name}' or $document-extension='{$document-extension}'or $file-id='{$file-id}'</error>

	else if (not(matches($file-id, $filename-pattern))) then
		<error>Datei "{$file-id}" ist kein gueltiger Datei-Name. Must match {$filename-pattern}.</error>

	else if (not(matches($document-id, $filename-pattern))) then
		<error>Dokument "{$document-id}" ist kein gueltiger Dokument-Name. Must match {$filename-pattern}.</error>

	else if (empty(index-of(xmldb:get-child-resources($transfer-collection),$file-id))) then
		<error>Datei "{$file-id}" existiert nicht (im Transfer Ordner).</error>

(:
	else if (index-of(xmldb:get-child-resources($binder-collection), $document-id||'.dm.xml') != 0) then
		<error>Dokument "{$document-id}" ist bereits vorhanden (abgeheftet).</error>

	else if (index-of(xmldb:get-child-resources($binder-collection), $document-id) != 0) then
		<error>Attachment "{$document-id}" ist bereits vorhanden (abgeheftet).</error>
:)
	else
		let $move1 := xmldb:move($transfer-collection, $tenant-collection, $file-id)
		let $rename := if ($file-id != $document-id) then xmldb:rename($tenant-collection, $file-id, $document-id) else "unchanged"
		let $move2 := xmldb:move($tenant-collection, $binder-collection, $document-id)
		return
		if (empty($move1)) then
			<error>Datei konnte nicht in Temp Ordner verschoben werden</error>
		else if ($file-id != $document-id and empty($rename) and empty(index-of(xmldb:get-child-resources($tenant-collection), $document-id))) then
			<error>Datei konnte nicht umbenannt werden.</error>
		else if (empty($move2)) then
			<error>Datei konnte nicht vom Temp Ordner in den Dokumente Ordner verschoben werden.</error>
		else			
			<moved document-id="{$document-id}" from="transfer" to="{concat('/',$tenant,'/',$year,'/binders/',$binder)}"/>
};



(: Test from .xqy
import module namespace document="http://bintellix.com/docman/document" at "/db/apps/docman/modules/module_document.xqm"; 

let $data-collection := '/db/apps/docman/data'
let $tenant := 'test'
let $file := $data-collection || '/' || $tenant || '/2020/01/2020-01-01_Test.dm.xml'

let $data :=  doc($file)/Document/Tasks/*/Files/File[@uploadSrc]
return
<result>
	<data src="{$file}">{$data}</data>
	<function>
	{local:moveAttachement($data-collection, $tenant, '2020', '01', $data)}
	</function>
</result>
:)
 