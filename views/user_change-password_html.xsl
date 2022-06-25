<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>            
	<xsl:param name="tenant" required="yes"/>

	<xsl:template match="/">
		<page>
			<body>
				<form action="{$home-web-gui}/{$tenant}/user/change-password_response.html" method="post">
					<label>Neues Passwort</label>
					<input type="password" name="password" minlength="6" maxlength="12" pattern="[A-Za-z0-9#_-]+"/>
					<br/>
					<label>Neues Passwort (Wiederholung)</label>
					<input type="password" name="password2" minlength="6" maxlength="12" pattern="[A-Za-z0-9#_-]+"/> 
					<br/>
					<input type="submit" name="Passwort ändern"/>
				</form>
			</body>
		</page>
	</xsl:template>

</xsl:stylesheet>