<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="3.0">

	<xsl:decimal-format name="EU" decimal-separator="," grouping-separator="."/>

	<xsl:variable name="GVList">
		<GVs>
			<GV key="008" type="replace">Dauerauftrag an</GV> <!-- Dauerauftrag Belastung -->
			<GV key="082" type="prefix">Einzahlung</GV>
			<GV key="083" type="prefix">Auszahlung</GV> 
			<GV key="104" type="fallback">Einzelbuchung Soll, SEPA B2B</GV>
			<GV key="105" type="replace">Lastschrift von</GV> <!-- Einzelbuchung Soll, SEPA Core -->
			<GV key="107" type="replace">Lastschrift (ELV) von</GV>
			<GV key="108" type="fallback">Rückbelastung Soll, SEPA B2B</GV>
			<GV key="109" type="fallback">Rückbelastung Soll, SEPA Core</GV>
			<GV key="116" type="fallback">Überweisung</GV> <!-- Einzelbuchung Soll -->
			<GV key="118" type="fallback">Einzelbuchung Soll</GV>
			<GV key="119" type="fallback">Einzelbuchung Spende (SEPA Purpose Code: CHAR)</GV>
			<GV key="152" type="fallback">Einzelbuchung Dauerauftrag</GV>
			<GV key="153" type="fallback">Einzelbuchung Haben, Lohn, Gehalts, Rentengutschrift</GV>
			<GV key="154" type="fallback">Einzelbuchung Haben, Vermögenswirksame Leistungen</GV>
			<GV key="156" type="fallback">Einzelbuchung Haben, Überweisung öffentlicher Kassen</GV>
			<GV key="159" type="fallback">Retoure Haben für unanbringliche SEPA Überweisung</GV>
			<GV key="160" type="fallback">Rücküberweisung (wegen Rückruf)</GV>
			<GV key="166" type="fallback">Gutschrift</GV> <!-- Einzelbuchung Haben -->
			<GV key="168" type="fallback">Gutschrift von</GV> <!-- Einzelbuchung Haben -->
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
			<GV key="835" type="prefix">Sonstige</GV> <!-- sonstige nicht definierte GV-Arten -->
			<GV key="836" type="fallback">Reklamationsbuchung</GV>
			<GV key="899" type="fallback">Storno</GV>
			<GV key="999" type="fallback">Sonstiges</GV>
		</GVs>
	</xsl:variable>

	<!-- <xsl:key name="GVC" match="$GVList/GVs/GV" use="@code"/> -->

	<xsl:template name="BankAccountDetail">
		<xsl:param name="BankAccountDetail" required="yes" as="element()"/>

		<table>
			<tr>
				<th>Bank Name:</th>
				<td>
					<xsl:value-of select="$BankAccountDetail/BankName"/>
				</td>
			</tr>
			<tr>
				<th>Konto Name:</th>
				<td>
					<xsl:value-of select="$BankAccountDetail/AccountName"/>
				</td>
			</tr>
			<tr>
				<th>Konto Kurzname:</th>
				<td>
					<xsl:value-of select="$BankAccountDetail/AccountNick"/>
				</td>
			</tr>
			<tr>
				<th>Kontonummer:</th>
				<td>
					<xsl:value-of select="$BankAccountDetail/KTNR"/>
				</td>
			</tr>
			<tr>
				<th>IBAN (BIC):</th>
				<td>
					<xsl:value-of select="$BankAccountDetail/IBAN"/>
					<xsl:text> (</xsl:text>
					<xsl:value-of select="$BankAccountDetail/BIC"/>
					<xsl:text>)</xsl:text>
				</td>
			</tr>
			<tr>
				<th>KontoNr / BLZ:</th>
				<td>
					<xsl:value-of select="$BankAccountDetail/KTNR"/>
					<xsl:text> (</xsl:text>
					<xsl:value-of select="$BankAccountDetail/BLZ"/>
					<xsl:text>)</xsl:text>
				</td>
			</tr>
			<tr>
				<th>Konto Inhaber ID</th>
				<td>
					<xsl:value-of select="$BankAccountDetail/CustomerID"/>
				</td>
			</tr>
			<tr>
				<th>Konto Inhaber Name:</th>
				<td>
					<xsl:value-of select="$BankAccountDetail/CustomerName"/>
				</td>
			</tr>				
		</table>
	</xsl:template>

	<xsl:template match="Accountings">
		<table>
			<tr>
				<th>#</th>
				<th>Aktivität</th>
				<th>Datum</th>
				<th>Betrag</th>
				<th>Umsatzart</th>
				<th>Begünstigter / Auftraggeber</th>
				<th>Verwendungszweck</th>
				<th>IBAN</th>
				<th>BIC</th>
				<th>Kundenreferenz</th>
				<th>Mandatsreferenz</th>
				<th>Gläubiger ID</th>
				<th>Sonstiges</th>
				<th>Saldo</th>
			</tr>
			<xsl:apply-templates>
				<xsl:sort select="BookingDate"/>
			</xsl:apply-templates>
		</table>
	</xsl:template>
	

	<xsl:template match="Accounting">
		<xsl:variable name="iban" select="IBAN"/>
		<xsl:variable name="owner" select="/result/Accounts/Account[$iban=tokenize(@iban)]"/>
		<xsl:variable name="isDuplicate" select="exists(/result/Parameter/UsedIDs/UsedID[. = current()/@id])"/>

		<tr>
			<xsl:attribute name="class">
				<xsl:choose>
					<xsl:when test="count(preceding-sibling::*) mod 2 = 0">
						<xsl:text>even</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>odd</xsl:text>
					</xsl:otherwise>
				</xsl:choose>

				<xsl:variable name="previousSaldo">
					<xsl:choose>
						<xsl:when test="not(preceding-sibling::Accounting)">
							<xsl:value-of select="../@saldoInitAmount"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="preceding-sibling::Accounting[1]/@saldoAmount"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="not(Amount castable as xs:double)">
						<xsl:text> Invalid</xsl:text>
					</xsl:when>
					<xsl:when test="not($previousSaldo castable as xs:double)">
						<xsl:text> NoTrust</xsl:text>
					</xsl:when>
					<xsl:when test="not(@saldoAmount castable as xs:double)">
						<xsl:text> NoTrust</xsl:text>
					</xsl:when>
					<xsl:when test="format-number(xs:double($previousSaldo) + xs:double(Amount) + xs:double(if(ExternalCosts castable as xs:double) then ExternalCosts else 0),'0.00') = format-number(@saldoAmount,'0.00')">
						<xsl:text> Trusted</xsl:text>
					</xsl:when>
					<xsl:when test="preceding-sibling::Accounting[1]/@saldoAmount">
						<xsl:text> Invalid</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text> Invalid</xsl:text>
					</xsl:otherwise>
				</xsl:choose>

				<xsl:if test="$isDuplicate">
					<xsl:text> Duplicate</xsl:text>
				</xsl:if>
			</xsl:attribute>

			<td>
				<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/banking/',$resource-id,'/',@id,'/details.html')}">
					<xsl:value-of select="count(preceding-sibling::Accounting)+1"/>
				</a>

				<xsl:if test="$isDuplicate">
					<xsl:text> !</xsl:text>
				</xsl:if>
			</td>
			<td>
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
			</td>
			<td>
				<xsl:value-of select="format-date(ValueDate,'[D01].[M01].[Y0001]')"/><br/>
				<span style="color:#aaa" class="BookingDate">
					<xsl:value-of select="format-date(BookingDate,'[D01].[M01].[Y0001]')"/>
				</span>
			</td>
			<td class="Money">
				<xsl:value-of select="format-number(Amount,'#.##0,00','EU')"/>
				
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
							<xsl:value-of select="format-number(@booked-amount,'#.##0,00','EU')"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="format-number(0,'#.##0,00','EU')"/>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:text>)</xsl:text>
				</div>
				<xsl:if test="OriginalAmount != ''">
					<div style="color:#aaa" class="OriginalAmount ClassMoney">
						<xsl:text> orig: </xsl:text>
						<xsl:value-of select="OriginalAmout"/>
						<xsl:text/>
					</div>
				</xsl:if>
			</td>
			<td>
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
					<xsl:otherwise> <!-- @type="fallback" -->
						<xsl:value-of select="$GV/text()"/>
					</xsl:otherwise>
				</xsl:choose>
			</td>
			<td>
				<xsl:choose>
					<xsl:when test="$owner">
						<xsl:value-of select="Recipient"/>
						<br/>			
						<a href="{$home-web-gui}/{$tenant}/accounts/{$owner/@id}/details.html" style="color:#aaa">
							<xsl:value-of select="$owner/Name"/>
							<xsl:text> (</xsl:text>
							<xsl:value-of select="$owner/@kto"/>
							<xsl:text>)</xsl:text>
						</a>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="Recipient"/>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:if test="DivergentRecepient">
					<div style="color:#aaa" class="DivergentRecepient">
						<xsl:text> (</xsl:text>
						<xsl:value-of select="DivergentRecepient"/>
						<xsl:text>)</xsl:text>
					</div>
				</xsl:if>
			</td>
			<td>
				<xsl:for-each select="PaymentDetails/PaymentDetail">
					<div class="PaymentDetail">
						<xsl:value-of select="."/>
					</div>
				</xsl:for-each>
				<xsl:for-each select="Usages/Usage">
					<div class="Usage" style="font-style:italic;">
						<xsl:value-of select="."/>
					</div>
				</xsl:for-each>
				<xsl:if test="Additional != ''">
					<div class="Additional">
						<xsl:value-of select="Additional"/>
					</div>
				</xsl:if>
			</td>
			<td>
				<xsl:choose>
					<xsl:when test="$owner">
						<a href="{$home-web-gui}/{$tenant}/accounts/{$owner/@id}/details.html">
							<xsl:value-of select="IBAN"/>
						</a>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="IBAN"/>
					</xsl:otherwise>
				</xsl:choose>
			</td>
			<td><xsl:value-of select="BIC"/></td>
			<td>
				<xsl:value-of select="EndToEndRef"/>
				<xsl:if test="CustomerRef != '' and CustomerRef != 'NONREF'">
					<xsl:value-of select="CustomerRef"/>
				</xsl:if>
			</td>
			<td><xsl:value-of select="MandantRef"/></td>
			<td><xsl:value-of select="CreditorID"/></td>
			<td>
				<xsl:if test="ExternalCosts != ''">
					<div class="ExternalCosts">Externe Kosten: <xsl:value-of select="ExternalCosts"/></div>
				</xsl:if>
			</td>
			<td class="Money">
				<xsl:value-of select="format-number(@saldoAmount,'#.##0,00','EU')"/>
			</td>
		</tr>
	</xsl:template>


	<xsl:template name="outputText">
		<xsl:param name="text" select="."/>

		<xsl:choose>
			<xsl:when test="not(contains($text, '&#xA;'))">
				<xsl:copy-of select="$text"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="substring-before($text, '&#xA;')"/>
				<br/>
				<xsl:call-template name="outputText">
					<xsl:with-param name="text" select="substring-after($text, '&#xA;')"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

</xsl:stylesheet>