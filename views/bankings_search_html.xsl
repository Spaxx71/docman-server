<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>             
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="year" required="yes"/>
	<xsl:param name="resource-id" select="''"/>

	<xsl:import href="templates/banking_templates.xsl"/>

	<xsl:template match="/">
		<page>
			<body>
				<h3>Suche in Bankbewegungen</h3>

				<xsl:apply-templates/>
			</body>
		</page>
	</xsl:template>

	<xsl:template match="result">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="BankAccounts">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="BankAccount">
		<xsl:if test="exists(Accountings/*)">
			<div>
				<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/banking/',@kto,'/index.html')}">Konto <xsl:value-of select="@kto"/>:</a>
			</div>
			<xsl:apply-templates/>
			<br/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="BankAccountDetail">
		<xsl:call-template name="BankAccountDetail">
			<xsl:with-param name="BankAccountDetail" select="."/>
		</xsl:call-template>
		<br/>
	</xsl:template>

</xsl:stylesheet>