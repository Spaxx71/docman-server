<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="home-views"/> 
	<xsl:param name="home-data"/>                
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="path" required="yes"/>
	<xsl:param name="username" required="yes"/>

	<xsl:template match="/">
		<page>
			<body>
				<xsl:apply-templates/>
		
		
				<h3>Jahresübersicht</h3>
				<ul>
					<xsl:for-each select="result/Years/Year">
						<li>
							<a href="{$home-web-gui||'/'||$tenant||'/'||text()||'/index.html'}">
								<xsl:value-of select="text()"/>
							</a>
						</li>
					</xsl:for-each>
				</ul>

				<h3>Unternehmensdokumente</h3>
				<ul>
					<xsl:for-each select="result/CompanyPaperFiles/CompanyPaperFile">
						<li>
							<a href="{$home-web-gui||'/'||$tenant||'/files/'||text()||'/index.html'}">
								<xsl:value-of select="text()"/>
							</a>
						</li>
					</xsl:for-each>
				</ul>

				<h3>Stammdaten Verwaltung</h3>
				<ul>
					<xsl:if test="$username=lower-case('eduard.huber') or $username=lower-case('extern.friederike.pfaffinger')">
						<li>
							<a href="{$home-web-gui||'/'||$tenant||'/settings/users/index.html'}">Benutzer</a>
						</li>
					</xsl:if>
				</ul>
			</body>
		</page>
	</xsl:template>

	<xsl:template match="node()" priority="-1"/>
	
</xsl:stylesheet>