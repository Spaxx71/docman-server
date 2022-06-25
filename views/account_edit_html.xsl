<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="home-views"/> 
	<xsl:param name="home-data"/>                
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="year" required="yes"/>
	<xsl:param name="resource-id" required="yes"/>

	<xsl:variable name="accountings" select="result/Accountings"/>


	<xsl:template match="/">
	<html xmlns="http://www.w3.org/1999/xhtml" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:xf="http://www.w3.org/2002/xforms">
		<head>
			<title>Edit document</title>
			<xf:model schema="" id="M">
				<xf:instance xmlns="" id="account">
					<xsl:choose>
						<xsl:when test="lower-case($resource-id) = 'new'">
							<Account id="New" kto="0000" iban="" type="nominal_account" classes="creditor" debtee="">
								<Name>New</Name>
								<Notes/>
								<Service>Service Beschreibung / Art der Produkte</Service>
								<Company>
									<Name/>
								</Company>
								<Person>
									<Vorname/>
									<Nachname/>
								</Person>
								<Contact>
									<Vorname/>
									<Nachname/>
									<Email/>
									<Website/>
									<Telefon/>
								</Contact>								
								<CustomerID/>
								<ProcessTemplates>
									<!-- <ProcessTemplate/> -->
								</ProcessTemplates>
								<PeriodicPayments/>
								<Accounting openingBalance="0" closingBalance="0" debitSum="0" creditSum="0"/>
							</Account>
						</xsl:when>
						<xsl:otherwise>
							<!-- 
							<xsl:attribute name="src">
								<xsl:value-of select="concat($home-web-api,'/',$tenant,'/',$year,'/accounts/',$resource-id)"/>
							</xsl:attribute>
							-->
							<xsl:copy-of select="result/Account"/>
						</xsl:otherwise>
					</xsl:choose>
					<!-- <xf:resource value="concat('{$home-web-api}','/','{$tenant}','/',$year,'/accounts/','{$resource-id}')"/> -->
				</xf:instance>

				<xf:instance xmlns="" id="accounts" src="{concat($home-web-api,'/',$tenant,'/',$year,'/accounts')}">
					<!-- <xf:resource value="concat('{$home-web-api}','/','{$tenant}','/',$year,'/accounts')"/> -->
				</xf:instance>

				<xf:instance xmlns="" id="processtemplate-new">
					<data>
						<ProcessTemplate>
							<Section/>
							<Other kto=""/>
							<RefID/>
							<TransactionID/>
							<Description/>
							<Tax key="" region="" type=""/>
							<TotalAmount value="" unit=""/>
							<Appointment date=""/>
							<Notes/>
						</ProcessTemplate>
					</data>
				</xf:instance>

				<xf:instance xmlns="" id="periodicpayment-new">
					<data>
						<PeriodicPayment>
							<Name>Neue monatliche Zahlung</Name>
							<Period interval="" min="1" max="1" valid-from="" valid-till=""/>
							<DocumentTemplate>
								<Section/>
								<Other kto=""/>
								<RefID/>
								<TransactionID/>
								<TotalAmount value="-0.00" unit="EUR"/>
								<Tax key="undefined" region="inland" type="GOODS"/>
								<Description/>
							</DocumentTemplate>				
							<PaymentOptions>
								<PaymentOption type="BankTransfer" kto="1234567">
									<IBAN/>
									<PaymentDetail>Dieser Text muss im Verwendungszweck stehen</PaymentDetail>
								</PaymentOption> 
							</PaymentOptions>
							<Notes/>
						</PeriodicPayment>
					</data>
				</xf:instance>

				<!-- needs to be in sync with enter_invoice-in -->
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

				<xf:bind ref="instance('account')">
					<xf:bind ref="@id" type="xs:ID" constraint="lower-case(.) != 'new'" readonly="lower-case(.)!='new'"/>
					<xf:bind ref="@kto" type="xs:string" required="true()" constraint="number(.) &gt; 0 and ((../@type='nominal_account' and string-length(.)=4) or (../@type='ledger_account') and string-length(.)=5)"/> 
					<xf:bind ref="@type" type="xs:string" required="true()"/>
					<xf:bind ref="@classes" type="xs:string" required="true()"/>
					<xf:bind ref="Name" type="xs:string" required="true()" relevance="../@type='ledger_account'"/>
					<xf:bind ref="CustomerID" type="xs:string" relevance="../@type='ledger_account'"/>
					<xf:bind ref="Service" type="xs:string" relevance="../@type='ledger_account'"/>
					<xf:bind ref="Company" relevance="../@type='ledger_account'"/>
					<xf:bind ref="Person" relevance="../@type='ledger_account'"/>
					<xf:bind ref="ProcessTemplates" relevance="../@type='ledger_account'"/>

					<xf:bind ref="@iban" type="xs:string" relevance="../@type='ledger_account'"/>
					<xf:bind ref="@debtee" type="xs:string" relevance="../@type='ledger_account'"/>
				</xf:bind>

				<xf:bind ref="instance('account')/Accounting">
					<xf:bind ref="@openingBalance" type="xs:decimal" required="true()"/>
					<xf:bind ref="@closingBalance" type="xs:decimal" required="true()"/>
					<xf:bind ref="@creditSum" type="xs:decimal" readonly="true()" required="true()"/>
					<xf:bind ref="@debitSum" type="xs:decimal" readonly="true()" required="true()"/>
				</xf:bind>

				<!-- PeriodPayment -->
				<xf:bind ref="instance('account')/PeriodicPayments" relevance="../@type='ledger_account'">
					<xf:bind ref="PeriodicPayment/Period/@interval" required="true()" constraint=".='annually' or .='quarterly' or .='monthly'"/>
					<xf:bind ref="PeriodicPayment/Period/@min" type="xs:positiveInteger" required="true()"/>
					<xf:bind ref="PeriodicPayment/Period/@max" type="xs:positiveInteger" required="true()"/>

					<xf:bind ref="PeriodicPayment/Period/@valid-from" type="xs:date" required="false()"/>
					<xf:bind ref="PeriodicPayment/Period/@valid-till" type="xs:date" required="false()"/>

					<xf:bind ref="PeriodicPayment/DocumentTemplate/RefID" type="xs:string" required="true()" relevance="../@type='ledger_account'" constraint=".='#' or string-length(.) &gt; 5"/>
					<xf:bind ref="PeriodicPayment/DocumentTemplate/CustomerID" type="xs:string" relevance="../@type='ledger_account'" constraint=".='#' or string-length(.) &gt; 5"/>
					<xf:bind ref="PeriodicPayment/PaymentOptions/PaymentOption/@type" type="xs:string" relevance="../@type='ledger_account'" required="true()"/>
					<xf:bind ref="PeriodicPayment/PaymentOptions/PaymentOption/@kto" type="xs:string" relevance="../@type='ledger_account'" required="true()"/>
					<xf:bind ref="PeriodicPayment/PaymentOptions/PaymentOption/IBAN" type="xs:string" relevance="../@type='ledger_account'" required="true()"/>
					<xf:bind ref="PeriodicPayment/DocumentTemplate/TotalAmount/@value" type="xs:decimal" relevance="../@type='ledger_account'" required="true()"/>
					<xf:bind ref="PeriodicPayment/DocumentTemplate/TotalAmount/@unit" type="xs:string" relevance="../@type='ledger_account'" required="true()"/>
					<xf:bind ref="PeriodicPayment/DocumentTemplate/Other/@kto" type="xs:integer" relevance="../@type='ledger_account'" required="true()"/>
					<xf:bind ref="PeriodicPayment/DocumentTemplate/Description" type="xs:string" relevance="../@type='ledger_account'" required="true()" constraint="string-length(.) &gt; 5"/>
					<xf:bind ref="PeriodicPayment/DocumentTemplate/Tax/@key" type="xs:string" relevance="../@type='ledger_account'" required="true()" constraint="starts-with(.,'L-') or starts-with(.,'L+') or starts-with(.,'EU-') or starts-with(.,'EU+') or starts-with(.,'I-')"/> 
					<xf:bind ref="PeriodicPayment/DocumentTemplate/Tax/@region" type="xs:string" relevance="../@type='ledger_account'" required="true()"/>
					<xf:bind ref="PeriodicPayment/DocumentTemplate/Tax/@goods" type="xs:string" relevance="../@type='ledger_account'" required="true()"/>
				</xf:bind>
				
				<xf:submission id="save" method="put" instance="account" replace="none" validate="true"> <!-- indent="true"  replace="all" --> <!-- /{$year}/{$binder}/{$document} -->
					<xf:resource value="concat('{$home-web-api}/{$tenant}/',{$year},'/accounts/',instance('account')/@id)"/>
	                		<xf:action ev:event="xforms-submit-done">
						<xf:message>Erfolgreich gespeichert.
							<xf:output value="event('resource-uri')">
								<xf:label>Resource URI: </xf:label>
							</xf:output>
							<xsl:text>
