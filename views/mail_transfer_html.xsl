<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:mail="http://exist-db.org/xquery/mail" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="home-data" required="yes"/>                
	<xsl:param name="home-views"/>                
	<xsl:param name="tenant" required="yes"/>
	
	<xsl:decimal-format name="european" decimal-separator="," grouping-separator="."/>

	<xsl:template match="/">
		<page>
			<head>
				<title>Mail Index</title>	
				<style>td { background-color: #eee; }</style>
			</head>
			<body>
				<xsl:apply-templates/>
			</body>
		</page>
	</xsl:template>

	<xsl:template match="result">
		<xsl:apply-templates/>
	</xsl:template>


	<xsl:template match="transfer">
		<div>Das Dokument "<xsl:value-of select="@document"/>" wurde <xsl:value-of select="@status"/> im Transfer hinterlegt.</div>
	</xsl:template>

</xsl:stylesheet>