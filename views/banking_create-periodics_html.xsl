<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="year" required="no"/>
	<xsl:param name="resource-id" required="no"/>

	<xsl:decimal-format name="EU" decimal-separator="," grouping-separator="."/>

	<!-- same result as /exist-backend/rest/db/apps/docman/modules/functions/automatic/automatic_periodic-payments.xqy -->

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
		Name: <xsl:value-of select="@name"/><br/>
		ID: <xsl:value-of select="@id"/><br/>
		Buchungskonto: <xsl:value-of select="@kto"/><br/>
		IBAN: <xsl:value-of select="@iban"/><br/>
		<br/>
		<xsl:apply-templates/>
		<br/>
		<br/>
	</xsl:template>


	<xsl:template match="Process">
		<subtitle>Wiederkehrende Kosten (per Bankeinzug)</subtitle>
		<table>
			<tr>
				<th>Datum:</th>
				<td>
					<xsl:value-of select="format-date(Tasks/InvoiceInTask/@date,'[D00].[M00].[Y0000]')"/>
				</td>
			</tr>
			<tr>
				<th>Zahlungsempfänger:</th>
				<td>
					<xsl:value-of select="../Account/Name"/>
					(<xsl:value-of select="Tasks/InvoiceInTask/Owner"/>)
				</td>
			</tr>
			<tr>
				<th>Betrag:</th>
				<td>
					<xsl:value-of select="Tasks/InvoiceInTask/Amount/@value"/>
				</td>
			</tr>
			<tr>
				<th>Inhalt:</th>
				<td>
					<xsl:value-of select="Tasks/InvoiceInTask/Description"/>
				</td>
			</tr>
			<tr>
				<th>Zahlungsdetails:</th>
				<td>
					<xsl:value-of select="Tasks/PaymentTask/Description"/>
				</td>
			</tr>
		</table>
	</xsl:template>

	<xsl:template match="Account"/>

	<xsl:template match="error">
		<div style="color:red">
			<xsl:apply-templates/>
		</div>
	</xsl:template>

</xsl:stylesheet>