</xsl:text>
							<xf:output value="event('response-body')">
								<xf:label>Body: </xf:label>
							</xf:output>
						</xf:message>
					</xf:action>
					<xf:action ev:event="xforms-submit-error">
						<xf:message>Es ist ein Fehler aufgetreten: 
							<xsl:text>
</xsl:text>
							<xf:output value="event('error-type')">
								<xf:label>Error type: </xf:label>
							</xf:output>
							<xsl:text>
</xsl:text>
							<xf:output value="event('resource-uri')">
								<xf:label>
Resource URI: </xf:label>
							</xf:output>
							<xsl:text>
</xsl:text>
							<xf:output value="event('response-status-code')">
								<xf:label>
Status Code: </xf:label>
							</xf:output>
							<xsl:text>
</xsl:text>
							<xf:output value="event('response-reason-phrase')">
								<xf:label>
Reason: </xf:label>
							</xf:output>
							<xsl:text>
</xsl:text>
							<xf:output value="event('response-headers')">
								<xf:label>
Headers: </xf:label>
							</xf:output>
							<xsl:text>
</xsl:text>
							<xf:output value="event('response-body')">
								<xf:label>
Body: </xf:label>
							</xf:output>
						</xf:message>
					</xf:action>
				</xf:submission>
			</xf:model>

			<style>
