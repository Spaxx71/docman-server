<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="year" required="yes"/>

	<xsl:decimal-format name="EU" decimal-separator="," grouping-separator="."/>

	<xsl:template match="/">
		<html>
			<body>
				<h1>Kontenplan aktualisieren</h1>
				<div>Alle Salden des Kontenplan wurden aktualisiert.</div>
				<xsl:apply-templates/>
			</body>
		</html>
	</xsl:template>

</xsl:stylesheet>