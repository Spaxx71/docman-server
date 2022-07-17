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

import module namespace banking="http://bintellix.com/docman/banking" at "/db/apps/docman/modules/module_banking.xqm";
import module namespace email="http://bintellix.com/docman/email" at "/db/apps/docman/modules/module_email.xqm";

declare namespace docman = "http://docman.bintellix.com";

(: ############  public functions  ########### :)

declare function document:listDocuments ($dm-home-data as xs:string, $tenant as xs:string, $year as xs:integer, $owner as xs:string?) {
	<Binders version="1.0" tenantId="{$tenant}">
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
					let $doc := doc($document-collection||'/'||$document)/Process
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
	<Binders version="1.0" tenantId="{$tenant}">
		<Binder name="{$binder}" tenantId="{$tenant}" year="{$year}" binder="{$binder}">
		{ 
			let $document-collection := $dm-home-data||'/'||$tenant||'/'||$year||'/'||$binder
			for $document in xmldb:get-child-resources($document-collection)
			where ends-with($document,'.dm.xml')
			let $doc := doc($document-collection||'/'||$document)/Process
			order by $doc/@date, $doc/@name
			return
				<Process>
					{$doc/@*}
					{$doc/*}
				</Process>
		}
		</Binder>
	</Binders>
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


declare function document:getDocument($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $binder as xs:string?, $document as xs:string) {
	if (matches($document,'^PRO[0-9a-f\-]+$')) then
		if (not($binder)) then
			collection(concat($home-data,'/',$tenant,'/',$year))/Process[@id=$document]
		else
			collection(concat($home-data,'/',$tenant,'/',$year,'/',$binder))/Process[@id=$document]
	else
		doc(concat($home-data,'/',$tenant,'/',$year,'/',$binder,'/',$document,'.dm.xml'))
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
								return
									let $move := local:moveAttachement($home-data, $tenant, $year, $binder, $attachment)
									let $delUploadSrc := update delete $attachment/@uploadSrc
									let $updateSrc := update value $attachment/@src with concat($resource-uri, '/', $attachment/@fileName, $attachment/@fileExtension) 
									return 
										$attachment
					return
					<created resource="{$resource-uri}" document-id="{$document-id}" filename="{$filename||'.dm.xml'}">
						{$moveAttachements}
					</created>
	}
	catch * {
		<error>{$err:code, $err:value, $err:description, " module: ", $err:module, "(", $err:line-number, ",", $err:column-number, ") for ", $filename||'.dm.xml'}</error>
	}
};


declare function document:updateDocument($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $binder as xs:string, $document-id as xs:string, $document-data) as element()
{
	let $user := sm:id()/sm:id/sm:real/sm:username/data()
	let $collection := concat($home-data,'/',$tenant,'/',$year,'/',$binder)
	let $resource-uri := concat('/',$tenant,'/',$year,'/binders/',$binder)
	let $filename := xs:string(collection($collection)/Process[@id=$document-id]/@name)
	let $schema := doc('/db/apps/docman/Process.xsd')
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
						return
							let $move := local:moveAttachement($home-data, $tenant, $year, $binder, $attachment)
							let $delUploadSrc := update delete $attachment/@uploadSrc
							let $updateSrc := update value $attachment/@src with concat($resource-uri, '/', $attachment/@fileName, $attachment/@fileExtension) 
							return 
								$attachment
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
			return
				let $move := local:moveAttachement($home-data, $tenant, $year, $binder, $attachment)
				let $delUploadSrc := update delete $attachment/@uploadSrc
				let $updateSrc := update value $attachment/@src with concat($resource-uri, '/', $attachment/@fileName, $attachment/@fileExtension) 
				return 
					$attachment
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
declare function local:moveAttachement($home-data as xs:string, $tenant as xs:string, $year as xs:integer, $binder as xs:string, $attachment) as element() {

	let $transfer-collection := concat($home-data,'/',$tenant,'/',$year,'/transfer')
	return
		if (contains($attachment/@uploadSrc,concat('/',$tenant,'/',$year,'/transfer/'))) then 
				let $move := local:moveFileFromTransfer($home-data, $tenant, $year, $binder, $attachment/@fileName, $attachment/@fileExtension, $attachment/@uploadName)
				let $setSrc := update value $attachment/@src with concat('/', $tenant, '/', $year, '/', $binder, '/', $attachment/@fileName, $attachment/@fileExtension)
				let $dropUploadSrc := update delete $attachment/@uploadSrc
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

	let $filename-pattern as xs:string := '^[A-Za-z0-9Ä-Öä-ö_\(\)\-\.]+\.(pdf|tif|tiff|png|gif|txt|xml)$' 

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

	else if (index-of(xmldb:get-child-resources($transfer-collection),$file-id) = 0) then
		<error>Datei "{$file-id}" existiert nicht (im Transfer Ordner).</error>

(:
	else if (index-of(xmldb:get-child-resources($binder-collection), $document-id||'.dm.xml') != 0) then
		<error>Dokument "{$document-id}" ist bereits vorhanden (abgeheftet).</error>

	else if (index-of(xmldb:get-child-resources($binder-collection), $document-id) != 0) then
		<error>Attachment "{$document-id}" ist bereits vorhanden (abgeheftet).</error>
:)
	else
		let $move1 := xmldb:move($transfer-collection, $tenant-collection, $file-id)
		let $rename := if ($file-id != $document-id) then xmldb:rename($tenant-collection, $file-id, $document-id) else ()
		let $move2 := xmldb:move($tenant-collection, $binder-collection, $document-id)
		return
		if ($move1 = ()) then
			<error>Datei konnte nicht in Temp Ordner verschoben werden</error>
		else if ($rename = ()) then
			<error>Datei konnte nicht umbenannt werden.</error>
		else if ($move2 = ()) then
			<error>Datei konnte nicht vom Temp Ordner in den Dokumente Ordner verschoben werden.</error>
		else			
			<moved document-id="{$document-id}" from="transfer" to="{concat('/',$tenant,'/',$year,'/binder/',$binder)}"/>
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
 