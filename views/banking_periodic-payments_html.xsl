<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="year" required="no"/>
	<xsl:param name="resource-id" required="no"/>

	<xsl:decimal-format name="EU" decimal-separator="," grouping-separator="."/>

	<xsl:template match="/">
		<page>
			<body>
				<xsl:apply-templates/>
			</body>
		</page>
	</xsl:template>

	<xsl:template match="result">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="PeriodicPayments">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="PeriodicPayment">
		<table>
			<tr>
				<th>Name:</th>
				<td>
					<xsl:value-of select="RegardingAccount/Name"/>
					<xsl:text> - </xsl:text>
					<b><xsl:value-of select="Name"/></b>
				</td>
			</tr>				
			<tr>
				<th>Zahlungsintervall:</th>
				<td>
					Zahlungsperiode:
					<xsl:value-of select="Period/@interval"/>
					<br/>
					Anzahl der Vorgänge min.
					<xsl:value-of select="Period/@min"/>
					<xsl:text> max. </xsl:text> 
					<xsl:value-of select="Period/@max"/>
					
					<br/>
					Gültigkeitszeitraum:
					<xsl:value-of select="Period/@valid-from"/>
					<xsl:text> - </xsl:text>
					<xsl:value-of select="Period/@valid-till"/>
				</td>
			</tr>
			<tr>
				<th>Filterkriterien:</th>
				<td>
					<xsl:for-each select="PaymentOptions">
						Zahlungsart:
						<xsl:value-of select="PaymentOption/@type"/>
						<br/>
						Bankkonto:
						<xsl:value-of select="PaymentOption/@kto"/>
						<br/>
						IBAN:
						<xsl:value-of select="PaymentOption/IBAN"/>
						<br/>
						Filter für Inhaltsangabe:
						<xsl:choose>
							<xsl:when test="PaymentOption/PaymentDetail/@type = 'TEXT'">
								Text-String: "<xsl:value-of select="PaymentOption/PaymentDetail/text()"/>"
							</xsl:when>
							<xsl:when test="PaymentOption/PaymentDetail/@type = 'REGEX'">
								Suchmuster: <xsl:value-of select="PaymentOption/PaymentDetail/text()"/>
							</xsl:when>
							<xsl:otherwise>
								<error>Unbekannter Typ '<xsl:value-of select="PaymentOption/PaymentDetail/@type"/>'</error>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</td>
			</tr>			
			<tr>
				<th>Buchungsvorlage:</th>
				<td>
					Sektion:
					<xsl:value-of select="DocumentTemplate/Section"/>
					<br/>
					Gegenkonto:
					<xsl:value-of select="DocumentTemplate/Other/@kto"/>
					<br/>
					Referenz-ID:
					<xsl:value-of select="DocumentTemplate/RefID"/>
					<br/>
					Transaktions-ID:
					<xsl:value-of select="DocumentTemplate/TransactionID"/>
					<br/>
					Betrag
					<xsl:value-of select="DocumentTemplate/TotalAmount/@value"/>
					<xsl:text> </xsl:text>
					<xsl:value-of select="DocumentTemplate/TotalAmount/@unit"/>
					<br/>
					Steuer:
					<xsl:value-of select="DocumentTemplate/Tax/@key"/>
					<xsl:text> </xsl:text>
					<xsl:value-of select="DocumentTemplate/Tax/@region"/>
					<xsl:text> </xsl:text>
					<xsl:value-of select="DocumentTemplate/Tax/@type"/>
					<br/>
					<xsl:value-of select="DocumentTemplate/Tax/Description"/>
				</td>
			</tr>
			<tr>
				<th>Account:</th>
				<td>
					ID:
					<xsl:value-of select="RegardingAccount/@id"/>
					<br/>
					Buchungskonto:
					<xsl:value-of select="RegardingAccount/@kto"/>
					<br/>
					IBAN:
					<xsl:value-of select="RegardingAccount/@iban"/>
					<br/>
					Kategorisierung:
					<xsl:value-of select="RegardingAccount/@type"/>
					<xsl:text> </xsl:text>
					<xsl:value-of select="RegardingAccount/@classes"/>

				</td>
			</tr>			
			<tr>
				<th>Notizen:</th>
				<td>
					zum Zahlungsintervall
					<xsl:value-of select="Notes"/>
					<br/>
					zum Account:
					<xsl:value-of select="RegardingAccount/Notes"/>
					<br/>
				</td>
			</tr>
		</table>
		<br/>
	</xsl:template>

</xsl:stylesheet>