<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="home-data" required="yes"/>                
	<xsl:param name="home-views"/>                
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="folder" required="yes"/>
	<xsl:param name="filename"/>
	
	<xsl:decimal-format name="european" decimal-separator="," grouping-separator="."/>

	<xsl:template match="/">
		<page>
			<body>
				<!--
				<ul class="nav">
					<li>
						<a href="{$home-web-gui}/{$tenant}/files/{$folder}/upload_file.html">Datei hochladen…</a>
					</li>
					<li>
						<a href="{$home-web-gui}/{$tenant}/files/{$folder}/upload_folder.html">Verzeichnis hochladen…</a>
					</li>
				</ul>
				-->
				<table>
					<tr>
						<th>#</th>
						<th>Dateiname</th>
						<th>Aktiviät</th>
						<th>Größe</th>
						<th>Erstellt</th>
					</tr>
					<xsl:apply-templates/>
				</table>			
			</body>
		</page>
	</xsl:template>

	<xsl:template match="CompanyPaperFiles">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="Files">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="File">
		<tr>
			<xsl:attribute name="class">
				<xsl:choose>
					<xsl:when test="count(preceding-sibling::*) mod 2 = 0">
						<xsl:text>even</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>odd</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>

			<td>
				<xsl:value-of select="count(preceding-sibling::File)+1"/>
			</td>
			<td>
				<a href="{$home-web-gui}/{$tenant}/files/{$folder}/{@name}">
					<xsl:value-of select="@name"/>
				</a>
			</td>
			<td>
				<ul class="nav">
					<xsl:if test="@size!=0">
						<li>
							<a href="{$home-web-gui}/{$tenant}/files/{$folder}/{@name}/rename.html">umbenennen…</a>
						</li>
					</xsl:if>

					<li>
						<!-- https://github.com/SauceCodeFr/RestfulizerJs -->
						<!-- <button onclick="deleteData('{$home-web-api}/{$tenant}/files/{$folder}/{@name}?display=html')">X</button> -->
						<!-- jquery rails -->
						<!-- <a data-confirm="Are you sure?" data-method="delete" href="{$home-web}/{$tenant}/{@name}" rel="nofollow">Löschen</a> -->
						<a href="{$home-web-gui}/{$tenant}/files/{$folder}/{@name}/delete.html">löschen…</a>
					</li>

				</ul>
			</td>
			<td style="text-align:right">
				<xsl:value-of select="format-number(@size,'###.##0', 'european')"/>
			</td>
			<td style="text-align:center"> 
				<xsl:value-of select="format-dateTime(@created,'[D01].[M01].[Y0001]')"/> 
			</td>
		</tr>
	</xsl:template>
</xsl:stylesheet>