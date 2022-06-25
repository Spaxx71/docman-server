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
			<div>Soll die Datei "<xsl:value-of select="@file"/>" wirklich gelöscht werden?</div>
			<br/>
			<form action="{concat($home-web-gui,'/',$tenant,'/',$year,'/transfer/',@file,'/delete_response.html')}">
				  <input type="submit" value="Löschen" default="default"/>
				  <xsl:text>  </xsl:text>
			</form>
			<br/>

			<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/transfer/index.html')}">Zurück zum Transfer-Ordner</a>
			<br/>

			<iframe src="{concat($home-web-gui,'/',$tenant,'/',$year,'/transfer/',@file)}" style="width:100%; height:500px;">
				<xsl:text> </xsl:text>
			</iframe>
		</div>
	</xsl:template>

	<xsl:template match="@*|node()" priority="-1">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>