<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>             
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="year" required="yes"/>
	<xsl:param name="resource-id" select="''"/>

	<xsl:import href="templates/banking_templates.xsl"/>
	<xsl:import href="templates/analysis_templates.xsl"/>

	<xsl:template match="/">
		<page>
			<body>
				<h1>Übersicht aller Banken</h1>

				<h2>Übersicht aller Bankbewegungen</h2>
				<xsl:call-template name="BalanceGraph">
					<xsl:with-param name="Analysis" select="result/Analysis"/>
				</xsl:call-template>
				<br/>
				<br/>
				<h2>Übersicht aller Bankverbindungen</h2>

				<xsl:apply-templates/>
			</body>
		</page>
	</xsl:template>

	<xsl:template match="result">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="BankAccounts">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="BankAccount">
		<h3>Bankverbindung '<xsl:value-of select="@kto"/>'</h3>
		<ul class="Nav">
			<li>
				<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/banking/',@kto,'/index.html')}">Kontoauszug anzeigen…</a>
			</li>
			<xsl:if test="@hasOnlineBanking=true()">
				<li>
					<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/banking/',@kto,'/update.html')}">per Onlinebanking aktualisieren…</a>
				</li>
			</xsl:if>
			<li>
				<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/banking/',@kto,'/create-periodics.html')}">Daueraufträge zuordnen<br/>(Dokumente erstellen und verknüpfen)</a>
			</li>	
			<li>
				<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/banking/',@kto,'/attach.html')}">Bankbewegungen Automatching<br/>(mit Dokumenten verknüpfen)</a>
			</li>
			<li>
				<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/banking/',@kto,'/edit.html')}">Bankverbing bearbeiten</a>
			</li>
			<li>
				<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/banking/',@kto,'/periodic-payments.html')}">Übersicht aller Daueraufträge<br/>(mit diesem Bankkonto)</a>
			</li>
		</ul>
		<xsl:apply-templates/>
		<br/>
		<br/>
	</xsl:template>

	<xsl:template match="BankAccountDetail">
		<xsl:call-template name="BankAccountDetail">
			<xsl:with-param name="BankAccountDetail" select="."/>
		</xsl:call-template>
	</xsl:template>

</xsl:stylesheet>