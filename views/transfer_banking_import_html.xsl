<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="home-data" required="yes"/>                
	<xsl:param name="home-views"/>                
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="year" required="yes"/>
	<xsl:param name="resource-id" required="yes"/>

	<xsl:import href="templates/banking_templates.xsl"/>

	<xsl:template match="/"> 
		<page>
			<head>
				<style>
					label {{
						display:inline-block;
						min-width:20ex;
					}}
					select[name='period'] {{
						min-width:40ex;
					}}

					select[name='account'] {{
						min-width:40ex;
					}}
				</style>
			</head>
			<body>
				<div>
					<h3>Kontoauszug <xsl:value-of select="$resource-id"/> importieren</h3>

					<xsl:choose>
						<xsl:when test="//import/@status">
							<xsl:text>Import der Bankbewebungen </xsl:text>
							<xsl:choose>
								<xsl:when test="//import[not(@status!='fine')]">
									<xsl:text>erfolgreich</xsl:text>
								</xsl:when>
								<xsl:otherwise>
									<xsl:text>mit Fehlern</xsl:text>
								</xsl:otherwise>
							</xsl:choose>
							<xsl:text> abgeschlossen.</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<form action="{$home-web-gui}/{$tenant}/{$year}/transfer/{$resource-id}/banking_import.html">
								<label>Von</label>
								<input type="date" name="from" value="{//Parameter/From/text()}"/>
								<label>bis</label>
								<input type="date" name="till" value="{//Parameter/Till/text()}"/>
								<br/>

								<label>Konto für Import</label>
								<select name="bank-account">
									<xsl:for-each select="result/BankAccounts/BankAccount/@kto">
										<option value="{.}"><xsl:value-of select="AccountNick"/> (<xsl:value-of select="."/>)</option>
									</xsl:for-each>
								</select>
								<br/>
								<input type="submit" name="refresh" value="Ansicht aktualisieren"/>
								<input type="submit" name="import" value="Auswahl importieren"/>
							</form>
							<xsl:apply-templates/>
						</xsl:otherwise>
					</xsl:choose>
				</div>
			</body>
		</page>
	</xsl:template>

	<xsl:template match="result">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="Preview">
		<h3>Preview der zu importierenden Kontobewegungen:</h3>
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="BankingStatement">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="BankingAccounts">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="BankingAccount">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="Preview/BankAccountDetail">
		<xsl:call-template name="BankAccountDetail">
			<xsl:with-param name="BankAccountDetail" select="."/>
		</xsl:call-template>
		<br/> 
	</xsl:template>

	<xsl:template match="BankAccountDetail" priority="-1">
		<!-- ignore all other banking accounts -->
	</xsl:template>

	<xsl:template match="Parameter"/>

</xsl:stylesheet>