<![CDATA[
				.xforms-label {
					width: inherit !important;
				}
]]>
			</style>
		</head>
		<body>
			<table>
				<tr>
					<th>ID</th>
					<td>
						<xf:input ref="instance('account')/@id"/>
					</td>
				</tr>
				<tr>
					<th>Kurzname</th>
					<td>
						<xf:input ref="instance('account')/Name"/>
					</td>
				</tr>
				<tr>
					<th>Inhaber / Eigentümer</th>
					<td>
						<div id="horiz-tab-menu">
							<xf:trigger id="tab-company" appearance="minimal">
								<xf:label>Juristische Person</xf:label>
								<xf:toggle case="case-company" ev:event="DOMActivate"/>
							</xf:trigger>
							<xf:trigger id="tab-person" appearance="minimal">
								<xf:label>Natürliche Person</xf:label>
								<xf:toggle case="case-person" ev:event="DOMActivate"/>
							</xf:trigger>
							<xf:trigger id="tab-other" appearance="minimal">
								<xf:label>Sonstige</xf:label>
								<xf:toggle case="case-other" ev:event="DOMActivate"/>
							</xf:trigger>
						</div>					
						<xf:switch>
							<xf:case id="case-company" selected="true">
								<xf:label>Firma</xf:label>
								<xf:input ref="instance('account')/Company/Name">
									<xf:label>Firmenname:</xf:label>
								</xf:input>
							</xf:case>
							<xf:case id="case-person">
								<xf:label>Person</xf:label>
								<xf:input ref="instance('account')/Person/Vorname">
									<xf:label>Vorname:</xf:label>
								</xf:input>
								<xf:input ref="instance('account')/Person/Nachname">
									<xf:label>Nachname:</xf:label>
								</xf:input>
							</xf:case>
							<xf:case id="case-other">
								<xf:input ref="instance('account')/Name">
									<xf:label>Name:</xf:label>
								</xf:input>
							</xf:case>
						</xf:switch>
					</td>
				</tr>
				<tr>
					<th>Kontaktdaten</th>
					<td>
							<xf:input ref="instance('account')/Contact/Vorname">
								<xf:label>Vorname:</xf:label>
							</xf:input>
							<br/>
							<xf:input ref="instance('account')/Contact/Nachname">
								<xf:label>Nachname:</xf:label>
							</xf:input>
							<br/>
							<xf:input ref="instance('account')/Contact/Email">
								<xf:label>E-Mail:</xf:label>
							</xf:input>
							<br/>
							<xf:input ref="instance('account')/Contact/Website">
								<xf:label>Webseite:</xf:label>
							</xf:input>
							<br/>
							<xf:input ref="instance('account')/Contact/Telefon">
								<xf:label>Telefon:</xf:label>
							</xf:input>
					</td>
				</tr>
				<tr>
					<th>Leistung / Service</th>
					<td>
						<xf:input ref="instance('account')/Service"/>
					</td>
				</tr>
				<tr>
					<th>Kundennummer</th>
					<td>
						<xf:input ref="instance('account')/CustomerID"/>
					</td>
				</tr>
				<tr>
					<th>Notizen</th>
					<td>
						<xf:textarea ref="instance('account')/Notes"/>
					</td>
				</tr>
				<tr>
					<th>Konto Nr.</th>
					<td>
						<xf:input ref="instance('account')/@kto">
							<xf:hint>Buchungskonto</xf:hint>
						</xf:input>
						<br/>
						<a href="https://www.datev.de/dnlexom/v2/content/files/st2111766667.pdf" target="_blank">Datev SKR04 Kontorahmen 2020</a>
						<br/>
						<a href="https://www.buchungssatz.de/rahmen/skr04/6.html" target="_blank">Buchhungssatz.de</a>
					</td>
				</tr>
				<tr>
					<th>Konto Art</th>
					<td>
						<xf:select1 ref="instance('account')/@type">
							<xf:item>
								<xf:label>Sachkonto</xf:label>
								<xf:value>nominal_account</xf:value> 
							</xf:item>
							<xf:item>
								<xf:label>Personenkonto</xf:label>
								<xf:value>ledger_account</xf:value> 
							</xf:item>
						</xf:select1>
					</td>
				</tr>
				<tr>
					<th>Konto Klassen</th>
					<td>
