<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="type" required="yes"/>
	<xsl:param name="year" required="yes"/>

	<xsl:variable name="accountings" select="result/Accountings"/>

	<xsl:decimal-format name="EU" decimal-separator="," grouping-separator="."/>

	<xsl:template match="/">
		<html>
			<head>
				<title>Übersicht der Budget-Kategorien von "<xsl:value-of select="@tenantId"/>"</title>
			</head>
			<body>
				<xsl:apply-templates/>
				<br/>
				<ul class="Nav">
					<li>
						<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/categories/edit.html')}">Budget-Kategorien bearbeiten</a>
					</li>
				</ul>
			</body>
		</html>
	</xsl:template>

	<xsl:template match="result">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="BudgetCategories">
		<h1>Übersicht der Budget-Kategorien der Domäne '<xsl:value-of select="@domain"/>'</h1>
		<ol>
			<xsl:apply-templates/>
		</ol>
	</xsl:template>

	<xsl:template match="BudgetCategory">
		<li>
			<span><xsl:value-of select="@name"/></span>
			<span> [<xsl:value-of select="@id"/>]</span>
		</li>
	</xsl:template>

</xsl:stylesheet>