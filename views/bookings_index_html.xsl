<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="year" required="yes"/>

	<xsl:decimal-format name="EU" decimal-separator="," grouping-separator="."/>

	<xsl:template match="/">
		<html>
			<body>
				<h1>Verbuchung aller Geschäftsvorfälle</h1>
				<ul>
					<li>
						<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/bookings/accounts.html')}">Hauptbuch</a>
					</li>
					<li>
						<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/bookings/sheet.html')}">Bilanz (Vor)Ansicht</a>
					</li>
					<li>
						<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/bookings/refresh.html')}">Summen &amp; Salden aktualisieren</a>
					</li>					
				</ul>
				<xsl:apply-templates/>
			</body>
		</html>
	</xsl:template>

</xsl:stylesheet>