<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xf="http://www.w3.org/2002/xforms" version="3.1">
 
	<!-- todo attachment https://docman.bintellix.com/app/test/2020/binders/01/PRO49476a8f-b159-42ab-876a-8fb15962abe9/edit/invoice-in.html?task=TransferVoucher&ref=/test/2020/transfer/2020-01-10_Rechnung_(Allnet)_(A123)_(B123)_(C123).pdf -->
	<xsl:import href="templates/template_tasks.xsl"/>
	<xsl:import href="templates/template_file.xsl"/>

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="home-data" required="yes"/>
	<xsl:param name="home-views"/>
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="year" required="yes"/>
	<xsl:param name="resource-id"/>
	<xsl:param name="username"/>
	<xsl:param name="path"/>
	<xsl:param name="binder"/>
	<xsl:param name="function" required="yes"/>
	<xsl:param name="attach"/>
	<xsl:param name="ref"/>
	<xsl:param name="type" select="'undefined'"/> <!-- which type of document process -->

	<xsl:param name="new-document" select="contains($path,'/enter/')"/> <!-- or $attach != '' -->
	<xsl:param name="is-storno" select="if (matches(upper-case($type),'STORNO$')) then true() else result/Process/Tasks/*[1]/@isStorno='true'"/>

	<xsl:variable name="isReadonly" select="'true()'"/>

	<xsl:variable name="date">
		<xsl:choose>
			<xsl:when test="matches(/result/@resource-id, '^20[0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]([_-])(.*)')">
				<xsl:value-of select="substring(/result/@resource-id,1,10)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="format-date(current-date(),'[Y0000]-[M00]-[D00]')"/>
			</xsl:otherwise> 
		</xsl:choose>
	</xsl:variable>


	<xsl:template match="/">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="result">
		<xhtml:html xmlns:xhtml="http://www.w3.org/1999/xhtml">
			<head>
				<style>
.xforms-alert .xforms-alert-value {
	display:block;
	position: absolute;
	top: 2rem;
	right: 2rem;
}

