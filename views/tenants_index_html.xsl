<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="tenant" required="yes"/>


	<xsl:template match="/">
		<page>
			<body>
				<h3>Übersicht der Mandanten</h3>
				<xsl:apply-templates/>
			</body>
		</page>
	</xsl:template>

	<xsl:template match="Tenants">
		<ul>
			<xsl:apply-templates>
				<xsl:sort select="number(@priority)" order="ascending"/>
			</xsl:apply-templates>
		</ul>
	</xsl:template>

	<xsl:template match="Tenant">
		<li>
			<a href="{concat($home-web-gui,'/',@id,'/index.html')}"><xsl:value-of select="Name"/></a>
			<!-- [<xsl:value-of select="@priority"/>] -->
		</li>
	</xsl:template>

</xsl:stylesheet>