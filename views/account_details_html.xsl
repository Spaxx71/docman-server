<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="home-views"/> 
	<xsl:param name="home-data"/>                
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="year" required="yes"/>
	<xsl:param name="path" required="yes"/>

	<xsl:variable name="bank-accounts" select="result/BankAccounts/BankAccount"/>
	<xsl:variable name="documents" select="result/Documents"/>
	<xsl:decimal-format name="EU" decimal-separator="," grouping-separator="."/>


	<xsl:template match="/">
		<html>
			<head>
				<title>Übersicht Accounts von "<xsl:value-of select="@tenantId"/>"</title>
			</head>
			<body>
				<table>
					<xsl:apply-templates/>
				</table>

				<br/>
			</body>
		</html>
	</xsl:template>


	<xsl:template match="Account">
		<xsl:variable name="Owner" select="@id"/>
		<tr>
			<th>ID / Kurzname</th>
			<td>
				<xsl:value-of select="@id"/>
			</td>
		</tr>
		<tr>
			<th>Name</th>
			<td>
				<xsl:value-of select="Name"/>
			</td>
		</tr>
		<tr>
			<th>Kontakt</th>
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
		</tr>
		<tr>
			<th>Leistung / Service</th>
			<td>
				<xsl:value-of select="Service"/>
			</td>
		</tr>
		<tr>
			<th>Kundennummer</th>
			<td>
				<xsl:value-of select="CustomerID"/>
			</td>
		</tr>
		<tr>
			<th>Notizen</th>
			<td style="height:8ex;">
				<xsl:value-of select="Notes"/>
			</td>
		</tr>
		<tr>
			<th>Konto Nr</th>
			<td>
				<xsl:value-of select="@kto"/>
			</td>
		</tr>
		<tr>
			<th>Konto Art</th>
			<td>
				<xsl:value-of select="@type"/>
			</td>
		</tr>
		<tr>
			<th>IBAN / Gläubiger ID</th>
			<td>
				<xsl:choose>
					<xsl:when test="@iban != '' or @debtee != ''">
						<ul>
							<xsl:for-each select="tokenize(@iban)">
								<li>
									<xsl:text>IBAN: </xsl:text>
									<xsl:value-of select="data(.)"/>
								</li>
							</xsl:for-each>
							<xsl:for-each select="tokenize(@debtee)">
								<li>
									<xsl:text>Gläubiger ID: </xsl:text>
									<xsl:value-of select="data(.)"/>
								</li>
							</xsl:for-each>
						</ul>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>Keine Bankdaten (IBAN oder Gläubiger ID) hinterlegt.</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</td>
		</tr>
		<tr>
			<th>Buchhaltung</th>
			<td>
					Anfangsbestand: <xsl:value-of select="Acccounting/@openingBalance"/>
					<br/>
					Endbestand: <xsl:value-of select="Acccounting/@openingBalance"/>
					<br/>
					SOLL Stand: <xsl:value-of select="Acccounting/@creditSum"/>
					<br/>
					HABEN Stand: <xsl:value-of select="Acccounting/@DebitSum"/>
			</td>
		</tr>

		<tr>
			<th>Vorgänge / Dokumente</th>
			<td style="padding-left:0;padding-right:0">
				<xsl:variable name="owner" select="@kto"/>
				<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/binders/search.html?owner=',$owner)}">Vergänge anzeigen</a>
			</td>
		</tr>

		<tr>
			<th>Bankbewegungen</th>
			<td style="padding-left:0;padding-right:0">
				<xsl:variable name="owner" select="@kto"/>
				<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/banking/search.html?owner=',$owner)}">Bankbewegungen anzeigen</a>
			</td>
		</tr>

		<tr>
			<th>Buchungen</th>
			<td style="padding-left:0;padding-right:0">
				<xsl:variable name="owner" select="@kto"/>
				<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/bookings/accounts.html?owner=',$owner)}">Buchungen anzeigen</a>
			</td>
		</tr>

		<tr>
			<th colspan="2">

				<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/accounts/',@id,'/edit.html')}">Bearbeiten</a>
			</th>
		</tr>
	</xsl:template>

	<xsl:template match="BankingAccounts"/>
	<xsl:template match="BankingAccount"/>
	<xsl:template match="Accountings"/>
	<xsl:template match="Accounting"/>
	<xsl:template match="Documents"/>
	<xsl:template match="Document"/>
	<xsl:template match="Years"/>

</xsl:stylesheet>