.Sumup {
	border-top: 2px solid #333;
}
				</style>
				<xf:model schema="" id="M">
					<xsl:choose>
						<xsl:when test="$attach = ''">
							<xf:instance xmlns="" id="attachtask-extern">
								<data/>
							</xf:instance>
						</xsl:when>
						<xsl:when test="$attach = 'TransferVoucher'">
							<xf:instance xmlns="" id="attachtask-extern" src="/app/{$tenant}/{$year}/binders/{/result/Process/@id}/attach/transfer-voucher.xml?ref={$ref}"/>
						</xsl:when>
						<xsl:when test="$attach = 'DunningFee'">
							<xf:instance xmlns="" id="attachtask-extern" src="/app/{$tenant}/{$year}/binders/{/result/Process/@id}/attach/dunning-fee.xml?ref={$ref}"/>
						</xsl:when>
						<xsl:when test="$attach = 'DeliveryNote'">
							<xf:instance xmlns="" id="attachtask-extern" src="/app/{$tenant}/{$year}/binders/{/result/Process/@id}/attach/delivery-note.xml?ref={$ref}"/>
						</xsl:when>
						<xsl:when test="$attach = 'Payment'">
							<xf:instance xmlns="" id="attachtask-extern" src="/app/{$tenant}/{$year}/binders/{/result/Process/@id}/attach/payment.xml?ref={$ref}"/>
						</xsl:when>	
						<xsl:when test="$attach = 'Attachment'">
							<xf:instance xmlns="" id="attachtask-extern" src="/app/{$tenant}/{$year}/binders/{/result/Process/@id}/attach/attachment.xml?ref={$ref}"/>
						</xsl:when>					
						<xsl:otherwise>
							<xf:instance xmlns="" id="attachtask-extern">
								<undefinded><xsl:value-of select="attach"/></undefinded>
							</xf:instance>
						</xsl:otherwise>
					</xsl:choose>
					<xf:instance xmlns="" id="attachtask-new">
						<data>
							<xsl:choose>
								<xsl:when test="$function='InvoiceIn'">
									<Task name="Artikel" type="CommodityTask">
										<CommodityTask type="{if ($is-storno) then 'invoice-in-storno' else 'invoice-in'}" id="ACCxxx" date="" created="{current-dateTime()}" isMaster="false" user="{$username}" isStorno="false">
											<Notes/>
											<Files/>
											<Bookings>
												<Booking date="" quality="3" amountValue="" amountUnit="EUR" credit="" debit="" taxKey="" taxAmount="0" refID="" description=""/>
											</Bookings>
											<Amount value="-0" unit="EUR"/>
											<Tax key="" region="" type=""/>
											<Other/>
											<Description/>
										</CommodityTask>
									</Task>
									<Task name="Skonto" type="DiscountTask">
										<DiscountTask type="discount" id="ACCxxx" date="" created="{current-dateTime()}" isMaster="false" user="{$username}" isStorno="false">
											<Notes/>
											<Files/>
											<Bookings>
												<Booking date="" quality="3" amountValue="" amountUnit="EUR" credit="" debit="" taxKey="-" taxAmount="0" refID="#" description=""/>
											</Bookings>
											<Amount value="0" unit="EUR"/>
											<RefID/>
											<Description/>
										</DiscountTask>
									</Task>
									<Task name="Mahngebühr" type="DunningFeeTask">								
										<DunningFeeTask type="dunning-fee" id="ACCxxx" date="" created="{current-dateTime()}" isMaster="false" user="{$username}" isStorno="false">
											<Notes/>
											<Files/>
											<Bookings>
												<Booking date="" quality="3" amountValue="" amountUnit="EUR" credit="" debit="6855" taxKey="1" taxAmount="0" refID="#" description=""/>
											</Bookings>
											<Amount value="-0.0" unit="EUR"/>
											<RefID/>
											<Description/>
										</DunningFeeTask>
									</Task>
									<Task name="Anhang" type="AttachmentTask">								
										<AttachmentTask type="dunning-fee" id="ACCxxx" date="" created="{current-dateTime()}" isMaster="false" user="{$username}" isStorno="false">
											<Notes/>
											<Files/>
											<Bookings>
												<Booking date="" quality="3" amountValue="" amountUnit="EUR" credit="" debit="6855" taxKey="1" taxAmount="0" refID="#" description=""/>
											</Bookings>
											<Amount value="-0.0" unit="EUR"/>
											<DocName/>
											<RefID/>
											<Description/>
										</AttachmentTask>
									</Task>
								</xsl:when>
								<xsl:when test="$function='InvoiceOut'">
									<Task name="Artikel" type="CommodityTask">
										<CommodityTask type="{if ($is-storno) then 'invoice-in-storno' else 'invoice-in'}" id="ACCxxx" date="" created="{current-dateTime()}" isMaster="false" user="{$username}" isStorno="false">
											<Notes/>
											<Files/>
											<Bookings>
												<Booking date="" quality="3" amountValue="" amountUnit="EUR" credit="" debit="" taxKey="" taxAmount="0" refID="" description=""/>
											</Bookings>
											<Amount value="" unit="EUR"/>
											<Tax key="" region="" type=""/>
											<Other/>
											<Description/>
										</CommodityTask>
									</Task>
									<Task name="Skonto" type="DiscountTask">
										<DiscountTask type="discount" id="ACCxxx" date="" created="{current-dateTime()}" isMaster="false" user="{$username}" isStorno="false">
											<Notes/>
											<Files/>
											<Bookings>
												<Booking date="" quality="3" amountValue="" amountUnit="EUR" credit="" debit="" taxKey="-" taxAmount="0" refID="#" description=""/>
											</Bookings>
											<Amount value="0" unit="EUR"/>
											<RefID/>
											<Description/>
										</DiscountTask>
									</Task>
									<Task name="Anhang" type="AttachmentTask">								
										<AttachmentTask type="dunning-fee" id="ACCxxx" date="" created="{current-dateTime()}" isMaster="false" user="{$username}" isStorno="false">
											<Notes/>
											<Files/>
											<Bookings>
												<Booking date="" quality="3" amountValue="" amountUnit="EUR" credit="" debit="6855" taxKey="1" taxAmount="0" refID="#" description=""/>
											</Bookings>
											<Amount value="-0.0" unit="EUR"/>
											<DocName/>
											<RefID/>
											<Description/>
										</AttachmentTask>
									</Task>
								</xsl:when>								
							</xsl:choose>		
						</data>
					</xf:instance>

					<xsl:call-template name="ProcessModel"/>				

					<xf:action ev:event="xforms-ready">
						<xsl:if test="$attach != ''">
							<!-- hinzufügen eines Task per externem Import via  instance('attachtask-extern') -->
							<xf:insert origin="instance('attachtask-extern')/{$attach}Task" nodeset="instance('document')/Process/Tasks/*" at="last()" position="after"/>
							<xsl:call-template name="AddTask"/>							
						</xsl:if>

						<xsl:choose>
							<xsl:when test="$function='Simple'">
								<xsl:choose>
									<xsl:when test="$new-document">
										<xf:setvalue ref="instance('document')/Process/TotalAmount/@value" value="'0.0'"/>
										<xf:setvalue ref="instance('document')/Process/TotalAmount/@unit" value="'EUR'"/>
										<xf:setvalue ref="instance('document')/Process/Tasks/SimpleTask/@date" value="instance('document')/Process/@date"/>
										<xf:setvalue ref="instance('document')/Process/Tasks/SimpleTask/Files/File/@type" value="'doc-information'"/>
									</xsl:when>
								</xsl:choose>
							</xsl:when>
							<xsl:when test="$function='InvoiceIn'">
								<xsl:choose>
									<xsl:when test="$new-document">
										<!-- set attachment filetype -->
										<xf:setvalue ref="instance('document')/Process/Tasks/InvoiceInTask/@date" value="instance('document')/Process/@date"/>
										<xf:setvalue ref="instance('temp')/TaskType" value="'CommodityTask'"/>
										<xsl:choose>
											<xsl:when test="$is-storno">
												<xf:setvalue ref="instance('document')/Process/Tasks/InvoiceInTask/Files/File/@type" value="'doc-invoice-in-storno'"/>
											</xsl:when>
											<xsl:otherwise>
												<xf:setvalue ref="instance('document')/Process/Tasks/InvoiceInTask/Files/File/@type" value="'doc-invoice-in'"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
								</xsl:choose>
							</xsl:when>
							<xsl:when test="$function='InvoiceOut'">
								<xsl:choose>
									<xsl:when test="$new-document">
										<!-- set attachment filetype -->
										<xf:setvalue ref="instance('file-new')/File/@type" value="instance('document')/Process/@type"/>
										<xf:setvalue ref="instance('document')/Process/Tasks/InvoiceOutTask/@date" value="instance('document')/Process/@date"/>
										<xf:setvalue ref="instance('temp')/TaskType" value="'CommodityTask'"/>
										<xsl:choose>
											<xsl:when test="$is-storno">
												<xf:setvalue ref="instance('document')/Process/Tasks/InvoiceOutTask/Files/File/@type" value="'doc-invoice-out-storno'"/>
											</xsl:when>
											<xsl:otherwise>
												<xf:setvalue ref="instance('document')/Process/Tasks/InvoiceOutTask/Files/File/@type" value="'doc-invoice-out'"/>
											</xsl:otherwise>
										</xsl:choose>										
									</xsl:when>
								</xsl:choose>
							</xsl:when>							
							<xsl:when test="$function='Document'">
								<xsl:choose>
									<xsl:when test="$new-document">
										<xf:setvalue ref="instance('document')/Process/@type" value="'doc-{$type}'"/>
										<xsl:choose>
											<xsl:when test="$type='bank-statement'">
												<xf:setvalue ref="instance('document')/Process/@binder" value="'{substring($date,6,2)}'"/>
												<xf:setvalue ref="instance('document')/Process/Tasks/DocumentTask/DocName" value="'Kontoauszug von Konto xxx - Auszug #00'"/>
											</xsl:when>
											<xsl:otherwise>
												<xf:setvalue ref="instance('document')/Process/@binder" value="'{$type}'"/>
											</xsl:otherwise>
										</xsl:choose>
										<xf:setvalue ref="instance('document')/Process/TotalAmount/@value" value="'0.0'"/>
										<xf:setvalue ref="instance('document')/Process/TotalAmount/@unit" value="'EUR'"/>
										<xf:setvalue ref="instance('document')/Process/Tasks/DocumentTask/@type" value="concat('doc-','{$type}')"/>
															
										<!-- set attachment filetype -->
										<xf:setvalue ref="instance('document')/Process/Tasks/DocumentTask/Files/File/@type" value="concat('doc-','{$type}')"/>

										<xf:setvalue ref="instance('document')/Process/Tasks/DocumentTask/@date" value="instance('document')/Process/@date"/>
									</xsl:when>
									<xsl:otherwise>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
							<xsl:when test="$function='Tax'">
								<xsl:choose>
									<xsl:when test="$new-document">							
										<xf:setvalue ref="instance('document')/Process/@type" value="'tax'"/>
										<xf:setvalue ref="instance('document')/Process/TotalAmount/@value" value="'0.0'" if="instance('document')/Process/TotalAmount/@value=''"/>
										<xf:setvalue ref="instance('document')/Process/TotalAmount/@unit" value="'EUR'" if="instance('document')/Process/TotalAmount/@unit=''"/>
										<xf:setvalue ref="instance('document')/Process/Tasks/TaxTask/@date" value="instance('document')/Process/@date" if="instance('document')/Process/Tasks/TaxTask/@date=''"/>
										<xf:setvalue ref="instance('document')/Process/Tasks/TaxTask/Files/File/@type" value="'doc-tax'"/>
									</xsl:when>
									<xsl:otherwise>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
							<xsl:when test="$function='EmployeeSalary'">
								<xsl:choose>
									<xsl:when test="$new-document">							
										<xf:setvalue ref="instance('document')/Process/@type" value="'employee-salary'"/>
										<xf:setvalue ref="instance('document')/Process/TotalAmount/@value" value="'0.0'"/>
										<xf:setvalue ref="instance('document')/Process/TotalAmount/@unit" value="'EUR'"/>
										<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Files/File/@type" value="'doc-payslip'"/>
										<!-- <xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/@date" value="instance('document')/Process/@date"/> NICHT das Datum sezten -->
									</xsl:when>
									<xsl:otherwise>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
							<xsl:when test="$function='BankBalancing'">
								<xsl:choose>
									<xsl:when test="$new-document">
										<xf:setvalue ref="instance('document')/Process/@type" value="'bank-balancing'"/>
										<xf:setvalue ref="instance('document')/Process/Tasks/BankBalancingTask/Files/File/@type" value="'doc-bank-transfer'"/>
									</xsl:when>
									<xsl:otherwise>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
							<xsl:when test="$function='DeliveryNote'">
								<xsl:choose>
									<xsl:when test="$new-document">
										<xf:setvalue ref="instance('document')/Process/Tasks/DeliveryNoteTask/@type" value="'doc-delivery-note'"/>
										<xf:setvalue ref="instance('document')/Process/Tasks/DeliveryNoteTask/@date" value="instance('document')/Process/Tasks/InvoiceInTask/@date"/>
										<xf:setvalue ref="instance('document')/Process/Tasks/DeliveryNoteTask/@is-storno" value="'{$is-storno}'"/>
										<xf:setvalue ref="instance('document')/Process/Tasks/DeliveryNoteTask/Files/File/@type" value="'doc-delivery-note'"/>
									</xsl:when>
									<xsl:otherwise>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
							<xsl:when test="$function='Attachment'">
								<xsl:choose>
									<xsl:when test="$new-document">
										<!-- <xf:setvalue ref="instance('document')/Process/Tasks/AttachmentTask/@type" value="'doc-undefined'"/> -->
										<!-- <xf:setvalue ref="instance('document')/Process/Tasks/AttachmentTask/Files/File/@type" value="'doc-undefined'"/> -->
										<xf:setvalue ref="instance('document')/Process/Tasks/AttachmentTask/@is-storno" value="'{$is-storno}'"/>
									</xsl:when>
									<xsl:otherwise>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:when>					
						</xsl:choose>
					</xf:action>

				</xf:model>
			</head>
			<body>
				<!--
				<div class="Debug">
					[$function=<xsl:value-of select="$function"/>]
					[$attach=<xsl:value-of select="$attach"/>]
					[$type=<xsl:value-of select="$type"/>]
					[$ref=<xsl:value-of select="$ref"/>]
					[result/Process/@isStorno=<xsl:value-of select="result/Process/@isStorno"/>]
					[$is-storno=<xsl:value-of select="$is-storno"/>]
				</div>
				-->
				
				<div class="flex">
					<!--
					<xf:trigger>
						<xf:label>Test</xf:label>
						<xf:action ev:event="DOMActivate">
							<xf:setvalue ref="xxx" value="'test'"/>
						</xf:action>
					</xf:trigger>
					-->
					<div class="Form" style="min-width: 800px;">
						<xf:output value="instance('attachtask-extern')//error/text()"/>
						<xf:output value="instance('document')//error"/>

						<xf:group ref="instance('document')/Process">
							<div class="DocHeader">
								<!-- <xf:output ref="@type"/> erstellt am <xf:output value="substring(@created,1,10)"/> -->
								<xf:output ref="@name">
									<xf:label>Vorgang Name:</xf:label>
									<xf:alert>Der Vorgang Name ist noch nicht gültig</xf:alert>
								</xf:output>
								<br/>
		
								<xf:input ref="@date">
									<xf:label>Datum:</xf:label>
									<xf:alert>Das Datum muss in der aktuellen Periode liegen.</xf:alert>
								</xf:input>
								<br/>
		
								<xf:select1 ref="@binder">
									<xf:label>Ablageordner:</xf:label>
									<xf:hint>Hierbei handelt es sich um eine logische Gruppierung gemäß definierter Kriterien</xf:hint>
									<xf:alert>Der Ablageordner muss ggf. dem aktuellen Buchungsmonat entsprechen.</xf:alert>
									<xf:itemset nodeset="instance('binders')/Binders/Binder">
										<xf:label ref="@name"/>
										<xf:value ref="@name"/>
									</xf:itemset>
								</xf:select1>
								<br/>
		
								<xf:input ref="TotalAmount/@value" id="TotalValue">
									<xf:label>Gesamtbetrag:</xf:label>
									<xf:alert>Bitte einen negativen Betrag eingeben (bei STORNO einen positiven Betrag)</xf:alert>
									<xf:hint>Automatisch berechnete Summe aller einzelnen Positionen, als negativer Betrag (außer bei STORNO, dort als positiven Betrag)</xf:hint>
								</xf:input>
								<xf:output value="' EUR'"/>
								<br/>
		
								<hr/>

								<xf:textarea ref="Notes" class="DoubleInputSize">
									<xf:label>Besondere Hinweise:</xf:label>
									<xf:help>Besondere Hinweise zu diesem Vorgang</xf:help>
								</xf:textarea>	
							</div>
						</xf:group>
		
						<xf:repeat id="tasks" nodeset="instance('document')/Process/Tasks/*" appearance="full">
							<!--
							<xf:group ref=".[@isMaster='false']" style="float:right">
								<xf:trigger>
									<xf:label>X</xf:label>
									<xf:delete nodeset="." at="1" if="count(//.) &gt; 1" ev:event="DOMActivate"/>
								</xf:trigger>
							</xf:group>
							-->
							<!--
							[<xf:output value="index('tasks')"/>]
							<xf:output value="count(preceding-sibling::*) +1"/>
							-->
		
							<xsl:choose>
								<xsl:when test="/result/Process/Tasks/SimpleTask">
									<xf:group ref=".[name(.)='SimpleTask']">
										<div class="MainTask">
											<xsl:call-template name="SimpleTask"/>
										</div>
									</xf:group>
								</xsl:when>
								<xsl:when test="/result/Process/Tasks/DocumentTask">
									<xf:group ref=".[name(.)='DocumentTask']">
										<div class="MainTask">
											<xsl:call-template name="DocumentTask"/>
										</div>
									</xf:group>
								</xsl:when>
								<xsl:when test="/result/Process/Tasks/InvoiceInTask">
									<xf:group ref=".[name(.)='InvoiceInTask']">
										<div class="MainTask">
											<xsl:call-template name="InvoiceInTask"/>
										</div>
									</xf:group>
								</xsl:when>
								<xsl:when test="/result/Process/Tasks/InvoiceOutTask">
									<xf:group ref=".[name(.)='InvoiceOutTask']">
										<div class="MainTask">
											<xsl:call-template name="InvoiceOutTask"/>
										</div>
									</xf:group>
								</xsl:when>
								<xsl:when test="/result/Process/Tasks/TaxTask">
									<xf:group ref=".[name(.)='TaxTask']">
										<div class="MainTask">
											<xsl:call-template name="TaxTask"/>
										</div>
									</xf:group>
								</xsl:when>
								<xsl:when test="/result/Process/Tasks/EmployeeSalaryTask">
									<xf:group ref=".[name(.)='EmployeeSalaryTask']">
										<div class="MainTask">
											<xsl:call-template name="EmployeeSalaryTask"/>
										</div>
									</xf:group>
								</xsl:when>
								<xsl:when test="/result/Process/Tasks/BankBalancingTask">
									<xf:group ref=".[name(.)='BankBalancingTask']">
										<div class="MainTask">
											<xsl:call-template name="BankBalancingTask"/>
										</div>
									</xf:group>
								</xsl:when>
								<xsl:otherwise>
									<error>No main task given</error>
								</xsl:otherwise>
							</xsl:choose>
		
							<xf:group ref=".[name(.)='AttachmentTask']">
								<div class="AttachmentTask">
									<xsl:call-template name="AttachmentTask"/>
								</div>
							</xf:group>

							<xf:group ref=".[name(.)='CommodityTask']">
								<div class="AttachTask">
									<xsl:call-template name="CommodityTask"/>
								</div>
							</xf:group>
		
							<xf:group ref=".[name(.)='DiscountTask']">
								<div class="AttachTask">
									<xsl:call-template name="DiscountTask"/>
								</div>
							</xf:group>
		
							<xf:group ref=".[name(.)='DunningFeeTask']">
								<div class="AttachTask">
									<xsl:call-template name="DunningFeeTask"/>
								</div>
							</xf:group>
		
							<xf:group ref=".[name(.)='PaymentTask']">
								<div class="AttachTask">
									<xsl:call-template name="PaymentTask"/>
								</div>
							</xf:group>
		
							<xf:group ref=".[name(.)='TransferVoucherTask']">
								<div class="TransferVoucherTask">
									<xsl:call-template name="TransferVoucherTask"/>
								</div>
							</xf:group>
						
							<xf:group ref=".[name(.)='DeliveryNoteTask']">
								<div class="DeliveryNoteTask">
									<xsl:call-template name="DeliveryNoteTask"/>
								</div>
							</xf:group>
		
						</xf:repeat>
						
						<div style="background-color:#ddd">
							<xf:group ref="instance('attachtask-new')/*">
								<xf:select1 id="AddTask" ref="instance('temp')/TaskType">
									<xf:label>Neues Element</xf:label>
									<xf:itemset nodeset="instance('attachtask-new')/Task">
										<xf:label ref="@name"/>
										<xf:value ref="@type"/>
									</xf:itemset>
								</xf:select1>
								<xf:trigger>
									<xf:label>hinzufügen</xf:label>
									<!-- hinzufügen eines neuen Task durch drücken von "hinzufügen" -->
									<xf:action ev:event="DOMActivate" if="instance('temp')/TaskType != ''">
										<xf:insert origin="instance('attachtask-new')/Task[@type=instance('temp')/TaskType]/*" nodeset="instance('document')/Process/Tasks/*" at="last()" position="after"/>
										<xsl:call-template name="AddTask"/>
										<xf:setvalue ref="instance('temp')/TaskType" value="''"/>
									</xf:action>
								</xf:trigger>
							</xf:group>
						</div>
						<br/>
						<xf:submit submission="save" id="Save">
							<xf:label>Speichern</xf:label>
						</xf:submit>
						<br/>
					</div>
		
					<div>
						<xsl:call-template name="Attachments">
							<xsl:with-param name="new-document" select="$new-document"/>
						</xsl:call-template>
					</div>
				</div>
			</body>
		</xhtml:html>
	</xsl:template>


	<xsl:template name="ProcessModel">
	
		<xf:instance xmlns="" id="document">
			<data>
				<xsl:copy-of select="Process"/>
			</data>
		</xf:instance>

		<xf:instance xmlns="" id="accounts">
			<Accounts>
				<Account id="" kto="" type="nominal_account" classes="debitor creditor owner">
        			<Name>– Konto auswählen –</Name>
				</Account>
				<xsl:for-each select="Accounts/Account">
					<xsl:sort select="Name"/>
					<xsl:copy-of select="."/>
				</xsl:for-each>
			</Accounts>
		</xf:instance>

		<xf:instance xmlns="" id="file-new">
			<data>
				<xsl:choose>
					<xsl:when test="Files/File">
						<xsl:copy-of select="Files/File"/>
					</xsl:when>
					<xsl:otherwise>
						<File fileName="" fileExtension="" mimeType="" src="" type="" uploadName="" uploadSrc="" doctype="" archived=""/>
					</xsl:otherwise>
				</xsl:choose>
			</data>
		</xf:instance>

		<xf:instance xmlns="" id="binders">
			<data>
				<xsl:copy-of select="Binders"/>
			</data>
		</xf:instance>

		<xf:instance xmlns="" id="sections">
			<data>
				<Section name="Unbekannt" value=""/>
			</data>
		</xf:instance>

		<xf:instance xmlns="" id="temp">
			<data>
				<TaskType/>
				<LoopCounter>0</LoopCounter>
			</data>
		</xf:instance>

		<!-- needs to be in sync with account_edit_html.xsl -->
		<xf:instance xmlns="" id="taxes">
			<data>
				<item region="inland" name="unbekannt" value="L+U-0"/>
				<item region="inland" name="Gemischt" value="L+X-0"/>
				<item region="inland" name="Steuerfrei (USt/VSt)" value="L-0"/>
				<item region="inland" name="Vorst. 19%" value="L-19"/>
				<item region="inland" name="Vorst. 7%" value="L-7"/>
				<!--
			<item region="inland" name="PKW Kauf 19% Vorst. 50 %" value="L+PKW-19"/>
			<item name="PKW Kauf Vorst. 50%" value="L+PKW2-19"/>
			-->
				<item region="EU" name="unbekannt" value="EU+U-0"/>
				<item region="EU" name="Gemischt" value="EU+X-0"/>
				<item region="EU" name="Steuerfrei (USt/VSt)" value="EU-0"/>
				<item region="EU" name="I.g.E. mit 19% USt/VSt" value="EU-19"/>
				<item region="EU" name="I.g.E. mit 7% USt/VSt" value="EU-7"/>
				<item region="EU" name="Reverse Charge (§13) 19% USt/VSt" value="EU+RC-19"/>
				<item region="EU" name="Reverse Charge (§13) 7% USt/VSt" value="EU+RC-7"/>
				<!--
			<item region="EU" name="PKW EU I.g.E. Neu 19% USt/ VSt" value="EU+PKW-19"/>
			-->
				<item region="international" name="Steuerfrei" value="I-0"/>
			</data>
		</xf:instance>

		<xsl:call-template name="TaskBindings"/>

		<xf:action ev:event="xforms-ready">		
			<xsl:choose>
				<xsl:when test="$new-document">
					<!-- Werte initialisieren -->
					<xf:setvalue ref="instance('document')/Process/@date" value="'{$date}'"/>
					<xf:setvalue ref="instance('document')/Process/@created" value="'{current-dateTime()}'"/>

					<xf:setvalue ref="instance('document')/Process/Tasks/*/@isStorno" value="'{$is-storno}'"/>

					<!-- add file as attachement -->
					<xf:insert context="instance('document')/Process/Tasks/*/Files" origin="instance('file-new')/File" nodeset="File" at="last"/>

					<!--
					<xf:setvalue ref="instance('accounting-new')/Accounting/@created" value="'{current-dateTime()}'"/>
					<xf:setvalue ref="instance('accounting-new')/Accounting/@date" value="'{$date}'"/>
					-->
					<xsl:if test="$is-storno">
						<xf:setvalue ref="Description" value="'(STORNO)'"/>
						<xf:setvalue ref="Notes" value="'(STORNO)'"/>
					</xsl:if>

					<xf:delete ref="Other"/>
				</xsl:when>
				<xsl:otherwise>
					<!-- <xf:setvalue ref="instance('accounting-new')/Accounting/@changed" value="'{current-dateTime()}'"/> -->
				</xsl:otherwise>
			</xsl:choose>

			<xf:setfocus control="TotalValue"/>
		</xf:action>


		<xf:submission id="save" method="put" ref="instance('document')/Process" replace="all" validate="true">
			<!-- indent="true"  replace="all / none" -->
			<!-- /{$year}/{$binder}/{$document} -->
			<xf:resource value="concat('{$home-web-api}/{$tenant}/',substring(instance('document')/Process/@date,1,4),'/binders/',instance('document')/Process/@binder,'/', if({$new-document}(), instance('document')/Process/@name, instance('document')/Process/@id))"/>

			<xf:action ev:event="xforms-submit-done">
				<xf:message>
					Dokument wurde erfolgreich gespeichert.
					<xf:output value="event('resource-uri')">
						<xf:label>Resource URI: </xf:label>
					</xf:output>
					<xsl:text/>
					<xf:output value="event('response-body')">
						<xf:label>Body: </xf:label>
					</xf:output>
				</xf:message>
			</xf:action>

			<xf:action ev:event="xforms-submit-error" if="event('error-type')='validation-error'">
				<xf:message>Validierungsfehler: Es sind noch nicht alle notwendigen Felder mit zulässigen Werten gefüllt.</xf:message>
				<!-- <xf:output value="event"/> -->
			</xf:action>

			<xf:action ev:event="xforms-submit-error" if="not(event('error-type')='validation-error')">
				<xf:message>
					Es ist ein Fehler aufgetreten:
					<xsl:text/>
					<xf:output value="event('error-type')">
						<xf:label>Error type: </xf:label>
					</xf:output>
					<xsl:text/>
					<xf:output value="event('resource-uri')">
						<xf:label>
