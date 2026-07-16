<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:err="http://www.w3.org/2005/xqt-errors" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xf="http://www.w3.org/2002/xforms" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="home-views"/>
	<xsl:param name="home-data"/>
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="path" required="yes"/>
	<xsl:param name="year" required="yes"/>
	<xsl:param name="resource-id" required="yes"/>
	<xsl:param name="format"/>

	<xsl:import href="templates/banking_templates.xsl"/>
	<xsl:import href="templates/analysis_templates.xsl"/>

	<xsl:template match="/">
		<xhtml:html xmlns="http://www.w3.org/1999/xhtml" xmlns:xhtml="http://www.w3.org/1999/xhtml">
			<head>
				<!--
				<xf:model schema="" id="M">

					<xf:instance xmlns="" id="bank-account" src="{$home-web-api}/tenants/{$tenant}/years/{$year}/banks/{$resource-id}"/>
						
					<xf:instance xmlns="" id="budget-categories" src="{$home-web-api}/tenants/{$tenant}/years/{$year}/categories">
						
						<BudgetCategories domain="BUDGET">
							<BudgetCategory id="4711" name="Test"/>
						</BudgetCategories>
					</xf:instance>

					<xf:instance xmlns="" id="accounts">
						<xsl:copy-of select="result/Accounts"/>
					</xf:instance>

					<xf:instance xmlns="" id="URL-container">
						<data/>
					</xf:instance>

					<xf:instance xmlns="" id="GV">
						<data>
						<GVs>
							<GV key="008" type="replace">Dauerauftrag an</GV> 
							<GV key="082" type="prefix">Einzahlung</GV>
							<GV key="083" type="prefix">Auszahlung</GV> 
							<GV key="104" type="fallback">Einzelbuchung Soll, SEPA B2B</GV>
							<GV key="105" type="replace">Lastschrift von</GV> 
							<GV key="107" type="replace">Lastschrift (ELV) von</GV>
							<GV key="108" type="fallback">Rückbelastung Soll, SEPA B2B</GV>
							<GV key="109" type="fallback">Rückbelastung Soll, SEPA Core</GV>
							<GV key="116" type="fallback">Überweisung</GV> 
							<GV key="118" type="fallback">Einzelbuchung Soll</GV>
							<GV key="119" type="fallback">Einzelbuchung Spende (SEPA Purpose Code: CHAR)</GV>
							<GV key="152" type="fallback">Einzelbuchung Dauerauftrag</GV>
							<GV key="153" type="fallback">Einzelbuchung Haben, Lohn, Gehalts, Rentengutschrift</GV>
							<GV key="154" type="fallback">Einzelbuchung Haben, Vermögenswirksame Leistungen</GV>
							<GV key="156" type="fallback">Einzelbuchung Haben, Überweisung öffentlicher Kassen</GV>
							<GV key="159" type="fallback">Retoure Haben für unanbringliche SEPA Überweisung</GV>
							<GV key="160" type="fallback">Rücküberweisung (wegen Rückruf)</GV>
							<GV key="166" type="fallback">Gutschrift</GV> 
							<GV key="168" type="fallback">Gutschrift von</GV> 
							<GV key="169" type="replace">Einzelbuchung Spende(SEPA Purpose Code: CHAR)</GV>
							<GV key="171" type="fallback">Einzelbuchung Haben, SEPA Core</GV>
							<GV key="174" type="fallback">Einzelbuchung Haben, SEPA B2B</GV>
							<GV key="177" type="fallback">Online Einzelbuchung Soll</GV>
							<GV key="181" type="fallback">Wiedergutschrift Haben, SEPA Core</GV>
							<GV key="184" type="fallback">Wiedergutschrift Haben, SEPA B2B</GV>
							<GV key="188" type="fallback">Sammler Soll [Reserviert]</GV>
							<GV key="189" type="fallback">Sammler Haben</GV>
							<GV key="191" type="fallback">Sammler Soll</GV>
							<GV key="192" type="fallback">Sammler Haben Core</GV>
							<GV key="193" type="fallback">Soll, SEPA Reversal</GV>
							<GV key="194" type="fallback">Sammler Haben</GV>
							<GV key="195" type="fallback">Sammler Soll, SEPA Core</GV>
							<GV key="196" type="fallback">Sammler Haben, SEPA B2B</GV>
							<GV key="197" type="fallback">Sammler Soll, SEPA B2B</GV>
							<GV key="801" type="fallback">Scheckkarte</GV>
							<GV key="802" type="fallback">Scheckheft</GV>
							<GV key="803" type="fallback">Depotverwahrung</GV>
							<GV key="804" type="fallback">Dauerauftragsgebühren</GV>
							<GV key="805" type="fallback">Abschluß</GV>
							<GV key="806" type="fallback">Porto/Zustellgebühren</GV>
							<GV key="807" type="fallback">Preise/Spesen</GV>
							<GV key="808" type="fallback">Gebühren</GV>
							<GV key="809" type="fallback">Provisionen</GV>
							<GV key="810" type="fallback">Mahngebühren</GV>
							<GV key="811" type="fallback">Kreditkosten</GV>
							<GV key="812" type="fallback">Stundungszinsen</GV>
							<GV key="813" type="fallback">Disagio</GV>
							<GV key="814" type="fallback">Zinsen</GV>
							<GV key="815" type="fallback">Kapitalisierte Zinsen</GV>
							<GV key="816" type="fallback">Zinssatzänderung</GV>
							<GV key="817" type="fallback">Zinsberichtigung</GV>
							<GV key="818" type="fallback">Abbuchung</GV>
							<GV key="819" type="fallback">Bezüge</GV>
							<GV key="820" type="fallback">Übertrag</GV>
							<GV key="821" type="fallback">Telefon</GV>
							<GV key="822" type="fallback">Auszahlplan</GV>
							<GV key="823" type="fallback">Festgeld</GV>
							<GV key="824" type="fallback">Leihgeld</GV>
							<GV key="825" type="fallback">Universaldarlehn</GV>
							<GV key="826" type="fallback">Dynamisches Sparen</GV>
							<GV key="827" type="fallback">Überschußsparen</GV>
							<GV key="828" type="fallback">Sparbrief</GV>
							<GV key="829" type="fallback">Sparplan</GV>
							<GV key="830" type="fallback">Bonus</GV>
							<GV key="831" type="fallback">Alte Rechnung</GV>
							<GV key="832" type="fallback">Hypothek</GV>
							<GV key="833" type="fallback">Cash Concentrating-Buchung Hauptkonten</GV>
							<GV key="834" type="fallback">Cash Concentrating-Avisenformation für Nebenkosten</GV>
							<GV key="835" type="prefix">Sonstige</GV> 
							<GV key="836" type="fallback">Reklamationsbuchung</GV>
							<GV key="899" type="fallback">Storno</GV>
							<GV key="999" type="fallback">Sonstiges</GV>
						</GVs>
						</data>
					</xf:instance>

					<xf:bind nodeset="instance('bank-account')/Accountings/Accounting/BookingDate" type="xs:date" required="true()"/>
					<xf:bind nodeset="instance('bank-account')/Accountings/Accounting/ValueDate" type="xs:date" required="true()"/>
					<xf:bind nodeset="instance('budget-categories')/BudgetCategories/BudgetCategory/@name" constraint="string-length(.) &gt;= 3" type="xs:string" required="true()"/>
					<xf:bind nodeset="instance('budget-categories')/BudgetCategories/BudgetCategory/@name" constraint="string-length(.) &gt;= 3" type="xs:string" required="true()"/>

				</xf:model>
				<style>
					<![CDATA[
									.xforms-label {
										width: inherit !important;
									}
					]]>
				</style>
				<style type="text/css">
					@namespace xf url("http://www.w3.org/2002/xforms");
					body {font-family:Helvetica, sans-serif}
					.links xf|repeat * {display: inline;}
					.url {color: blue; text-decoration:underline; margin: 0 2px;}
					tr:nth-child(odd) {
						background-color: #FDF5E6;
					}
					tr:nth-child(even) {
						background-color:#EEDFCC;
					}
				 </style>				
			-->
			</head>
			<body>
				<xsl:if test="result/BankAccount/@hasOnlineBanking=true()">
					<ul class="Nav">
						<li>
							<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/banking/',$resource-id,'/update.html')}">per Onlinebaning aktualiseren…</a>
						</li>
					</ul>
				</xsl:if>
				<h1>Bankkonto <xsl:value-of select="$resource-id"/></h1>

				<h2>Kontoübersicht</h2>
				
				<xsl:call-template name="BalanceGraph">
					<xsl:with-param name="Analysis" select="result/Analysis"/>
					<xsl:with-param name="HomeWebGui" select="$home-web-gui"/>
				</xsl:call-template>
				<br/>
				<br/> 
				<h2>Kontoauszug / Liste aller Bankbewegungen</h2>

				<!-- A pure XSLT version of the table can be found at banking_templates.xsl; which needs to be imported than -->
				<xsl:apply-templates/>


				<!-- here the XForms version is been used -->
				<!-- for this the xForms Model has to be included -->
				<!-- ans at controler.xql the follwing added: or ($resource-type='banking' and $function='index') -->
				<!--
				<table>
					<tr>
						<th>#</th>
						<th>Datum</th>
						<th>Betrag</th>
						<th>Umsatzart</th>
						<th>Begünstigter / Auftraggeber</th>
						<th>Verwendungszweck</th>
						<th>Saldo</th>
						<th>Kategorie</th>
						<th>Aktivität</th>
						<th>IBAN</th>
						<th>BIC</th>
						<th>Kundenreferenz</th>
						<th>Mandatsreferenz</th>
						<th>Gläubiger ID</th>
						<th>Sonstiges</th>
					</tr>
					<xf:repeat id="Accountings" nodeset="instance('bank-account')/Accountings/Accounting" appearance="full">
						<tr class="{{if(position() mod 2 = 0, 'even', 'odd')}} {{count(current()/preceding-sibling::*)}}">
							<xsl:call-template name="XFormsAccountingRow"/>
						</tr>
					</xf:repeat>
				</table>
				-->
			</body>
		</xhtml:html>
	</xsl:template>

	
	
