<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:xhtml="http://www.w3.org/1999/xhtml" version="3.1">

	<xsl:template name="SimpleTask">
		<div class="tabmenu" style="float:left">
			<!-- Attribute Value Templates (AVT): {{if (instance('temp')/selected = .) then 'selected' else 'not-selected')}} -->
			<xf:trigger id="tab-SimpleTask-1" appearance="minimal" class="TabBase">
				<xf:label>Beleg</xf:label>
				<xf:action ev:event="DOMActivate">
					<!-- <xf:setindex repeat="tasks" index="1"/> -->
					<xf:toggle case="case-SimpleTask-1"/>
				</xf:action>
			</xf:trigger>
			<xf:trigger id="tab-SimpleTask-2" appearance="minimal" class="TabAttachment">
				<xf:label>Anhang</xf:label>
				<xf:action ev:event="DOMActivate">
					<xf:toggle case="case-SimpleTask-2"/>
				</xf:action> 
			</xf:trigger>
		</div>
		<div style="float:right"><br/>erstellt <xf:output value="substring(@created,1,10)"/></div>
		<div style="clear:both">
			<xf:switch>
				<xf:case id="case-SimpleTask-1" selected="true">
					<div class="tabbody TabBase">
						<xf:input bind="SimpleTask-date">
							<xf:label>Belegdatum:</xf:label>
							<xf:alert>Der Monat und/oder das Jahr sind nicht gültig</xf:alert>
							<xf:hint>
								Zur Verfügung stehen die folgenden Ordner:
								<xf:output value="instance('binders')/Binders/Binder[@type='MONTH']/@name"/>
								Aktuell ist das Buchungsjahr <xsl:value-of select="$year"/> ausgewählt.
							</xf:hint>
							<xf:action ev:event="xforms-value-changed" if="instance('document')/Process/Tasks/SimpleTask/@date != ''">
								<xf:setvalue ref="instance('document')/Process/@date" value="instance('document')/Process/Tasks/SimpleTask/@date"/>
							</xf:action>
						</xf:input>
						<br/>

						<xf:select1 bind="SimpleTask-Owner">
							<xf:label>Halter (Kreditor):</xf:label>
							<xf:hint>
								Service / Dienstleistung:
								<xf:output ref="instance('accounts')/Account[@kto=instance('document')/Process/Tasks/SimpleTask/Owner]/Service"/>
							</xf:hint>
							<xf:alert>Der Halter muss definiert sein</xf:alert>
							<xf:itemset nodeset="instance('accounts')/Account[contains(@classes,'creditor') or contains(@classes,'bank') or contains(@classes,'self')]">
								<xf:label ref="Name"/>
								<xf:value ref="@kto"/>
							</xf:itemset>
						</xf:select1>
						<span> #</span>
						<xf:output bind="SimpleTask-Owner"/>
						<br/>

						<xf:input bind="SimpleTask-RefID">
							<xf:label>Beleg Kennzeichen:</xf:label>
						</xf:input>
						<br/>
						<xf:textarea bind="SimpleTask-Description" class="DoubleInputSize">
							<xf:label>Inhaltsangabe / Kurzbeschreibung:</xf:label>
							<xf:help>Kurze Darstellung, was in der Rechnung enthalten ist. Damit man eine Idee hat, was enthalten ist, wenn einen Beleg unter hunderten sucht.</xf:help>
						</xf:textarea>
						<hr/>
						<xf:textarea bind="SimpleTask-Notes" class="DoubleInputSize">
							<xf:label>Besonderheiten:</xf:label>
						</xf:textarea>
					</div>
				</xf:case>
				<xf:case id="case-SimpleTask-2">
					<div class="tabbody TabAttachment">
						<xf:group ref="Files/File">
							<xsl:call-template name="Attachment">
								<xsl:with-param name="name" select="'SimpleTask'"/>
								<xsl:with-param name="new-document" select="$new-document"/>
							</xsl:call-template>
						</xf:group>
					</div>
				</xf:case>
			</xf:switch>
		</div>
	</xsl:template>

	<xsl:template name="AttachmentTask">
		<xsl:call-template name="DocumentTask">
			<xsl:with-param name="Taskname" select="'AttachmentTask'"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="DocumentTask">
		<xsl:param name="Taskname" select="'DocumentTask'"/>
		<div class="tabmenu" style="float:left">
			<!-- Attribute Value Templates (AVT): {{if (instance('temp')/selected = .) then 'selected' else 'not-selected')}} -->
			<xf:trigger id="tab-DocumentTask-1" appearance="minimal" class="TabBase">
				<xf:label>Dokument</xf:label>
				<xf:action ev:event="DOMActivate">
					<!-- <xf:setindex repeat="tasks" index="1"/> -->
					<xf:toggle case="case-DocumentTask-1"/>
				</xf:action>
			</xf:trigger>
			<xf:trigger id="tab-DocumentTask-2" appearance="minimal" class="TabAttachment">
				<xf:label>Anhang</xf:label>
				<xf:action ev:event="DOMActivate">
					<xf:toggle case="case-DocumentTask-2"/>
				</xf:action>
			</xf:trigger>
		</div>
		<div style="float:right">
			<xsl:choose>
				<xsl:when test="$Taskname='DocumentTask'">
				</xsl:when>
				<xsl:when test="$Taskname='AttachmentTask'">
					<xf:trigger>
						<xf:label><span style="font-weight:normal; font-size:80%"><xf:output ref="@type"/></span> X</xf:label>
						<!-- <xf:delete nodeset="." at="1" if="count(//.) &gt; 1" ev:event="DOMActivate"/> -->
						<xf:delete nodeset="." ev:event="DOMActivate"/> 
					</xf:trigger>
				</xsl:when>
				<xsl:otherwise>
					<error>Invalid type for DocumentTask</error>
				</xsl:otherwise>
			</xsl:choose>
		</div>
		<div style="float:right">
			<br/>erstellt <xf:output value="substring(@created,1,10)"/>
		</div>
		<div style="clear:both">
			<xf:switch>
				<xf:case id="case-DocumentTask-1" selected="true">
					<div class="tabbody TabBase">
						<div>Hinweis: Für Kontotransfer, Lieferschein, Mahngebühr und Steuer-Abrechnung gibt es eigene Vorgänge.</div>
						<xf:input bind="DocumentTask-date">
							<xf:label>Belegdatum:</xf:label>
							<xf:alert>Das Jahr sind nicht gültig.</xf:alert>
							<xf:hint>Aktuell ist das Buchungsjahr <xsl:value-of select="$year"/> ausgewählt.</xf:hint>
							<xf:action ev:event="xforms-value-changed" if="instance('document')/Process/Tasks/{$Taskname}/@date != ''">
								<xf:setvalue ref="instance('document')/Process/@date" value="instance('document')/Process/Tasks/{$Taskname}/@date"/>
							</xf:action>
							<xf:action ev:event="xforms-value-changed" if="instance('document')/Process/Tasks/{$Taskname}/@type='doc-bank-statement'">
								<xf:setvalue ref="instance('document')/Process/@binder" value="substring(instance('document')/Process/@date,6,2)"/>
							</xf:action>
						</xf:input>
						<br/>
						<xf:select1 bind="DocumentTask-Owner">
							<xf:label>Halter (Kreditor):</xf:label>
							<xf:hint>
								Service / Dienstleistung:
								<xf:output ref="instance('accounts')/Account[@kto=instance('document')/Process/Tasks/TaxTask/Owner]/Service"/>
							</xf:hint>
							<xf:itemset nodeset="instance('accounts')/Account[contains(@classes,'creditor')]">
								<xf:label ref="Name"/>
								<xf:value ref="@kto"/>
							</xf:itemset>

							<xf:action ev:event="xforms-value-changed" if="name(instance('document')/Process/Tasks/*[index('tasks')])='TaxTask'">
								<xsl:choose>
									<xsl:when test="$is-storno">
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@credit" value="instance('document')/Process/Tasks/*[index('tasks')]/Owner"/>
									</xsl:when>
									<xsl:otherwise>
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@debit" value="instance('document')/Process/Tasks/*[index('tasks')]/Owner"/>
									</xsl:otherwise>
								</xsl:choose>
							</xf:action>
						</xf:select1>
						<span> #</span>
						<xf:output bind="DocumentTask-Owner"/>
						<br/>
						
						<xf:select1 bind="DocumentTask-type">
							<xf:label>Dokumentenart:</xf:label>
							<xf:hint>Für Kontotransfer, Lieferschein, Mahngebühr und Steuer-Abrechnung gibt es eigene Vorgänge.</xf:hint>
							<xf:item>
								<xf:label>Sonstiges</xf:label>
								<xf:value>doc-undefined</xf:value>
							</xf:item>
							<xf:item>
								<xf:label>Vertrag</xf:label>
								<xf:value>doc-contract</xf:value>
							</xf:item>
							<xf:item>
								<xf:label>Info-Schreiben</xf:label>
								<xf:value>doc-info</xf:value>
							</xf:item>
							<xf:item>
								<xf:label>Steuer Info</xf:label>
								<xf:value>doc-tax</xf:value>
							</xf:item>
							<xf:item>
								<xf:label>Zahlungsbeleg</xf:label>
								<xf:value>doc-payslip</xf:value>
							</xf:item>
							<xf:item>
								<xf:label>Kontoauszug</xf:label>
								<xf:value>doc-bank-statement</xf:value>
							</xf:item>							
							<xf:action ev:event="xforms-value-changed">
								<xf:setvalue ref="instance('document')/Process/Tasks/{$Taskname}/Files/File/@type" value="instance('document')/Process/Tasks/{$Taskname}/@type"/>
							</xf:action>							
						</xf:select1>
						<br/>

						<xf:input bind="DocumentTask-DocName" class="DoubleInputSize">
							<xf:label>Dokument Name:</xf:label>
							<xf:alert>Es wird ein Titel benötigt</xf:alert>
						</xf:input>
						<br/>

						<xf:input bind="DocumentTask-RefID">
							<xf:label>Beleg Kennzeichen:</xf:label>
						</xf:input>

						<xf:textarea bind="DocumentTask-Description" class="DoubleInputSize">
							<xf:label>Inhaltsangabe / Kurzbeschreibung:</xf:label>
							<xf:help>Kurze Darstellung, was in der Rechnung enthalten ist. Damit man eine Idee hat, was enthalten ist, wenn einen Beleg unter hunderten sucht.</xf:help>
						</xf:textarea>					
						<br/>
						<hr/>
						<xf:textarea bind="DocumentTask-Notes" class="DoubleInputSize">
							<xf:label>Notizen:</xf:label>
						</xf:textarea>
					</div>
				</xf:case>
				<xf:case id="case-DocumentTask-2">
					<div class="tabbody TabAttachment">
						<xf:group ref="Files/File">
							<xsl:call-template name="Attachment">
								<xsl:with-param name="name" select="'DocumentTask'"/>
								<xsl:with-param name="new-document" select="$new-document"/>
							</xsl:call-template>
						</xf:group>
					</div>
				</xf:case>
			</xf:switch>
		</div>
	</xsl:template>


	<xsl:template name="TaxTask">
		<div class="tabmenu" style="float:left">
			<!-- Attribute Value Templates (AVT): {{if (instance('temp')/selected = .) then 'selected' else 'not-selected')}} -->
			<xf:trigger id="tab-TaxTask-1" appearance="minimal" class="TabBase">
				<xf:label>Beleg</xf:label>
				<xf:action ev:event="DOMActivate">
					<!-- <xf:setindex repeat="tasks" index="1"/> -->
					<xf:toggle case="case-TaxTask-1"/>
				</xf:action>
			</xf:trigger>
			<xf:trigger id="tab-TaxTask-2" appearance="minimal" class="TabBooking">
				<xf:label>Buchungssätze</xf:label>
				<xf:action ev:event="DOMActivate">
					<xf:toggle case="case-TaxTask-2"/>
				</xf:action>
			</xf:trigger>
			<xf:trigger id="tab-TaxTask-3" appearance="minimal" class="TabAttachment">
				<xf:label>Anhang</xf:label>
				<xf:action ev:event="DOMActivate">
					<xf:toggle case="case-TaxTask-3"/>
				</xf:action>
			</xf:trigger>
		</div>
		<div style="float:right">
			<xf:select1 ref="@isStorno">
				<xf:item>
					<xf:label>STORNO</xf:label>
					<xf:value>true</xf:value>
				</xf:item>
				<xf:item>
					<xf:label/>
					<xf:value>false</xf:value>
				</xf:item>
			</xf:select1> 
			<br/>erstellt <xf:output value="substring(@created,1,10)"/>
		</div>
		<div style="clear:both">
			<xf:switch>
				<xf:case id="case-TaxTask-1" selected="true">
					<div class="tabbody TabBase">
						<xf:input ref="@date">
							<xf:label>Belegdatum:</xf:label>
							<xf:alert>Der Monat und/oder das Jahr sind nicht gültig</xf:alert>
							<xf:hint>
								Zur Verfügung stehen die folgenden Ordner:
								<xf:output value="instance('binders')/Binders/Binder[@type='MONTH']/@name"/>
								Aktuell ist das Buchungsjahr <xsl:value-of select="$year"/> ausgewählt.
							</xf:hint>
							<xf:action ev:event="xforms-value-changed" if="name(instance('document')/Process/Tasks/*[index('tasks')])='TaxTask'">
								<xf:setvalue ref="instance('document')/Process/@date" value="instance('document')/Process/Tasks/*[index('tasks')]/@date"/>
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@date" value="instance('document')/Process/Tasks/*[index('tasks')]/@date"/>
								<xf:setvalue ref="instance('document')/Process/@binder" value="substring(instance('document')/Process/Tasks/*[index('tasks')]/@date,6,2)"/>
							</xf:action>
						</xf:input>
						<br/>
						<xf:select1 ref="Owner">
							<xf:label>Halter (Kreditor):</xf:label>
							<xf:hint>
								Service / Dienstleistung:
								<xf:output ref="instance('accounts')/Account[@kto=instance('document')/Process/Tasks/TaxTask/Owner]/Service"/>
							</xf:hint>
							<xf:itemset nodeset="instance('accounts')/Account[contains(@classes,'creditor')]">
								<xf:label ref="Name"/>
								<xf:value ref="@kto"/>
							</xf:itemset>

							<xf:action ev:event="xforms-value-changed" if="name(instance('document')/Process/Tasks/*[index('tasks')])='TaxTask'">
								<xsl:choose>
									<xsl:when test="$is-storno">
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@credit" value="instance('document')/Process/Tasks/*[index('tasks')]/Owner"/>
									</xsl:when>
									<xsl:otherwise>
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@debit" value="instance('document')/Process/Tasks/*[index('tasks')]/Owner"/>
									</xsl:otherwise>
								</xsl:choose>
							</xf:action>
						</xf:select1>
						<span> #</span>
						<xf:output ref="Owner"/>
						<br/>

						<xf:input ref="Amount/@value">
							<xf:label>Betrag:</xf:label>
							<xf:action ev:event="xforms-value-changed" if="name(instance('document')/Process/Tasks/*[index('tasks')])='TaxTask'">
								<xsl:choose>
									<xsl:when test="$is-storno">
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@amountValue" value="instance('document')/Process/Tasks/*[index('tasks')]/Amount/@value"/>
									</xsl:when>
									<xsl:otherwise>
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@amountValue" value="instance('document')/Process/Tasks/*[index('tasks')]/Amount/@value * -1.0"/>
									</xsl:otherwise>
								</xsl:choose>
								<xf:setvalue ref="instance('document')/Process/TotalAmount/@value" value="instance('document')/Process/Tasks/*[index('tasks')]/Amount/@value"/>
							</xf:action>
						</xf:input> 

						<xf:select1 ref="Amount/@unit">
							<xf:item>
								<xf:label>CHF</xf:label>
								<xf:value>CHF</xf:value>
							</xf:item>
							<xf:item>
								<xf:label>EUR</xf:label>
								<xf:value>EUR</xf:value>
							</xf:item>
							<xf:item>
								<xf:label>USD</xf:label>
								<xf:value>USD</xf:value>
							</xf:item>
							<xf:action ev:event="xforms-value-changed" if="name(instance('document')/Process/Tasks/*[index('tasks')])='TaxTask'">
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@amountUnit" value="instance('document')/Process/Tasks/*[index('tasks')]/Amount/@unit"/>
							</xf:action>
						</xf:select1>
						<br/>

						<xf:select1 ref="Tax/@typeOfTax">
							<xf:label>Steurerart</xf:label>
							<!--
							<xf:item>
								<xf:label>UmsSt. Meldung (Elster)</xf:label>
								<xf:value>UmstMeldung</xf:value>
							</xf:item>
							-->
							<!--
							<xf:item>
								<xf:label>UmsSt. Zahlung</xf:label>
								<xf:value>UmstZahlung</xf:value>
							</xf:item>
							-->
							<xf:item>
								<xf:label>UmsSt. Vorauszahlung</xf:label>
								<xf:value>UmstVorauszahlung</xf:value>
							</xf:item>
							<xf:item>
								<xf:label>UmsSt. Voraus-Zinsen 1/11</xf:label>
								<xf:value>UmstVorausKosten</xf:value>
							</xf:item>
							<!--
							<xf:item>
								<xf:label>GewerbeSt. Vorausz.</xf:label>
								<xf:value>GewVorauszahlung</xf:value>
							</xf:item>
							-->
							<xf:item>
								<xf:label>GewerbeSt. Zahlung</xf:label>
								<xf:value>GewZahlung</xf:value>
							</xf:item>
							<xf:item>
								<xf:label>Eink.St. Zahlung</xf:label>
								<xf:value>EkstZahlung</xf:value>
							</xf:item>
							<xf:item>
								<xf:label>Eink.St. (Vorauszahlung)</xf:label>
								<xf:value>EkstVoraus</xf:value>
							</xf:item>
						</xf:select1>
						<br/>
						<xf:dialog id="tax-error-dialog">
							<xf:output value="'Die Steuerart wird für für diese Periode noch nicht unterstützt.'"/>
							<br/>
							<xf:trigger>
								<xf:label>Close</xf:label>
								<xf:hide ev:event="DOMActivate" dialog="tax-error-dialog"/>
							</xf:trigger>
						</xf:dialog>

						<xf:select1 ref="Tax/@period">
							<xf:label>Periode</xf:label>
							<xf:item>
								<xf:label>aktuelles Jahr</xf:label>
								<xf:value>CurrentPeriod</xf:value>
							</xf:item>
							<xf:item>
								<xf:label>kommendes Jahr</xf:label>
								<xf:value>NextPeriod</xf:value>
							</xf:item>							
							<xf:item>
								<xf:label>vergangenes Jahr</xf:label>
								<xf:value>LastPeriod</xf:value>
							</xf:item>
							<xf:item>
								<xf:label>frühere Jahre</xf:label>
								<xf:value>OutdatedPeriod</xf:value>
							</xf:item>

							<!-- Umsatzsteuer Vorauszahlungen -->
							<xf:action ev:event="xforms-value-changed" if="name(instance('document')/Process/Tasks/*[index('tasks')])='TaxTask' and instance('document')/Process/Tasks/*[index('tasks')]/Tax/@typeOfTax='UmstVorauszahlung' and instance('document')/Process/Tasks/*[index('tasks')]/Tax/@period='NextPeriod'">
								<xf:show dialog="tax-error-dialog"/>
							</xf:action>
							<xf:action ev:event="xforms-value-changed" if="name(instance('document')/Process/Tasks/*[index('tasks')])='TaxTask' and instance('document')/Process/Tasks/*[index('tasks')]/Tax/@typeOfTax='UmstVorauszahlung' and instance('document')/Process/Tasks/*[index('tasks')]/Tax/@period='CurrentPeriod'">
								<xsl:choose>
									<xsl:when test="$is-storno">
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@debit" value="'3820'"/>
									</xsl:when>
									<xsl:otherwise>
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@credit" value="'3820'"/>
									</xsl:otherwise>
								</xsl:choose>
							</xf:action>
							<xf:action ev:event="xforms-value-changed" if="name(instance('document')/Process/Tasks/*[index('tasks')])='TaxTask' and instance('document')/Process/Tasks/*[index('tasks')]/Tax/@typeOfTax='UmstVorauszahlung' and instance('document')/Process/Tasks/*[index('tasks')]/Tax/@period='LastPeriod'">
								<xsl:choose>
									<xsl:when test="$is-storno">
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@debit" value="'3841'"/>
									</xsl:when>
									<xsl:otherwise>
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@credit" value="'3841'"/>
									</xsl:otherwise>
								</xsl:choose>
							</xf:action>
							<xf:action ev:event="xforms-value-changed" if="name(instance('document')/Process/Tasks/*[index('tasks')])='TaxTask' and instance('document')/Process/Tasks/*[index('tasks')]/Tax/@typeOfTax='UmstVorauszahlung' and instance('document')/Process/Tasks/*[index('tasks')]/Tax/@period='OutdatedPeriod'">
								<xsl:choose>
									<xsl:when test="$is-storno">
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@debit" value="'3845'"/>
									</xsl:when>
									<xsl:otherwise>
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@credit" value="'3845'"/>
									</xsl:otherwise>
								</xsl:choose>
							</xf:action>

							<!-- Umsatzsteuer Vorauszahlung Gebühr (Zinsen) 1/11 -->
							<xf:action ev:event="xforms-value-changed" if="name(instance('document')/Process/Tasks/*[index('tasks')])='TaxTask' and instance('document')/Process/Tasks/*[index('tasks')]/Tax/@typeOfTax='UmstVorausKosten' and not(instance('document')/Process/Tasks/*[index('tasks')]/Tax/@period='CurrentPeriod')">
								<xf:show dialog="tax-error-dialog"/>
							</xf:action>
							<xf:action ev:event="xforms-value-changed" if="name(instance('document')/Process/Tasks/*[index('tasks')])='TaxTask' and instance('document')/Process/Tasks/*[index('tasks')]/Tax/@typeOfTax='UmstVorausKosten' and instance('document')/Process/Tasks/*[index('tasks')]/Tax/@period='CurrentPeriod'">
								<xsl:choose>
									<xsl:when test="$is-storno">
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@debit" value="'3830'"/>
									</xsl:when>
									<xsl:otherwise>
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@credit" value="'3830'"/>
									</xsl:otherwise>
								</xsl:choose>
							</xf:action>

							<!-- Gewerbesteuer -->
							<xf:action ev:event="xforms-value-changed" if="name(instance('document')/Process/Tasks/*[index('tasks')])='TaxTask' and instance('document')/Process/Tasks/*[index('tasks')]/Tax/@typeOfTax='GewZahlung' and instance('document')/Process/Tasks/*[index('tasks')]/Tax/@period='NextPeriod'">
								<xf:show dialog="tax-error-dialog"/>
							</xf:action>
							<xf:action ev:event="xforms-value-changed" if="name(instance('document')/Process/Tasks/*[index('tasks')])='TaxTask' and instance('document')/Process/Tasks/*[index('tasks')]/Tax/@typeOfTax='GewZahlung' and instance('document')/Process/Tasks/*[index('tasks')]/Tax/@period='CurrentPeriod'">
								<xsl:choose>
									<xsl:when test="$is-storno">
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@debit" value="'7610'"/>
									</xsl:when>
									<xsl:otherwise>
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@credit" value="'7610'"/>
									</xsl:otherwise>
								</xsl:choose>
							</xf:action>
							<xf:action ev:event="xforms-value-changed" if="name(instance('document')/Process/Tasks/*[index('tasks')])='TaxTask' and instance('document')/Process/Tasks/*[index('tasks')]/Tax/@typeOfTax='GewZahlung' and instance('document')/Process/Tasks/*[index('tasks')]/Tax/@period='LastPeriod'">
								<xsl:choose>
									<xsl:when test="$is-storno">
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@debit" value="'7642'"/> <!-- andere KTO nummer -->
									</xsl:when>
									<xsl:otherwise>
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@credit" value="'7640'"/>
									</xsl:otherwise>
								</xsl:choose>
							</xf:action>
							<xf:action ev:event="xforms-value-changed" if="name(instance('document')/Process/Tasks/*[index('tasks')])='TaxTask' and instance('document')/Process/Tasks/*[index('tasks')]/Tax/@typeOfTax='GewZahlung' and instance('document')/Process/Tasks/*[index('tasks')]/Tax/@period='OutdatedPeriod'">
								<xsl:choose>
									<xsl:when test="$is-storno">
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@debit" value="'7642'"/> <!-- andere KTO nummer-->
									</xsl:when>
									<xsl:otherwise>
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@credit" value="'7640'"/>
									</xsl:otherwise>
								</xsl:choose>
							</xf:action>

							<!-- Einkommenssteuer Zahlung (alle Perioden)-->
							<xf:action ev:event="xforms-value-changed" if="name(instance('document')/Process/Tasks/*[index('tasks')])='TaxTask' and instance('document')/Process/Tasks/*[index('tasks')]/Tax/@typeOfTax='EkstZahlung'">
								<xsl:choose>
									<xsl:when test="$is-storno">
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@debit" value="'3651'"/>
									</xsl:when>
									<xsl:otherwise>
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@credit" value="'3651'"/>
									</xsl:otherwise>
								</xsl:choose>
							</xf:action>

							<!-- Einkommenssteuer Vorauszahlung (alle Perioden) -->
							<xf:action ev:event="xforms-value-changed" if="name(instance('document')/Process/Tasks/*[index('tasks')])='TaxTask' and instance('document')/Process/Tasks/*[index('tasks')]/Tax/@typeOfTax='EkstVoraus'">
								<xsl:choose>
									<xsl:when test="$is-storno">
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@debit" value="'3651'"/>
									</xsl:when>
									<xsl:otherwise>
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@credit" value="'3651'"/>
									</xsl:otherwise>
								</xsl:choose>
							</xf:action>
						</xf:select1>
						<br/>

						<xf:input ref="RefID" class="DoubleInputSize">
							<xf:label>Vorgangsnummer:</xf:label>
						</xf:input>
						<br/>

						<xf:textarea ref="Description" class="DoubleInputSize">
							<xf:label>Inhaltsangabe / Kurzbeschreibung:</xf:label>
							<xf:help>Kurze Darstellung, was in der Rechnung enthalten ist. Damit man eine Idee hat, was enthalten ist, wenn einen Beleg unter hunderten sucht.</xf:help>
						</xf:textarea>

						<hr/>

						<xf:textarea ref="Notes" class="DoubleInputSize">
							<xf:label>Besonderheiten:</xf:label>
						</xf:textarea>
					</div>
				</xf:case>
				<xf:case id="case-TaxTask-2">
					<div class="tabbody TabBooking">
						<xf:repeat ref="Bookings/Booking">
							<xsl:call-template name="TaskBooking"/>
						</xf:repeat>
					</div>
				</xf:case>					
				<xf:case id="case-TaxTask-3">
					<div class="tabbody TabAttachment">
						<xf:group ref="Files/File">
							<xsl:call-template name="Attachment">
								<xsl:with-param name="name" select="'TaxTask'"/>
								<xsl:with-param name="new-document" select="$new-document"/>
							</xsl:call-template>
						</xf:group>
					</div>
				</xf:case>
			</xf:switch>
		</div>
	</xsl:template>


	<xsl:template name="EmployeeSalaryTask">
		<div class="tabmenu" style="float:left">
			<!-- Attribute Value Templates (AVT): {{if (instance('temp')/selected = .) then 'selected' else 'not-selected')}} -->
			<xf:trigger id="tab-EmployeeSalaryTask-1" appearance="minimal" class="TabBase">
				<xf:label>Beleg</xf:label>
				<xf:action ev:event="DOMActivate">
					<!-- <xf:setindex repeat="tasks" index="1"/> -->
					<xf:toggle case="case-EmployeeSalaryTask-1"/>
				</xf:action>
			</xf:trigger>
			<xf:trigger id="tab-EmployeeSalaryTask-2" appearance="minimal" class="TabBooking">
				<xf:label>Buchungssätze</xf:label>
				<xf:action ev:event="DOMActivate">
					<xf:toggle case="case-EmployeeSalaryTask-2"/>
				</xf:action>
			</xf:trigger>
			<xf:trigger id="tab-EmployeeSalaryTask-3" appearance="minimal" class="TabAttachment">
				<xf:label>Anhang</xf:label>
				<xf:action ev:event="DOMActivate">
					<xf:toggle case="case-EmployeeSalaryTask-3"/>
				</xf:action>
			</xf:trigger>
		</div>
		<div style="float:right"><br/>erstellt <xf:output value="substring(@created,1,10)"/></div>
		<div style="clear:both">
			<xf:switch>
				<xf:case id="case-EmployeeSalaryTask-1" selected="true">
					<div class="tabbody TabBase">
						<xf:input ref="@date">
							<xf:label>Belegdatum:</xf:label>
							<xf:alert>Der Monat und/oder das Jahr sind nicht gültig</xf:alert>
							<xf:hint>
								Zur Verfügung stehen die folgenden Ordner:
								<xf:output value="instance('binders')/Binders/Binder[@type='MONTH']/@name"/>
								Aktuell ist das Buchungsjahr <xsl:value-of select="$year"/> ausgewählt.
							</xf:hint>
							<xf:action ev:event="xforms-value-changed" if="instance('document')/Process/Tasks/EmployeeSalaryTask/@date != ''">
								<xf:setvalue ref="instance('document')/Process/@date" value="instance('document')/Process/Tasks/EmployeeSalaryTask/@date"/>
							</xf:action>
							<xf:action ev:event="xforms-value-changed" if="instance('document')/Process/Tasks/EmployeeSalaryTask">
								<xsl:if test="$new-document">
									<xf:setvalue ref="instance('document')/Process/@binder" value="substring(instance('document')/Process/Tasks/EmployeeSalaryTask/@date,6,2)"/>
								</xsl:if>
							</xf:action>
							<xf:action ev:event="xforms-value-changed" if="instance('document')/Process/Tasks/EmployeeSalaryTask/@date != ''">
								<xf:setvalue ref="instance('document')/Process/@date" value="instance('document')/Process/Tasks/EmployeeSalaryTask/@date"/>
							</xf:action>
							<xf:action ev:event="xforms-value-changed" if="instance('document')/Process/Tasks/EmployeeSalaryTask/SalaryMonth = ''">
								<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/SalaryMonth" value="concat(substring(instance('document')/Process/Tasks/EmployeeSalaryTask/@date,6,2),'/',substring(instance('document')/Process/Tasks/EmployeeSalaryTask/@date,1,4))"/>
							</xf:action>
							<xf:action ev:event="xforms-value-changed" if="instance('document')/Process/Tasks/EmployeeSalaryTask/Description = ''">
								<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Description" value="concat('Reguläres Gehalt für ',substring(instance('document')/Process/Tasks/EmployeeSalaryTask/@date,6,2),'/',substring(instance('document')/Process/Tasks/EmployeeSalaryTask/@date,1,4))"/>
							</xf:action>
						</xf:input>
						<br/>						
						<xf:select1 ref="Owner">
							<xf:label>Halter (Kreditor):</xf:label>
							<xf:hint>
								Service / Dienstleistung:
								<xf:output ref="instance('accounts')/Account[@kto=instance('document')/Process/Tasks/SimpleTask/Owner]/Service"/>
							</xf:hint>
							<xf:alert>Der Halter muss definiert sein</xf:alert>
							<xf:itemset nodeset="instance('accounts')/Account[contains(@classes,'self')]">
								<xf:label ref="Name"/>
								<xf:value ref="@kto"/>
							</xf:itemset>
						</xf:select1>
						<span> #</span>
						<xf:output ref="Owner"/>					
						<br/>
						<div>
							<xf:input ref="EmployeeName">
								<xf:label>Mitarbeiter Name:</xf:label>
							</xf:input>
							<br/>
							<xf:input ref="EmployeeID">
								<xf:label>Mitarb. Nummer:</xf:label>
							</xf:input>
							<br/>
							<xf:input ref="SalaryMonth">
								<xf:label>Abrechungs-Monat:</xf:label>
							</xf:input>							
						</div>
						<hr/>
						<div>
							<xf:input ref="GrossSalary">
								<xf:label>Gehalt-Brutto:</xf:label>
								<xf:hint>Brutto Gehalt des Arbeitnehmers</xf:hint>
								<xf:action ev:event="xforms-value-changed" if="instance('document')/Process/Tasks/EmployeeSalaryTask">
									<!-- Gehalt "Gesamt-Brutto": 560,00 EUR -->
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='A']/@description" value="'Gehalt Brutto'"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='A']/@amountValue" value="instance('document')/Process/Tasks/EmployeeSalaryTask/GrossSalary"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='A']/@credit" value="'6020'"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='A']/@debit" value="'3790'"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='A']/@date" value="instance('document')/Process/Tasks/EmployeeSalaryTask/@date"/>
								</xf:action>
							</xf:input>
							<xf:output ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='A']/@amountUnit"/>
							<br/>
							<xf:input ref="TaxBasedComission">
								<xf:label>Steuer-Abzüge AN:</xf:label>
								<xf:hint>Lohnsteuer, Kirchensteuer, Solidaritätszuschlag</xf:hint>
								<xf:action ev:event="xforms-value-changed" if="instance('document')/Process/Tasks/EmployeeSalaryTask">
									<!-- "Steuerrechtliche Abzüge": 63,41 EUR -->
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='B']/@description" value="'Steuerrechtliche-Abzüge (Arbeitnehmer)'"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='B']/@amountValue" value="instance('document')/Process/Tasks/EmployeeSalaryTask/TaxBasedComission"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='B']/@credit" value="'3790'"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='B']/@debit" value="'3730'"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='B']/@date" value="instance('document')/Process/Tasks/EmployeeSalaryTask/@date"/>
								</xf:action>
							</xf:input>
							<xf:output ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='B']/@amountUnit"/>
							<br/>
							<xf:input ref="SozialSecurityCommission">
								<xf:label>Sozialv. Abzüge AN:</xf:label>
								<xf:hint>Krankenversicherung, Rentenversicherung, Arbeitslosenversicherung, Pflegeversicherung</xf:hint>
								<xf:action ev:event="xforms-value-changed" if="instance('document')/Process/Tasks/EmployeeSalaryTask">
									<!-- "SV-rechtliche Abzüge": 74,76 EUR-->
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='C']/@description" value="'Sozialversicherungs-Abzüge (Arbeitnehmer)'"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='C']/@amountValue" value="instance('document')/Process/Tasks/EmployeeSalaryTask/SozialSecurityCommission"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='C']/@credit" value="'3790'"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='C']/@debit" value="'3740'"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='C']/@date" value="instance('document')/Process/Tasks/EmployeeSalaryTask/@date"/>
								</xf:action>
							</xf:input>
							<xf:output ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='C']/@amountUnit"/>
							<br/>
							<xf:input ref="AmountPaid" class="Sumup">
								<xf:label>Auszahlungsbetrag:</xf:label>
								<xf:hint>An den Arbeitnehmer ausgezahltes Gehalt</xf:hint>
								<xf:action ev:event="xforms-value-changed" if="instance('document')/Process/Tasks/EmployeeSalaryTask">
									<!-- "Auszahlungsbetrag": 421,83 EUR-->
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='D']/@description" value="'Gehalt Auszahlung an Arbeitnehmer'"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='D']/@amountValue" value="instance('document')/Process/Tasks/EmployeeSalaryTask/AmountPaid"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='D']/@credit" value="'3790'"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='D']/@debit" value="'3720'"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='D']/@date" value="instance('document')/Process/Tasks/EmployeeSalaryTask/@date"/>
								</xf:action>
							</xf:input>
							<xf:output ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='D']/@amountUnit"/>
						</div>
						<hr/>
						<div>
							<xf:input ref="SozialSecurityEmloyeeContribution">
								<xf:label>Sozialv. AG-Anteil:</xf:label>
								<xf:action ev:event="xforms-value-changed" if="instance('document')/Process/Tasks/EmployeeSalaryTask">
									<!-- "SV-AG-Anteil": 111,58 EUR-->
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='E']/@description" value="'Sozialversicherung (Arbeitgeber)'"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='E']/@amountValue" value="instance('document')/Process/Tasks/EmployeeSalaryTask/SozialSecurityEmloyeeContribution"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='E']/@credit" value="'6130'"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='E']/@debit" value="'3790'"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='E']/@date" value="instance('document')/Process/Tasks/EmployeeSalaryTask/@date"/>

									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='F']/@description" value="'Sozialversicherung (Arbeitgeber) in Beitragsnachweis'"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='F']/@amountValue" value="instance('document')/Process/Tasks/EmployeeSalaryTask/SozialSecurityEmloyeeContribution"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='F']/@credit" value="'3790'"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='F']/@debit" value="'3740'"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='F']/@date" value="instance('document')/Process/Tasks/EmployeeSalaryTask/@date"/>
								</xf:action>
							</xf:input>
							<xf:output ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='E']/@amountUnit"/>
							<br/>
							<xf:input ref="SozialSecurityEmployeeAddition">
								<xf:label>Sozialv. AG-Zusatzkosten:</xf:label>
								<xf:action ev:event="xforms-value-changed" if="instance('document')/Process/Tasks/EmployeeSalaryTask">
									<!-- "Zus. AG-Kosten": 12,50 EUR-->
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='G']/@description" value="'Sozialvers. Zusatzkosten (Umlagen Arbeitgeber)'"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='G']/@amountValue" value="instance('document')/Process/Tasks/EmployeeSalaryTask/SozialSecurityEmployeeAddition"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='G']/@credit" value="'6110'"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='G']/@debit" value="'3790'"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='G']/@date" value="instance('document')/Process/Tasks/EmployeeSalaryTask/@date"/>

									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='H']/@description" value="'Sozialvers. Zustatzkosten (Umlagen Arbeitgeber) in Beitragsnachweis'"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='H']/@amountValue" value="instance('document')/Process/Tasks/EmployeeSalaryTask/SozialSecurityEmployeeAddition"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='H']/@credit" value="'3790'"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='H']/@debit" value="'3740'"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='H']/@date" value="instance('document')/Process/Tasks/EmployeeSalaryTask/@date"/>
								</xf:action>								
							</xf:input>
							<xf:output ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='G']/@amountUnit"/>
							<br/>
							<xf:input ref="OverallCosts" class="Sumup">
								<xf:label>Gesamtkosten:</xf:label>
								<xf:action ev:event="xforms-value-changed" if="instance('document')/Process/Tasks/EmployeeSalaryTask/OverallCosts &gt; 0">
									<xf:setvalue ref="instance('document')/Process/TotalAmount/@value" value="instance('document')/Process/Tasks/EmployeeSalaryTask/OverallCosts * -1.0"/>
									<xf:setvalue ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Amount/@value" value="instance('document')/Process/Tasks/EmployeeSalaryTask/OverallCosts * -1.0"/>
								</xf:action>
							</xf:input>
							<xf:output ref="instance('document')/Process/Tasks/EmployeeSalaryTask/Bookings/Booking[@refID='A']/@amountUnit"/>
						</div>
						<br/>

						<xf:textarea ref="Description" class="DoubleInputSize">
							<xf:label>Inhaltsangabe / Kurzbeschreibung:</xf:label>
							<xf:help>Kurze Darstellung, was in der Rechnung enthalten ist. Damit man eine Idee hat, was enthalten ist, wenn einen Beleg unter hunderten sucht.</xf:help>
						</xf:textarea>

						<hr/>

						<xf:textarea ref="Notes" class="DoubleInputSize">
							<xf:label>Besonderheiten:</xf:label>
						</xf:textarea>
					</div>
				</xf:case>
				<xf:case id="case-EmployeeSalaryTask-2">
					<div class="tabbody TabBooking">
						<xf:repeat ref="Bookings/Booking">
							<xsl:call-template name="TaskBooking"/>
						</xf:repeat>
					</div>
				</xf:case>					
				<xf:case id="case-EmployeeSalaryTask-3">
					<div class="tabbody TabAttachment">
						<xf:group ref="Files/File">
							<xsl:call-template name="Attachment">
								<xsl:with-param name="name" select="'EmployeeSalaryTask'"/>
								<xsl:with-param name="new-document" select="$new-document"/>
							</xsl:call-template>
						</xf:group>
					</div>
				</xf:case>
			</xf:switch>
		</div>
	</xsl:template>


	<xsl:template name="InvoiceInTask">
		<div class="tabmenu" style="float:left">
			<!-- Attribute Value Templates (AVT): {{if (instance('temp')/selected = .) then 'selected' else 'not-selected')}} -->
			<xf:trigger id="tab-InvoiceInTask-1" appearance="minimal" class="TabBase">
				<xf:label>Rechnung eing.</xf:label>
				<xf:action ev:event="DOMActivate">
					<!-- <xf:setindex repeat="tasks" index="1"/> -->
					<xf:toggle case="case-InvoiceInTask-1"/>
				</xf:action>
			</xf:trigger>
			<xf:trigger id="tab-InvoiceInTask-2" appearance="minimal" class="TabAttachment">
				<xf:label>Anhang</xf:label>
				<xf:action ev:event="DOMActivate">
					<xf:toggle case="case-InvoiceInTask-2"/>
				</xf:action>
			</xf:trigger>
		</div>
		<div style="float:right">
			<xf:select1 ref="@isStorno">
				<xf:item>
					<xf:label>STORNO</xf:label>
					<xf:value>true</xf:value>
				</xf:item>
				<xf:item>
					<xf:label/>
					<xf:value>false</xf:value>
				</xf:item>
			</xf:select1> 
			<br/>erstellt <xf:output value="substring(@created,1,10)"/>
		</div>
		<div style="clear:both">
			<xf:switch>
				<xf:case id="case-InvoiceInTask-1" selected="true">
					<div class="tabbody TabBase">
						<xf:input ref="@date" id="belegdatum">
							<xf:label>Belegdatum:</xf:label>
							<xf:alert>Der Monat und/oder das Jahr sind nicht gültig</xf:alert>
							<xf:hint>
								Zur Verfügung stehen die folgenden Ordner:
								<xf:repeat ref="instance('binders')/Binders/Binder[@type='MONTH']">
									<xf:output value="@name"/>
								</xf:repeat>
								Aktuell ist das Buchungsjahr <xsl:value-of select="$year"/> ausgewählt.
							</xf:hint>
							<xsl:choose>
								<xsl:when test="$new-document">
									<xf:action ev:event="xforms-value-changed">
										<xf:setvalue ref="instance('document')/Process/@binder" value="substring(instance('document')/Process/Tasks/InvoiceInTask/@date,6,2)"/>
										<xf:setvalue ref="instance('document')/Process/@date" value="instance('document')/Process/Tasks/InvoiceInTask/@date"/>
										<xf:setvalue ref="instance('document')/Process/Tasks/CommodityTask/@date" value="instance('document')/Process/Tasks/InvoiceInTask/@date"/>
										<xf:setvalue ref="instance('document')/Process/Tasks/CommodityTask/Bookings/Booking/@date" value="instance('document')/Process/Tasks/InvoiceInTask/@date"/>
									</xf:action>
								</xsl:when>
								<xsl:otherwise>
									<xf:action ev:event="xforms-value-changed" if="substring(instance('document')/Process/@date,1,7)=substring(instance('document')/Process/Tasks/InvoiceInTask/@date,1,7)">
										<!-- never set folder -->
										<xf:setvalue ref="instance('document')/Process/@date" value="instance('document')/Process/Tasks/InvoiceInTask/@date"/>
										<xf:setvalue ref="instance('document')/Process/Tasks/CommodityTask/@date" value="instance('document')/Process/Tasks/InvoiceInTask/@date"/>
										<xf:setvalue ref="instance('document')/Process/Tasks/CommodityTask/Bookings/Booking/@date" value="instance('document')/Process/Tasks/InvoiceInTask/@date"/>
									</xf:action>
								</xsl:otherwise>
							</xsl:choose>
						</xf:input>
						<br/>

						<xf:select1 ref="Owner" id="invoice-in_owner">
							<xf:label>Halter (Kreditor):</xf:label>
							<xf:hint>
								Service / Dienstleistung:
								<xf:output ref="instance('accounts')/Account[@kto=instance('document')/Process/Tasks/InvoiceInTask/Owner]/Service"/>
							</xf:hint>
							<xf:itemset nodeset="instance('accounts')/Account[contains(@classes,'creditor')]">
								<xf:label ref="Name"/>
								<xf:value ref="@kto"/>
							</xf:itemset>

							<xf:action ev:event="xforms-value-changed">
								<xf:setvalue ref="instance('temp')/LoopCounter" value="0"/>
								<xf:action while="instance('temp')/LoopCounter &lt; count(instance('document')/Process/Tasks/CommodityTask)">
									<xf:setvalue ref="instance('temp')/LoopCounter" value="instance('temp')/LoopCounter + 1"/>
									<xsl:choose>
										<xsl:when test="$is-storno">
											<xf:setvalue ref="instance('document')/Process/Tasks/CommodityTask[number(instance('temp')/LoopCounter)]/Bookings/Booking/@credit" value="instance('document')/Process/Tasks/*[index('tasks')]/Owner"/>
										</xsl:when>
										<xsl:otherwise>
											<xf:setvalue ref="instance('document')/Process/Tasks/CommodityTask[number(instance('temp')/LoopCounter)]/Bookings/Booking/@debit" value="instance('document')/Process/Tasks/*[index('tasks')]/Owner"/>
										</xsl:otherwise>
									</xsl:choose>								
								</xf:action>
							</xf:action>
						</xf:select1>
						<span> #</span>
						<xf:output ref="Owner"/>
						<br/>

						<xf:output ref="instance('accounts')/Account[@kto=instance('document')/Process/Tasks/InvoiceInTask/Owner]/Notes">
							<xf:label>Besonderheiten:</xf:label>
						</xf:output>
						<br/>
						<hr/>

						<xf:input ref="RefID">
							<xf:label>Rechnungsnummer:</xf:label>
							<xf:help>Wenn es keine Belegnummer gibt, einfach # eintragen</xf:help>
						</xf:input>
						<br/>

						<xf:input ref="TransactionID">
							<xf:label>Bestellnummer:</xf:label>
							<xf:hint>Bei Amazon z. B. 303-xxxxxxx-xxxxxxx oder 028-xxxxxxx-xxxxxxx</xf:hint>
						</xf:input>
						<br/>

						<xf:textarea ref="Description" class="DoubleInputSize">
							<xf:label>Inhaltsangabe / Kurzbeschreibung:</xf:label>
							<xf:help>Kurze Darstellung, was in der Rechnung enthalten ist. Damit man eine Idee hat, was enthalten ist, wenn einen Beleg unter hunderten sucht.</xf:help>
						</xf:textarea>
						<hr/>

						<xf:textarea ref="Notes" class="DoubleInputSize">
							<xf:label>Notizen:</xf:label>
							<xf:help>Besondere Hinweise</xf:help>
						</xf:textarea>						
					</div>
				</xf:case>
				<xf:case id="case-InvoiceInTask-2">
					<div class="tabbody TabAttachment">
						<xf:group ref="Files/File">
							<xsl:call-template name="Attachment">
								<xsl:with-param name="name" select="'InvoiceInTask'"/>
								<xsl:with-param name="new-document" select="$new-document"/>
							</xsl:call-template>
						</xf:group>
					</div>
				</xf:case>
			</xf:switch>
		</div>
	</xsl:template>


	<xsl:template name="InvoiceOutTask">
		<div class="tabmenu" style="float:left">
			<!-- Attribute Value Templates (AVT): {{if (instance('temp')/selected = .) then 'selected' else 'not-selected')}} -->
			<xf:trigger id="tab-InvoiceOutTask-1" appearance="minimal" class="TabBase">
				<xf:label>Rechnung eing.</xf:label>
				<xf:action ev:event="DOMActivate">
					<!-- <xf:setindex repeat="tasks" index="1"/> -->
					<xf:toggle case="case-InvoiceOutTask-1"/>
				</xf:action>
			</xf:trigger>
			<xf:trigger id="tab-InvoiceOutTask-2" appearance="minimal" class="TabAttachment">
				<xf:label>Anhang</xf:label>
				<xf:action ev:event="DOMActivate">
					<xf:toggle case="case-InvoiceOutTask-2"/>
				</xf:action>
			</xf:trigger>
		</div>
		<div style="float:right"><br/>erstellt <xf:output value="substring(@created,1,10)"/></div>
		<div style="clear:both">
			<xf:switch>
				<xf:case id="case-InvoiceOutTask-1" selected="true">
					<div class="tabbody TabBase">
						<xf:input ref="@date" id="belegdatum">
							<xf:label>Belegdatum:</xf:label>
							<xf:alert>Der Monat und/oder das Jahr sind nicht gültig</xf:alert>
							<xf:hint>
								Zur Verfügung stehen die folgenden Ordner:
								<xf:repeat ref="instance('binders')/Binders/Binder[@type='MONTH']">
									<xf:output value="@name"/>
								</xf:repeat>
								Aktuell ist das Buchungsjahr <xsl:value-of select="$year"/> ausgewählt.
							</xf:hint>
							<xsl:choose>
								<xsl:when test="$new-document">
									<xf:action ev:event="xforms-value-changed">
										<xf:setvalue ref="instance('document')/Process/@binder" value="substring(instance('document')/Process/Tasks/InvoiceOutTask/@date,6,2)"/>
										<xf:setvalue ref="instance('document')/Process/@date" value="instance('document')/Process/Tasks/InvoiceOutTask/@date"/>
										<xf:setvalue ref="instance('document')/Process/Tasks/CommodityTask/@date" value="instance('document')/Process/Tasks/InvoiceOutTask/@date"/>
										<xf:setvalue ref="instance('document')/Process/Tasks/CommodityTask/Bookings/Booking/@date" value="instance('document')/Process/Tasks/InvoiceOutTask/@date"/>
									</xf:action>
								</xsl:when>
								<xsl:otherwise>
									<xf:action ev:event="xforms-value-changed" if="substring(instance('document')/Process/@date,1,7)=substring(instance('document')/Process/Tasks/InvoiceOutTask/@date,1,7)">
										<!-- never set folder -->
										<xf:setvalue ref="instance('document')/Process/@date" value="instance('document')/Process/Tasks/InvoiceOutTask/@date"/>
										<xf:setvalue ref="instance('document')/Process/Tasks/CommodityTask/@date" value="instance('document')/Process/Tasks/InvoiceOutTask/@date"/>
										<xf:setvalue ref="instance('document')/Process/Tasks/CommodityTask/Bookings/Booking/@date" value="instance('document')/Process/Tasks/InvoiceOutTask/@date"/>
									</xf:action>
								</xsl:otherwise>
							</xsl:choose>
						</xf:input>
						<br/>

						<xf:select1 ref="Owner" id="invoice-in_owner">
							<xf:label>Halter (Kreditor):</xf:label>
							<xf:hint>
								Service / Dienstleistung:
								<xf:output ref="instance('accounts')/Account[@kto=instance('document')/Process/Tasks/InvoiceOutTask/Owner]/Service"/>
							</xf:hint>
							<xf:itemset nodeset="instance('accounts')/Account[contains(@classes,'debitor')]">
								<xf:label ref="Name"/>
								<xf:value ref="@kto"/>
							</xf:itemset>

							<xf:action ev:event="xforms-value-changed">
								<xf:setvalue ref="instance('temp')/LoopCounter" value="0"/>
								<xf:action while="instance('temp')/LoopCounter &lt; count(instance('document')/Process/Tasks/CommodityTask)">
									<xf:setvalue ref="instance('temp')/LoopCounter" value="instance('temp')/LoopCounter + 1"/>
									<xsl:choose>
										<xsl:when test="$is-storno">
											<xf:setvalue ref="instance('document')/Process/Tasks/CommodityTask[number(instance('temp')/LoopCounter)]/Bookings/Booking/@credit" value="instance('document')/Process/Tasks/*[index('tasks')]/Owner"/>
										</xsl:when>
										<xsl:otherwise>
											<xf:setvalue ref="instance('document')/Process/Tasks/CommodityTask[number(instance('temp')/LoopCounter)]/Bookings/Booking/@debit" value="instance('document')/Process/Tasks/*[index('tasks')]/Owner"/>
										</xsl:otherwise>
									</xsl:choose>								
								</xf:action>
							</xf:action>
						</xf:select1>
						<span> #</span>
						<xf:output ref="Owner"/>
						<br/>

						<xf:input ref="Amount/@value">
							<xf:label>Betrag:</xf:label>
							<xf:action ev:event="xforms-value-changed" if="name(instance('document')/Process/Tasks/*[index('tasks')])='CommodityTask'">
								<xsl:choose>
									<xsl:when test="$is-storno">
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@amountValue" value="instance('document')/Process/Tasks/*[index('tasks')]/Amount/@value"/>
									</xsl:when>
									<xsl:otherwise>
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@amountValue" value="instance('document')/Process/Tasks/*[index('tasks')]/Amount/@value * -1.0"/>
									</xsl:otherwise>
								</xsl:choose>
							</xf:action>
						</xf:input> 

						<xf:select1 ref="Amount/@unit">
							<xf:item>
								<xf:label>CHF</xf:label>
								<xf:value>CHF</xf:value>
							</xf:item>
							<xf:item>
								<xf:label>EUR</xf:label>
								<xf:value>EUR</xf:value>
							</xf:item>
							<xf:item>
								<xf:label>USD</xf:label>
								<xf:value>USD</xf:value>
							</xf:item>
							<xf:action ev:event="xforms-value-changed">
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@amountUnit" value="instance('document')/Process/Tasks/*[index('tasks')]/Amount/@unit"/>
							</xf:action>
						</xf:select1>
						<br/>

						<xf:select1 ref="Tax/@region" selection="closed">
							<xf:label>Vorsteuer:</xf:label>
							<xf:item>
								<xf:label>Inlandsgeschäft</xf:label>
								<xf:value>inland</xf:value> 
							</xf:item>
							<xf:item>
								<xf:label>EU-Geschäft</xf:label>
								<xf:value>EU</xf:value> 
							</xf:item>
							<xf:item>
								<xf:label>International</xf:label>
								<xf:value>international</xf:value> 
							</xf:item>
							<!-- reset tax code if changed -->
							<xf:action ev:event="xforms-value-changed"> 
								<xf:setvalue ref="Tax/@key" value="''"/> 
							</xf:action>
						</xf:select1>
						
						<xf:output ref="instance('accounts')/Account[@kto=instance('document')/Process/Tasks/InvoiceOutTask/Owner]/Notes">
							<xf:label>Besonderheiten:</xf:label>
						</xf:output>
						<br/>
						<hr/>

						<xf:input ref="RefID">
							<xf:label>Rechnungsnummer:</xf:label>
							<xf:help>Wenn es keine Belegnummer gibt, einfach # eintragen</xf:help>
						</xf:input>
						<br/>

						<xf:input ref="TransactionID">
							<xf:label>Bestellnummer:</xf:label>
							<xf:hint>Bei Amazon z. B. 303-xxxxxxx-xxxxxxx oder 028-xxxxxxx-xxxxxxx</xf:hint>
						</xf:input>
						<br/>

						<xf:textarea ref="Description" class="DoubleInputSize">
							<xf:label>Inhaltsangabe / Kurzbeschreibung:</xf:label>
							<xf:help>Kurze Darstellung, was in der Rechnung enthalten ist. Damit man eine Idee hat, was enthalten ist, wenn einen Beleg unter hunderten sucht.</xf:help>
						</xf:textarea>
						<hr/>

						<xf:textarea ref="Notes" class="DoubleInputSize">
							<xf:label>Notizen:</xf:label>
							<xf:help>Besondere Hinweise</xf:help>
						</xf:textarea>						
					</div>
				</xf:case>
				<xf:case id="case-InvoiceOutTask-2">
					<div class="tabbody TabAttachment">
						<xf:group ref="Files/File">
							<xsl:call-template name="Attachment">
								<xsl:with-param name="name" select="'InvoiceOutTask'"/>
								<xsl:with-param name="new-document" select="$new-document"/>
							</xsl:call-template>
						</xf:group>
					</div>
				</xf:case>
			</xf:switch>
		</div>
	</xsl:template>


	<xsl:template name="CommodityTask">
		<div class="tabmenu" style="float:left">
			<xf:trigger id="tab-CommodityTask-1" appearance="minimal" class="TabBase">
				<xf:label>Artikel</xf:label>
				<xf:action ev:event="DOMActivate">
					<!-- <xf:setindex repeat="tasks" index="1"/> -->
					<xf:toggle case="case-CommodityTask-1"/>
				</xf:action>
			</xf:trigger>
			<xf:trigger id="tab-CommodityTask-2" appearance="minimal" class="TabBooking">
				<xf:label>Buchungssätze</xf:label>
				<xf:action ev:event="DOMActivate">
					<xf:toggle case="case-CommodityTask-2"/>
				</xf:action>
			</xf:trigger>
		</div>
		<div style="float:right">
			<xf:trigger>
				<xf:label><span style="font-weight:normal; font-size:80%"><xf:output ref="@type"/></span> X</xf:label>
				<!-- <xf:delete nodeset="." at="1" if="count(//.) &gt; 1" ev:event="DOMActivate"/> -->
				<xf:delete nodeset="." ev:event="DOMActivate"/> 
			</xf:trigger>
		</div>
		<div style="float:right"><br/>erstellt <xf:output value="substring(@created,1,10)"/></div>		
		<div style="clear:both">
			<xf:switch>
				<xf:case id="case-CommodityTask-1" selected="true">
					<div class="tabbody TabBase">
						<!--
						<xf:input ref="@date">
							<xf:label>Belegdatum</xf:label>
							<xf:alert>
								Zur Buchung sind nur die folgenden Monate aus
								<xf:output value="instance('binders')/Binders/@year"/>
								zulässig:
								<xf:output value="string-join(instance('binders')/Binders/Binder/@month,', ')"/>
							</xf:alert>
							<xf:hint>
								Zur Verfügung stehen die folgenden Ordner:
								<xf:output value="instance('binders')/Binders/Binder/@month"/>
							</xf:hint>
						</xf:input>
						-->

						<div class="popup">
							<a href="#">Buchungsvorlagen</a>
							<table class="popup-content">
								<tr>
									<xf:repeat id="ProcessTemplates" nodeset="instance('accounts')/Account[@kto=instance('document')/Process/Tasks/InvoiceInTask/Owner]/ProcessTemplates/ProcessTemplate" class="inline">
										<td>
											<xf:trigger ref="self::node()[instance('document')/Process/Tasks/InvoiceInTask/Owner!='']" class="popup-close">
												<xf:label>Vorlage <xf:output value="count(preceding-sibling::*) +1"/></xf:label>

												<!-- Wizard Daten -->
												<xf:action ev:event="DOMActivate">
													<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Other" value="current()/Other/@kto" if="current()/Other/@kto != ''"/>
													<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Amount/@value" value="current()/TotalAmount/@value" if="current()/TotalAmount/@value != ''"/>
													<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Amount/@unit" value="current()/TotalAmount/@unit" if="current()/TotalAmount/@unit != ''"/>
													
													<xsl:choose>
														<xsl:when test="$is-storno">
															<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Description" value="concat('(STORNO) ', current()/Description)" if="current()/Description != ''"/>
														</xsl:when>
														<xsl:otherwise>
															<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Description" value="current()/Description" if="current()/Description != ''"/>
														</xsl:otherwise>
													</xsl:choose>

													<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Tax/@region" value="current()/Tax/@region" if="current()/Tax/@region != ''"/>
													<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Tax/@key" value="current()/Tax/@key" if="current()/Tax/@key != ''"/>
													<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Tax/@type" value="current()/Tax/@type" if="current()/Tax/@type != ''"/>
													<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Tax/@value" value="0.0" if="current()/Tax/@value != ''"/>
												</xf:action>

												<!-- Booking Daten -->
												<xf:action ev:event="DOMActivate">
													<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@date" value="current()/@date" if="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@date=''"/>

													<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@debit" value="current()/Other/@kto" if="current()/Other/@kto != ''"/>
													<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/Amount/@value" value="current()/TotalAmount/@value" if="current()/TotalAmount/@value != ''"/>
													<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/Amount/@unit" value="current()/TotalAmount/@unit" if="current()/TotalAmount/@unit != ''"/>

													<xsl:choose>
														<xsl:when test="$is-storno">
															<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@description" value="concat('(STORNO) ', current()/Description)" if="current()/TotalAmount/Description != ''"/>
														</xsl:when>
														<xsl:otherwise>
															<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@description" value="current()/Description" if="current()/TotalAmount/Description != ''"/>
														</xsl:otherwise>
													</xsl:choose>

													<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/Tax/@region" value="current()/Tax/@region" if="current()/Tax/@region != ''"/>
													<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/Tax/@key" value="current()/Tax/@key" if="current()/Tax/@key != ''"/>
													<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/Tax/@type" value="current()/Tax/@type" if="current()/Tax/@type != ''"/>
													<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/Tax/@value" value="0.0" if="current()/Tax/@value != ''"/>
												</xf:action>
											</xf:trigger>
										</td>
									</xf:repeat>
								</tr>
								<tr>									
									<xf:repeat nodeset="instance('accounts')/Account[@kto=instance('document')/Process/Tasks/InvoiceInTask/Owner]/ProcessTemplates/ProcessTemplate" class="inline">
										<td>
											<xf:output ref="instance('accounts')/Account[@kto=current()/Other/@kto]/Name"/>
											<xsl:text> #</xsl:text>
											<xf:output ref="Other/@kto"/>
										</td>
									</xf:repeat>
								</tr>
								<tr>
									<xf:repeat nodeset="instance('accounts')/Account[@kto=instance('document')/Process/Tasks/InvoiceInTask/Owner]/ProcessTemplates/ProcessTemplate" class="inline">
										<td>
											<xf:output ref="TotalAmount/@value"/>
											<span> </span>
											<xf:output ref="TotalAmount/@unit"/>
										</td>
									</xf:repeat>
								</tr>
								<tr>
									<xf:repeat nodeset="instance('accounts')/Account[@kto=instance('document')/Process/Tasks/InvoiceInTask/Owner]/ProcessTemplates/ProcessTemplate" class="inline">
										<td>
											<xf:output ref="Tax/@region"/>
											<br/>
											<xf:output ref="Tax/@key"/>
											<br/>
											<xf:output ref="Tax/@type"/>
										</td>
									</xf:repeat>
								</tr>
								<tr>
									<xf:repeat nodeset="instance('accounts')/Account[@kto=instance('document')/Process/Tasks/InvoiceInTask/Owner]/ProcessTemplates/ProcessTemplate" class="inline">
										<td>
											<xf:output ref="RefID"/>
										</td>
									</xf:repeat>

								</tr>
								<tr>
									<xf:repeat nodeset="instance('accounts')/Account[@kto=instance('document')/Process/Tasks/InvoiceInTask/Owner]/ProcessTemplates/ProcessTemplate" class="inline">
										<td>
											<xf:output ref="TransactionID"/>
										</td>
									</xf:repeat>
								</tr>
								<tr>
									<xf:repeat nodeset="instance('accounts')/Account[@kto=instance('document')/Process/Tasks/InvoiceInTask/Owner]/ProcessTemplates/ProcessTemplate" class="inline">
										<td>
											<xf:output ref="Description"/>
										</td>
									</xf:repeat>
								</tr>
							</table>
						</div>
						<hr/>

						<br/>

						<xf:select1 ref="Other">
							<xf:label>Aufwandskonto:</xf:label>
							<xf:itemset nodeset="instance('accounts')/Account[@type='nominal_account']">
								<xf:label ref="Name"/>
								<xf:value ref="@kto"/>
							</xf:itemset>
							<xf:action ev:event="xforms-value-changed" if="name(instance('document')/Process/Tasks/*[index('tasks')])='CommodityTask'">
								<xsl:choose>
									<xsl:when test="$is-storno">
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@debit" value="instance('document')/Process/Tasks/*[index('tasks')]/Other"/>
									</xsl:when>
									<xsl:otherwise>
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@credit" value="instance('document')/Process/Tasks/*[index('tasks')]/Other"/>
									</xsl:otherwise>
								</xsl:choose>
							</xf:action>
						</xf:select1>
						<span> #</span>
						<xf:select1 ref="Other">
							<xf:itemset nodeset="instance('accounts')/Account[@type='nominal_account']">
								<xf:label ref="@kto"/>
								<xf:value ref="@kto"/>
							</xf:itemset>
							<xf:action ev:event="xforms-value-changed" if="name(instance('document')/Process/Tasks/*[index('tasks')])='CommodityTask'">
								<xsl:choose>
									<xsl:when test="$is-storno">
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@debit" value="instance('document')/Process/Tasks/*[index('tasks')]/Other"/>
									</xsl:when>
									<xsl:otherwise>
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@credit" value="instance('document')/Process/Tasks/*[index('tasks')]/Other"/>
									</xsl:otherwise>
								</xsl:choose>
							</xf:action>
						</xf:select1>
						<br/>

						<xf:input ref="Amount/@value">
							<xf:label>Betrag:</xf:label>
							<xf:action ev:event="xforms-value-changed" if="name(instance('document')/Process/Tasks/*[index('tasks')])='CommodityTask'">
								<xsl:choose>
									<xsl:when test="$is-storno">
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@amountValue" value="instance('document')/Process/Tasks/*[index('tasks')]/Amount/@value"/>
									</xsl:when>
									<xsl:otherwise>
										<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@amountValue" value="instance('document')/Process/Tasks/*[index('tasks')]/Amount/@value * -1.0"/>
									</xsl:otherwise>
								</xsl:choose>
							</xf:action>
							<xf:hint>Als negativer Betrag (ausser bei STORNO)</xf:hint>
						</xf:input> 

						<xf:select1 ref="Amount/@unit">
							<xf:item>
								<xf:label>CHF</xf:label>
								<xf:value>CHF</xf:value>
							</xf:item>
							<xf:item>
								<xf:label>EUR</xf:label>
								<xf:value>EUR</xf:value>
							</xf:item>
							<xf:item>
								<xf:label>USD</xf:label>
								<xf:value>USD</xf:value>
							</xf:item>
							<xf:action ev:event="xforms-value-changed">
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@amountUnit" value="instance('document')/Process/Tasks/*[index('tasks')]/Amount/@unit"/>
							</xf:action>
						</xf:select1>
						<br/>

						<xf:select1 ref="Tax/@region" selection="closed">
							<xf:label>Vorsteuer:</xf:label>
							<xf:item>
								<xf:label>Inlandsgeschäft</xf:label>
								<xf:value>inland</xf:value> 
							</xf:item>
							<xf:item>
								<xf:label>EU-Geschäft</xf:label>
								<xf:value>EU</xf:value> 
							</xf:item>
							<xf:item>
								<xf:label>International</xf:label>
								<xf:value>international</xf:value> 
							</xf:item>
							<!-- reset tax code if changed -->
							<xf:action ev:event="xforms-value-changed" if="instance('document')/Process/Tasks/*[index('tasks')]/Tax[@region != 'international']"> 
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Tax/@key" value="''"/> 
							</xf:action>
							<xf:action ev:event="xforms-value-changed" if="instance('document')/Process/Tasks/*[index('tasks')]/Tax[@region = 'international']"> 
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Tax/@key" value="'I-0'"/> 
							</xf:action>
						</xf:select1>

						<xf:select1 ref="Tax/@key" selection="closed">
							<xf:itemset nodeset="instance('taxes')/item[@region=instance('document')/Process/Tasks/*[count(preceding-sibling::*) +1]/Tax/@region]">
								<xf:label ref="@name"/>
								<xf:value ref="@value"/>
							</xf:itemset>

							<xf:help>Achtung EU: Steuer 0,00 meint meist nicht steuerfrein. Sondern:<br/>"Reverse Charge" oder "based on the EU directive 2008/8/CE" oder auch "§ 13b (2) No. 10 UStG" und meint eine "Verschiebung der Steuerschuld zum Leistungsempfänger" (ist somit mit dem im eigenen Land üblichen Steuersatz zu versteuern).</xf:help>

							<xf:action ev:event="xforms-value-changed">
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@taxKey" value="'-'" if="instance('document')/Process/Tasks/*[index('tasks')]/Tax/@key='L+U-0'"/>
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@taxKey" value="'X'" if="instance('document')/Process/Tasks/*[index('tasks')]/Tax/@key='L+X-0'"/>

								<!-- Inlandsgeschaeft -->
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@taxKey" value="'1'" if="instance('document')/Process/Tasks/*[index('tasks')]/Tax/@key='L-0' and instance('document')/Process/Tasks/*[index('tasks')]/@isStorno=false()"/>
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@taxKey" value="'8'" if="instance('document')/Process/Tasks/*[index('tasks')]/Tax/@key='L-7' and instance('document')/Process/Tasks/*[index('tasks')]/@isStorno=false()"/>
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@taxKey" value="'9'" if="instance('document')/Process/Tasks/*[index('tasks')]/Tax/@key='L-19' and instance('document')/Process/Tasks/*[index('tasks')]/@isStorno=false()"/>

								<!-- STORNO Inlandsgeschaeft -->
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@taxKey" value="'20'" if="instance('document')/Process/Tasks/*[index('tasks')]/Tax/@key='L-0' and instance('document')/Process/Tasks/*[index('tasks')]/@isStorno=true()"/>
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@taxKey" value="'28'" if="instance('document')/Process/Tasks/*[index('tasks')]/Tax/@key='L-7' and instance('document')/Process/Tasks/*[index('tasks')]/@isStorno=true()"/>
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@taxKey" value="'29'" if="instance('document')/Process/Tasks/*[index('tasks')]/Tax/@key='L-19' and instance('document')/Process/Tasks/*[index('tasks')]/@isStorno=true()"/>

								<!-- EU-Geschaeft -->
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@taxKey" value="'-'" if="instance('document')/Process/Tasks/*[index('tasks')]/Tax/@key='EU-0' and instance('document')/Process/Tasks/*[index('tasks')]/@isStorno=false()"/>
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@taxKey" value="'18'" if="instance('document')/Process/Tasks/*[index('tasks')]/Tax/@key='EU-7' and instance('document')/Process/Tasks/*[index('tasks')]/@isStorno=false()"/>
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@taxKey" value="'19'" if="instance('document')/Process/Tasks/*[index('tasks')]/Tax/@key='EU-19' and instance('document')/Process/Tasks/*[index('tasks')]/@isStorno=false()"/>

								<!-- STORNO EU-Geschaeft -->
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@taxKey" value="'-'" if="instance('document')/Process/Tasks/*[index('tasks')]/Tax/@key='EU-0' and instance('document')/Process/Tasks/*[index('tasks')]/@isStorno=true()"/>
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@taxKey" value="'68'" if="instance('document')/Process/Tasks/*[index('tasks')]/Tax/@key='EU-7' and instance('document')/Process/Tasks/*[index('tasks')]/@isStorno=true()"/>
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@taxKey" value="'69'" if="instance('document')/Process/Tasks/*[index('tasks')]/Tax/@key='EU-19' and instance('document')/Process/Tasks/*[index('tasks')]/@isStorno=true()"/>

								<!-- EU-Geschaeft Reverse Charge (§13) -->
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@taxKey" value="'-'" if="instance('document')/Process/Tasks/*[index('tasks')]/Tax/@key='EU+RC-0' and instance('document')/Process/Tasks/*[index('tasks')]/@isStorno=false()"/>
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@taxKey" value="'91'" if="instance('document')/Process/Tasks/*[index('tasks')]/Tax/@key='EU+RC-7' and instance('document')/Process/Tasks/*[index('tasks')]/@isStorno=false()"/>
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@taxKey" value="'94'" if="instance('document')/Process/Tasks/*[index('tasks')]/Tax/@key='EU+RC-19' and instance('document')/Process/Tasks/*[index('tasks')]/@isStorno=false()"/>

								<!-- STORNO EU-Geschaeft Reverse Charge (§13) -->
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@taxKey" value="'-'" if="instance('document')/Process/Tasks/*[index('tasks')]/Tax/@key='EU+RC-0' and instance('document')/Process/Tasks/*[index('tasks')]/@isStorno=true()"/>
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@taxKey" value="'91'" if="instance('document')/Process/Tasks/*[index('tasks')]/Tax/@key='EU+RC-7' and instance('document')/Process/Tasks/*[index('tasks')]/@isStorno=true()"/>
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@taxKey" value="'94'" if="instance('document')/Process/Tasks/*[index('tasks')]/Tax/@key='EU+RC-19' and instance('document')/Process/Tasks/*[index('tasks')]/@isStorno=true()"/>

								<!-- International -->
								<!-- STORNO International -->
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@taxKey" value="'-'" if="instance('document')/Process/Tasks/*[index('tasks')]/Tax/@region='international'"/>

								<!-- Geschaeft mit Generalumkehr kann ignoriert werden -->
							</xf:action>
						</xf:select1>

						<xf:select1 ref="Tax/@type">
							<xf:item>
								<xf:label>          </xf:label>
								<xf:value/> 
							</xf:item>
							<xf:item>
								<xf:label>Warenlieferung</xf:label>
								<xf:value>GOODS</xf:value> 
							</xf:item>
							<xf:item>
								<xf:label>Dienstleistung</xf:label>
								<xf:value>SERVICE</xf:value> 
							</xf:item>
							<xf:item>
								<xf:label>Virtuelle Güter</xf:label>
								<xf:value>VIRTUAL</xf:value> 
							</xf:item>
						</xf:select1>
						<br/>

						<!--
						<xf:input ref="RefID">
							<xf:label>Rechnungsnummer:</xf:label>
							<xf:help>Wenn es keine Belegnummer gibt, einfach # eintragen</xf:help>
							<xf:action ev:event="xforms-value-changed">
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@refID" value="instance('document')/Process/Tasks/*[index('tasks')]/RefID"/>
							</xf:action>
						</xf:input>
						<br/>

						<xf:input ref="TransactionID">
							<xf:label>Bestellnummer:</xf:label>
							<xf:hint>Bei Amazon z. B. 303-xxxxxxx-xxxxxxx oder 028-xxxxxxx-xxxxxxx</xf:hint>
						</xf:input>
						<br/>
						-->
						
						<xf:textarea ref="Description" class="DoubleInputSize">
							<xf:label>Inhaltsangabe:</xf:label>
							<xf:action ev:event="xforms-value-changed">
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@description" value="instance('document')/Process/Tasks/*[index('tasks')]/Description"/>
							</xf:action>
						</xf:textarea>
						<hr/>

						<xf:textarea ref="Notes" class="DoubleInputSize">
							<xf:label>Notizen:</xf:label>
							<xf:help>Besondere Hinweise</xf:help>
						</xf:textarea>
						<br/>
					</div>
				</xf:case>
				<xf:case id="case-CommodityTask-2">
					<div class="tabbody TabBooking">
						<xf:group ref="Bookings/Booking">
							<xsl:call-template name="TaskBooking"/>
						</xf:group>
					</div>
				</xf:case>
			</xf:switch>
		</div>
	</xsl:template>


	<xsl:template name="DiscountTask">
		<div class="tabmenu" style="float:left">
			<xf:trigger id="tab-DiscountTask-1" appearance="minimal" class="TabBase">
				<xf:label>Skonto</xf:label>
				<xf:action ev:event="DOMActivate">
					<!-- <xf:setindex repeat="tasks" index="1"/> -->
					<xf:toggle case="case-DiscountTask-1"/>
				</xf:action>
			</xf:trigger>
			<xf:trigger id="tab-DiscountTask-2" appearance="minimal" class="TabBooking">
				<xf:label>Buchungssätze</xf:label>
				<xf:action ev:event="DOMActivate">
					<xf:toggle case="case-DiscountTask-2"/>
				</xf:action>
			</xf:trigger>
		</div>
		<div style="float:right">
			<xf:trigger>
				<xf:label><span style="font-weight:normal; font-size:80%"><xf:output ref="@type"/></span> X</xf:label>
				<!-- <xf:delete nodeset="." at="1" if="count(//.) &gt; 1" ev:event="DOMActivate"/> -->
				<xf:delete nodeset="." ev:event="DOMActivate"/> 
			</xf:trigger>
		</div>
		<div style="float:right"><br/>erstellt <xf:output value="substring(@created,1,10)"/></div>		
		<div style="clear:both">
			<xf:switch>
				<xf:case id="case-DiscountTask-1" selected="true">
					<div class="tabbody TabBase">
						<xf:input ref="Amount/@value">
							<xf:label>Betrag:</xf:label>
							<xf:action ev:event="xforms-value-changed" if="name(instance('document')/Process/Tasks/*[index('tasks')])='DiscountTask' and instance('document')/Process/Tasks/*[index('tasks')]/Amount/@value &gt; 0">
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@amountValue" value="instance('document')/Process/Tasks/*[index('tasks')]/Amount/@value"/>
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@credit" value="instance('document')/Process/Tasks/InvoiceInTask/Owner"/>
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@debit" value="'5730'"/>
							</xf:action>
							<xf:action ev:event="xforms-value-changed" if="name(instance('document')/Process/Tasks/*[index('tasks')])='DiscountTask' and instance('document')/Process/Tasks/*[index('tasks')]/Amount/@value &lt; 0">
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@amountValue" value="instance('document')/Process/Tasks/*[index('tasks')]/Amount/@value * -1"/>
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@credit" value="'5730'"/>
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@debit" value="instance('document')/Process/Tasks/InvoiceInTask/Owner"/>
							</xf:action>
						</xf:input> 

						<xf:select1 ref="Amount/@unit">
							<xf:item>
								<xf:label>CHF</xf:label>
								<xf:value>CHF</xf:value>
							</xf:item>
							<xf:item>
								<xf:label>EUR</xf:label>
								<xf:value>EUR</xf:value>
							</xf:item>
							<xf:item>
								<xf:label>USD</xf:label>
								<xf:value>USD</xf:value>
							</xf:item>
							<xf:action ev:event="xforms-value-changed">
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@amountUnit" value="instance('document')/Process/Tasks/*[index('tasks')]/Amount/@unit"/>
							</xf:action>
						</xf:select1>
						<br/>
						<xf:input ref="RefID">
							<xf:label>Rechnungsnummer:</xf:label>
							<xf:hint>Wenn es keine Belegnummer gibt, einfach # eintragen</xf:hint>
							<xf:action ev:event="xforms-value-changed">
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@refID" value="instance('document')/Process/Tasks/*[index('tasks')]/RefID"/>
							</xf:action>
						</xf:input>
						<br/>
						<xf:textarea ref="Description" class="DoubleInputSize">
							<xf:label>Inhaltsangabe:</xf:label>
							<xf:action ev:event="xforms-value-changed">
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@description" value="instance('document')/Process/Tasks/*[index('tasks')]/Description"/>
							</xf:action>
						</xf:textarea>
						<hr/>
						<xf:textarea ref="Notes" class="DoubleInputSize">
							<xf:label>Notizen:</xf:label>
							<xf:help>Besondere Hinweise</xf:help>
						</xf:textarea>											
					</div>
				</xf:case>
				<xf:case id="case-DiscountTask-2">
					<div class="tabbody TabBooking">
						<xf:group ref="Bookings/Booking">
							<xsl:call-template name="TaskBooking"/>
						</xf:group>
					</div>
				</xf:case>				
			</xf:switch>
		</div>
	</xsl:template>


	<xsl:template name="DunningFeeTask">
		<div class="tabmenu" style="float:left">
			<xf:trigger id="tab-DunningFeeTask-1" appearance="minimal" class="TabBase">
				<xf:label>Mahngebühr</xf:label>
				<xf:action ev:event="DOMActivate">
					<!-- <xf:setindex repeat="tasks" index="1"/> -->
					<xf:toggle case="case-DunningFeeTask-1"/>
				</xf:action>
			</xf:trigger>
			<xf:trigger id="tab-DunningFeeTask-2" appearance="minimal" class="TabBooking">
				<xf:label>Buchungssätze</xf:label>
				<xf:action ev:event="DOMActivate">
					<xf:toggle case="case-DunningFeeTask-2"/>
				</xf:action>
			</xf:trigger>
			<xf:trigger id="tab-DunningFeeTask-3" appearance="minimal" class="TabAttachment">
				<xf:label>Anhang</xf:label>
				<xf:action ev:event="DOMActivate">
					<xf:toggle case="case-DunningFeeTask-3"/>
				</xf:action>
			</xf:trigger>
		</div>
		<div style="float:right">
			<xf:trigger>
				<xf:label><span style="font-weight:normal; font-size:80%"><xf:output ref="@type"/></span> X</xf:label>
				<!-- <xf:delete nodeset="." at="1" if="count(//.) &gt; 1" ev:event="DOMActivate"/> -->
				<xf:delete nodeset="." ev:event="DOMActivate"/> 
			</xf:trigger>
		</div>
		<div style="float:right"><br/>erstellt <xf:output value="substring(@created,1,10)"/></div>		
		<div style="clear:both">
			<xf:switch>
				<xf:case id="case-DunningFeeTask-1" selected="true">
					<div class="tabbody TabBase">
						<xf:input ref="Amount/@value">
							<xf:label>Betrag:</xf:label>
							<xf:action ev:event="xforms-value-changed" if="name(instance('document')/Process/Tasks/*[index('tasks')])='DunningFeeTask' and instance('document')/Process/Tasks/*[index('tasks')]/Amount/@value &gt; 0">
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@amountValue" value="instance('document')/Process/Tasks/*[index('tasks')]/Amount/@value"/>
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@credit" value="instance('document')/Process/Tasks/InvoiceInTask/Owner"/>
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@debit" value="'6430'"/> <!-- Oder als Zinsaufwendugen: 7300 -->
							</xf:action>
							<xf:action ev:event="xforms-value-changed" if="name(instance('document')/Process/Tasks/*[index('tasks')])='DunningFeeTask' and instance('document')/Process/Tasks/*[index('tasks')]/Amount/@value &lt; 0">
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@amountValue" value="instance('document')/Process/Tasks/*[index('tasks')]/Amount/@value * -1"/>
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@credit" value="'6430'"/>
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@debit" value="instance('document')/Process/Tasks/InvoiceInTask/Owner"/>
							</xf:action>
						</xf:input> 

						<xf:select1 ref="Amount/@unit">
							<xf:item>
								<xf:label>CHF</xf:label>
								<xf:value>CHF</xf:value>
							</xf:item>
							<xf:item>
								<xf:label>EUR</xf:label>
								<xf:value>EUR</xf:value>
							</xf:item>
							<xf:item>
								<xf:label>USD</xf:label>
								<xf:value>USD</xf:value>
							</xf:item>
							<xf:action ev:event="xforms-value-changed" if="name(instance('document')/Process/Tasks/*[index('tasks')])='DunningFeeTask'">
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@amountUnit" value="instance('document')/Process/Tasks/*[index('tasks')]/Amount/@unit"/>
							</xf:action>
						</xf:select1>
						<br/>
						<xf:input ref="RefID">
							<xf:label>Rechnungsnummer:</xf:label>
							<xf:help>Wenn es keine Belegnummer gibt, einfach # eintragen</xf:help>
							<xf:action ev:event="xforms-value-changed" if="name(instance('document')/Process/Tasks/*[index('tasks')])='DunningFeeTask'">
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@refID" value="instance('document')/Process/Tasks/*[index('tasks')]/RefID"/>
							</xf:action>
						</xf:input>
						<br/>
						<xf:textarea ref="Description" class="DoubleInputSize">
							<xf:label>Inhaltsangabe:</xf:label>
							<xf:action ev:event="xforms-value-changed" if="name(instance('document')/Process/Tasks/*[index('tasks')])='DunningFeeTask'">
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@description" value="instance('document')/Process/Tasks/*[index('tasks')]/Description"/>
							</xf:action>
						</xf:textarea>
						<hr/>
						<xf:textarea ref="Notes" class="DoubleInputSize">
							<xf:label>Notizen:</xf:label>
							<xf:help>Besondere Hinweise</xf:help>
						</xf:textarea>											
					</div>
				</xf:case>
				<xf:case id="case-DunningFeeTask-2">
					<div class="tabbody TabBooking">
						<xf:group ref="Bookings/Booking">
							<xsl:call-template name="TaskBooking"/>
						</xf:group>
					</div>
				</xf:case>
				<xf:case id="case-DunningFeeTask-3">
					<div class="tabbody TabAttachment">
						<xf:group ref="Files/File">
							<xsl:call-template name="Attachment">
								<xsl:with-param name="name" select="'dunning-fee'"/>
								<xsl:with-param name="new-document" select="$new-document"/>
							</xsl:call-template>
						</xf:group>
					</div>
				</xf:case>				
			</xf:switch>
		</div>
	</xsl:template>


	<xsl:template name="PaymentTask">
		<div class="tabmenu" style="float:left">
			<xf:trigger id="tab-PaymentTask-1" appearance="minimal" class="TabBase">
				<xf:label>Bezahlung</xf:label>
				<xf:action ev:event="DOMActivate">
					<xf:toggle case="case-PaymentTask-1"/>
				</xf:action>
			</xf:trigger>
			<xf:trigger id="tab-PaymentTask-2" appearance="minimal" class="TabBooking">
				<xf:label>Buchungssätze</xf:label>
				<xf:action ev:event="DOMActivate">
					<xf:toggle case="case-PaymentTask-2"/>
				</xf:action>
			</xf:trigger>
			<xf:trigger id="tab-PaymentTask-3" appearance="minimal" class="TabAttachment">
				<xf:label>Anhänge</xf:label>
				<xf:action ev:event="DOMActivate">
					<xf:toggle case="case-PaymentTask-3"/>
				</xf:action>
			</xf:trigger>			
		</div>
		<div style="float:right">
			<xf:trigger>
				<xf:label><span style="font-weight:normal; font-size:80%"><xf:output ref="@type"/></span> X</xf:label>
				<!-- <xf:delete nodeset="." at="1" if="count(//.) &gt; 1" ev:event="DOMActivate"/> -->
				<xf:delete nodeset="." ev:event="DOMActivate"/>
			</xf:trigger>
		</div>
		<div style="float:right">erstellt <xf:output value="substring(@created,1,10)"/></div>		
		<div style="clear:both">
			<xf:switch>
				<xf:case id="case-PaymentTask-1" selected="true">
					<div class="tabbody TabBase">
						<xf:input ref="@date">
							<xf:label>Belegdatum:</xf:label>
							<xf:action ev:event="xforms-value-changed">
								<xf:setvalue ref="current()/Bookings/Booking/@date" value="current()/@date"/>
							</xf:action>
						</xf:input>
						<br/>

						<xf:input ref="Amount/@value">
							<xf:label>Betrag:</xf:label>
							<xf:action ev:event="xforms-value-changed">
								<xf:setvalue ref="current()/Bookings/Booking/@amountValue" value="current()/Amount/@value"/>
							</xf:action>	
						</xf:input> 

						<xf:select1 ref="Amount/@unit">
							<xf:item>
								<xf:label>CHF</xf:label>
								<xf:value>CHF</xf:value>
							</xf:item>
							<xf:item>
								<xf:label>EUR</xf:label>
								<xf:value>EUR</xf:value>
							</xf:item>
							<xf:item>
								<xf:label>USD</xf:label>
								<xf:value>USD</xf:value>
							</xf:item>
						</xf:select1>
						<br/>

						<xf:input ref="RefID">
							<xf:label>Rechnungsnummer:</xf:label>
							<xf:help>Wenn es keine Belegnummer gibt, einfach # eintragen</xf:help>
							<xf:action ev:event="xforms-value-changed">
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@refID" value="instance('document')/Process/Tasks/*[index('tasks')]/RefID"/>
							</xf:action>
						</xf:input>
						<br/>
						<xf:textarea ref="Description" class="DoubleInputSize">
							<xf:label>Inhaltsangabe:</xf:label>
							<xf:action ev:event="xforms-value-changed">
								<xf:setvalue ref="instance('document')/Process/Tasks/*[index('tasks')]/Bookings/Booking/@description" value="instance('document')/Process/Tasks/*[index('tasks')]/Description"/>
							</xf:action>
						</xf:textarea>
						<hr/>
						<xf:textarea ref="Notes" class="DoubleInputSize">
							<xf:label>Notizen:</xf:label>
							<xf:help>Besondere Hinweise</xf:help>
						</xf:textarea>
					</div>
				</xf:case>
				<xf:case id="case-PaymentTask-2">
					<div class="tabbody TabBooking">
						<xf:group ref="Bookings/Booking">
							<xsl:call-template name="TaskBooking"/>
						</xf:group>
					</div>
				</xf:case>
				<xf:case id="case-PaymentTask-3">
					<div class="tabbody TabAttachment">
						<xf:group ref="Files/File">
							<xsl:call-template name="Attachment">
								<xsl:with-param name="name" select="'PaymentTask'"/>
								<xsl:with-param name="new-document" select="$new-document"/>
							</xsl:call-template>
						</xf:group>
					</div>
				</xf:case>
			</xf:switch>
		</div>
	</xsl:template>


	<xsl:template name="TransferVoucherTask">
		<div class="tabmenu" style="float:left">
			<xf:trigger id="tab-TransferVoucherTask-1" appearance="minimal" class="TabBase">
				<xf:label>Überweisungsbeleg</xf:label>
				<xf:action ev:event="DOMActivate">
					<!-- <xf:setindex repeat="tasks" index="1"/> -->
					<xf:toggle case="case-TransferVoucherTask-1"/>
				</xf:action>
			</xf:trigger>
			<xf:trigger id="tab-TransferVoucherTask-2" appearance="minimal" class="TabAttachment">
				<xf:label>Anhang</xf:label>
				<xf:action ev:event="DOMActivate">
					<xf:toggle case="case-TransferVoucherTask-2"/>
				</xf:action>
			</xf:trigger>
		</div>
		<div style="float:right">
			<xf:trigger>
				<xf:label><span style="font-weight:normal; font-size:80%"><xf:output ref="@type"/></span> X</xf:label>
				<!-- <xf:delete nodeset="." at="1" if="count(//.) &gt; 1" ev:event="DOMActivate"/> -->
				<xf:delete nodeset="." ev:event="DOMActivate"/> 
			</xf:trigger>
		</div>
		<div style="float:right"><br/>erstellt <xf:output value="substring(@created,1,10)"/></div>		
		<div style="clear:both">
			<xf:switch>
				<xf:case id="case-TransferVoucherTask-1" selected="true">
					<div class="tabbody TabBase">
						<xf:input ref="@date">
							<xf:label>Belegdatum:</xf:label>
						</xf:input>
						<br/>
						<xf:input ref="Amount/@value">
							<xf:label>Betrag:</xf:label>
						</xf:input>
						<xf:select1 ref="Amount/@unit">
							<xf:item>
								<xf:label>CHF</xf:label>
								<xf:value>CHF</xf:value>
							</xf:item>
							<xf:item>
								<xf:label>EUR</xf:label>
								<xf:value>EUR</xf:value>
							</xf:item>
							<xf:item>
								<xf:label>USD</xf:label>
								<xf:value>USD</xf:value>
							</xf:item>
						</xf:select1>
						<br/>
						<xf:input ref="RefID">
							<xf:label>Dokumentennummer:</xf:label>
						</xf:input>
						<br/>
						<xf:textarea ref="Description" class="DoubleInputSize">
							<xf:label>Inhaltsangabe:</xf:label>
						</xf:textarea>
						<hr/>
						<xf:textarea ref="Notes" class="DoubleInputSize">
							<xf:label>Notizen:</xf:label>
							<xf:help>Besondere Hinweise</xf:help>
						</xf:textarea>
					</div>
				</xf:case>
				<xf:case id="case-TransferVoucherTask-2">
					<div class="tabbody TabAttachment">
						<xf:group ref="Files/File">
							<xsl:call-template name="Attachment">
								<xsl:with-param name="name" select="'payment'"/>
								<xsl:with-param name="new-document" select="$new-document"/>
							</xsl:call-template>
						</xf:group>
					</div>
				</xf:case>
			</xf:switch>
		</div>
	</xsl:template>


	<xsl:template name="BankBalancingTask">
		<div class="tabmenu" style="float:left">
			<xf:trigger id="tab-BankBalancingTask-1" appearance="minimal" class="TabBase">
				<xf:label>Kontoausgleich</xf:label>
				<xf:action ev:event="DOMActivate">
					<!-- <xf:setindex repeat="tasks" index="1"/> -->
					<xf:toggle case="case-BankBalancingTask-1"/>
				</xf:action>
			</xf:trigger>
			<xf:trigger id="tab-BankBalancingTask-2" appearance="minimal" class="TabBooking">
				<xf:label>Buchungssätze</xf:label>
				<xf:action ev:event="DOMActivate">
					<xf:toggle case="case-BankBalancingTask-2"/>
				</xf:action>
			</xf:trigger>			
			<xf:trigger id="tab-BankBalancingTask-3" appearance="minimal" class="TabAttachment">
				<xf:label>Anhang</xf:label>
				<xf:action ev:event="DOMActivate">
					<xf:toggle case="case-BankBalancingTask-3"/>
				</xf:action>
			</xf:trigger>
		</div>
		<div style="float:right">
			<xf:trigger>
				<xf:label><span style="font-weight:normal; font-size:80%"><xf:output ref="@type"/></span> X</xf:label>
				<!-- <xf:delete nodeset="." at="1" if="count(//.) &gt; 1" ev:event="DOMActivate"/> -->
				<xf:delete nodeset="." ev:event="DOMActivate"/> 
			</xf:trigger>
		</div>
		<div style="float:right"><br/>erstellt <xf:output value="substring(@created,1,10)"/></div>		
		<div style="clear:both">
			<xf:switch>
				<xf:case id="case-BankBalancingTask-1" selected="true">
					<div class="tabbody TabBase">
						<xf:input ref="@date">
							<xf:label>Belegdatum:</xf:label>
							<xf:action ev:event="xforms-value-changed">
								<xf:setvalue ref="instance('document')/Process/@binder" value="substring(instance('document')/Process/Tasks/BankBalancingTask/@date,6,2)"/>
								<xf:setvalue ref="instance('document')/Process/@date" value="instance('document')/Process/Tasks/BankBalancingTask/@date"/>
							</xf:action>
						</xf:input>
						<br/>

						<xf:input ref="Amount/@value">
							<xf:label>Betrag:</xf:label>
							<xf:action ev:event="xforms-value-changed">
								<xf:setvalue ref="instance('document')/Process/TotalAmount/@value" value="instance('document')/Process/Tasks/BankBalancingTask/Amount/@value"/>
							</xf:action>
						</xf:input>
						<br/>

						<xf:select1 ref="Owner">
							<xf:label>von Bank:</xf:label>
							<xf:hint>
								Service / Dienstleistung:
								<xf:output ref="instance('accounts')/Account[@kto=instance('document')/Process/Tasks/SimpleTask/Owner]/Service"/>
							</xf:hint>
							<xf:itemset nodeset="instance('accounts')/Account[contains(@classes,'bank')]">
								<xf:label ref="Name"/>
								<xf:value ref="@kto"/>
							</xf:itemset>
						</xf:select1>
						<span> #</span>
						<xf:output ref="Owner"/>
						<br/>

						<xf:select1 ref="Other">
							<xf:label>an Bank:</xf:label>
							<xf:itemset nodeset="instance('accounts')/Account[contains(@classes,'bank')]">
								<xf:label ref="Name"/>
								<xf:value ref="@kto"/>
							</xf:itemset>
						</xf:select1>
						<span> #</span>
						<xf:output ref="Other"/>
						<br/>

						<xf:input ref="RefID">
							<xf:label>Belegnummer:</xf:label>
							<xf:help>Wenn es keine Belegnummer gibt, einfach # eintragen</xf:help>
						</xf:input>
						<br/>

						<xf:textarea ref="Description" class="DoubleInputSize">
							<xf:label>Inhaltsangabe:</xf:label>
						</xf:textarea>
						<hr/>
						<xf:textarea ref="Notes" class="DoubleInputSize">
							<xf:label>Notizen:</xf:label>
							<xf:help>Besondere Hinweise</xf:help>
						</xf:textarea>
					</div>
				</xf:case>
				<xf:case id="case-BankBalancingTask-2">
					<div class="tabbody TabBooking">
						<xf:group ref="Bookings/Booking">
							<xsl:call-template name="TaskBooking"/>
						</xf:group>
					</div>
				</xf:case>				
				<xf:case id="case-BankBalancingTask-3">
					<div class="tabbody TabAttachment">
						<xf:group ref="Files/File">
							<xsl:call-template name="Attachment">
								<xsl:with-param name="name" select="'payment'"/>
								<xsl:with-param name="new-document" select="$new-document"/>
							</xsl:call-template>
						</xf:group>
					</div>
				</xf:case>
			</xf:switch>
		</div>
	</xsl:template>


	<xsl:template name="DeliveryNoteTask">
		<div class="tabmenu" style="float:left">
			<xf:trigger id="tab-DeliveryNoteTask-1" appearance="minimal" class="TabBase">
				<xf:label>Lieferschein</xf:label>
				<xf:action ev:event="DOMActivate">
					<!-- <xf:setindex repeat="tasks" index="1"/> -->
					<xf:toggle case="case-DeliveryNoteTask-1"/>
				</xf:action>
			</xf:trigger>
			<xf:trigger id="tab-DeliveryNoteTask-2" appearance="minimal" class="TabAttachment">
				<xf:label>Anhang</xf:label>
				<xf:action ev:event="DOMActivate">
					<xf:toggle case="case-DeliveryNoteTask-2"/>
				</xf:action>
			</xf:trigger>
		</div>
		<div style="float:right">
			<xf:trigger>
				<xf:label><span style="font-weight:normal; font-size:80%"><xf:output ref="@type"/></span> X</xf:label>
				<!-- <xf:delete nodeset="." at="1" if="count(//.) &gt; 1" ev:event="DOMActivate"/> -->
				<xf:delete nodeset="." ev:event="DOMActivate"/> 
			</xf:trigger>
		</div>
		<div style="float:right"><br/>erstellt <xf:output value="substring(@created,1,10)"/></div>		
		<div style="clear:both">
			<xf:switch>
				<xf:case id="case-DeliveryNoteTask-1" selected="true">
					<div class="tabbody TabBase">
						<xf:input ref="@date">
							<xf:label>Belegdatum:</xf:label>
						</xf:input>
						<br/>
						<xf:input ref="RefID">
							<xf:label>Dokumentennummer:</xf:label>
						</xf:input>
						<br/>
						<xf:textarea ref="Description" class="DoubleInputSize">
							<xf:label>Inhaltsangabe:</xf:label>
						</xf:textarea>
						<hr/>
						<xf:textarea ref="Notes" class="DoubleInputSize">
							<xf:label>Notizen:</xf:label>
							<xf:help>Besondere Hinweise</xf:help>
						</xf:textarea>
					</div>
				</xf:case>
				<xf:case id="case-DeliveryNoteTask-2">
					<div class="tabbody TabAttachment">
						<xf:group ref="Files/File">
							<xsl:call-template name="Attachment">
								<xsl:with-param name="name" select="'PaymentTask'"/>
								<xsl:with-param name="new-document" select="$new-document"/>
							</xsl:call-template>
						</xf:group>
					</div>
				</xf:case>
			</xf:switch>
		</div>
	</xsl:template>


	<!-- 
		Separter Block, da dieser im Model (im Head der HTML Datei) enthalten sein muss. 
	-->
	<xsl:template name="TaskBindings">
		<xsl:variable name="FilenamePrefix">
			<xsl:text>instance('document')/Process/@date,'_'</xsl:text>
			<xsl:text>,</xsl:text>
			<xsl:choose>
				<xsl:when test="/result/Process/Tasks/SimpleTask">
					<xsl:text>'Buchung'</xsl:text>
				</xsl:when>
				<xsl:when test="/result/Process/Tasks/DocumentTask">
					<xsl:text>'Dokument'</xsl:text>
				</xsl:when>
				<xsl:when test="/result/Process/Tasks/AttachmentTask">
					<xsl:text>'Anhang'</xsl:text>
				</xsl:when>
				<xsl:when test="/result/Process/Tasks/InvoiceInTask">
					<xsl:text>'Rechnung'</xsl:text>
				</xsl:when>
				<xsl:when test="/result/Process/Tasks/InvoiceOutTask">
					<xsl:text>'InvoiceOut'</xsl:text>
				</xsl:when>
				<xsl:when test="/result/Process/Tasks/BankBalancingTask">
					<xsl:text>'Kontoausgleich'</xsl:text>
				</xsl:when>
				<xsl:when test="/result/Process/Tasks/TaxTask">
					<xsl:text>'Steuer'</xsl:text>
				</xsl:when>
				<xsl:when test="/result/Process/Tasks/EmployeeSalaryTask">
					<xsl:text>'Gehalt'</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>'Unbekannt'</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:text>,</xsl:text>
			<xsl:text>if(instance('document')/Process/Tasks/*/@isStorno='true','-STORNO','')</xsl:text>
			<xsl:text>,'_(',</xsl:text>
			<xsl:text>instance('accounts')/Account[@kto=instance('document')/Process/Tasks/*[1]/Owner]/@id</xsl:text>
			<xsl:text>,')'</xsl:text>
			<xsl:choose>
				<xsl:when test="/result/Process/Tasks/SimpleTask">
					<xsl:text>,''</xsl:text>
				</xsl:when>
				<xsl:when test="/result/Process/Tasks/DocumentTask">
					<xsl:text>,'_',</xsl:text>
					<xsl:text>replace(translate(substring(instance('document')/Process/Tasks/*[1]/DocName,1,40),' ','_'),'[^A-Za-z0-9_\\-\\+]','-')</xsl:text>
					<xsl:text>,'_',</xsl:text>
					<xsl:text>replace(translate(substring(instance('document')/Process/Tasks/*[1]/RefID,1,40),' ','_'),'[^A-Za-z0-9_\\-\\+]','-')</xsl:text>
				</xsl:when>
				<xsl:when test="/result/Process/Tasks/InvoiceInTask">
					<xsl:text>,'_(',</xsl:text>
					<xsl:text>replace(translate(substring(instance('document')/Process/Tasks/*[1]/RefID,1,25),' ','_'),'[^A-Za-z0-9_\\-\\+]','-')</xsl:text>
					<xsl:text>,')_(',</xsl:text>
					<xsl:text>replace(translate(substring(instance('document')/Process/Tasks/*[1]/TransactionID,1,25),' ','_'),'[^A-Za-z0-9_\\-\\+]','-')</xsl:text>
					<xsl:text>,')_(',</xsl:text>
					<xsl:text>replace(translate(substring(instance('document')/Process/Tasks/*[1]/Description,1,25),' ','_'),'[^A-Za-z0-9_\\-\\+]','-')</xsl:text>
					<xsl:text>,')'</xsl:text>
				</xsl:when>
				<xsl:when test="/result/Process/Tasks/InvoiceOutTask">
					<xsl:text>,'_(',</xsl:text>
					<xsl:text>replace(translate(substring(instance('document')/Process/Tasks/*[1]/RefID,1,25),' ','_'),'[^A-Za-z0-9_\\-\\+]','-')</xsl:text>
					<xsl:text>,')_(',</xsl:text>
					<xsl:text>replace(translate(substring(instance('document')/Process/Tasks/*[1]/TransactionID,1,25),' ','_'),'[^A-Za-z0-9_\\-\\+]','-')</xsl:text>
					<xsl:text>,')_(',</xsl:text>
					<xsl:text>replace(translate(substring(instance('document')/Process/Tasks/*[1]/Description,1,25),' ','_'),'[^A-Za-z0-9_\\-\\+]','-')</xsl:text>
					<xsl:text>,')'</xsl:text>
				</xsl:when>				
				<xsl:when test="/result/Process/Tasks/TaxTask">
					<xsl:text>,'_(',</xsl:text>
					<xsl:text>replace(translate(substring(instance('document')/Process/Tasks/*[1]/RefID,1,40),' ','_'),'[^A-Za-z0-9_\\-\\+]','-')</xsl:text>
					<xsl:text>,')_',</xsl:text>
					<xsl:text>replace(translate(substring(instance('document')/Process/Tasks/*[1]/Description,1,40),' ','_'),'[^A-Za-z0-9_\\-\\+]','-')</xsl:text>
				</xsl:when>				
				<xsl:when test="/result/Process/Tasks/EmployeeSalaryTask">
					<xsl:text>,')_(',</xsl:text>
					<xsl:text>replace(translate(substring(instance('document')/Process/Tasks/*[1]/EmployeeID,1,40),' ','_'),'[^A-Za-z0-9_\\-\\+]','-')</xsl:text>
					<xsl:text>,'_',</xsl:text>
					<xsl:text>replace(translate(substring(instance('document')/Process/Tasks/*[1]/EmployeeName,1,40),' ','_'),'[^A-Za-z0-9_\\-\\+]','-')</xsl:text>
					<xsl:text>,')_',</xsl:text>
					<xsl:text>replace(translate(substring(instance('document')/Process/Tasks/*[1]/SalaryMonth,1,40),' ','_'),'[^A-Za-z0-9_\\-\\+]','-')</xsl:text>
				</xsl:when>
				<xsl:when test="/result/Process/Tasks/BankBalancingTask">
					<xsl:text/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>,(</xsl:text>
					<xsl:text>replace(translate(substring(instance('document')/Process/Tasks/*[1],1,20),' ','_'),'[^A-Za-z0-9_\\-\\+]','-')</xsl:text>
					<xsl:text>),</xsl:text>
					<xsl:text>replace(translate(substring(instance('document')/Process/Notes,1,20),' ','_'),'[^A-Za-z0-9_\\-\\+]','-')</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<!-- https://gist.github.com/dmccreary/8927998 https://www.w3.org/community/xformsusers/wiki/XForms_2.0#The_alert_Property -->


		<!-- Process general: -->
		<!-- can be found at template_process.xsl -->
		<xf:bind nodeset="instance('document')/Process">
			<xsl:if test="$new-document">
				<xf:bind nodeset="@name" calculate="concat({$FilenamePrefix})"/>
			</xsl:if>
			<xf:bind nodeset="@type" type="xs:string" required="true()"/>
			<xf:bind nodeset="@date" type="xs:date" required="true()" constraint="substring(instance('document')/Process/@date,1,4)='{$year}' and instance('document')/Process/@binder=instance('binders')/Binders/Binder/@name"> <!-- instance('binders')/Binders/@year -->
				<xsl:choose>
					<xsl:when test="not($new-document)">
						<xsl:attribute name="readonly" select="'true()'"/>
					</xsl:when>
					<xsl:when test="name(result/Process/Tasks/*)=('SimpleTask','DocumentTask','InvoiceInTask','InvoiceOutTask','TaxTask','EmployeeSalaryTask','BankBalancingTask')">
						<xsl:attribute name="readonly" select="'true()'"/>
					</xsl:when>
				</xsl:choose>
			</xf:bind>
			<xf:bind nodeset="@name" type="xs:string" required="true()" constraint="string-length(.) &gt; 10"/>
			<xf:bind nodeset="@binder" type="xs:string" required="true()" constraint=".=instance('binders')/Binders/Binder/@name and string-length(.) &gt; 1">
				<xsl:if test="not($new-document)"> 
					<xsl:attribute name="readonly" select="'true()'"/>
				</xsl:if>
			</xf:bind>
			<xf:bind nodeset="Notes" type="xs:string" required="false()"/>
			<xf:bind nodeset="TotalAmount/@value" type="xs:decimal" required="true()" alert="Amount is mandatory"/>
		</xf:bind>

		<!-- All kind of Task (general) -->
		<xf:bind nodeset="Tasks/*/">
			<xf:bind nodeset="@date" type="xs:date" required="true()" alert="Invalid date"/>
			<xf:bind nodeset="@id" type="xs:string" required="true()" readonly="true()" alert="invalid ID"/> 
			<xf:bind nodeset="@created" type="xs:dateTime" required="true()" readonly="true()" alert="invalid created"/>
			<xf:bind nodeset="@user" type="xs:string" required="true()" readonly="true()" alert="invalid user"/>
			<xf:bind nodeset="@isStorno" type="xs:string" readonly="true()" alert="invalid storno"/>
			<xf:bind nodeset="TotalAmount/@value" type="xs:decimal" required="true()" alert="invalid amount value"/>
		</xf:bind>

		<!-- All kind of Accounting (general) -->
		<xf:bind nodeset="instance('document')/Process/Tasks/*/Bookings/Booking" relevant="instance('document')/Process/Tasks/*/Bookings/Booking">
			<xf:bind nodeset="@date" type="xs:date" required="true()" readonly="true()"/>
			<xf:bind nodeset="@amountValue" type="xs:decimal" required="true()" readonly="true()" constraint=". != 0"/>
			<xf:bind nodeset="@amountUnit" type="xs:string" required="true()" readonly="true()" constraint=".='EUR' or .='CHF' or .='USD'"/>
			<xf:bind nodeset="@credit" type="xs:string" required="true()" readonly="true()" constraint="number(.) &gt; 0"/>
			<xf:bind nodeset="@debit" type="xs:stromg" required="true()" readonly="true()" constraint="number(.) &gt; 0"/>
			<xf:bind nodeset="@taxKey" type="xs:string" required="true()" readonly="true()"/>
			<xf:bind nodeset="@taxAmount" type="xs:decimal" required="true()" readonly="true()" constraint=". &gt;= 0"/>
			<xf:bind nodeset="@refID" type="xs:string" required="true()" readonly="true()" costraint="string-length(.) &gt; 3"/>
			<xf:bind nodeset="@description" type="xs:string" required="true()" readonly="true()" costraint="string-length(.) &gt; 3"/>
		</xf:bind>

		<!-- Attachment general -->
		<xf:bind nodeset="instance('document')/Process/Tasks/*/Files/File" relevant="instance('document')/Process/Tasks/*/Files/File">
			<xf:bind nodeset="@fileName" type="xs:string" required="true()" readonly="true()" alert="Filename is missing"/>
			<xf:bind nodeset="@doctype" type="xs:string" required="true()" constraint=".='digital' or .='paper'" alert="File type is missing"/>
		</xf:bind>

		<!-- there is only one main task given -->
		<xsl:choose>
			<xsl:when test="/result/Process/Tasks/SimpleTask">
				<xf:bind nodeset="instance('document')/Process/@binder" constraint=".=instance('binders')/Binders/Binder[@type='MONTH']/@name"/>

				<xf:bind nodeset="instance('document')/Process/Tasks/SimpleTask">
					<xf:bind id="SimpleTask-date" nodeset="@date" type="xs:date" required="true()" constraint="substring(.,1,4)='{$year}'"/>
					<xf:bind id="SimpleTask-Owner" nodeset="Owner" type="xs:positiveInteger" required="true()" constraint="string-length(.) &gt; 3"/>
					<xf:bind id="SimpleTask-RefID" nodeset="RefID" type="xs:string" required="true()" constraint=".='#' or string-length(.) &gt; 3"/>
					<xf:bind id="SimpleTask-Description" nodeset="Description" type="xs:string" required="true()" constraint="string-length(.) &gt; 3"/>
					<xf:bind id="SimpleTask-Notes" nodeset="Notes" type="xs:string" required="false()"/>

					<!-- <xf:bind nodeset="Bookings" constraint="count(*) != 0"/> -->
					<xsl:choose>
						<xsl:when test="$new-document">
							<xf:bind nodeset="Files/File/@fileName" calculate="concat({$FilenamePrefix})" relevant="instance('document')/Process/Tasks/SimpleTask/Files/File/@uploadSrc"/>
							<xf:bind nodeset="Files/File/@type" relevant="instance('document')/Process/Tasks/SimpleTask/Files/File/@uploadSrc"/>
						</xsl:when>
					</xsl:choose>
				</xf:bind>
			</xsl:when>
		
			<xsl:when test="/result/Process/Tasks/DocumentTask">
				<!-- Also AttachmentTask -->
			</xsl:when>

			<xsl:when test="/result/Process/Tasks/InvoiceInTask">
				<xf:bind nodeset="instance('document')/Process/TotalAmount/@value" readonly="true()" calculate="round(sum(instance('document')/Process/Tasks/*[not(name()='PaymentTask') and not(name()='TransferVoucherTask') and not(name()='DeliveryNoteTask')]/Amount/@value)*100) div 100"/>
				<xsl:choose>
					<xsl:when test="$is-storno">
						<xf:bind nodeset="instance('document')/Process/TotalAmount/@value" constraint=". &gt; 0" alert="Amount has to be given as a positive value"/>
					</xsl:when>
					<xsl:otherwise>
						<xf:bind nodeset="instance('document')/Process/TotalAmount/@value" constraint=". &lt; 0" alert="Amount has to be given as a negative value"/>
					</xsl:otherwise>
				</xsl:choose>

				<xf:bind nodeset="instance('document')/Process/@binder" constraint=".=instance('binders')/Binders/Binder[@type='MONTH']/@name" readonly="true()"/>

				<xf:bind nodeset="instance('document')/Process/Tasks/InvoiceInTask">
					<xf:bind nodeset="@date" type="xs:date" required="true()" constraint="substring(.,1,4)='{$year}' and substring(.,6,2)=instance('document')/Process/@binder"/>
					<xf:bind nodeset="Owner" type="positiveNumber" required="true()"/>

					<xf:bind nodeset="RefID" type="xs:string" required="true()" constraint=".='#' or string-length(.) &gt; 3"/>
					<xf:bind nodeset="TransactionID" type="xs:string" required="false()" constraint=".='' or .='#' or string-length(.) &gt; 3"/>
					<xf:bind nodeset="Description" type="xs:string" required="true()" constraint="string-length(.) &gt; 3"/>

					<!-- <xf:bind nodeset="Bookings" required="true()" constraint="count(*) = 0"/> -->
					
					<xf:bind nodeset="Files/File/@type" calculate="if({$is-storno},'doc-invoice-in-storno','doc-invoice-in')" readonly="true()" relevant="instance('document')/Process/Tasks/InvoiceInTask/Files/File"/>
					<xf:bind nodeset="Files/File/@fileName" calculate="concat({$FilenamePrefix})" relevant="instance('document')/Process/Tasks/InvoiceInTask/Files/File/@uploadSrc"/>
					<xf:bind nodeset="Files/File/@fileName" type="xs:string" relevant="instance('document')/Process/Tasks/InvoiceInTask/Files/File"/>
				</xf:bind>
				<xf:bind nodeset="instance('temp')/TaskType" type="xs:string" constraint=".=''" relevant="instance('document')/Process/Tasks/InvoiceInTask"/>
			</xsl:when>

			<xsl:when test="/result/Process/Tasks/InvoiceOutTask">
				<xf:bind nodeset="instance('document')/Process/TotalAmount/@value" readonly="true()" calculate="sum(instance('document')/Process/Tasks/*[not(name()='PaymentTask') and not(name()='TransferVoucherTask') and not(name()='DeliveryNoteTask')]/Amount/@value)"/>
				<xsl:choose>
					<xsl:when test="$is-storno">
						<xf:bind nodeset="instance('document')/Process/TotalAmount/@value" constraint=". &lt; 0" alert="Amount has to be given as a positive value"/>
					</xsl:when>
					<xsl:otherwise>
						<xf:bind nodeset="instance('document')/Process/TotalAmount/@value" constraint=". &gt; 0" alert="Amount has to be given as a negative value"/>
					</xsl:otherwise>
				</xsl:choose>

				<xf:bind nodeset="instance('document')/Process/@binder" constraint=".=instance('binders')/Binders/Binder[@type='MONTH']/@name" readonly="true()"/>

				<xf:bind nodeset="instance('document')/Process/Tasks/InvoiceOutTask">
					<xf:bind nodeset="@date" type="xs:date" required="true()" constraint="substring(.,1,4)='{$year}' and substring(.,6,2)=instance('document')/Process/@binder"/>
					<xf:bind nodeset="Owner" type="positiveNumber" required="true()"/>

					<xf:bind nodeset="RefID" type="xs:string" required="true()" constraint=".='#' or string-length(.) &gt; 3"/>
					<xf:bind nodeset="TransactionID" type="xs:string" required="false()" constraint=".='' or .='#' or string-length(.) &gt; 3"/>
					<xf:bind nodeset="Description" type="xs:string" required="true()" constraint="string-length(.) &gt; 3"/>

					<!-- <xf:bind nodeset="Bookings" required="true()" constraint="count(*) = 0"/> -->
					<!-- only for new files (relevant=.../@uploadSrc) -->
					<xf:bind nodeset="Files/File/@type" calculate="if({$is-storno},'doc-invoice-out-storno','doc-invoice-out')" readonly="true()" relevant="instance('document')/Process/Tasks/InvoiceOutTask/Files/File"/>
					<xf:bind nodeset="Files/File/@fileName" calculate="concat({$FilenamePrefix})" relevant="instance('document')/Process/Tasks/InvoiceOutTask/Files/File/@uploadSrc"/>
					<xf:bind nodeset="Files/File/@fileName" type="xs:string" relevant="instance('document')/Process/Tasks/InvoiceOutTask/Files/File"/>
				</xf:bind>			

				<xf:bind nodeset="instance('temp')/TaskType" type="xs:string" constraint=".=''" relevant="instance('document')/Process/Tasks/InvoiceOutTask"/>
			</xsl:when>

			<xsl:when test="/result/Process/Tasks/TaxTask">
				<xf:bind nodeset="instance('document')/Process/@binder" constraint=".=instance('binders')/Binders/Binder[@type='MONTH']/@name" readonly="true()"/>
				<xf:bind nodeset="instance('document')/Process/TotalAmount/@value" readonly="true()"/>

				<xf:bind nodeset="instance('document')/Process/Tasks/TaxTask">
					<xf:bind nodeset="@date" type="xs:date" required="true()"/>
					<xf:bind nodeset="Amount/@value" type="xs:decimal" required="true()"/>
					<xf:bind nodeset="Amount/@value" constraint="{if($is-storno) then '. &gt; 0' else '. &lt; 0'}"/>

					<xf:bind nodeset="Amount/@unit" type="xs:string" required="true()"/>
					<xf:bind nodeset="Owner" type="xs:positiveInteger" required="true()"/>
					<xf:bind nodeset="Tax/@typeOfTax" type="xs:string" constraint="string-length(.) &gt; 0" required="true()"/>
					<xf:bind nodeset="Tax/@period" type="xs:string" constraint="string-length(.) &gt; 0" required="true()"/>
					<xf:bind nodeset="RefID" type="xs:string" constraint=".='#' or string-length(.) &gt; 4" required="true()"/>
					<xf:bind nodeset="Description" type="xs:string" constraint="string-length(.) &gt; 4" required="true()"/>
					
					<!-- only for new files (relevant=.../@uploadSrc) -->
					<xf:bind nodeset="Files/File/@type" readonly="true()" relevant="instance('document')/Process/Tasks/TaxTask/Files/File"/>
					<xf:bind nodeset="Files/File/@fileName" calculate="concat({$FilenamePrefix})" relevant="instance('document')/Process/Tasks/TaxTask/Files/File/@uploadSrc"/>
					<xf:bind nodeset="Files/File/@fileName" type="xs:string" relevant="instance('document')/Process/Tasks/TaxTask/Files/File"/>
				</xf:bind>
			</xsl:when>

			<xsl:when test="/result/Process/Tasks/EmployeeSalaryTask">
				<xf:bind nodeset="instance('document')/Process/@binder" constraint=".=instance('binders')/Binders/Binder[@type='MONTH']/@name" readonly="true()"/>
				<xf:bind nodeset="instance('document')/Process/TotalAmount/@value" constraint=". &lt; 0" readonly="true()"/>

				<xf:bind nodeset="instance('document')/Process/Tasks/EmployeeSalaryTask">
					<xf:bind nodeset="Owner" type="xs:positiveInteger" required="true()"/>
					<xf:bind nodeset="EmployeeID" type="xs:string" required="true()"/>
					<xf:bind nodeset="EmployeeName" type="xs:string" required="true()"/>
					<xf:bind nodeset="SalaryMonth" type="xs:string" required="true()"/>

					<xf:bind nodeset="GrossSalary" type="xs:decimal" constraint=". &gt; 0" required="true()"/>
					<xf:bind nodeset="TaxBasedComission" type="xs:decimal" constraint=". &gt;= 0" required="true()"/>
					<xf:bind nodeset="SozialSecurityCommission" type="xs:decimal" constraint=". &gt;= 0" required="true()"/>
					<xf:bind nodeset="AmountPaid" type="xs:decimal" constraint=". &gt; 0" required="true()" readonly="true()" calculate="GrossSalary - instance('document')/Process/Tasks/EmployeeSalaryTask/TaxBasedComission - instance('document')/Process/Tasks/EmployeeSalaryTask/SozialSecurityCommission"/>

					<xf:bind nodeset="SozialSecurityEmloyeeContribution" constraint=". &gt;= 0" type="xs:decimal" required="true()"/>
					<xf:bind nodeset="SozialSecurityEmployeeAddition" constraint=". &gt;= 0" type="xs:decimal" required="true()"/>
					<xf:bind nodeset="OverallCosts" type="xs:decimal" constraint=". &gt; 0" required="true()" readonly="true()" calculate="instance('document')/Process/Tasks/EmployeeSalaryTask/GrossSalary + instance('document')/Process/Tasks/EmployeeSalaryTask/SozialSecurityEmloyeeContribution + instance('document')/Process/Tasks/EmployeeSalaryTask/SozialSecurityEmployeeAddition"/>

					<!-- only for new files (relevant=.../@uploadSrc) -->
					<xf:bind nodeset="Files/File/@type" readonly="true()" relevant="instance('document')/Process/Tasks/EmployeeSalaryTask/Files/File"/>
					<xf:bind nodeset="Files/File/@fileName" calculate="concat({$FilenamePrefix})" relevant="instance('document')/Process/Tasks/EmployeeSalaryTask/Files/File/@uploadSrc"/>
					<xf:bind nodeset="Files/File/@fileName" type="xs:string" relevant="instance('document')/Process/Tasks/EmployeeSalaryTask/Files/File"/>
				</xf:bind>

			</xsl:when>

			<xsl:when test="/result/Process/Tasks/BankBalancingTask">
				<xf:bind nodeset="instance('document')/Process/@binder" constraint=".=instance('binders')/Binders/Binder[@type='MONTH']/@name" readonly="true()"/>
				<xf:bind nodeset="instance('document')/Process/TotalAmount/@value" readonly="true()" relevant="instance('document')/Process/Tasks/BankBalancingTask"/>

				<xf:bind nodeset="instance('document')/Process/Tasks/BankBalancingTask">
					<xf:bind nodeset="@date" type="xs:date" required="true()"/> 
					<!-- <xf:bind nodeset="Owner" type="xs:positiveInteger" required="true()"/> -->
					<!-- <xf:bind nodeset="Other" type="xs:positiveInteger" required="true()"/> -->
					<xf:bind nodeset="RefID" type="xs:string" required="true()" constraint=".='#' or string-length(.) &gt; 3"/>
					<xf:bind nodeset="Amount/@value" type="xs:decimal" required="true()" constraint=". &lt; 0"/>
					<xf:bind nodeset="Description" type="xs:string" required="true()" constraint="string-length(.) &gt; 3"/>
					<!-- <xf:bind nodeset="/TriggerDate" type="xs:date" required="false()"/> -->

					<!-- only for new files (relevant=.../@uploadSrc) -->
					<xf:bind nodeset="Files/File/@type" relevant="instance('document')/Process/Tasks/BankBalancingTask/Files/File"/>				
					<xf:bind nodeset="Files/File/@fileName" calculate="concat({$FilenamePrefix},'_Lieferschein')" relevant="instance('document')/Process/Tasks/BankBalancingTask/Files/File/@uploadSrc"/>
					<xf:bind nodeset="Files/File/@fileName" type="xs:string" required="true()" relevant="instance('document')/Process/Tasks/BankBalancingTask/Files/File"/>
				</xf:bind>
			</xsl:when>

			<xsl:otherwise>
				<xf:bind nodeset="ERROR_Unknown_Main_Task_Given"/>
			</xsl:otherwise>
		</xsl:choose>


		<!-- additional task can be optionally given in advance -->

				<xf:bind nodeset="instance('document')/Process/Tasks/DocumentTask">
					<xf:bind id="DocumentTask-date" nodeset="@date" type="xs:date" required="true()" constraint="substring(.,1,4)='{$year}'"/>
					<xf:bind id="DocumentTask-type" nodeset="@type" type="xs:ENTITY" required="true()" constraint=".!=''"/>
					<xf:bind id="DocumentTask-Owner" nodeset="Owner" type="xs:positiveInteger" required="true()" constraint="string-length(.) &gt; 3"/>
					<xf:bind id="DocumentTask-DocName" nodeset="DocName" type="xs:string" required="true()" constraint="string-length(.) &gt; 3"/>
					<xf:bind id="DocumentTask-RefID" nodeset="RefID" type="xs:string" required="false()"/>
					<xf:bind id="DocumentTask-Description" nodeset="Description" type="xs:string" required="true()" constraint="string-length(.) &gt; 3"/>
					<xf:bind id="DocumentTask-Notes" nodeset="Notes" type="xs:string" required="false()"/>

					<xf:bind nodeset="Bookings" constraint="count(*) = 0"/>
					<xsl:choose>
						<xsl:when test="$new-document">
							<xf:bind nodeset="Files/File/@fileName" calculate="concat({$FilenamePrefix})" relevant="instance('document')/Process/Tasks/DocumentTask/Files/File/@uploadSrc"/>
							<xf:bind nodeset="Files/File/@type" relevant="instance('document')/Process/Tasks/DocumentTask/Files/File/@uploadSrc"/>
						</xsl:when>
					</xsl:choose>				
					<xf:bind nodeset="Files/File/@fileName" type="xs:string" relevant="instance('document')/Process/Tasks/DocumentTask/Files/File"/>
				</xf:bind>


		<!-- CommodityTask -->
		<xf:bind nodeset="instance('document')/Process/Tasks/CommodityTask">
			<xf:bind nodeset="@date" type="xs:date" required="true()"/>
			<xf:bind nodeset="Other" type="xs:positiveNumber" required="true()" constraint=". &gt; 0"/>
			<xf:bind nodeset="Amount/@value" type="xs:decimal" required="true()" constraint="(. &gt; 0 and ((instance('document')/Process/Tasks/InvoiceInTask and instance('document')/Process/Tasks/CommodityTask[@isStorno='true'])                    or (instance('document')/Process/Tasks/InvoiceOutTask and instance('document')/Process/Tasks/CommodityTask[not(@isStorno='true')]))                ) or (. &lt; 0 and ((instance('document')/Process/Tasks/InvoiceInTask and instance('document')/Process/Tasks/CommodityTask[not(@isStorno='true')])                            or (instance('document')/Process/Tasks/InvoiceOutTask and instance('document')/Process/Tasks/CommodityTask[@isStorno='true'])) )"/>
			<xf:bind nodeset="Amount/@unit" type="xs:string" required="true()"/>
			<xf:bind nodeset="Tax/@key" type="xs:string" required="true()" constraint="string-length(.) &gt; 0"/>
			<xf:bind nodeset="Tax/@region" type="xs:string" required="true()" constraint="string-length(.) &gt; 0"/>
			<xf:bind nodeset="Tax/@type" type="xs:string" required="true()" constraint="string-length(.) &gt; 0"/>
			<xf:bind nodeset="Description" type="xs:string" required="true()" constraint="string-length(.) &gt; 3"/>
			<!-- <xf:bind nodeset="Bookings/*" required="true()" alert="At least one booking required"/> -->
		</xf:bind>

		<!-- PaymentTask -->
		<xf:bind nodeset="instance('document')/Process/Tasks/PaymentTask">
			<xf:bind nodeset="@date" type="xs:date" required="true()" readonly="true()"/>
			<xf:bind nodeset="Amount/@value" type="xs:decimal" required="true()" readonly="true()"/>
			<xf:bind nodeset="Amount/@unit" type="xs:string" required="true()" readonly="true()"/>
			<xf:bind nodeset="RefID" type="xs:string" required="true()" readonly="true()"/>
			<xf:bind nodeset="Description" type="xs:string" required="true()" readonly="true()"/>
			<!-- only for new files (relevant=.../@uploadSrc) -->
			<xf:bind nodeset="Files/File/@type" readonly="true()" relevant="instance('document')/Process/Tasks/PaymentTask/Files/File"/>
			<xf:bind nodeset="Files/File/@fileName" calculate="concat({$FilenamePrefix},'_Bezahlung')" relevant="Files/File/@uploadSrc"/>
			<xf:bind nodeset="Files/File/@fileName" type="xs:string" relevant="instance('document')/Process/Tasks/PaymentTask/Files/File"/>
		</xf:bind>

		<!-- TransferVoucher -->
		<xf:bind nodeset="instance('document')/Process/Tasks/TransferVoucherTask">
			<xf:bind nodeset="@type" type="xs:string" required="true()"/>
			<xf:bind nodeset="Amount/@value" type="xs:decimal" required="true()"/>
			<xf:bind nodeset="Amount/@unit" type="xs:string" required="true()"/>
			<xf:bind nodeset="Description" type="xs:string" required="false()"/>
			<xf:bind nodeset="Notes" type="xs:string" required="false()"/>
			<xf:bind nodeset="Appointment/@date" type="xs:date" required="false()"/>
			<!-- only for new files (relevant=.../@uploadSrc) -->
			<xf:bind nodeset="Files/File/@type" readonly="true()" relevant="instance('document')/Process/Tasks/TransferVoucherTask/Files/File"/>				
			<xf:bind nodeset="Files/File/@fileName" calculate="concat({$FilenamePrefix},'_Ueberweisung')" relevant="instance('document')/Process/Tasks/TransferVoucherTask/Files/File/@uploadSrc"/>
			<xf:bind nodeset="Files/File/@fileName" type="xs:string" relevant="instance('document')/Process/Tasks/TransferVoucherTask/Files/File"/>
		</xf:bind>

		<!-- DiscountTask -->
		<xf:bind nodeset="instance('document')/Process/Tasks/DiscountTask">
			<xf:bind nodeset="Amount/@value" type="xs:decimal" required="true()" constraint=". != 0"/>
			<xf:bind nodeset="Amount/@unit" type="xs:string" required="true()"/>
			<xf:bind nodeset="RefID" type="xs:string" required="true()" constraint=".='#' or string-length(.) &gt; 3"/>
			<xf:bind nodeset="Description" type="xs:string" required="true()" constraint="string-length(.) &gt; 3"/>
		</xf:bind>

		<!-- DunningFeeTask -->
		<xf:bind nodeset="instance('document')/Process/Tasks/DunningFeeTask">
			<xf:bind nodeset="Amount/@value" type="xs:decimal" required="true()" constraint=". != 0" relevant="instance('document')/Process/Tasks/DunningFeeTask"/>
			<xf:bind nodeset="Amount/@unit" type="xs:string" required="true()" relevant="instance('document')/Process/Tasks/DunningFeeTask"/>
			<xf:bind nodeset="RefID" type="xs:string" required="true()" constraint=".='#' or string-length(.) &gt; 3" relevant="instance('document')/Process/Tasks/DunningFeeTask"/>
			<xf:bind nodeset="Description" type="xs:string" required="true()" constraint="string-length(.) &gt; 3" relevant="instance('document')/Process/Tasks/DunningFeeTask"/>
			<!-- only for new files (relevant=.../@uploadSrc) -->
			<xf:bind nodeset="Files/File/@type" calculate="'doc-dunning-charge'" relevant="instance('document')/Process/Tasks/DunningFeeTask/Files/File"/>				
			<xf:bind nodeset="Files/File/@fileName" calculate="concat({$FilenamePrefix},'_Lieferschein')" relevant="instance('document')/Process/Tasks/DunningFeeTask/Files/File/@uploadSrc"/>
			<xf:bind nodeset="Files/File/@fileName" type="xs:string" relevant="instance('document')/Process/Tasks/DunningFeeTask/Files/File"/>
		</xf:bind>

		<!-- DeliveryNoteTask -->
		<xf:bind nodeset="instance('document')/Process/Tasks/DeliveryNoteTask">
			<xf:bind nodeset="Description" type="xs:string" required="true()" constraint="string-length(.) &gt; 3" relevant="instance('document')/Process/Tasks/DeliveryNoteTask"/>
			<!-- only for new files (relevant=.../@uploadSrc) -->
			<xf:bind nodeset="Files/File/@type" calculate="'doc-delivery-note'" readonly="true()" relevant="Files/File"/>
			<xf:bind nodeset="Files/File/@fileName" calculate="concat({$FilenamePrefix},'_Lieferschein')" relevant="instance('document')/Process/Tasks/DeliveryNoteTask/Files/File/@uploadSrc"/>
			<xf:bind nodeset="Files/File/@fileName" type="xs:string" relevant="instance('document')/Process/Tasks/DeliveryNoteTask/Files/File"/>
		</xf:bind>

		<!-- AttachmentTask -->
		<xf:bind nodeset="instance('document')/Process/Tasks/AttachmentTask">
			<xf:bind nodeset="Files/File/@fileName" calculate="concat({$FilenamePrefix},'_Anhang')" relevant="instance('document')/Process/Tasks/AttachmentTask/Files/File/@uploadSrc"/>
			<xf:bind nodeset="Files/File/@fileName" type="xs:string" relevant="instance('document')/Process/Tasks/AttachmentTask/Files/File"/>
		</xf:bind>

	</xsl:template>


	<xsl:template name="TaskBooking">
		<dev>
			<!--								
			<xf:trigger>
				<xf:label>X</xf:label>
				<xf:delete nodeset="." at="1" if="count(//.) &gt; 1" ev:event="DOMActivate"/>
			</xf:trigger>
			-->
			<xf:output value="../../@type"> 
				<xf:label>Typ</xf:label>
			</xf:output>
			<br/>
			<xf:input ref="@date">
				<xf:label>Datum:</xf:label>
			</xf:input>
			<br/>
			<xf:select1 ref="@credit" selection="closed" appearance="minimal" incremental="true">
				<xf:label>Soll:</xf:label>
				<xf:itemset nodeset="instance('accounts')/Account">
					<xf:label ref="Name"/>
					<xf:value ref="@kto"/>
				</xf:itemset>
			</xf:select1>
			<span> #</span>
			<xf:select1 ref="@credit" selection="closed" appearance="minimal" incremental="true">
				<xf:itemset nodeset="instance('accounts')/Account">
					<xf:label ref="@kto"/>
					<xf:value ref="@kto"/>
				</xf:itemset>
			</xf:select1>
			<br/>
			<xf:select1 ref="@debit" selection="closed" appearance="minimal" incremental="true">
				<xf:label>Haben:</xf:label>
				<xf:itemset nodeset="instance('accounts')/Account">
					<xf:label ref="Name"/>
					<xf:value ref="@kto"/>
				</xf:itemset>
			</xf:select1>
			<span> #</span>
			<xf:select1 ref="@debit" selection="closed" appearance="minimal" incremental="true">
				<xf:itemset nodeset="instance('accounts')/Account">
					<xf:label ref="@kto"/>
					<xf:value ref="@kto"/>
				</xf:itemset>
			</xf:select1>
			<br/>
			<xf:input ref="@amountValue">
				<xf:label>Betrag:</xf:label>
			</xf:input>
			<span> EUR</span>
			<br/>
			<xf:select1 ref="@taxKey">
				<xf:label>Umsatzsteuer:</xf:label>
				<xf:item>
					<xf:label>Unbekannt</xf:label>
					<xf:value>X</xf:value>
				</xf:item>
				<xf:item>
					<xf:label>Umsatzst. Automatik</xf:label>
					<xf:value>-</xf:value>
				</xf:item>
				<xf:item>
					<xf:label>0% Umsatzst. frei (Inland)</xf:label>
					<xf:value>1</xf:value>
				</xf:item>
				<xf:item>
					<xf:label>7% Umsatzst. (Inland)</xf:label>
					<xf:value>2</xf:value>
				</xf:item>
				<xf:item>
					<xf:label>19% Umsatzst. (Inland)</xf:label>
					<xf:value>3</xf:value>
				</xf:item>
				<xf:item>
					<xf:label>7% Vorsteuer (Inland)</xf:label>
					<xf:value>8</xf:value>
				</xf:item>
				<xf:item>
					<xf:label>19% Vorsteuer (Inland)</xf:label>
					<xf:value>9</xf:value>
				</xf:item>

				<xf:item>
					<xf:label>0% Vorsteuer (Inland STORNO)</xf:label>
					<xf:value>20</xf:value>
				</xf:item>
				<xf:item>
					<xf:label>7% Vorsteuer (Inland STORNO)</xf:label>
					<xf:value>27</xf:value>
				</xf:item>
				<xf:item>
					<xf:label>19% Vorsteuer (Inland STORNO)</xf:label>
					<xf:value>29</xf:value>
				</xf:item>

				<xf:item>
					<xf:label>Steuerplicht in anderem Land (EU)</xf:label>
					<xf:value>10</xf:value>
				</xf:item>
				<xf:item>
					<xf:label>Umst. frei (mit Vorsteuerabzug) (EU)</xf:label>
					<xf:value>11</xf:value>
				</xf:item>
				<xf:item>
					<xf:label>7% Umsatzst. (EU)</xf:label>
					<xf:value>18</xf:value>
				</xf:item>
				<xf:item>
					<xf:label>19% Umsatzst. (EU)</xf:label>
					<xf:value>19</xf:value>
				</xf:item>
				<xf:item>
					<xf:label>7% UmSt. EU Reverse-Charge gemä0 §13b</xf:label>
					<xf:value>92</xf:value>
				</xf:item>
				<xf:item>
					<xf:label>19% UmSt. EU Reverse-Charge gemäß §13b</xf:label>
					<xf:value>94</xf:value>
				</xf:item>

				<xf:item>
					<xf:label>Steuerplicht in anderem Land (EU STORNO)</xf:label>
					<xf:value>60</xf:value>
				</xf:item>
				<xf:item>
					<xf:label>Umst. frei (mit Vorsteuerabzug) (EU STORNO)</xf:label>
					<xf:value>61</xf:value>
				</xf:item>
				<xf:item>
					<xf:label>7% UmSt. EU (STORNO)</xf:label>
					<xf:value>68</xf:value>
				</xf:item>
				<xf:item>
					<xf:label>19% UmSt. EU (STORNO)</xf:label>
					<xf:value>69</xf:value>
				</xf:item>
				<!--
				<xf:item>
					<xf:label>7% UmSt. EU Reverse-Charge gemäß §13b (STORNO)</xf:label>
					<xf:value>X</xf:value>
				</xf:item>
				<xf:item>
					<xf:label>19% UmSt. EU Reverse-Charge gemäß §13b (STORNO)</xf:label>
					<xf:value>X</xf:value>
				</xf:item>
				-->
			</xf:select1>
			<span> # </span>
			<xf:output ref="@taxKey"/>
			<span> (</span>
			<xf:output ref="@taxAmount"/>
			<span> EUR</span>
			<span>)</span>
			<br/>
			<xf:input ref="@refID" class="DoubleInputSize">
				<xf:label>Beleg Nummer:</xf:label>
				<xf:help>Wenn es keine Belegnummer gibt, einfach # eintragen</xf:help>
			</xf:input>
			<br/>
			<xf:textarea ref="@description" class="DoubleInputSize">
				<xf:label>Beleg Inhalt:</xf:label>
			</xf:textarea>
		</dev>

	</xsl:template>
	
</xsl:stylesheet>