Resource URI: </xf:label>
					</xf:output>
					<xsl:text/>
					<xf:output value="event('response-status-code')">
						<xf:label>
Status Code: </xf:label>
					</xf:output>
					<xsl:text/>
					<xf:output value="event('response-reason-phrase')">
						<xf:label>
Reason: </xf:label>
					</xf:output>
					<xsl:text/>
					<xf:output value="event('response-headers')">
						<xf:label>
Headers: </xf:label>
					</xf:output>
					<xsl:text/>
					<xf:output value="event('response-body')">
						<xf:label>
Body: </xf:label>
					</xf:output>
				</xf:message>
			</xf:action>
		</xf:submission>

	</xsl:template>


	<xsl:template name="AddTask">

		<!-- Booking init -->	
		<!-- darf nicht pauschal alles setzen (z. B. bei PaymentTask) 
		<xf:setvalue ref="instance('document')/Process/Tasks/*[last()]/Bookings/Booking/@date" value="instance('document')/Process/@date"/>
		<xsl:choose>
			<xsl:when test="$is-storno">
				<xf:setvalue ref="instance('document')/Process/Tasks/*[last()]/Bookings/Booking/@credit" value="instance('document')/Process/Tasks/InvoiceInTask/Owner"/>
			</xsl:when>
			<xsl:otherwise>
				<xf:setvalue ref="instance('document')/Process/Tasks/*[last()]/Bookings/Booking/@debit" value="instance('document')/Process/Tasks/InvoiceInTask/Owner"/>
			</xsl:otherwise>
		</xsl:choose>
		<xf:setvalue ref="instance('document')/Process/Tasks/*[last()]/Bookings/Booking/@refID" value="instance('document')/Process/Taks/InvoiceInTask/RefID"/>
		<xf:setvalue ref="instance('document')/Process/Tasks/*[last()]/Bookings/Booking/@description" value="instance('document')/Process/Tasks/InvoiceInTask/Description"/>
		-->

		<!-- only valid vor InvoiceInTask 
		<xf:setvalue ref="instance('document')/Process/Tasks/*[last()]/@date" value="instance('document')/Process/Tasks/InvoiceInTask/@date"/>
		<xf:setvalue ref="instance('document')/Process/Tasks/*[last()]/Description" value="instance('document')/Process/Tasks/InvoiceInTask/Description"/>
		-->

		<!-- Main init -->
		<xf:setvalue ref="instance('document')/Process/Tasks/*[last()]/@created" value="'{current-dateTime()}'"/>
		<xf:setvalue ref="instance('document')/Process/Tasks/*[last()]/@user" value="'{$username}'"/>
		<xf:setvalue ref="instance('document')/Process/Tasks/*[last()]/@isStorno" value="'{$is-storno}'"/>
		<xf:action if="instance('document')/Process/Tasks/*[last()]/Amount/@value=''">
			<xf:setvalue ref="instance('document')/Process/Tasks/*[last()]/Amount/@value" value="instance('document')/Process/TotalAmount/@value"/>
		</xf:action>

		<!-- DunningFeeTask init -->
		<xf:action if="name(instance('document')/Process/Tasks/*[last()])='AttachmentTask'">

		</xf:action>

		<!-- CommodityTask init -->
		<xf:action if="name(instance('document')/Process/Tasks/*[last()])='CommodityTask'">
			<xf:setvalue ref="instance('document')/Process/Tasks/*[last()]/@type" value="'{if ($is-storno) then 'invoice-in-storno' else 'invoice-in'}'"/>
			<xf:setvalue ref="instance('document')/Process/Tasks/*[last()]/@date" value="instance('document')/Process/Tasks/InvoiceInTask/@date"/>
			<xf:setvalue ref="instance('document')/Process/Tasks/*[last()]/Description" value="instance('document')/Process/Tasks/InvoiceInTask/Description"/>
			<xf:setvalue ref="instance('document')/Process/Tasks/*[last()]/Bookings/Booking/@description" value="instance('document')/Process/Tasks/InvoiceInTask/Description"/>
			<xsl:choose>
				<xsl:when test="$is-storno">
					<xf:setvalue ref="instance('document')/Process/Tasks/*[last()]/Bookings/Booking/@credit" value="instance('document')/Process/Tasks/InvoiceInTask/Owner"/>
				</xsl:when>
				<xsl:otherwise>
					<xf:setvalue ref="instance('document')/Process/Tasks/*[last()]/Bookings/Booking/@debit" value="instance('document')/Process/Tasks/InvoiceInTask/Owner"/>
				</xsl:otherwise>
			</xsl:choose>
			<xf:setvalue ref="instance('document')/Process/Tasks/*[last()]/Bookings/Booking/@refID" value="instance('document')/Process/Tasks/InvoiceInTask/RefID" if="instance('document')/Process/Tasks/InvoiceInTask/RefID != ''"/>
			<xf:setvalue ref="instance('document')/Process/Tasks/*[last()]/Bookings/Booking/@refID" value="instance('document')/Process/Tasks/InvoiceOutTask/RefID" if="instance('document')/Process/Tasks/InvoiceOutTask/RefID != ''"/>
			<xf:setvalue ref="instance('document')/Process/Tasks/*[last()]/Bookings/Booking/@date" value="instance('document')/Process/Tasks/InvoiceInTask/@date" if="instance('document')/Process/Tasks/InvoiceInTask/RefID != ''"/>
			<xf:setvalue ref="instance('document')/Process/Tasks/*[last()]/Bookings/Booking/@date" value="instance('document')/Process/Tasks/InvoiceOutTask/@date" if="instance('document')/Process/Tasks/InvoiceOutTask/RefID != ''"/>
			<xf:setvalue ref="instance('document')/Process/Tasks/*[last()]/@is-storno" value="'{$is-storno}'"/>
		</xf:action>

		<!-- DunningFeeTask init -->
		<xf:action if="name(instance('document')/Process/Tasks/*[last()])='DunningFeeTask'">
			<xf:setvalue ref="instance('document')/Process/Tasks/*[last()]/Bookings/Booking/@credit" value="instance('document')/Process/Tasks/*[1]/Owner"/>
		</xf:action>

		<!-- DunningFeeTask init -->
		<xf:action if="name(instance('document')/Process/Tasks/*[last()])='DiscountTask'">
			<xf:setvalue ref="instance('document')/Process/Tasks/*[last()]/@date" value="instance('document')/Process/Tasks/InvoiceInTask/@date"/>
			<xf:setvalue ref="instance('document')/Process/Tasks/*[last()]/Bookings/Booking/@date" value="instance('document')/Process/Tasks/InvoiceInTask/@date"/>
		</xf:action>

		<!-- PaymentTask init -->
		<xf:action if="name(instance('document')/Process/Tasks/*[last()])='PaymentTask'">
			<xf:setvalue ref="instance('document')/Process/Tasks/*[last()]/Bookings/Booking/@date" value="instance('document')/Process/Tasks/PaymentTask/@date"/>
		<!-- ACHTUNG BUCHUNG ist POSITIV 
			<xf:setvalue ref="instance('document')/Process/Tasks/*[last()]/Bookings/Booking/@amountValue" value="instance('document')/Process/Tasks/PaymentTask/Amount/@value"/>
			<xf:setvalue ref="instance('document')/Process/Tasks/*[last()]/Bookings/Booking/@description" value="instance('document')/Process/Tasks/PaymentTask/Description"/>
		-->
		</xf:action>

	</xsl:template>

</xsl:stylesheet>