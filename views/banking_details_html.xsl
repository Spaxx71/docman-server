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

	<xsl:template match="BankAccount">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="BankAccountDetail">
		<headline>
			<xsl:value-of select="BankName"/>
		</headline>
		<table>
			<tr>
				<th>Konto:</th>
				<td>
					<xsl:value-of select="AccountName"/>
				</td>
			</tr>
			<tr>
				<th>Kontonummer:</th>
				<td>
					<xsl:value-of select="KTNR"/>
				</td>
			</tr>
			<tr>
				<th>IBAN:</th>
				<td>
					<xsl:value-of select="IBAN"/>
				</td>
			</tr>
		</table>
		<br/>
	</xsl:template>

	<xsl:template match="BankAccount">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="Accountings">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="Accounting">
		<xsl:variable name="iban" select="IBAN"/>
		<xsl:variable name="owner" select="/result/BankAccount/Accounts/Account[$iban=tokenize(@iban)]"/>
		<subtitle>
			<xsl:value-of select="SalesType"/>
		</subtitle>
		<table>
			<tr>
				<th>Buchungdatum:</th>
				<td>
					<xsl:value-of select="format-date(ValueDate,'[D01].[M01].[Y0001]')"/>
					<xsl:text> (</xsl:text>
					<xsl:value-of select="format-date(BookingDate,'[D01].[M01].[Y0001]')"/>
					<xsl:text>)</xsl:text>
				</td>
			</tr>
			<tr>
				<th>Empfänger:</th>
				<td>
					<xsl:choose>
						<xsl:when test="$owner">
							<a href="{$home-web-gui}/{$tenant}/accounts/{$owner/@id}/details.html">
								<xsl:value-of select="Recipient"/>
							</a>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="Recipient"/>
						</xsl:otherwise>
					</xsl:choose>
				</td>
			</tr>
			<tr>
				<th>Abweichender Empfänger:</th>
				<td>
					<xsl:value-of select="DivergentRecepient"/>
				</td>
			</tr>
			<tr>
				<th>Zahlungsdetails:</th>
				<td>
					<xsl:call-template name="outputText">
						<xsl:with-param name="text" select="PaymentDetails/PaymentDetail"/>
					</xsl:call-template>
					<xsl:call-template name="outputText">
						<xsl:with-param name="text" select="Usages/Usage"/>
					</xsl:call-template>
				</td>
			</tr>
			<tr>
				<th>IBAN:</th>
				<td>
					<xsl:value-of select="IBAN"/>
				</td>
			</tr>
			<xsl:if test="BIC">
				<tr>
					<th>BIC:</th>
					<td>
						<xsl:value-of select="BIC"/>
					</td>
				</tr>
			</xsl:if>
			<xsl:if test="CustomerRef">
				<tr>
					<th>Kundenreferenz:</th>
					<td>
						<xsl:value-of select="CustomerRef"/>
					</td>
				</tr>
			</xsl:if>
			<xsl:if test="MandantRef">
				<tr>
					<th>Mandatenreferenz:</th>
					<td>
						<xsl:value-of select="MandantRef"/>
					</td>
				</tr>
			</xsl:if>
			<xsl:if test="CreditorID">
				<tr>
					<th>Creditor ID:</th>
					<td>
						<xsl:value-of select="CreditorID"/>
					</td>
				</tr>
			</xsl:if>
			<xsl:if test="ExternalCosts">
				<tr>
					<th>Externe Kosten für den Bankvorgang:</th>
					<td>
						<xsl:value-of select="ExternalCosts"/>
					</td>
				</tr>
			</xsl:if>
			<xsl:if test="Amount">
				<tr>
					<th>Ursprünglicher Zahlungsbetrag:</th>
					<td>
						<xsl:value-of select="format-number(Amount,'#.#00,00','EU')"/>
					</td>
				</tr>
			</xsl:if>
			<xsl:if test="DebitAmount">
				<tr>
					<th>Zahlungseingang:</th>
					<td class="Money">
						<xsl:if test="number(DebitAmount)">
							<xsl:value-of select="format-number(DebitAmount,'#.#00,00','EU')"/>
							<xsl:text> </xsl:text>
							<xsl:value-of select="CurrencyUnit"/>
						</xsl:if>
					</td>
				</tr>
			</xsl:if>
			<xsl:if test="CreditAmount">
				<tr>
					<th>Zahlungsausgang:</th>
					<td class="Money">
						<xsl:if test="number(CreditAmount)">
							<xsl:value-of select="format-number(CreditAmount,'#.##0,00','EU')"/>
							<xsl:text> </xsl:text>
							<xsl:value-of select="CurrencyUnit"/>
						</xsl:if>
					</td>
				</tr>
			</xsl:if>
		</table>
	</xsl:template>

	<!--
	<xsl:template match="@*|node()" priority="-1">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
	-->

	<xsl:template name="outputText">
		<xsl:param name="text"/>

		<xsl:for-each select="$text">
			<xsl:choose>
				<xsl:when test="not(contains(., '&#xA;'))">
					<xsl:value-of select="."/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="substring-before(., '&#xA;')"/>
					<br/>
					<xsl:call-template name="outputText">
						<xsl:with-param name="text" select="substring-after(., '&#xA;')"/>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:if test="not(position()=last())">
				<br/>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="PaymentDetails"/>
	<xsl:template match="PaymentDetail"/>

</xsl:stylesheet>