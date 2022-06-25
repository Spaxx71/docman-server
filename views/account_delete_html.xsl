<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="home-views"/> 
	<xsl:param name="home-data"/>                
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="resource-id" required="yes"/>


	<xsl:template match="/">
		<html xmlns="http://www.w3.org/1999/xhtml">
			<head>
				<title>Delete account</title>
				<meta http-equiv="refresh" content="10; URL={$home-web-gui}/{$tenant}/accounts/index.html"/>
			</head>
			<body>
				<xsl:apply-templates/>

				<ul class="nav">
					<li>
						<a href="{$home-web-gui}/{$tenant}/accounts/index.html">zurück zur Kreditoren/Debitoren Übersicht</a>
					</li>
				</ul>
			</body>
		</html>
	</xsl:template>

</xsl:stylesheet>