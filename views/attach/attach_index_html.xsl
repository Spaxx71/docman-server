<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:xf="http://www.w3.org/2002/xforms" version="3.1">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="home-data" required="yes"/>                
	<xsl:param name="home-views"/>                
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="year" required="yes"/>
	<xsl:param name="resource-id"/>
	<xsl:param name="ref"/>

	<xsl:param name="new-document" select="true()"/>

	<xsl:variable name="isReadonly" select="'true()'"/>

	<xsl:template match="/">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="result">
		<page>
			<body>
				<div class="TilesHeader">Allgemein:</div>
				<ul class="Tiles">
					<li class="Tile"><a href="../search.html?attach=Attachment&amp;ref={$ref}">Dokument Anhang</a></li>
				</ul>
				<div class="TilesHeader">Bestellung:</div>
				<ul class="Tiles">
					<li class="Tile"><a href="../search.html?attach=DeliveryNote&amp;ref={$ref}">Lieferschein</a></li>
					<li class="Tile"><a href="../search.html?attach=DunningFee&amp;ref={$ref}">Mahngebühr</a></li>
				</ul>
				<div class="TilesHeader">Ablage / Archiv:</div>
				<ul class="Tiles disabled">
					<li class="Tile"><a href="xxx.html?ref={$ref}">Vertrag</a></li>
				</ul>
				<div class="TilesHeader">Bank:</div>
				<ul class="Tiles">
					<li>
						<xsl:attribute name="class">
							<xsl:text>Tile </xsl:text>
							<xsl:choose>
								<xsl:when test="contains($ref, '/transfer/')">
									<!-- active -->
								</xsl:when>
								<xsl:otherwise>
									<xsl:text>disabled</xsl:text>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
						<a href="../search.html?attach=TransferVoucher&amp;ref={$ref}">Überweisungsbeleg / Zahlbeleg</a>
					</li>			
				</ul>
				<br/>
				<iframe src="/app/{$ref}" width="100%" height="550px"/>			
			</body>
		</page>
	</xsl:template>

</xsl:stylesheet>