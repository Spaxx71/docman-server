<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="tenant" required="yes"/>

	<xsl:template match="/">
		<page>
			<head>
				<title>Übersicht User</title>
			</head>
			<body>
				<h3>Übersicht aller Benutzer der Tenant-Gruppe '<xsl:value-of select="/result/Users/@group"/>'</h3>
				<xsl:apply-templates/>
			</body>
		</page>
	</xsl:template>
	
	<xsl:template match="Users">
		<ul class="nav">
			<xsl:apply-templates/>
		</ul>
	</xsl:template>

	<xsl:template match="User">
		<li>
			<a href="{$home-web-gui}/{$tenant}/settings/users/{@id}/index.html">
				<xsl:value-of select="@id"/>
				<!--
				<br/>
				<xsl:text>"</xsl:text>
				<xsl:value-of select="Name"/>
				<xsl:text>"</xsl:text>
				<br/>
				<xsl:value-of select="Description"/>
				-->
			</a>
		</li>
	</xsl:template>
</xsl:stylesheet>