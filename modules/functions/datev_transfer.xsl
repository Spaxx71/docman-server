<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">
	<!-- http://localhost:8080/exist/apps/docman/bix/transfer/DTVF_Buchungsstapel_20200331_153741_00005.csv/datev_import.html -->

	<xsl:param name="home-data" required="yes"/>
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="filename" required="yes"/>
	<xsl:variable name="Year" select="substring(Records/Record[1]/WKZ-Basis-Umsatz,1,4)"/>

	<xsl:template match="/">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="Records">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="Record">
		<xsl:variable name="Month" select="substring(Belegdatum,3,2)"/>
		<xsl:variable name="Day" select="substring(Belegdatum,1,2)"/>

<!--
		<xsl:result-document href="xmldb:exist://{$home-data}/{$tenant}/{$Year}/{$Day}/$filename" method="xml">
			<Document name="{currentDate()}" created="{currentDate()}">

				<Section/>
				<Accountings>
					<Accounting created="{currentDate()}" date="{$Year}-{$Month}-{$Day}" booktype="{SH-Kennzeichen}">
						<From account="{Konto}" amount="{translate(Umsatz,',','.')}" unit="EUR"/>
						<To account="{Gegenkonto}" amount="{translate(Umsatz,',','.')}" unit="EUR"/>
						<Tax percent="7" amount="{translate(EU-Steuersatz,',','.')}" unit="EUR"/>
						<Description>{Buchungstext}</Description>
					</Accounting>
				</Accountings>
				<Files>
				</Files>
				<Notes/>

			</Document>
      		</xsl:result-document>
-->
	</xsl:template>

</xsl:stylesheet>