<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:mail="http://exist-db.org/xquery/mail" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="home-data" required="yes"/>                
	<xsl:param name="home-views"/>                
	<xsl:param name="tenant" required="yes"/>
	
	<xsl:decimal-format name="european" decimal-separator="," grouping-separator="."/>

	<xsl:template match="/">
		<page>
			<head>
				<style>td { background-color: #eee; }
					.unread {
						font-weight: bold;
					}
					.flagged {
						background-color: orange;
					}
				</style>
			</head>
			<body>
				<!--
				<ul class="nav">
					<li>
						<a href="{$home-web-gui}/{$tenant}/mail/xxx.html">xxx</a>
					</li>
					<li>
						<a href="{$home-web-gui}/{$tenant}/mail/xxx.html">xxx</a>
					</li>
				</ul>
				-->
				<table>
					<tr>
						<th>#</th>
						<th>Titel</th>
						<th>Absender</th>
						<th>Gesendet</th>
						<th>Empfangen</th>
						<th>Status</th>
					</tr>
					<xsl:apply-templates/>
				</table>
			</body>
		</page>
	</xsl:template>

	<xsl:template match="result">
		<xsl:apply-templates/>
	</xsl:template>


	<xsl:template match="mail:messages">
		<xsl:apply-templates>
			<xsl:sort select="@number" lang="de" data-type="number" order="descending"/>
		</xsl:apply-templates>
	</xsl:template>

	<xsl:template match="mail:message">
		<tr>
			<xsl:if test="not('seen' = mail:flags/mail:flag/@type)">
				<xsl:attribute name="class">unread</xsl:attribute>
			</xsl:if>
			<td><xsl:value-of select="@number"/></td>
			<td><a href="message.html?number={@number}"><xsl:value-of select="mail:subject"/></a></td>
			<td><a href="mailto:{mail:from/text()}"><xsl:value-of select="mail:from/@personal"/><xsl:value-of select="mail:from/text()"/></a></td>
			<!--
			<td>
				<xsl:for-each select="mail:recipients/mail:recipient">
					<xsl:value-of select="@type"/>
					<xsl:text>:&#160;</xsl:text>
					<xsl:value-of select="."/>
					<br/>
				</xsl:for-each>
			</td>
			-->
			<td><xsl:value-of select="format-dateTime(mail:received,'[D01].[M01].[Y0001] [H01]:[m01]')"/></td>
			<td><xsl:value-of select="format-dateTime(mail:sent,'[D01].[M01].[Y0001] [H01]:[m01]')"/></td>
			<td>
				<xsl:if test="'flagged' = mail:flags/mail:flag/@type">
					<xsl:attribute name="class">flagged</xsl:attribute>
				</xsl:if>
				<xsl:value-of select="mail:flags/mail:flag/@type"/>
			</td>
		</tr>
	</xsl:template>
</xsl:stylesheet>