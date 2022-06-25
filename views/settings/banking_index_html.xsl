<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>             
	<xsl:param name="tenant" required="yes"/>


	<xsl:template match="/">
		<page>
			<body>
				<h3>Übersicht Bankverbindungen von Tenant <xsl:value-of select="$tenant"/></h3>

				<xsl:apply-templates/>
			</body>
		</page>
	</xsl:template>

	<xsl:template match="result">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="BankAccounts">
		<xsl:for-each-group select="BankAccount" group-by="@year">
			<subtitle>
				<xsl:text>Jahr </xsl:text>
				<xsl:value-of select="current-grouping-key()"/>
				<xsl:text>:</xsl:text>
			</subtitle>
			<ul>
				<xsl:for-each select="current-group()">
					<li>
						<a href="{concat($home-web-gui,'/',$tenant,'/settings/banking/',@kto,'/edit.html?year=',current-grouping-key())}">
							<xsl:value-of select="BankAccountDetail/AccountName"/>
						</a>
					</li>
				</xsl:for-each>
			</ul>
		</xsl:for-each-group>
	</xsl:template>

	<xsl:template match="BankAccount"/>

	<xsl:template match="BankAccountDetail"/>

</xsl:stylesheet>