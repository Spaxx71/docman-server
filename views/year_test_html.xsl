<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:math="http://www.w3.org/2005/xpath-functions/math" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>             
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="year" required="yes"/>

	<xsl:import href="templates/analysis_templates.xsl"/>

	<xsl:template match="/">
		<page>
			<body>
				<ul class="nav">
					<li>
						<a href="{$home-web-gui}/{$tenant}/{$year}/binders/enter/index.html">Neues Dokument</a>
					</li>
				</ul>

				<h3>Übersicht Opos</h3>
				<xsl:apply-templates select="result/Dashboard"/>
				<br/>
				<br/>
			</body>
		</page>
	</xsl:template>

	<xsl:template match="result"/>

	<xsl:template match="Dashboard">
		<xsl:variable name="Segments">
			<Segments>
				<Segment index="1" percent="{OverallCount/Mapped * 100 div OverallCount/@count}" name="Vollständig verbucht"/>
				<Segment index="2" percent="{OverallCount/DocumentsOpen * 100 div OverallCount/@count}" name="Vorgänge ohne Verknüpfung"/>
				<Segment index="3" percent="{OverallCount/BankingsOpen * 100 div OverallCount/@count}" name="Bankbewegungen ohne Verknüpfung"/>
				<Segment index="4" percent="{OverallCount/Transfer * 100 div OverallCount/@count}" name="Neuzugang Transfer Ordner"/>
				<Segment index="5" percent="{OverallCount/Email * 100 div OverallCount/@count}" name="Neuzugang Email"/>
			</Segments>
		</xsl:variable>
		<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" id="head" version="1.1" font-family="Helvetica, Arial" width="750" height="424">

			<style id="styles" type="text/css"> <![CDATA[
			.series-areas-general {
				stroke-width: 0;
			}
			#segment1,
			#legend-area1 {
				fill: rgb(0, 192, 0);
			}
			#segment2,
			#legend-area2 {
				fill: rgb(255, 204, 80);
			}
			#segment3,
			#legend-area3 {
				fill: rgb(255, 204, 170);
			}
			#segment4,
			#legend-area4 {
				fill: rgb(255, 100, 0);
			}
			#segment5,
			#legend-area5 {
				fill: rgb(192, 64, 0);
			}
			]]>
			</style>

			<style id="styles" type="text/css"> <![CDATA[
			.legendbox {
				stroke:       black;
				stroke-width: 1;
				fill:         white;
			}
			.legendtext {
				font-size:   15px;
				text-anchor: start;
			}
			]]>
			</style>

			<!-- Tortendiagram -->
			<g id="segments" class="series-areas-general"> <!-- transform="scale(1, 1) translate(12, -412)" -->

				<xsl:for-each select="$Segments/Segments/Segment">
					<xsl:call-template name="pie">
						<xsl:with-param name="index" select="@index"/>
						<xsl:with-param name="percentStart" select="sum(preceding-sibling::Segment/@percent)"/>
						<xsl:with-param name="percent" select="@percent"/>
					</xsl:call-template>
				</xsl:for-each>
			</g>

			<!-- Legende -->
			<g id="legend" transform="translate(280, 52)">
				<rect id="legend-background" class="legendbox" x="0" y="0" width="370" height="{count($Segments/Segments/Segment) * 20 + 15}"/>

				<xsl:for-each select="$Segments/Segments/Segment">
					<rect id="legend-area{@index}" class="series-area" x="10" y="{-10 + (20 * @index)}" width="30" height="15"/>
					<text id="legend-text{@index}" class="legendtext" x="50" y="{(20 * @index)}"><xsl:value-of select="@name"/>  (<xsl:value-of select="format-number(@percent,'0.00')"/>%)</text>
				</xsl:for-each>
			</g>
		</svg>
	</xsl:template>

	<xsl:template name="pie">
		<xsl:param name="radius" select="100"/>
		<xsl:param name="index" required="yes"/>
		<xsl:param name="percentStart" required="yes"/>
		<xsl:param name="percent" required="yes"/>
		<xsl:variable name="angS" select="2 * math:pi() * $percentStart div 100"/>
		<xsl:variable name="angE" select="2 * math:pi() * $percent div 100"/>

		<xsl:variable name="centre" select="120"/>
		
		<xsl:variable name="largeArcFlag">
			<xsl:choose>
				<xsl:when test="$angE + $angS &gt; 180">
					<xsl:value-of select="1"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="0"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<!-- <text x="100" y="{100+$index*20}">[<xsl:value-of select="$percentStart"/>|<xsl:value-of select="$percent"/>]</text>  -->
		<!-- rotate() -->
		<path id="segment{$index}" class="segment" transform="translate({$centre} {$centre}) rotate({360 * $percentStart div 100})" d="M {$radius},0 A {$radius},{$radius} 0 {$largeArcFlag} 1 {xs:integer(math:cos($angE) * $radius)},{xs:integer(math:sin($angE) * $radius)} L 0,0 z"/>

		<text transform="translate({$centre} {$centre})" text-anchor="middle" x="{xs:integer(math:cos($angS + $angE div 2) * $radius div 1.6)}" y="{xs:integer(math:sin($angS + $angE div 2) * $radius div 1.6)}"><xsl:value-of select="format-number($percent,'0.00')"/>%</text>

	</xsl:template>
	
	<xsl:template match="node()|@*" priority="-1"/>
</xsl:stylesheet>