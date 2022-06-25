<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="home-data"/>                
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="resource-id" required="yes"/>
	<xsl:param name="year" required="yes"/>

	<xsl:import href="templates/banking_templates.xsl"/>

	<xsl:template match="/">
		<page>
			<body>
				<ul class="Nav">
					<li>
						<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/banking/',$resource-id,'/index.html')}">Kontoauzug ansehen…</a>
					</li>
				</ul>

				<h3>Bankverbindung per HBCI/Fin-TS aktualisieren</h3>

				<form action="{concat($home-web-gui,'/',$tenant,'/',$year,'/banking/',$resource-id,'/update.html')}">
					<label>Bankverbindung</label>
					<input type="text" name="bank-account" value="{$resource-id}"/>
					<br/>
					<label>Von Tag</label>
					<input type="date" name="from" value="{//Parameter/From}"/>
					<label>Bis Tag</label>
					<input type="date" name="till" value="{//Parameter/Till}"/>
					<br/>
					<input type="submit" name="refresh" value="Vorschau aktualisieren"/>
					<input type="submit" name="import" value="Auswahl importieren"/>
				</form>
				<xsl:apply-templates/>
			</body>
		</page>
	</xsl:template>

	<xsl:template match="result">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="FinTS">
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

	<xsl:template match="Parameter"/>

</xsl:stylesheet>