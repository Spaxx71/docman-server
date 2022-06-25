<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="3.1">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="year" required="yes"/>
	<xsl:param name="binder"/>
	<xsl:param name="TimezoneOffset" required="yes"/>

	<!--
	<xsl:param name="attach"/>
	<xsl:param name="ref"/>
	-->

	<xsl:import href="templates/process-list.xsl"/>
	<xsl:variable name="is-search" select="true()"/>

	<xsl:variable name="attach" select="result/@attach"/>
	<xsl:variable name="ref" select="result/@ref"/>


	<xsl:template match="/">
		<page>
			<body>
				<h3>Suchergebnis</h3>

				<xsl:if test="/result/@owner != ''">
					Halter = <xsl:value-of select="/result/@owner"/>
				</xsl:if>
				<xsl:apply-templates/>
			</body>
		</page>
	</xsl:template>

	<xsl:template match="result">
		<xsl:choose>
			<xsl:when test="Process">
				<a href="{$home-web-gui||'/'||$tenant||'/'||$year||'/binders/'||Process/@binder||'/'||Process/@id||'/edit/'||replace(name(Process/Tasks/*[1]),'Task$','')||'.html'}{if ($attach) then '?attach='||$attach||'&amp;ref='||$ref else ''}">
					Vorgang: <xsl:value-of select="Process/@name"/>
				</a>
				<ul>
					<xsl:for-each select="/result/Process//File">
						<li>
							<a href="{$home-web-gui||'/'||@src}">
								Anhang: <xsl:value-of select="@fileName"/>
							</a>
						</li>
					</xsl:for-each>
				</ul>
			</xsl:when>
			<xsl:otherwise>		
				<xsl:apply-templates/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>


	<xsl:template match="Binders">
		<!-- <div style="background-color:#0CF">Ablage Ordner [<xsl:value-of select="@name"/>]:</div> -->
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="Accounts"/>
	<xsl:template match="Account"/>

</xsl:stylesheet>