<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="home-data" required="yes"/>                
	<xsl:param name="home-views"/>                
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="year" required="yes"/>	
	<xsl:param name="filename"/>
	
	<xsl:template match="/">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="result">
		<div>
			<div>Das Dokument "<xsl:value-of select="@from"/>" wurde in "<xsl:value-of select="@to"/>" umbenannt.</div>
			<br/>
			<a href="{$home-web-gui}/{$tenant}/{$year}/transfer/index.html">Zurück zum Transfer-Ordner</a>
		</div>
	</xsl:template>

	<xsl:template match="@*|node()" priority="-1">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>