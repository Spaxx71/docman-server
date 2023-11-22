<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="type" required="yes"/>
	<xsl:param name="year" required="yes"/>

	<xsl:variable name="accountings" select="result/Accountings"/>

	<xsl:decimal-format name="EU" decimal-separator="," grouping-separator="."/>

	<xsl:template match="/">
		<html>
			<head>
				<title>Übersicht Accounts von "<xsl:value-of select="@tenantId"/>"</title>
			</head>
			<body>
				<ul class="Nav">
					<li>
						<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/bookings/refresh.html')}">Buchungskonten aktualisieren</a>
					</li>
					<li>
						<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/accounts/datev-export.csv')}">DATEV Export</a>
					</li>
				</ul>
				<span>Jahr <xsl:value-of select="$year"/></span>
				<xsl:choose>
					<xsl:when test="$type!='*'">
						<div class="Filter">Anzeige gefiltert: <xsl:value-of select="$type"/></div>
					</xsl:when>
					<xsl:otherwise>
						<div>Keine Filter gesetzt</div> 
					</xsl:otherwise>
				</xsl:choose>
				<xsl:apply-templates/>
				<br/>
			</body>
		</html>
	</xsl:template>

	<xsl:template match="Accounts">
		<table>
			<tr>
				<th>#</th>
				<th>Name</th>
				<th>Kontakt</th>
				<th>Leistung / Service</th>
				<th>Notizen</th>
				<th>Konto Nr</th>
				<th>Konto Art</th>
				<th>Kategorien</th>
				<!-- 
				<th>IBAN</th> 
				<th>Bank</th>
				<th>Buchungen</th>
				-->
				<th>Buchungskonto</th>
				<th>Funktion</th>
			</tr>
			<xsl:apply-templates/>

			<tr>
				<th colspan="10">
					<ul class="Nav">
						<li>
							<a href="{$home-web-gui}/{$tenant}/{$year}/accounts/New/edit.html" class="Button" target="_blank">Neuen Debitor / Kreditor hinzufügen</a>
						</li>
					</ul>
				</th>
			</tr>
		</table>
	</xsl:template>

	<xsl:template match="Account">
		<xsl:choose>
			<xsl:when test="$type='*' or @type=$type">
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

						<xsl:if test="count(//Account[@id=current()/@id]) != 1 or count(//Account[@kto=current()/@kto]) != 1">
							<xsl:text> error</xsl:text>
						</xsl:if>
					</xsl:attribute>
					<td>
						<xsl:value-of select="count(preceding-sibling::Account)+1"/>
					</td>
					<td>
						<a href="{$home-web-gui}/{$tenant}/{$year}/accounts/{@id}/details.html">
							<xsl:value-of select="Name"/>
						</a>
					</td>
					<td>
						<xsl:if test="Person">
							<div>
								<label>Person</label><br/>
								<xsl:value-of select="Person/Name"/>
							</div>
						</xsl:if>
						<xsl:if test="Company">
							<div>
								<label>Firma</label><br/>
								<xsl:value-of select="Company/Name"/>
							</div>
						</xsl:if>
					</td>
					<td>
						<xsl:value-of select="Service"/>
					</td>
					<td>
						<xsl:value-of select="Notes"/>
					</td>
					<td>
						<a href="{$home-web-gui}/{$tenant}/{$year}/accounts/{@id}/details.html">
							<xsl:value-of select="@kto"/>
						</a>
					</td>
					<td>
						<xsl:choose>
							<xsl:when test="@type='nominal_account'">Sachkonto</xsl:when>
							<xsl:when test="@type='ledger_account'">Personenkonto</xsl:when>
							<xsl:otherwise>ERROR invalid type '<xsl:value-of select="."/>'</xsl:otherwise>
						</xsl:choose>
					</td>
					<td>
						<xsl:for-each select="tokenize(@classes)">
						
							<xsl:choose>
								<xsl:when test=".='debitor'">Debitor</xsl:when>
								<xsl:when test=".='creditor'">Kreditor</xsl:when>
								<xsl:when test=".='bank'">Bankkonto</xsl:when>
								<xsl:when test=".='expense'">Aufwandskonto</xsl:when>
								<xsl:otherwise>ERROR invalid class '<xsl:value-of select="."/>'</xsl:otherwise>
							</xsl:choose>
						</xsl:for-each>
					</td>
					<!--
					<td>
						<xsl:if test="@iban or @debtee">
							<ul>
								<xsl:for-each select="tokenize(@iban)">
									<li>
										<xsl:text>IBAN: </xsl:text>
										<xsl:value-of select="."/>
									</li>
								</xsl:for-each>
								<xsl:for-each select="tokenize(@debtee)">
									<li>
										<xsl:text>Gläubiger ID: </xsl:text>
										<xsl:value-of select="."/>
									</li>
								</xsl:for-each>
							</ul>
						</xsl:if>
					</td>
					-->
					<!--
					<td style="padding-left:0;padding-right:0">
						<xsl:variable name="iban" select="tokenize(@iban)"/>
						<xsl:if test="$accountings/Accounting[IBAN=$iban]">
							<table style="min-width:0;border-spacing:0">
								<xsl:for-each select="$accountings/Accounting[IBAN=$iban]">
									<tr>
										<td>
											<xsl:value-of select="format-date(BookingDate,'[D00].[M00].[Y0000]')"/>
										</td>
										<td style="text-align:right">
											<xsl:value-of select="CreditAmount"/>
											<xsl:value-of select="DebitAmount"/>
											<xsl:text> </xsl:text>
											<xsl:value-of select="CurrencyUnit"/>
										</td>
									</tr>
								</xsl:for-each>
							</table>
						</xsl:if>
					</td>
					-->
					<!--
					<td>
						<xsl:value-of select="@kto"/>
					</td>
					-->
					<td>
						<div>AB: <xsl:value-of select="format-number(Accounting/@openingBalance,'#.##0,00','EU')"/> EUR EB: <xsl:value-of select="format-number(Accounting/@closingBalance,'#.##0,00','EU')"/> EUR</div>
						<div>Soll: <xsl:value-of select="format-number(Accounting/@creditSum,'#.##0,00','EU')"/> EUR Haben: <xsl:value-of select="format-number(Accounting/@debitSum,'#.##0,00','EU')"/> EUR</div>
					</td>
					<td>
						<br/>
						<ul class="nav">
							<li>
								<a href="{$home-web-gui}/{$tenant}/{$year}/accounts/{@id}/details.html">Anzeigen</a>
							</li>
							<li>
								<a href="{$home-web-gui}/{$tenant}/{$year}/accounts/{@id}/edit.html">Bearbeiten</a>
							</li>
							<li>
								<a href="{$home-web-gui}/{$tenant}/{$year}/accounts/{@id}/delete.html">Löschen</a>
							</li>
						</ul>
						<br/>
					</td>
				</tr>
			</xsl:when>
		</xsl:choose>

	</xsl:template>

	<xsl:template match="Accountings"/>
	<xsl:template match="Accounting"/>

</xsl:stylesheet>