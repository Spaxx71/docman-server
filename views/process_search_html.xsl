<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="3.1">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="home-data" required="yes"/>                
	<xsl:param name="home-views"/>                
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="year" required="yes"/>
	<xsl:param name="binder"/>
	<xsl:param name="filename"/>
	<xsl:param name="TimezoneOffset" required="yes"/>

	<xsl:import href="templates/process-list.xsl"/>

	<xsl:variable name="is-search" select="false()"/>	
	<xsl:variable name="attach"/>
	<xsl:variable name="ref"/>

	<xsl:template match="/">
		<page>
			<body>
				<ul class="nav">
					<li>
						xxx
					</li>
				</ul>
				<xsl:apply-templates/>
			</body>
		</page>
	</xsl:template>

	<xsl:template match="Booking">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="Documents">
		<xsl:apply-templates>
			<xsl:sort select="@date"/>
		</xsl:apply-templates>
	</xsl:template>

	<xsl:template match="Accounts"/>

	<xsl:template match="Account"/>

</xsl:stylesheet>