<xsl:template name="XFormsAccountingRow">		
		<td>
			<!-- to mark dupplicate IDs {{if(count(../Accounting/@id[. = current()/@id]) > 1, ' Duplicate ', '')}} -->
			<xsl:variable name="details-uri" select="concat($home-web-gui,'/',$tenant,'/',$year,'/banking/',$resource-id,'/')"/>
			<!-- 
			
			<a href="{{concat('{$uri}', @id, '/details.html')}}">
				<xf:output value="position()"/>
			</a>
			-->

			<xf:trigger appearance="minimal" class="url">
				<xf:label>
					<xf:output value="position()"/>
				</xf:label>
				<xf:action ev:event="DOMActivate">
					<xf:setvalue ref="instance('URL-container')" value="concat('{$details-uri}', current()/@id,'/details.html')"/>
					<xf:load ref="instance('URL-container')"/>
				</xf:action>
			</xf:trigger>
		</td>
		<td>
			<!-- format-date(ValueDate,'[D01].[M01].[Y0001]') -->
			<xf:output ref="ValueDate"/><br/>
			<span style="color:#aaa" class="BookingDate">
				<xf:output ref="BookingDate"/>
			</span>
		</td>
		
		<td class="Money">
			<xf:output value="translate(format-number(Amount,'#,##0.00'),'.,',',.')"/>
			<xsl:text> </xsl:text>
			<xf:output ref="instance('bank-account')/BankAccountDetail/CurrencyUnit"/>
			<!--
			<div>
				<xsl:choose>
					<xsl:when test="format-number(Amount,'0.00')=format-number(@booked-amount,'0.00')">
						<xsl:attribute name="style" select="'color:#6c6'"/>
					</xsl:when>
					<xsl:when test="(Amount &lt; 0 and @booked-amount &gt; 0) or (Amount &gt; 0 and @booked-amount &lt; 0)">
						<xsl:attribute name="style" select="'color:#d20'"/>
					</xsl:when>
					<xsl:when test="abs(Amount) &lt; abs(@booked-amount)">
						<xsl:attribute name="style" select="'color:#d20'"/>
					</xsl:when>
					<xsl:when test="@booked">
						<xsl:attribute name="style" select="'color:#f90'"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:attribute name="style" select="'color:#ea3'"/>
					</xsl:otherwise>
				</xsl:choose>				
				<xsl:text> (</xsl:text>
				<xsl:choose>
					<xsl:when test="@booked-amount castable as xs:decimal">
						<xf:output ref="format-number(@booked-amount,'#.##0,00')"/>
					</xsl:when>
					<xsl:otherwise>
						<xf:output ref="format-number(0,'#.##0,00')"/>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:text>)</xsl:text>
			</div>
			-->
			<!--
			<xf:group bind="OriginalAmount != ''">
				<div style="color:#aaa" class="OriginalAmount ClassMoney">
					<xf:label> orig: </xf:label>
					<xf:output ref="OriginalAmout"/>
				</div>
			</xf:group>
			-->
		</td>

		<td style="white-space: nowrap;">
			<xf:group ref="instance('GV')/GVs/GV[@key = current()/SalesType/@key]">
				<!-- Verwende xf:switch anstelle von xf:choose -->
				<xf:switch>
					
					<!-- Fall 1: Wenn der Typ 'replace' ist -->
					<xf:case id="replace-case" selected="if(@type = 'replace') then true() else false()">
						<xf:output value="."/> <!-- Zeige den Text des GV-Eintrags -->
					</xf:case>
			
					<!-- Fall 2: Wenn der Typ 'prefix' ist -->
					<xf:case id="prefix-case" selected="if(@type = 'prefix') then true() else false()">
						<xf:output value="."/> <!-- Zeige den Text des GV-Eintrags -->
					
						<!-- Wenn der SalesType-Text vorhanden ist, zeige ihn -->
						<xf:group>
							<xf:output value="': '"/>
							<xf:output value="current()/SalesType" appearance="minimal" style="color:#999"/>
						</xf:group>
					</xf:case>
			
					<!-- Standardfall: Wenn der SalesType nicht 'replace' oder 'prefix' ist -->
					<xf:case id="default-case" selected="if(@type != 'replace' and @type != 'prefix') then true() else false()">
						<xf:output value="current()/SalesType" appearance="minimal" style="color:#999"/>
					</xf:case>
			
				</xf:switch>
				</xf:group>			
			<!--
			<xsl:variable name="GV" select="$GVList/GVs/GV[@key=current()/SalesType/@key]"/>
			<xsl:choose>
				<xsl:when test="$GV[@type='replace']">
					<xsl:value-of select="$GV/text()"/>
				</xsl:when>
				<xsl:when test="$GV[@type='prefix']">
					<xsl:value-of select="$GV/text()"/>
					<xsl:if test="SalesType/text() != ''">
						<xsl:text>: </xsl:text>
						<span style="color:#999"><xsl:value-of select="SalesType"/></span>
					</xsl:if>
				</xsl:when>
				<xsl:when test="SalesType/text() != ''">
					<span style="color:#999"><xsl:value-of select="SalesType"/></span>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$GV/text()"/>
				</xsl:otherwise>
			</xsl:choose>
			-->
		</td>
		<td>
			<div>
				<xf:output ref="Recipient"/>
			</div>
			<!-- Conditional display for "Owner" -->
			<xf:var name="current-iban" value="IBAN"/>
			<xf:group ref="instance('accounts')/Account[BankAccounts/BankAccount/@iban = $iban and $iban != '']">
				<div>
					<!-- href="{{concat('{concat($home-web-gui, '/', $tenant, '/accounts/')}', @id, '/details.html')}}" -->
					<a style="color:#aaa">
						<xf:output ref="Name"/>
						<xf:output value="' ('"/>
						<xf:output ref="@kto"/>
						<xf:output value="')'"/>
					</a>
				</div>
			</xf:group>
		
			<!-- Conditional display for DivergentRecepient -->				
			<xf:group ref=".[DivergentRecepient]">
				<div style="color:#aaa; background-color:#ffffcc" class="DivergentRecepient">
					Abweichender Kontoinhaber:
					<xf:output ref="DivergentRecepient"/>
				</div>
			</xf:group>
		</td>
		<td>
			<xf:repeat id="PaymentDetails" nodeset="PaymentDetails/PaymentDetail" appearance="full">
				<div class="PaymentDetail">
					<xf:output ref="."/>
				</div>
			</xf:repeat>

			<xf:repeat id="Usages" nodeset="Usages/Usage" appearance="full">
				<div class="Usage" style="font-style:italic;">
					<xf:output ref="."/>
				</div>
			</xf:repeat>

			<xf:group ref=".[Additional != '']">
				<div class="Additional">
					<xf:output ref="Additional"/>
				</div>
			</xf:group>
		</td>
		<td class="Money" style="background-color:rgba(0,0,0,0.1)">
			<xf:output ref="@saldoAmount"/>
			<xsl:text> </xsl:text>
			<xf:output ref="instance('bank-account')/BankAccountDetail/CurrencyUnit"/>
		</td>
		<td> 
			<xf:select1 ref="@budgetCategory">
				<xf:itemset nodeset="instance('budget-categories')/BudgetCategory">
					<xf:label ref="@name"/>
					<xf:value ref="@id"/>
				</xf:itemset>
			</xf:select1>
		</td>
		<td>
			<!--
			<xsl:choose>
				<xsl:when test="format-number(@booked-amount,'0.00')=format-number(Amount,'0.00')">
					<xsl:attribute name="class" select="'done'"/>
					<xsl:for-each select="tokenize(@booked)">
						<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/binders/',.,'.html')}">Verknüpfung <xsl:value-of select="position()"/> anzeigen</a>
						<br/>
					</xsl:for-each>
					<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/banking/',$resource-id,'/',@id,'/assign-document.html?owner=',$owner/@kto)}">weiteren Beleg zuordnen</a>
				</xsl:when>
				<xsl:when test="(Amount &lt; 0 and @booked-amount &gt; 0) or (Amount &gt; 0 and @booked-amount &lt; 0)">
					<xsl:attribute name="class" select="'invalid'"/>
					<div>Falsche Zuordnung:</div>
					<xsl:for-each select="tokenize(@booked)">
						<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/binders/',.,'.html')}">Verknüpfung <xsl:value-of select="position()"/> anzeigen</a>
						<br/>
					</xsl:for-each>
				</xsl:when>
				<xsl:when test="abs(Amount) &lt; abs(@booked-amount)">
					<xsl:attribute name="class" select="'invalid'"/>
					<div>Falsche Zuordnung:</div>
					<xsl:for-each select="tokenize(@booked)">
						<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/binders/',.,'.html')}">Verknüpfung <xsl:value-of select="position()"/> anzeigen</a>
						<br/>
					</xsl:for-each>
				</xsl:when>
				<xsl:when test="@booked">
					<xsl:attribute name="class" select="'part'"/>
					<xsl:for-each select="tokenize(@booked)">
						<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/binders/',.,'.html')}">Verknüpfung <xsl:value-of select="position()"/> anzeigen</a>
						<br/>
					</xsl:for-each>
					<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/banking/',$resource-id,'/',@id,'/assign-document.html?owner=',$owner/@kto)}">weiteren Beleg zuordnen</a>
				</xsl:when>
				<xsl:otherwise>
					<xsl:attribute name="class" select="'open'"/>
					<ul class="Nav">
						<li><a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/binders/enter/index.html?ref=','/',$tenant,'/',$year,'/banking/',$resource-id,'/',@id,'.pdf')}">Dokument erstellen</a></li>
						<li><a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/banking/',$resource-id,'/',@id,'/assign-document.html?owner=',$owner/@kto)}">einem Beleg zuordnen</a></li>
					</ul>
				</xsl:otherwise>
			</xsl:choose>
			-->
		</td>
		<td>
			<!-- test if owner
			
				<a href="{$home-web-gui}/{$tenant}/accounts/{owner/@id}/details.html">
					<xf:output ref="IBAN"/>
				</a>
			 -->
			<xf:output ref="IBAN"/>
		</td>
		<td><xf:output ref="BIC"/></td>
		<td>
			<xf:output ref="EndToEndRef"/>
			<xf:group ref=".[CustomerRef != '' and CustomerRef != 'NONREF']">
				<xf:output ref="CustomerRef"/>
			</xf:group>
		</td>
		<td><xf:output ref="MandantRef"/></td>
		<td><xf:output ref="CreditorID"/></td>
		<td>
			<xf:group ref=".[ExternalCosts != '']">
				<div class="ExternalCosts">Externe Kosten: <xf:output ref="ExternalCosts"/></div>
			</xf:group>
		</td>

	</xsl:template>


	<xsl:template match="result">
		<xsl:apply-templates/> 
	</xsl:template>

	<xsl:template match="BankStatement">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="BankAccounts">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="BankAccount">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="BankAccountDetail">
		<xsl:call-template name="BankAccountDetail">
			<xsl:with-param name="BankAccountDetail" select="."/>
		</xsl:call-template>
		<br/> 
	</xsl:template>
<!--
	<xsl:template name="Accountings">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template name="Accounting">
	</xsl:template>
-->

	<xsl:template match="Accounts"/>

	<xsl:template match="Account"/>

	<xsl:template match="Balances"/>

	<xsl:template match="Balance"/>

	<!--
	<xsl:template match="@*|node()" priority="-1">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
	-->

</xsl:stylesheet>