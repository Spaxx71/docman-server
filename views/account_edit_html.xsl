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
	<xhtml:html xmlns="http://www.w3.org/1999/xhtml" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:xhtml="http://www.w3.org/1999/xhtml">
		<head>
			<title>Edit document</title>
			<xf:model schema="" id="M">
				<xf:instance xmlns="" id="account">
					<xsl:choose>
						<xsl:when test="lower-case($resource-id) = 'new'">
							<Account id="NewId" kto="0000" type="ledger_account" classes="creditor">
								<Name/>
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
								<BankAcconts/>
								<ProcessTemplates>
									<!-- <ProcessTemplate/> -->
								</ProcessTemplates>
								<PeriodicPayments/>
								<BudgetCategories/>
								<FieldHints/>
								<Accounting openingBalance="0" closingBalance="0" debitSum="0" creditSum="0"/>
							</Account>
						</xsl:when>
						<xsl:otherwise>
							<!-- 
							<xsl:attribute name="src">
								<xsl:value-of select="concat($home-web-api,'/tenants/',$tenant,'/years/',$year,'/accounts/',$resource-id)"/>
							</xsl:attribute>
							-->
							<xsl:copy-of select="result/Account"/>
						</xsl:otherwise>
					</xsl:choose>
					<!-- <xf:resource value="concat('{$home-web-api}','/tenants/','{$tenant}','/years/',$year,'/accounts/','{$resource-id}')"/> -->
				</xf:instance>

				<xf:instance xmlns="" id="accounts" src="{concat($home-web-api,'/tenants/',$tenant,'/years/',$year,'/accounts')}">
					<!-- <xf:resource value="concat('{$home-web-api}','/tenants/','{$tenant}','/years/',$year,'/accounts')"/> -->
				</xf:instance>

				<xf:instance xmlns="" id="budget-categories">
					<xsl:copy-of select="result/BudgetCategories"/>
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

				<xf:instance xmlns="" id="hint-new">
					<data>
						<FieldHints>
							<Hint field="invoiceNumber" label="" region="invoiceHeader" pattern=""/>
						</FieldHints>
					</data>
				</xf:instance>

				<xf:instance xmlns="" id="bankaccount-new">
					<data>
						<BankAccount name="" iban="" notes=""/>
					</data>
				</xf:instance>

				<xf:instance xmlns="" id="periodicpayment-new">
					<data>
						<PeriodicPayment>
							<Name>Neue monatliche Zahlung</Name>
							<Period interval="" min="1" max="1" valid-from="{current-date()}" valid-till="{concat(year-from-date(current-date()) + 100, '-12-31')}"/>
							<DocumentTemplate>
								<Section/>
								<Other kto=""/>
								<RefID/>
								<TransactionID/>
								<TotalAmount value="-0.00" unit="EUR"/>
								<Tax key="undefined" region="inland" type="GOODS"/>
								<Description/>
							</DocumentTemplate>
							<PaymentRules>
								<PaymentRule type=""/>
							</PaymentRules>
							<!--
							<PaymentOptions>
								<PaymentOption type="BankTransfer" kto="1234567">
									<IBAN/>
									<PaymentDetail>Dieser Text muss im Verwendungszweck stehen</PaymentDetail>
								</PaymentOption> 
							</PaymentOptions>
							-->
							<InitialContract/> <!-- Rahmenvertrag -->
							<PeriodInvoice required="true()"/>
							<Notes/>
						</PeriodicPayment>
					</data>
				</xf:instance>

				<xf:instance xmlns="" id="budgetcategory-new">
					<data>
						<BudgetCategory id="">
							<Period valid-from="{current-date()}" valid-till="{concat(year-from-date(current-date()) + 100, '-12-31')}"/>
							<PaymentRules>
								<PaymentRule type=""/>
							</PaymentRules>
							<Notes/>
						</BudgetCategory>
					</data>
				</xf:instance>
				
				<xf:instance xmlns="" id="paymentrule-new">
					<data>
						<PaymentRule type=""/>
					</data>
				</xf:instance>

				<xf:instance xmlns="" id="accountMapping">
					<data>
						<mapping>
							<accountName>A</accountName>
							<accountRange>70001 - 70099</accountRange>
						</mapping>
						<mapping>
							<accountName>B</accountName>
							<accountRange>70101 - 70199</accountRange>
						</mapping>
						<mapping>
							<accountName>C</accountName>
							<accountRange>70201 - 70299</accountRange>
						</mapping>
						<mapping>
							<accountName>D</accountName>
							<accountRange>70301 - 70399</accountRange>
						</mapping>
						<mapping>
							<accountName>E</accountName>
							<accountRange>70401 - 70499</accountRange>
						</mapping>
						<mapping>
							<accountName>F</accountName>
							<accountRange>70501 - 70599</accountRange>
						</mapping>
						<mapping>
							<accountName>G</accountName>
							<accountRange>70601 - 70699</accountRange>
						</mapping>
						<mapping>
							<accountName>H</accountName>
							<accountRange>70701 - 70799</accountRange>
						</mapping>
						<mapping>
							<accountName>I</accountName>
							<accountRange>70801 - 70899</accountRange>
						</mapping>
						<mapping>
							<accountName>J</accountName>
							<accountRange>70901 - 70999</accountRange>
						</mapping>
						<mapping>
							<accountName>K</accountName>
							<accountRange>71001 - 71099</accountRange>
						</mapping>
						<mapping>
							<accountName>L</accountName>
							<accountRange>71101 - 71199</accountRange>
						</mapping>
						<mapping>
							<accountName>M</accountName>
							<accountRange>71201 - 71299</accountRange>
						</mapping>
						<mapping>
							<accountName>N</accountName>
							<accountRange>71301 - 71399</accountRange>
						</mapping>
						<mapping>
							<accountName>O</accountName>
							<accountRange>71401 - 71499</accountRange>
						</mapping>
						<mapping>
							<accountName>P</accountName>
							<accountRange>71501 - 71599</accountRange>
						</mapping>
						<mapping>
							<accountName>Q</accountName>
							<accountRange>71601 - 71699</accountRange>
						</mapping>
						<mapping>
							<accountName>R</accountName>
							<accountRange>71701 - 71799</accountRange>
						</mapping>
						<mapping>
							<accountName>S</accountName>
							<accountRange>71801 - 71899</accountRange>
						</mapping>
						<mapping>
							<accountName>T</accountName>
							<accountRange>71901 - 71999</accountRange>
						</mapping>
						<mapping>
							<accountName>U</accountName>
							<accountRange>72001 - 72099</accountRange>
						</mapping>
						<mapping>
							<accountName>V</accountName>
							<accountRange>72101 - 72199</accountRange>
						</mapping>
						<mapping>
							<accountName>W</accountName>
							<accountRange>72201 - 72299</accountRange>
						</mapping>
						<mapping>
							<accountName>X</accountName>
							<accountRange>72301 - 72399</accountRange>
						</mapping>
						<mapping>
							<accountName>Y</accountName>
							<accountRange>72401 - 72499</accountRange>
						</mapping>
						<mapping>
							<accountName>Z</accountName>
							<accountRange>72501 - 72599</accountRange>
						</mapping>
					</data>
				</xf:instance>

				<xf:instance xmlns="" id="validation">
					<data>
						<accountExists/>
						<accountFirstChar/>
						<accountRange/>
						<nextFreeNumber/>
					</data>
				</xf:instance>
				
				<xf:bind nodeset="instance('validation')/accountExists" calculate="boolean(instance('accounts')//Account[@kto = instance('account')/@kto])"/>
				<xf:bind nodeset="instance('validation')/accountFirstChar" calculate="upper-case(substring(instance('account')/Name,1,1))" constraint="string-length(instance('account')/Name) != 0"/>
				<xf:bind nodeset="instance('validation')/accountRange" calculate="instance('accountMapping')/mapping[accountName = instance('validation')/accountFirstChar]/accountRange" constraint="string-length(instance('account')/Name) != 0"/>
				<xf:bind nodeset="instance('validation')/nextFreeNumber" calculate="max(instance('accounts')/Account/@kto[. &gt; substring-before(instance('validation')/accountRange,'-') and . &lt; substring-after(instance('validation')/accountRange,'-')]) +1" constraint="string-length(instance('account')/Name) != 0"/>

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
					<xf:bind ref="@id" type="xs:ID" constraint="lower-case(.) != 'newid'" readonly="lower-case(.)!='newid'"/>
					<xf:bind ref="@kto" type="xs:string" required="true()" constraint="number(.) &gt; 0 and ((../@type='nominal_account' and string-length(.)=4) or (../@type='ledger_account') and string-length(.)=5)"/> 
					<xf:bind ref="@type" type="xs:string" required="true()"/>
					<xf:bind ref="@classes" type="xs:string" required="true()"/>
					<xf:bind ref="Name" type="xs:string" required="true()" relevance="../@type='ledger_account'"/>
					<xf:bind ref="CustomerID" type="xs:string" relevance="../@type='ledger_account'"/>
					<xf:bind ref="Service" type="xs:string" relevance="../@type='ledger_account'"/>
					<xf:bind ref="Company" relevance="../@type='ledger_account'"/>
					<xf:bind ref="Person" relevance="../@type='ledger_account'"/>
					<xf:bind ref="ProcessTemplates" relevance="../@type='ledger_account'"/>

					<xf:bind ref="BankAccounts/BankAccount/@iban" type="xs:string" required="true()" relevance="../@type='ledger_account'" constraint="string-length(.) &gt;= 15 and string-length(.) &lt;= 34" message="Die IBAN muss aus zwei Länder-Buchstaben, gefolgt von zwei Zahlen und insgeammt 15 bis 34 Zeichen bestehen."/>
					<xf:bind ref="BankAccounts/BankAccount/@name" type="xs:string" required="false()" relevance="../@type='ledger_account'"/>
					<xf:bind ref="BankAccounts/BankAccount/@notes" type="xs:string" required="false()" relevance="../@type='ledger_account'"/>
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

					<xf:bind ref="PeriodicPayment/Period/@valid-from" type="xs:date" required="true()"/>
					<xf:bind ref="PeriodicPayment/Period/@valid-till" type="xs:date" required="false()"/>

					<xf:bind ref="PeriodicPayment/DocumentTemplate/RefID" type="xs:string" required="true()" relevance="../@type='ledger_account'" constraint=".='#' or string-length(.) &gt; 5"/>
					<xf:bind ref="PeriodicPayment/DocumentTemplate/CustomerID" type="xs:string" relevance="../@type='ledger_account'" constraint=".='#' or string-length(.) &gt; 5"/>
					<xf:bind ref="PeriodicPayment/PaymentOptions/PaymentOption/@type" type="xs:string" relevance="../@type='ledger_account'" required="true()"/>
					<xf:bind ref="PeriodicPayment/PaymentOptions/PaymentOption/@kto" type="xs:string" relevance="../@type='ledger_account'" required="true()"/>
					<xf:bind ref="PeriodicPayment/PaymentOptions/PaymentOption/IBAN" type="xs:string" relevance="../@type='ledger_account'" required="true()" constraint="string-length(.) &gt;= 15 and string-length(.) &lt;= 34" message="Die IBAN muss aus zwei Länder-Buchstaben, gefolgt von zwei Zahlen und insgeammt 15 bis 34 Zeichen bestehen."/>
					<xf:bind ref="PeriodicPayment/DocumentTemplate/TotalAmount/@value" type="xs:decimal" relevance="../@type='ledger_account'" required="true()"/>
					<xf:bind ref="PeriodicPayment/DocumentTemplate/TotalAmount/@unit" type="xs:string" relevance="../@type='ledger_account'" required="true()"/>
					<xf:bind ref="PeriodicPayment/DocumentTemplate/Other/@kto" type="xs:integer" relevance="../@type='ledger_account'" required="true()"/>
					<xf:bind ref="PeriodicPayment/DocumentTemplate/Description" type="xs:string" relevance="../@type='ledger_account'" required="true()" constraint="string-length(.) &gt; 5"/>
					<xf:bind ref="PeriodicPayment/DocumentTemplate/Tax/@key" type="xs:string" relevance="../@type='ledger_account'" required="true()" constraint="starts-with(.,'L-') or starts-with(.,'L+') or starts-with(.,'EU-') or starts-with(.,'EU+') or starts-with(.,'I-')"/> 
					<xf:bind ref="PeriodicPayment/DocumentTemplate/Tax/@region" type="xs:string" relevance="../@type='ledger_account'" required="true()"/>
					<xf:bind ref="PeriodicPayment/DocumentTemplate/Tax/@type" type="xs:string" relevance="../@type='ledger_account'" required="true()"/>
					<xf:bind ref="PeriodicPayment/PaymentRules/PaymentRule/@type" type="xs:string" required="true()"/>
					<xf:bind ref="PeriodicPayment/PaymentRules/PaymentRule" type="xs:string" required="true()"/>
					<xf:bind ref="PeriodicPayment/PaymentRules/PaymentRule" type="xs:string" required="true()" relevance=".[@type='SEPA_DIRECT-DEBIT_IBAN' or @type='SEPA_CREDIT-TRANSFER_IBAN']" constraint="string-length(.) &gt;= 15 and string-length(.) &lt;= 34" message="Die IBAN muss aus zwei Länder-Buchstaben, gefolgt von zwei Zahlen und insgeammt 15 bis 34 Zeichen bestehen."/>
				</xf:bind>

				<!-- BudgetCategories -->
				<xf:bind ref="instance('account')/BudgetCategories">
					<xf:bind ref="BudgetCategory/@id" type="xs:CDATA" required="true()"/>
					<xf:bind ref="BudgetCategory/Period/@valid-from" type="xs:date" required="true()"/>
					<xf:bind ref="BudgetCategory/Period/@valid-till" type="xs:date" required="false()"/>

					<xf:bind ref="BudgetCategory/PaymentRules/PaymentRule/@type" type="xs:string" required="true()"/>
					<xf:bind ref="BudgetCategory/PaymentRules/PaymentRule" type="xs:string" required="true()"/>
					<xf:bind ref="BudgetCategory/PaymentRules/PaymentRule" type="xs:string" required="true()" relevance=".[@type='SEPA_DIRECT-DEBIT_IBAN' or @type='SEPA_CREDIT-TRANSFER_IBAN']" constraint="string-length(.) &gt;= 15 and string-length(.) &lt;= 34" message="Die IBAN muss aus zwei Länder-Buchstaben, gefolgt von zwei Zahlen und insgeammt 15 bis 34 Zeichen bestehen."/>

				</xf:bind>
				
				<xf:submission id="save" method="put" instance="account" replace="none" validate="true"> <!-- indent="true"  replace="all" --> <!-- /{$year}/{$binder}/{$document} -->
					<xf:resource value="concat('{$home-web-api}/tenants/{$tenant}/years/{$year}/accounts/',instance('account')/@id)"/>
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
			<ul class="Nav">
				<li>
					<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/categories/index.html')}">Budget-Kategorien</a>
				</li>
			</ul>
			<table>
				<tr>
					<th>ID</th>
					<td>
						<xf:input ref="instance('account')/@id"/>
						<br/>
						Zulässige Zeichen sind: A-Z,a-z,0-9 und der _
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
						<xf:textarea ref="instance('account')/Notes" style="min-width:30em;min-height:5em;"/>
					</td>
				</tr>
				<tr>
					<th>Konto Nr.</th>
					<td>
						<xf:input ref="instance('account')/@kto">
							<xf:hint>Buchungskonto</xf:hint>
						</xf:input>
						<br/>
						<xf:group ref="instance('account')/Name[string-length(.) != 0]">
							<xf:output ref="instance('accounts')//Account[@kto = instance('account')/@kto]/Name">
								<xf:label>Account Exists!</xf:label>
							</xf:output>
							<br/>
							<xf:output value="instance('validation')/accountFirstChar">
								<xf:label>Gemäß Anfangsbuchstabe </xf:label> 
							</xf:output>
							<xsl:text> </xsl:text>
							<xf:output ref="instance('accountMapping')/mapping[accountName = upper-case(substring(instance('account')/Name,1,1))]/accountRange">
								<xf:label> zulässige Nummern: </xf:label>
							</xf:output>
							<br/>
							<xf:output value="instance('validation')/nextFreeNumber">
								<xf:label>Nächste freie Nummer: </xf:label> 
							</xf:output>
							<br/>
						</xf:group>

						<a href="https://www.datev.de/dnlexom/api/content/v01/entity/st26301494027_de.pdf?save=False&amp;docId=0907814" target="_blank">Datev SKR04 Kontorahmen 2023</a>
						<br/>
						<a href="https://www.buchungssatz.de/de/kontenrahmen/skr04.html" target="_blank">Buchhungssatz.de SKR04</a>
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
							<!--
							<xf:item>
								<xf:label>Info / Self</xf:label> 
								<xf:value>info</xf:value> 
							</xf:item>
							-->
						</xf:select1>
					</td>
				</tr>
				<tr>
					<th>Konto Klassen</th>
					<td>
						<xf:select ref="instance('account')/@classes[../@type='nominal_account']" selection="closed" appearance="full" incremental="true" multiple="true()">
							<!--
							<xf:item>
								<xf:label>Halter</xf:label>
								<xf:value>owner</xf:value> 
							</xf:item>
							-->
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
							<xf:item>
								<xf:label>Die eigene Firma</xf:label>
								<xf:value>self</xf:value> 
							</xf:item>
							<xf:action ev:event="xforms-select">
								<xf:setvalue ref="instance('account')/@classes" value="tokenize(., ' ')"/>
							  </xf:action>
						</xf:select>

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
					<th>Buchungsvorlagen</th>
					<td>
						<xf:repeat id="ProcessTemplates" nodeset="instance('account')/ProcessTemplates/ProcessTemplate" appearance="full">
							<div style="border:1px solid #999">
								<table style="width:100%">
									<tr>
										<td>
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

									</td>
									<th>
										<xf:trigger>
											<xf:label>X</xf:label>
											<xf:delete nodeset="." at="1" if="count(//.) &gt; 1" ev:event="DOMActivate"/>
										</xf:trigger>
									</th>
								</tr>
							</table>										
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
							<xf:repeat nodeset="instance('account')/BankAccounts/BankAccount">
								<table>
									<tr>
										<td>
											<xf:input ref="@name">
											<xf:label>Name der Bank</xf:label>
											</xf:input>
											<xf:input ref="@iban">
											<xf:label>Kontonummer (IBAN)</xf:label>
											<xf:hint>Die IBAN Nummer der Bank des Kreditors</xf:hint>
											</xf:input>
											<xf:input ref="@notes">
											<xf:label>Notizen</xf:label>
											</xf:input>
										</td>
										<th>
											<xf:trigger>
												<xf:label>X</xf:label>
												<xf:delete nodeset="." at="1" ev:event="DOMActivate"/>
											</xf:trigger>
										</th>
									</tr>
								</table>
							</xf:repeat>
							<xf:trigger>
								<xf:label>Bankverbindung hinzufügen</xf:label>
								<xf:action ev:event="DOMActivate">
									<xf:insert context="instance('account')/BankAccounts" origin="instance('bankaccount-new')/BankAccount" nodeset="BankAccount"/>
								</xf:action>
							</xf:trigger>				
						</xf:group>
						<xf:group ref="instance('account')/@type[.!='ledger_account']">
							<span>nur bei Personenkonten</span>
						</xf:group>

					</td>
				</tr>
				<tr>
					<th>Feldhinweise<br/><span style="font-size:80%">Bezeichner, Bereich, Muster</span></th>
					<td>
						<xf:group ref="instance('account')[contains(@classes,'creditor') or contains(@classes,'debitor') or @type='creditor' or @type='debitor']">
							<xf:repeat nodeset="FieldHints/Hint">
								<div>
									<xf:select1 ref="@field">
										<xf:label>Feld</xf:label>
										<xf:item><xf:label>Rechnungsnummer</xf:label><xf:value>invoiceNumber</xf:value></xf:item>
										<xf:item><xf:label>Rechnungsdatum</xf:label><xf:value>invoiceDate</xf:value></xf:item>
										<xf:item><xf:label>Leistungsdatum</xf:label><xf:value>serviceDate</xf:value></xf:item>
										<xf:item><xf:label>Fälligkeit</xf:label><xf:value>dueDate</xf:value></xf:item>
										<xf:item><xf:label>Zahlbetrag</xf:label><xf:value>payable</xf:value></xf:item>
										<xf:item><xf:label>Brutto</xf:label><xf:value>gross</xf:value></xf:item>
										<xf:item><xf:label>USt-IdNr.</xf:label><xf:value>vat</xf:value></xf:item>
										<xf:item><xf:label>IBAN</xf:label><xf:value>iban</xf:value></xf:item>
										<xf:item><xf:label>BIC</xf:label><xf:value>bic</xf:value></xf:item>
									</xf:select1>
									<xf:input ref="@label"><xf:label>Bezeichner</xf:label></xf:input>
									<xf:select1 ref="@region">
										<xf:label>Bereich</xf:label>
										<xf:item><xf:label>Rechnungskopf</xf:label><xf:value>invoiceHeader</xf:value></xf:item>
										<xf:item><xf:label>Summen</xf:label><xf:value>amounts</xf:value></xf:item>
										<xf:item><xf:label>Positionen</xf:label><xf:value>lines</xf:value></xf:item>
										<xf:item><xf:label>Zahlung</xf:label><xf:value>payment</xf:value></xf:item>
										<xf:item><xf:label>neben Rechnungsnummer</xf:label><xf:value>near:invoiceNumber</xf:value></xf:item>
									</xf:select1>
									<xf:input ref="@pattern"><xf:label>Regex</xf:label><xf:hint>Nur setzen, wenn das Format feststeht. Es wird nicht aus einer Nummer geraten.</xf:hint></xf:input>
									<xf:trigger>
										<xf:label>X</xf:label>
										<xf:delete nodeset="." ev:event="DOMActivate"/>
									</xf:trigger>
								</div>
							</xf:repeat>
							<xf:trigger>
								<xf:label>Feldhinweis hinzufügen</xf:label>
								<xf:action ev:event="DOMActivate">
									<xf:insert context="instance('account')" origin="instance('hint-new')/FieldHints" nodeset="FieldHints" if="not(FieldHints)"/>
									<xf:insert context="instance('account')/FieldHints" origin="instance('hint-new')/FieldHints/Hint" nodeset="Hint"/>
								</xf:action>
							</xf:trigger>
						</xf:group>
					</td>
				</tr>
				<tr>
					<th>
						Daueraufträge<br/>
						<span style="font-size:80%">Wiederkehrende Posten / Regelmäßige Position</span>
					</th>
					<td>
						<xf:repeat id="PeriodicPayments" nodeset="instance('account')/PeriodicPayments/PeriodicPayment" appearance="full">
							<div style="border:1px solid #999">
								<table style="width:100%">
									<tr>
										<th>Gültigkeit</th>
										<td>
											<xf:input ref="Period/@valid-from">
												<xf:label>Gültig von:</xf:label>
											</xf:input>

											<xf:input ref="Period/@valid-till">
												<xf:label>bis:</xf:label>
											</xf:input>
										</td>
										<th rowspan="5">
											<xf:trigger>
												<xf:label>X</xf:label>
												<xf:delete nodeset="." at="1" if="count(//.) &gt; 1" ev:event="DOMActivate"/>
											</xf:trigger>
										</th>										
									</tr>
									<tr>
										<th>
											Bezeichnung
										</th>
										<td>
											<xf:input ref="Name">
												<xf:label>Name:</xf:label>
												<xf:hint>Eine kurze Bezeichnung für diese Postition</xf:hint>
											</xf:input>
											<br/>
											<xf:textarea ref="Notes" style="min-width:30em;min-height:5em;">
												<xf:label>Notizen:</xf:label>
												<xf:hint>Hinweise und Notizen</xf:hint>
											</xf:textarea>
										</td>
									</tr>									
									<tr>
										<th>Zahlungsintervall</th>
										<td>
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
											<br/>
											<xf:label>Zulässige Anzahl von Zahlungen pro Intervall:</xf:label>
											<br/>
											<xf:input ref="Period/@min">
												<xf:label>min:</xf:label>
											</xf:input>
											<xf:input ref="Period/@max">
												<xf:label>max:</xf:label>
											</xf:input>
											<xf:input ref="Period/@max">
												<xf:label>max:</xf:label>
											</xf:input>
										</td>
									</tr>									
									<tr>
										<th>
											Regelset<br/>
											<span style="font-size:80%">(die erfüllt sein müssen, um die Dauerposition zu verbuchen)</span>
										</th>
										<td>
											<xf:repeat id="PaymentRulesTemplates" nodeset="PaymentRules/PaymentRule" appearance="full">
												<div style="border:1px solid #999">
													<table style="width:100%">
														<tr>
															<td>
																<!-- <xf:label value="concat('Regel #', position())" /> -->
																<xf:label>
																	<xf:output value="concat('Regel #', position(), ':')"/>
																</xf:label>
																
																<!-- Selection for Payment Type (@type) -->
																<xf:select1 ref="@type">
																	<xf:item>
																		<xf:label>SEPA Einzugsverfahren - IBAN</xf:label>
																		<xf:value>SEPA_DIRECT-DEBIT_IBAN</xf:value>
																	</xf:item>
																	<xf:item>
																		<xf:label>SEPA Einzugsverfahren - Gläubiger ID</xf:label>
																		<xf:value>SEPA_DIRECT-DEBIT_CREDITOR-ID</xf:value>
																	</xf:item>
																	<xf:item>
																		<xf:label>SEPA Überweisung - IBAN</xf:label>
																		<xf:value>SEPA_CREDIT-TRANSFER_IBAN</xf:value>
																	</xf:item>
																	<xf:item>
																		<xf:label>SEPA Zahlungsdetails - Textsuche</xf:label>
																		<xf:value>SEPA_PAYMENT-DETAILS_ASCII</xf:value>
																	</xf:item>
																	<xf:item>
																		<xf:label>SEPA Zahlungsdetails - RegEx-Suche</xf:label>
																		<xf:value>SEPA_PAYMENT-DETAILS_REGEX</xf:value>
																	</xf:item>
																	<xf:item>
																		<xf:label>Eigenes Bankkonto (von dem die Zahlung erfolgt)</xf:label>
																		<xf:value>PAYER_BANK-ACCOUNT_CONCERNED</xf:value>
																	</xf:item>																	
																	<xf:action ev:event="xforms-value-changed" ref=".">
																		<!-- Wert zurücksetzen '' -->
																		<xf:setvalue ref="../text()" value="''"/>
																	</xf:action>
																</xf:select1>
															</td>
															<td>
																<!-- Case for PaymentType Direct Debit - IBAN -->
																<xf:group ref=".[@type = 'SEPA_DIRECT-DEBIT_IBAN']">
																	<xf:input ref=".">
																		<xf:label>IBAN des Empfänger:</xf:label>
																	</xf:input>
																</xf:group>
																<!-- Case for IBAN -->
																<xf:group ref=".[@type = 'SEPA_DIRECT-DEBIT_CREDITOR-ID']">
																	<xf:input ref=".">
																		<xf:label>Gläubiger-ID des Empfänger:</xf:label>
																	</xf:input>
																</xf:group>
																<!-- Case for IBAN -->
																<xf:group ref=".[@type = 'SEPA_CREDIT-TRANSFER_IBAN']">
																	<xf:input ref=".">
																		<xf:label>IBAN des Empfänger:</xf:label>
																	</xf:input>
																</xf:group>
																<!-- Case for PaymentDetailTexxt -->
																<xf:group ref=".[@type = 'SEPA_PAYMENT-DETAILS_ASCII']">	
																	<xf:textarea ref=".">
																		<xf:label>Suche Verwendungszweck:</xf:label>
																		<xf:hint>Dieser Text / RegEx muss im Verwendungszweck enthalten sein / matchen.</xf:hint>
																	</xf:textarea>
																</xf:group>
																<!-- Case for PaymentDetailRegex -->
																<xf:group ref=".[@type = 'SEPA_PAYMENT-DETAILS_REGEX']">
																	<xf:textarea ref=".">
																		<xf:label>Suche Verwendungszweck:</xf:label>
																		<xf:hint>Dieser Text / RegEx muss im Verwendungszweck enthalten sein / matchen.</xf:hint>
																	</xf:textarea>
																</xf:group>
																<!-- Case for Own BankID -->
																<xf:group ref=".[@type = 'PAYER_BANK-ACCOUNT_CONCERNED']">
																	<xf:select1 ref=".">
																		<xf:label>Bankverbindung:</xf:label>
																		<xf:itemset nodeset="instance('accounts')//Account[contains(@classes, 'bank')]">
																			<xf:label ref="Name"/>
																			<xf:value ref="@id"/>
																		</xf:itemset>
																	</xf:select1>
																</xf:group>																
															</td>
															<th>
																<th rowspan="5">
																	<xf:trigger>
																		<xf:label>X</xf:label>
																		<xf:delete nodeset="." at="1" if="count(//.) &gt; 1" ev:event="DOMActivate"/>
																	</xf:trigger>
																</th>
															</th>
														</tr>
													</table>
												</div>
											</xf:repeat>
											<xf:trigger>
												<xf:label>Regel/Bedingung hinzufügen</xf:label>
												<xf:insert context="instance('account')/PeriodicPayments/PeriodicPayment/PaymentRules" origin="instance('paymentrule-new')/PaymentRule" nodeset="PaymentRule" ev:event="DOMActivate" position="after"/>
												<xf:setvalue ref="instance('account')/PeriodicPayments/PeriodicPayment/PaymentRules/PaymentRule[last()]/text()" value="''" ev:event="DOMActivate"/>
												<xf:setvalue ref="PaymentRules/PaymentRule[last()]/text()" value="''" ev:event="DOMActivate"/>
											</xf:trigger>
										</td>
									</tr>									
									<tr>
										<th>
											Buchungsvorlage<br/>
											<span style="font-size:80%">(für die automatische Verbuchung)</span>
										</th>
										<td>
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
										</td>
									</tr>
								</table>
							</div>
						</xf:repeat>

						<xf:trigger>
							<xf:label>Regelmäßige Zahlung hinzufügen</xf:label>
							<xf:insert context="instance('account')/PeriodicPayments" origin="instance('periodicpayment-new')/PeriodicPayment" nodeset="PeriodicPayment" ev:event="DOMActivate"/>
						</xf:trigger>
					</td>
				</tr>
				<tr>
					<th>
						Budget-Kategorien<br/>
						<span style="font-size:80%">Zuordnen von Zahlungen zu Budget Kategorien</span>
					</th>
					<td>
						<xf:repeat id="BudgetCategories" nodeset="instance('account')/BudgetCategories/BudgetCategory" appearance="full">
							<div style="border:1px solid #999">
								<table style="width:100%">
									<tr>
										<th>Gültigkeit</th>
										<td>
											<xf:input ref="Period/@valid-from">
												<xf:label>Gültig von:</xf:label>
											</xf:input>

											<xf:input ref="Period/@valid-till">
												<xf:label>bis:</xf:label>
											</xf:input>
										</td>
										<th rowspan="5">
											<xf:trigger>
												<xf:label>X</xf:label>
												<xf:delete nodeset="." at="1" if="count(//.) &gt; 1" ev:event="DOMActivate"/>
											</xf:trigger>
										</th>
									</tr>
									<tr>
										<th>
											Budget-Kategorie
										</th>
										<td>
											<xf:select1 ref="@id" style="min-width: 15em">
												<xf:label>Zugeordnete Kategorie:</xf:label>
												<xf:itemset nodeset="instance('budget-categories')/BudgetCategory">
													<xf:label ref="@name"/>
													<xf:value ref="@id"/>
												</xf:itemset>
												<xf:hint>Der Identifier dieser Kategorie aus der Kategoriebaum</xf:hint>
											</xf:select1>
											<br/>
											<xf:textarea ref="Notes" style="min-width:30em;min-height:5em;">
												<xf:label>Notizen:</xf:label>
												<xf:hint>Hinweise und Notizen</xf:hint>
											</xf:textarea>
										</td>
									</tr>									
									<tr>
										<th>
											Regelset<br/>
											<span style="font-size:80%">(die erfüllt sein müssen, um die Dauerposition zu verbuchen)</span>
										</th>
										<td>
											<xf:repeat id="BudgetCategoriesTemplates" nodeset="PaymentRules/PaymentRule" appearance="full">
												<div style="border:1px solid #999">
													<table style="width:100%">
														<tr>
															<td>
																<!-- <xf:label value="concat('Regel #', position())" /> -->
																<xf:label>
																	<xf:output value="concat('Regel #', position(), ':')"/>
																</xf:label>

																<!-- Selection for Payment Type (@type) -->
																<xf:select1 ref="@type">
																	<xf:item>
																		<xf:label>SEPA Einzugsverfahren - IBAN</xf:label>
																		<xf:value>SEPA_DIRECT-DEBIT_IBAN</xf:value>
																	</xf:item>
																	<xf:item>
																		<xf:label>SEPA Einzugsverfahren - Gläubiger ID</xf:label>
																		<xf:value>SEPA_DIRECT-DEBIT_CREDITOR-ID</xf:value>
																	</xf:item>
																	<xf:item>
																		<xf:label>SEPA Überweisung - IBAN</xf:label>
																		<xf:value>SEPA_CREDIT-TRANSFER_IBAN</xf:value>
																	</xf:item>
																	<xf:item>
																		<xf:label>SEPA Zahlungsdetails - Textsuche</xf:label>
																		<xf:value>SEPA_PAYMENT-DETAILS_ASCII</xf:value>
																	</xf:item>
																	<xf:item>
																		<xf:label>SEPA Zahlungsdetails - RegEx-Suche</xf:label>
																		<xf:value>SEPA_PAYMENT-DETAILS_REGEX</xf:value>
																	</xf:item>
																	<xf:item>
																		<xf:label>Eigenes Bankkonto (von dem die Zahlung erfolgt)</xf:label>
																		<xf:value>PAYER_BANK-ACCOUNT_CONCERNED</xf:value>
																	</xf:item>																	
																	<xf:action ev:event="xforms-value-changed" ref=".">
																		<!-- Wert zurücksetzen '' -->
																		<xf:setvalue ref="../text()" value="''"/>
																	</xf:action>
																</xf:select1>
															</td>
															<td>
																<!-- Case for PaymentType Direct Debit - IBAN -->
																<xf:group ref=".[@type = 'SEPA_DIRECT-DEBIT_IBAN']">
																	<xf:input ref=".">
																		<xf:label>IBAN des Empfänger:</xf:label>
																	</xf:input>
																</xf:group>
																<!-- Case for IBAN -->
																<xf:group ref=".[@type = 'SEPA_DIRECT-DEBIT_CREDITOR-ID']">
																	<xf:input ref=".">
																		<xf:label>Gläubiger-ID des Empfänger:</xf:label>
																	</xf:input>
																</xf:group>
																<!-- Case for IBAN -->
																<xf:group ref=".[@type = 'SEPA_CREDIT-TRANSFER_IBAN']">
																	<xf:input ref=".">
																		<xf:label>IBAN des Empfänger:</xf:label>
																	</xf:input>
																</xf:group>
																<!-- Case for PaymentDetailTexxt -->
																<xf:group ref=".[@type = 'SEPA_PAYMENT-DETAILS_ASCII']">	
																	<xf:textarea ref=".">
																		<xf:label>Suche Verwendungszweck:</xf:label>
																		<xf:hint>Dieser Text / RegEx muss im Verwendungszweck enthalten sein / matchen.</xf:hint>
																	</xf:textarea>
																</xf:group>
																<!-- Case for PaymentDetailRegex -->
																<xf:group ref=".[@type = 'SEPA_PAYMENT-DETAILS_REGEX']">
																	<xf:textarea ref=".">
																		<xf:label>Suche Verwendungszweck:</xf:label>
																		<xf:hint>Dieser Text / RegEx muss im Verwendungszweck enthalten sein / matchen.</xf:hint>
																	</xf:textarea>
																</xf:group>
																<!-- Case for Own BankID -->
																<xf:group ref=".[@type = 'PAYER_BANK-ACCOUNT_CONCERNED']">
																	<xf:select1 ref=".">
																		<xf:label>Bankverbindung:</xf:label>
																		<xf:itemset nodeset="instance('accounts')//Account[contains(@classes, 'bank')]">
																			<xf:label ref="Name"/>
																			<xf:value ref="@id"/>
																		</xf:itemset>
																	</xf:select1>
																</xf:group>																
															</td>
															<th>
																<th rowspan="5">
																	<xf:trigger>
																		<xf:label>X</xf:label>
																		<xf:delete nodeset="." at="1" if="count(//.) &gt; 1" ev:event="DOMActivate"/>
																	</xf:trigger>
																</th>
															</th>
														</tr>
													</table>
												</div>
											</xf:repeat>
											<xf:trigger>
												<xf:label>Regel/Bedingung hinzufügen</xf:label>
												<xf:insert context="instance('account')/BudgetCategories/BudgetCategory/PaymentRules" origin="instance('paymentrule-new')/PaymentRule" nodeset="PaymentRule" ev:event="DOMActivate" position="after"/>
												<xf:setvalue ref="instance('account')/BudgetCategories/BudgetCategory/PaymentRules/PaymentRule[last()]/text()" value="''"/>
												<xf:setvalue ref="PaymentRules/PaymentRule[last()]/text()" value="''"/>
											</xf:trigger>
										</td>
									</tr>									
								</table>
							</div>
						</xf:repeat>

						<xf:trigger>
							<xf:label>Budget Kategorie hinzufügen</xf:label>
							<xf:insert context="instance('account')/BudgetCategories" origin="instance('budgetcategory-new')/BudgetCategory" nodeset="BudgetCategory" ev:event="DOMActivate"/>
						</xf:trigger>
					</td>
				</tr>				
				<tr>
					<th>Billanzkonto</th>
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
					<td colspan="2" style="text-align:right">
						<xf:submit submission="save" id="Save">
		       					<xf:label>Speichern</xf:label>
		       				</xf:submit>
					</td>
				</tr>
			</table>
		</body>
	</xhtml:html>
	</xsl:template>

	<xsl:template match="Accounts"/>

	<xsl:template match="Account"/>

</xsl:stylesheet>