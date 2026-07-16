<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:math="http://www.w3.org/2005/xpath-functions/math" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>             
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="year" required="yes"/>
	<xsl:param name="username" required="yes"/>

	<xsl:import href="templates/analysis_templates.xsl"/>

	<xsl:template match="/">
		<page>
			<body>
				<h1>Übersicht Validierungsergebnisse</h1>
				<br/>
				<br/>
				<xsl:apply-templates/>
			</body>
		</page>
	</xsl:template>

	<xsl:template match="result">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="ValidateSchema">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="Collections">
		<xsl:apply-templates/>
		<br/>
		<br/>
		<br/>
	</xsl:template>

	<xsl:template match="Collection">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="Accounts">
		<h2>Buchungs-Konten</h2>
		Anzahl der Buchungs-Konten: <xsl:value-of select="@count"/>

		<xsl:choose>
			<xsl:when test="report/status != 'valid'">
				<h4>Chrosscheck Fehler - über alle Accouts hinweg:</h4>
				<error>Schema Fehler / Ungültige Identifier / Fehlerhafte Datenstruktur:<br/>
					<xsl:for-each select="report/message">
						<xsl:value-of select="text()"/>
						<br/>
					</xsl:for-each>
				</error>
			</xsl:when>
			<xsl:otherwise>
				<!-- nothing to do -->
				<xsl:apply-templates/>
			</xsl:otherwise>
		</xsl:choose>
		<br/>
		<br/>
		<br/>
	</xsl:template>

	<xsl:template match="Account">
		<xsl:choose>
			<xsl:when test="report/status = 'valid'">
				<!-- nothing to do -->
			</xsl:when>
			<xsl:when test="report/status != 'valid'">
				<h4>Konto '<xsl:value-of select="@id"/>' / <xsl:value-of select="@kto"/> - hat ein Problem:</h4>
				<error>Schema Fehler / Fehlerhafte Datenstruktur:<br/>
					<xsl:for-each select="report/message">
						<xsl:value-of select="text()"/>
						<br/>
					</xsl:for-each>
				</error>
			</xsl:when>
			<xsl:otherwise>
				<h3>Konto '<xsl:value-of select="@id"/> / <xsl:value-of select="@kto"/></h3>
				<error>Es gab einen nicht definierten Fehler:<br/>
					<xsl:value-of select="*"/>
				</error>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="BudgetCategories">
		<h2>Budget-Kategorien</h2>
		Anzahl der Budget-Kategorien: <xsl:value-of select="@count"/>

		<xsl:choose>
			<xsl:when test="report/status != 'valid'">
				<h4>Chrosscheck Fehler - über alle Accouts hinweg:</h4>
				<error>Schema Fehler / Ungültige Identifier / Fehlerhafte Datenstruktur:<br/>
					<xsl:for-each select="report/message">
						<xsl:value-of select="text()"/>
						<br/>
					</xsl:for-each>
				</error>
			</xsl:when>
			<xsl:otherwise>
				<!-- nothing to do -->
				<xsl:apply-templates/>
			</xsl:otherwise>
		</xsl:choose>
		<br/>
		<br/>
		<br/>
	</xsl:template>

	<xsl:template match="BankAccounts">
		<h2>Bank Konten</h2>
		Anzahl der Bank-Konten: <xsl:value-of select="@count"/>
		<xsl:apply-templates/>
		<br/>
	</xsl:template>

	<xsl:template match="BankAccount">
		<xsl:choose>
			<xsl:when test="report/status = 'valid'">
				<!-- nothing to do -->
			</xsl:when>
			<xsl:when test="report/status != 'valid'">
				<h4>Bank Konto '<xsl:value-of select="@bank-account-id"/>' - hat ein Problem:</h4>
				<error>Schema Fehler / Fehlerhafte Datenstruktur:<br/>
					<xsl:for-each select="report/message">
						<xsl:value-of select="text()"/>
						<br/>
					</xsl:for-each>
				</error>
			</xsl:when>
			<xsl:otherwise>
				<h4>Bank Konto '<xsl:value-of select="@bank-account-id"/>' - hat ein Problem:</h4>
				<error>Es gab einen nicht definierten Fehler:<br/>
					<xsl:value-of select="*"/>
				</error>
			</xsl:otherwise>
		</xsl:choose>
		<br/>
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="Processes">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="Binders">
		<h2>Dokumentenablagen</h2>
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="Binder">
		<h3>Dokumentenablage '<xsl:value-of select="@name"/>' (mit <xsl:value-of select="count(Process)"/> Vorgängen)</h3>
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="Process">
		<xsl:choose>
			<xsl:when test="report/status = 'valid'">
				<!-- nothing to do -->
			</xsl:when>
			<xsl:when test="report/status != 'valid'">
				<h4>Vorgang '<xsl:value-of select="@name"/>' - hat ein Problem:</h4>
				<error>Schema Fehler / Fehlerhafte Datenstruktur:<br/>
					<xsl:for-each select="report/message">
						<xsl:value-of select="text()"/>
						<br/>
					</xsl:for-each>
				</error>
			</xsl:when>
			<xsl:otherwise>
				<h3>Vorgang '<xsl:value-of select="@name"/></h3>
				<error>Es gab einen nicht definierten Fehler:<br/>
					<xsl:value-of select="*"/>
				</error>
			</xsl:otherwise>
		</xsl:choose>	
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="node()|@*" priority="-1"/>
</xsl:stylesheet>