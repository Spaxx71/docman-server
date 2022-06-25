<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="tenant" required="yes"/>

	<xsl:template match="/">
		<page>
			<body>
				<ul class="nav">
					<li>
						<a href="{$home-web-gui}/logout.html">Abmelden</a>
					</li>
					<li>
						<a href="{$home-web-gui}/{$tenant}/user/change-password.html">Passwort ändern</a>
					</li>
				</ul>
				<br/>
				<h3>Benuzer Details</h3>
				<xsl:apply-templates/>

			</body>
		</page>
	</xsl:template>
	
	<xsl:template match="User">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="Groups">
		Der Benuzer '<xsl:value-of select="../@id"/>' gehört zu folgenden Gruppen:
		<ul>
			<xsl:apply-templates/>
		</ul>
	</xsl:template>

	<xsl:template match="Group">
		<li>
			<xsl:value-of select="@id"/>
		</li>
	</xsl:template>

</xsl:stylesheet>