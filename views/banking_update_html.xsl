<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="home-data"/>                
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="resource-id" required="yes"/>
	<xsl:param name="year" required="yes"/>
	<xsl:param name="from" required="no"/>
	<xsl:param name="till" required="no"/>
	<xsl:param name="bank-account" required="no"/>
	<xsl:param name="import" required="no"/>

	<xsl:import href="templates/banking_templates.xsl"/>

	<xsl:template match="/">
		<page>
			<body>
				<ul class="Nav">
					<li>
						<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/banking/',$resource-id,'/index.html')}">Kontoauzug ansehen…</a>
					</li>
				</ul>

				<h3>Bankverbindung per HBCI+/FinTS aktualisieren</h3>

				<xsl:apply-templates/>
				
				<!--
				<form action="{concat($home-web-gui,'/',$tenant,'/',$year,'/banking/',$resource-id,'/update-process.html')}">
					<label>Bankverbindung</label>
					<input type="text" name="bank-account" value="{$resource-id}"/>
					<br/>
					<label>Von Tag</label>
					<input type="date" name="from" value="{//Parameter/From}"/>
					<label>Bis Tag</label>
					<input type="date" name="till" value="{//Parameter/Till}"/>
					<br/>
					<input type="submit" name="refresh" value="Vorschau aktualisieren"/>
					<input type="submit" name="import" value="Auswahl importieren"/>
				</form>
				-->
	
				<div xmlns="http://www.w3.org/1999/xhtml" id="post-section" style="background-color: #eee;">
					<h3>HBCI+/FinTS Meldungen:</h3><a href="{concat($home-web-api,'/',$tenant,'/hbci/',$resource-id,'/get-messages-from-hbci.json')}" target="_blank">Liste aller Meldugen</a>
					<div id="hbci-message-container" style="height:10rem; overflow-y: scroll; border: 1px solid #444; padding: 5px;"/>
					
					<!-- <script>
						function setFocusOnDivWithId(elementId) {
							const scrollIntoViewOptions = { behavior: "smooth", block: "center" };
							document.getElementById(elementId).scrollIntoView(scrollIntoViewOptions);
						}; 
						setFocusOnDivWithId('hbci-message-container');
					</script>
					-->
					<script type="text/javascript" src="/app/resources/active.js"> </script>
					<script type="text/javascript">
						window.setInterval(function() {
							var elem = document.getElementById('hbci-message-container');
							elem.scrollTop = elem.scrollHeight;
						}, 5000);
					</script>
					<script>
						<xsl:text> window.setInterval(function() {</xsl:text>
						<xsl:text>listMessages('</xsl:text>
						<xsl:value-of select="$home-web-api"/>
						<xsl:text>/</xsl:text>
						<xsl:value-of select="$tenant"/>
						<xsl:text>/hbci/</xsl:text>
						<xsl:value-of select="$resource-id"/>
						<xsl:text>/get-messages-from-hbci.json', 'hbci-message-container');</xsl:text>
						<xsl:text>}, 1000);</xsl:text>
					</script>

					<form action="{concat($home-web-api,'/',$tenant,'/hbci/',/result/Parameter/BankAccount,'/send-message-to-hbci.json')}" method="post" target="_blank">
						<label>Benutzereingabe</label>
						<input type="text" name="input"/>
						<input type="submit" name="send" value="Senden"/>
					</form>
				</div>

				<xsl:choose>
					<xsl:when test="$from != ''">
						<iframe src="{concat($home-web-gui,'/',$tenant,'/',$year,'/banking/',$resource-id,'/update-process.html?bank-account=',$bank-account,'&amp;from=',$from,'&amp;till=',$till,'&amp;import=',$import)}" title="description" style="width:100%;height:80%;"/>
					</xsl:when>
					<xsl:otherwise>
						<iframe src="{concat($home-web-gui,'/',$tenant,'/',$year,'/banking/',$resource-id,'/update-process.html')}" title="description" style="width:100%;height:80%;"/> 
					</xsl:otherwise>
				</xsl:choose>

			</body>
		</page>
	</xsl:template>

	<xsl:template match="result">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="FinTS">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="BankAccounts">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="BankAccount">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="BankAccountDetail">
		<xsl:call-template name="BankAccountDetail">
			<xsl:with-param name="BankAccountDetail" select="."/>
		</xsl:call-template>
		<br/>
	</xsl:template>

	<xsl:template match="Parameter"/>

</xsl:stylesheet>