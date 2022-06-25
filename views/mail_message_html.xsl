<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:mail="http://exist-db.org/xquery/mail" xmlns:my="http://localhost/my" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="home-data" required="yes"/>                
	<xsl:param name="home-views"/>                
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="year" required="yes"/>

	<xsl:decimal-format name="european" decimal-separator="," grouping-separator="."/>

	<xsl:template match="/">
		<page>
			<body>
				<xsl:apply-templates/>
			</body>
		</page>
	</xsl:template>

	<xsl:template match="result">
		<xsl:apply-templates/>
	</xsl:template>


	<xsl:template match="mail:messages">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="mail:message">
		<xsl:variable name="id" select="@number"/>
		<div>
			<label>Titel:</label>
			<span style="font-weight:600"><xsl:value-of select="mail:subject"/></span>
		</div>
		<div>
			<label>Empfangen:</label>
			<xsl:value-of select="format-dateTime(mail:received,'[D01].[M01].[Y0001] [H01]:[m01]')"/>
		</div>
		<div>
			<label>Gesendet:</label>
			<xsl:value-of select="format-dateTime(mail:sent,'[D01].[M01].[Y0001] [H01]:[m01]')"/>
		</div>
		<div>
			<label>Absender:</label>
			<xsl:value-of select="mail:from/text()"/>
		</div>
		<div>
			<label>Empfänger:</label>
			<xsl:for-each select="mail:recipients/mail:recipient">
				<xsl:value-of select="@type"/>
				<xsl:text>: </xsl:text>
				<xsl:value-of select="text()"/>
			</xsl:for-each>
		</div>
		<div>
			<label>Nachricht:</label>
			<xsl:choose>
				<xsl:when test="mail:xhtml">
					<iframe title="Email HTML Nachricht" srcdoc="{serialize(mail:xhtml/*)}" mime-type="{mail:xhtml/@mime-type}" height="350px" width="100%" sandbox="allow-same-origin">Can't show XHTML</iframe>
				</xsl:when>
				<xsl:when test="mail:text/text()">
					<iframe title="Email Text Nachricht" srcdoc="{my:replaceRC(mail:text/text())}" mime-type="{mail:text/@mime-type}" height="350px" width="100%" sandbox="allow-same-origin">Can't show Text</iframe>
				</xsl:when>
				<xsl:otherwise>
					Kein Text
				</xsl:otherwise>
			</xsl:choose>
		</div>
		<div>
			<label>Anhänge:</label>
			<xsl:choose>
				<xsl:when test="mail:attachment">
					<table>
						<tr>
							<th>Dateiname</th>
							<th>MIME Code</th>
							<th>Aktivität</th>
						</tr>
						<xsl:for-each select="mail:attachment">
							<xsl:variable name="name" select="replace(translate(replace(replace(@name,'\.PDF','.pdf'),'utf\-8',''),' ','_'),'[^A-Za-z0-9_#\.\-]','')"/>
							<tr>
								<td>
									<a href="{$home-web-gui}/{$tenant}/{$year}/mail/{$id}/attachment/{position()}/{$name}">
										<xsl:value-of select="$name"/>
									</a>
								</td>
								<td>
									<xsl:value-of select="@mime-type"/>
								</td>
								<td>
									<ul class="nav">
										<li>
											<a href="{$home-web-gui}/{$tenant}/{$year}/binders/enter/index.html?ref=/{$tenant}/{$year}/mail/{$id}/attachment/{position()}/{$name}">Abheften</a>
										</li>
										<li>
											<a href="{$home-web-gui}/{$tenant}/{$year}/mail/{$id}/attachment/{position()}/transfer.html">In Transfer ablegen</a>
										</li>
									</ul>
								</td>
							</tr>
						</xsl:for-each>
					</table>
				
					<!--
					<h3>Preview (nur von PDF "application/pdf" Anhängen)</h3>
					<xsl:for-each select="mail:attachment[@mime-type='application/pdf']">
						<label>
							<a href="attachment.xml?id={$id}">
								<xsl:value-of select="@name"/>
								<xsl:text>:</xsl:text>
							</a>
						</label>
						<iframe src="{$home-web-gui}/{$tenant}/mail/attachment.xml?id={$id}&amp;number={position()}" mime-type="{mail:text/@mime-type}" width="100%" height="500px" name="iFrame" title="Preview of attachment"> </iframe>
					</xsl:for-each>
					-->
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>Nicht vorhanden</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</div>
	</xsl:template>


	<xsl:function name="my:replaceRC">
		<xsl:param name="string"/>

		<div>
			<xsl:call-template name="replace">
				<xsl:with-param name="string" select="$string"/>
			</xsl:call-template>
		</div>
	</xsl:function>


<xsl:template name="replace">
    <xsl:param name="string"/>

    <xsl:choose>
        <xsl:when test="contains($string,'&#xA;')">
            <xsl:value-of select="substring-before($string,'&#xA;')"/>
            <br/>
            <xsl:call-template name="replace">
                <xsl:with-param name="string" select="substring-after($string,'&#xA;')"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$string"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

</xsl:stylesheet>