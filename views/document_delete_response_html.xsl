<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="home-data" required="yes"/>                
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="year" required="yes"/>
	<xsl:param name="binder" required="yes"/>
	<xsl:param name="filename"/>

	<xsl:template match="/">
		<page>
			<body>
				<h3>Der Vorgang <xsl:value-of select="$filename"/> wurde erfolgreich gelöscht</h3>
				<xsl:apply-templates/>

				<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/binders/',$binder,'/index.html')}">Zurück zum Ablageordner</a>
			</body>
		</page>
	</xsl:template>

</xsl:stylesheet>