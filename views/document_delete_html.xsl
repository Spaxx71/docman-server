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
			<div>Soll der Vorgang "<xsl:value-of select="Process/@name"/>" wirklich gelöscht werden?</div>
			<br/>
			<form action="{concat($home-web-gui,'/',$tenant,'/',$year,'/binders/',format-date(Process/@date,'[M00]'),'/',Process/@id,'/delete_response.html')}">
				  <input type="submit" value="Löschen" default="default"/>
				  <xsl:text>  </xsl:text>
			</form>
			<br/>

			<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/binders/',format-date(Process/@date,'[M00]'),'/index.html')}">Zurück zum Ablage-Ordner</a>
			<br/>

			<xsl:for-each select="Process//File">
				<iframe src="/app/{@src}" style="width:100%; height:500px;">
					<xsl:text> </xsl:text>
				</iframe>
			</xsl:for-each>
		</div>
	</xsl:template>

	<xsl:template match="@*|node()" priority="-1">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>