<!--
						<xf:select1 ref="instance('account')/@classes[../@type='nominal_account']">
							<xf:item>
								<xf:label>Aktivkonto</xf:label>
								<xf:value>aktivkonto</xf:value> 
							</xf:item>
							<xf:item>
								<xf:label>Passivkonto</xf:label>
								<xf:value>passivkonto</xf:value> 
							</xf:item>
							<xf:item>
								<xf:label>Ertragskonto</xf:label>
								<xf:value>ertragskonto</xf:value> 
							</xf:item>
							<xf:item>
								<xf:label>Auswandskonto</xf:label>
								<xf:value>aufwandskonto</xf:value> 
							</xf:item>
							<xf:item>
								<xf:label>Weitere Erträge und Aufwendungen</xf:label>
								<xf:value>weitere</xf:value> 
							</xf:item>
							<xf:item>
								<xf:label>Statistikkonto</xf:label>
								<xf:value>statatistikkonto</xf:value> 
							</xf:item>
						</xf:select1>
-->

						<xf:select1 ref="instance('account')/@classes[../@type='nominal_account']" selection="closed" appearance="full" incremental="true">
							<xf:item>
								<xf:label>Halter</xf:label>
								<xf:value>Owner</xf:value> 
							</xf:item>
							<xf:item>
								<xf:label>Bank</xf:label>
								<xf:value>bank</xf:value> 
							</xf:item>
							<xf:item>
								<xf:label>Aktiva-Konto</xf:label>
								<xf:value>essets</xf:value> 
							</xf:item>
							<xf:item>
								<xf:label>Passiva-Konto</xf:label>
								<xf:value>liabilities</xf:value> 
							</xf:item>
							<xf:item>
								<xf:label>Ertrags-Konto</xf:label>
								<xf:value>revenues</xf:value> 
							</xf:item>
							<xf:item>
								<xf:label>Aufwands-Konto</xf:label>
								<xf:value>expenses</xf:value> 
							</xf:item>
						</xf:select1>

						<xf:select1 ref="instance('account')/@classes[../@type='ledger_account']">
							<xf:item>
								<xf:label>Debitor</xf:label>
								<xf:value>debitor</xf:value> 
							</xf:item>
							<xf:item>
								<xf:label>Kreditor</xf:label>
								<xf:value>creditor</xf:value> 
							</xf:item>
						</xf:select1>
					</td>
				</tr>

				<tr>
					<th>Buchhaltung</th>
					<td>
						<xf:input ref="Accounting/@openingBalance">
							<xf:label>Anfangsbestand:</xf:label>
						</xf:input>
						<br/>
						<xf:input ref="Accounting/@closingBalance">
							<xf:label>Schlussbestand:</xf:label>
						</xf:input>
						<br/>
						<xf:input ref="Accounting/@creditSum">
							<xf:label>SOLL Stand:</xf:label>
						</xf:input>
						<br/>
						<xf:input ref="Accounting/@debitSum">
							<xf:label>HABEN Stand:</xf:label>
						</xf:input>
					</td>
				</tr>

				<tr>
					<th>Buchungsvorlagen</th>
					<td>
						<xf:repeat id="ProcessTemplates" nodeset="instance('account')/ProcessTemplates/ProcessTemplate" appearance="full">
							<div style="border:1px solid #999">
								<xf:select1 ref="Other/@kto">
									<xf:label>Gegenkonto:</xf:label>
									<xf:itemset nodeset="instance('accounts')/Account[@type != instance('account')/@type]"> <!-- [@classes='creditor'] -->
										<xf:label ref="Name"/>
										<xf:value ref="@kto"/>
									</xf:itemset>
								</xf:select1>
								<xsl:text> #</xsl:text>
								<xf:select1 ref="Other/@kto">
									<xf:itemset nodeset="instance('accounts')/Account[@type != instance('account')/@type]"> <!-- [@classes='creditor'] -->
										<xf:label ref="@kto"/>
										<xf:value ref="@kto"/>
									</xf:itemset>
								</xf:select1>								
								<br/>
								<xf:input ref="RefID">
									<xf:label>Belegnummer:</xf:label>
									<xf:hint>In der Regel die Rechnungsnummer</xf:hint>
									<xf:help>Falls keine Nummer bekannt ist, einfach # verweden</xf:help>
								</xf:input>								
								<br/>
								<xf:input ref="TransactionID">
									<xf:label>Vorgangsnummer:</xf:label>
									<xf:hint>In der Regel die Bestellnummer</xf:hint>
								</xf:input>								
								<br/>								
								<xf:input ref="TotalAmount/@value">
									<xf:label>Gesamtbetrag:</xf:label>
								</xf:input>
								<xsl:text> </xsl:text>
								<xf:select1 ref="TotalAmount/@unit">
									<xf:item>
										<xf:label>EUR</xf:label>
										<xf:value>EUR</xf:value> 
									</xf:item>
									<xf:item>
										<xf:label>CHF</xf:label>
										<xf:value>CHF</xf:value> 
									</xf:item>
									<xf:item>
										<xf:label>USD</xf:label>
										<xf:value>USD</xf:value> 
									</xf:item>
								</xf:select1>
								<br/>

							
								<xf:select1 ref="Tax/@region">
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

								<xf:select1 ref="Tax/@key" selection="closed">
									<xf:itemset nodeset="instance('taxes')/item[@region=instance('account')/ProcessTemplates/ProcessTemplate[index('ProcessTemplates')]/Tax/@region]">
										<xf:label ref="@name"/>
										<xf:value ref="@value"/>
									</xf:itemset>

									<xf:help>Reverse Charge ist eine Verschiebung der Steuerschuld zum Leistungsempfänger.</xf:help>
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
								<xf:input ref="Description">
									<xf:label>Beleg Inhalt:</xf:label>
								</xf:input>

								<xf:trigger>
									<xf:label>X</xf:label>
									<xf:delete nodeset="." at="1" if="count(//.) &gt; 1" ev:event="DOMActivate"/>
								</xf:trigger>
							</div>
						</xf:repeat>

						<xf:trigger>
							<xf:label>Vorlage hinzufügen</xf:label>
						
							<xf:insert context="instance('account')/ProcessTemplates" origin="instance('processtemplate-new')/ProcessTemplate" nodeset="ProcessTemplate" ev:event="DOMActivate"/>
						</xf:trigger>
					</td>
				</tr>

				<tr>
					<th>Bankverbindung(en)</th>
					<td>
						<xf:group ref="instance('account')/@type[.='ledger_account']">
							<xf:input ref="instance('account')/@iban">
								<xf:label>Kontonummer (IBAN)</xf:label>
								<xf:hint>Es können mehr als eine IBAN aufgelistet werden, dann sind diese mit einem Leerzeichen zu separieren.</xf:hint>
							</xf:input>
							<br/>
							<xf:input ref="instance('account')/@debtee">
								<xf:label>SEPA Einzug – Gläubiger ID</xf:label>
							</xf:input>
						</xf:group>
						<xf:group ref="instance('account')/@type[.!='ledger_account']">
							<span>nur bei Personenkonten</span>
						</xf:group>

					</td>
				</tr>
				<tr>
					<th>Regelmäßige Zahlungen / Wiederkehrende Posten</th>
					<td>
						<xf:repeat id="PeriodicPayments" nodeset="instance('account')/PeriodicPayments/PeriodicPayment" appearance="full">
							<div style="border:1px solid #999">
								<xf:input ref="Name">
									<xf:label>Name</xf:label>
									<xf:hint>Eine kurze Bezeichnung für diese Postition</xf:hint>
								</xf:input>
								<br/>

								<xf:select1 ref="Period/@interval">
									<xf:label>Zahlungs-Interval:</xf:label>
									<xf:item>
										<xf:label>jährlich</xf:label>
										<xf:value>annually</xf:value>
									</xf:item>
									<xf:item>
										<xf:label>quartalsweise</xf:label>
										<xf:value>quarterly</xf:value>
									</xf:item>
									<xf:item>
										<xf:label>monatlich</xf:label>
										<xf:value>monthly</xf:value>
									</xf:item>
								</xf:select1>
								<xf:input ref="Period/@min">
									<xf:label>Min:</xf:label>
								</xf:input>
								<xf:input ref="Period/@max">
									<xf:label>Max:</xf:label>
								</xf:input>
								<br/>

								<xf:input ref="Period/@valid-from">
									<xf:label>Gültig von:</xf:label>
								</xf:input>

								<xf:input ref="Period/@valid-till">
									<xf:label>bis:</xf:label>
								</xf:input>
								<br/>

								<xf:select1 ref="PaymentOptions/PaymentOption/@type">
									<xf:label>Art der Zahlung:</xf:label>
									<xf:item>
										<xf:label>Überweisung</xf:label>
										<xf:value>BankTransfer</xf:value>
									</xf:item>
									<xf:item>
										<xf:label>Bankeinzug</xf:label>
										<xf:value>DirectDebit</xf:value>
									</xf:item>
								</xf:select1>
								<br/>

								<xf:select1 ref="PaymentOptions/PaymentOption/@kto">
									<xf:label>Bankverbindung:</xf:label>
									<xf:item>
										<xf:label>Deuba 00</xf:label>
										<xf:value>222971400</xf:value>
									</xf:item>
									<xf:item>
										<xf:label>Deuba 01</xf:label>
										<xf:value>222971401</xf:value>
									</xf:item>
								</xf:select1>
								<br/>

								<xf:input ref="PaymentOptions/PaymentOption/IBAN">
									<xf:label>IBAN des Empfänger:</xf:label>
								</xf:input>
								<br/>

								<xf:textarea ref="PaymentOptions/PaymentOption/PaymentDetail">
									<xf:label>Suche Verwendungszweck:</xf:label>
									<xf:hint>Dieser Text / RegEx muss im Verwendungszweck enthalten sein / matchen.</xf:hint>
								</xf:textarea>
								<xf:select1 ref="PaymentOptions/PaymentOption/PaymentDetail/@type">
									<xf:label>Suchart:</xf:label>
									<xf:item>
										<xf:label>Textsuche</xf:label>
										<xf:value>TEXT</xf:value>
									</xf:item>
									<xf:item>
										<xf:label>RegEx</xf:label>
										<xf:value>REGEX</xf:value>
									</xf:item>
								</xf:select1>
								<br/>

								<xf:select1 ref="DocumentTemplate/Other/@kto">
									<xf:label>Gegenkonto:</xf:label>
									<xf:itemset nodeset="instance('accounts')/Account[@type != instance('account')/@type]"> <!-- [@classes='creditor'] -->
										<xf:label ref="Name"/>
										<xf:value ref="@kto"/>
									</xf:itemset>
								</xf:select1>
								<xsl:text> #</xsl:text>
								<xf:select1 ref="DocumentTemplate/Other/@kto">
									<xf:itemset nodeset="instance('accounts')/Account[@type != instance('account')/@type]"> <!-- [@classes='creditor'] -->
										<xf:label ref="@kto"/>
										<xf:value ref="@kto"/>
									</xf:itemset>
								</xf:select1>
								<br/>
								<xf:input ref="DocumentTemplate/RefID">
									<xf:label>Belegnummer:</xf:label>
									<xf:hint>In der Regel die Rechnungsnummer</xf:hint>
								</xf:input>								
								<br/>
								<xf:input ref="DocumentTemplate/TransactionID">
									<xf:label>Vorgangsnummer:</xf:label>
									<xf:hint>In der Regel die Bestellnummer</xf:hint>
								</xf:input>								
								<br/>								
								<xf:input ref="DocumentTemplate/TotalAmount/@value">
									<xf:label>Gesamtbetrag:</xf:label>
								</xf:input>
								<xsl:text> </xsl:text>
								<xf:select1 ref="DocumentTemplate/TotalAmount/@unit">
									<xf:item>
										<xf:label>EUR</xf:label>
										<xf:value>EUR</xf:value> 
									</xf:item>
									<xf:item>
										<xf:label>CHF</xf:label>
										<xf:value>CHF</xf:value> 
									</xf:item>
									<xf:item>
										<xf:label>USD</xf:label>
										<xf:value>USD</xf:value> 
									</xf:item>
								</xf:select1>
								<br/>

								<xf:select1 ref="DocumentTemplate/Tax/@region">
									<xf:item>
										<xf:label>Inlandsgeschäft</xf:label>
										<xf:value>inland</xf:value> 
									</xf:item>
									<xf:hint>Derzeit werden nur Inlandsgeschäfte für die automatische Belegerstellung unterstützt</xf:hint>
								</xf:select1>

								<xf:select1 ref="DocumentTemplate/Tax/@key" selection="closed">
									<xf:itemset nodeset="instance('taxes')/item[@region='inland']">
										<xf:label ref="@name"/>
										<xf:value ref="@value"/>
									</xf:itemset>

									<xf:help>Reverse Charge ist eine Verschiebung der Steuerschuld zum Leistungsempfänger.</xf:help>
								</xf:select1>					

								<xf:select1 ref="DocumentTemplate/Tax/@type">
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
								<xf:input ref="DocumentTemplate/Description">
									<xf:label>Beleg Inhalt:</xf:label>
								</xf:input>

								<xf:trigger>
									<xf:label>X</xf:label>
									<xf:delete nodeset="." at="1" if="count(//.) &gt; 1" ev:event="DOMActivate"/>
								</xf:trigger>
							</div>
						</xf:repeat>

						<xf:trigger>
							<xf:label>Regelmäßige Zahlung hinzufügen</xf:label>
						
							<xf:insert context="instance('account')/PeriodicPayments" origin="instance('periodicpayment-new')/PeriodicPayment" nodeset="PeriodicPayment" ev:event="DOMActivate"/>
						</xf:trigger>
					</td>
				</tr>
				<tr>
					<td colspan="2" style="text-align:right">
						<xf:submit submission="save" id="Save">
		       					<xf:label>Speichern</xf:label>
		       				</xf:submit>
					</td>
				</tr>
			</table>
		</body>
	</html>
	</xsl:template>

	<xsl:template match="Accounts"/>

	<xsl:template match="Account"/>

</xsl:stylesheet>