<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>             
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="year" required="yes"/>

	<xsl:template match="/">
		<page>
			<body>
				<h3>Dokumenenordner</h3>
				<ul>
					<xsl:for-each select="//Binders/Binder">
						<li>
							<a href="{$home-web-gui||'/'||$tenant||'/'||$year||'/binders/'||@name||'/index.html'}">
								<xsl:value-of select="@name"/>
							</a>
						</li>
					</xsl:for-each>
				</ul>
			</body>
		</page>
	</xsl:template>

	<xsl:template match="result"/>

	
</xsl:stylesheet>