<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:fox="http://xml.apache.org/fop/extensions" version="3.0">
	<xsl:param name="lang"/>
	<xsl:param name="environment"/>
	<xsl:param name="company"/>
	<xsl:param name="UseBusinessPaper" select="false()"/>

	<xsl:variable name="RootPath" select="'/db/apps/'||$environment"/>



	<!-- ********************* PARAMETER ********************* -->
	<!-- Blattgroessen -->
	<xsl:variable name="Papierbreite">210mm</xsl:variable>
	<xsl:variable name="Papierhoehe">297mm</xsl:variable>
	<!-- Raender -->
	<xsl:variable name="Margin">0mm 0mm 2mm 0mm</xsl:variable>
	<xsl:variable name="Margin-Region-Body">
		<xsl:choose>
			<xsl:when test="$UseBusinessPaper">40mm 0mm 15mm 0mm</xsl:when>
			<xsl:otherwise>10mm 0mm 5mm 0mm</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="Margin-Region-Body-Last-Site">5mm 0mm 10mm 0mm</xsl:variable>
	<xsl:variable name="Region-Before">20mm</xsl:variable>
	<xsl:variable name="Region-After">15mm</xsl:variable>
	<xsl:variable name="Region-After-Last-Site">30mm</xsl:variable>
	<xsl:variable name="Region-Start">20mm</xsl:variable>
	<xsl:variable name="Region-End">20mm</xsl:variable>
	<!-- Typografie -->
	<xsl:variable name="Font-Familie">Arial</xsl:variable>
	<xsl:variable name="Schriftgroesse-SeitenTitel">20pt</xsl:variable>
	<xsl:variable name="Schriftgroesse-Titel">20pt</xsl:variable>
	<xsl:variable name="Schriftgroesse-Text">11pt</xsl:variable>
	
	<xsl:template match="/">
		<fo:root>
			<!-- ********************* Bookmarks ********************* 
			<fox:outline internal-destination="link-first-page">
				<fox:label>bintellix</fox:label>
			</fox:outline>
			<fox:outline internal-destination="Signature">
				<fox:label>Kontaktdaten</fox:label>
			</fox:outline>
			-->
			<!-- ********************* LAYOUT-MASTER-SET (Seitenfolgen) ********************* -->
			<fo:layout-master-set>
				<!-- First-Site-Template -->
				<fo:simple-page-master margin="{$Margin}" master-name="First-Site-Template">
					<xsl:attribute name="page-height">
						<xsl:value-of select="$Papierhoehe"/>
					</xsl:attribute>
					<xsl:attribute name="page-width">
						<xsl:value-of select="$Papierbreite"/>
					</xsl:attribute>
					<fo:region-body margin="{$Margin-Region-Body}"/>
				</fo:simple-page-master>


				<fo:simple-page-master margin="{$Margin}" master-name="Content-Template">
					<xsl:attribute name="page-height">
						<xsl:value-of select="$Papierhoehe"/>
					</xsl:attribute>
					<xsl:attribute name="page-width">
						<xsl:value-of select="$Papierbreite"/>
					</xsl:attribute>
					<fo:region-body margin="{$Margin-Region-Body}"/>
					<fo:region-before precedence="true">
						<xsl:attribute name="extent">
							<xsl:value-of select="$Region-Before"/>
						</xsl:attribute>
					</fo:region-before>
					<fo:region-after precedence="true" region-name="empty-page-footer">
						<xsl:attribute name="extent">
							<xsl:value-of select="$Region-After"/>
						</xsl:attribute>
					</fo:region-after>
					<fo:region-start>
						<xsl:attribute name="extent">
							<xsl:value-of select="$Region-Start"/>
						</xsl:attribute>
					</fo:region-start>
					<fo:region-end>
						<xsl:attribute name="extent">
							<xsl:value-of select="$Region-End"/>
						</xsl:attribute>
					</fo:region-end>
				</fo:simple-page-master>

				<!-- Last-Site-Template -->
				<fo:simple-page-master margin="{$Margin}" master-name="Last-Site-Template">
					<xsl:attribute name="page-height">
						<xsl:value-of select="$Papierhoehe"/>
					</xsl:attribute>
					<xsl:attribute name="page-width">
						<xsl:value-of select="$Papierbreite"/>
					</xsl:attribute>
					<fo:region-body margin="{$Margin-Region-Body-Last-Site}"/>
					<fo:region-before precedence="true">
						<xsl:attribute name="extent">
							<xsl:value-of select="$Region-Before"/>
						</xsl:attribute>
					</fo:region-before>

					<fo:region-after precedence="true" region-name="page-footer">
						<xsl:choose>
							<xsl:when test="$UseBusinessPaper">
								<xsl:attribute name="extent">
									<xsl:value-of select="$Region-After-Last-Site"/>
								</xsl:attribute>
							</xsl:when>
							<xsl:otherwise>
							</xsl:otherwise>
						</xsl:choose>
					</fo:region-after>
					<fo:region-start>
						<xsl:attribute name="extent">
							<xsl:value-of select="$Region-Start"/>
						</xsl:attribute>
					</fo:region-start>
					<fo:region-end>
						<xsl:attribute name="extent">
							<xsl:value-of select="$Region-End"/>
						</xsl:attribute>
					</fo:region-end>
				</fo:simple-page-master>

				<!-- Document Page -->
				<fo:page-sequence-master master-name="Document-Page">
					<fo:repeatable-page-master-alternatives>
						<fo:conditional-page-master-reference master-reference="Last-Site-Template" page-position="last"/>
						<fo:conditional-page-master-reference master-reference="Content-Template"/>
					</fo:repeatable-page-master-alternatives>
				</fo:page-sequence-master>

			</fo:layout-master-set>

			<!-- ################## dyn. Seite ################## -->
			<fo:page-sequence language="de" country="de" master-reference="Document-Page">
				<fo:static-content flow-name="xsl-region-before">
					<xsl:choose>
						<xsl:when test="$UseBusinessPaper">
							<fo:block text-align="center">
								<xsl:call-template name="page-header"/>
							</fo:block>
						</xsl:when>
						<xsl:otherwise>
							<fo:block text-align="center"/>
						</xsl:otherwise>
					</xsl:choose>
				</fo:static-content>
				<fo:static-content flow-name="empty-page-footer">
					<fo:block text-align="center" font-size="7pt">
						<xsl:call-template name="page-footer"/>
					</fo:block>
				</fo:static-content>
				<fo:static-content flow-name="page-footer">
					<fo:block text-align="center" font-size="7pt">
						<xsl:call-template name="page-footer-last"/>
					</fo:block>
				</fo:static-content>
				<fo:flow flow-name="xsl-region-body" font-size="8pt" font-family="Verdana,Arial,sans-serif">
					<fo:block font-size="{$Schriftgroesse-SeitenTitel}" margin-top="-5mm" margin-right="-20mm" margin-left="-10mm" width="100%" color="#fff" background-color="#ff6c09" padding="3mm 20mm 3mm 20mm">

						<xsl:choose>
							<xsl:when test="//document-title//span">
								<fo:block>
									<xsl:value-of select="//document-title//span[@class='High']"/>
								</fo:block>
								<fo:block font-size="10pt">
									<xsl:value-of select="//document-title//span[@class='Low']"/>
								</fo:block>
							</xsl:when>
			 				<xsl:otherwise>
								<xsl:value-of select="//document-title"/>
							</xsl:otherwise>
						</xsl:choose>
					</fo:block>

					<fo:block font-size="{$Schriftgroesse-Text}" margin-top="0mm">
						 <xsl:apply-templates/>
					</fo:block>
					<fo:block id="last-block"/>
				</fo:flow>
			</fo:page-sequence>
		</fo:root>
	</xsl:template>


	<xsl:template name="page-header">

	</xsl:template>


	<xsl:template name="page-footer">

	</xsl:template>

	<xsl:template name="page-footer-last">

		
	</xsl:template>


	<xsl:template name="page-footer-last-site">
	</xsl:template>

	<xsl:template match="page">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="treenode">
		<!-- no longer needed -->
	</xsl:template>

	<xsl:template match="document-title">
		<!-- no longer needed -->
	</xsl:template>

	<xsl:template match="page/image">
		<!-- no longer needed -->
	</xsl:template>

	<xsl:template match="tags">
		<!-- no longer needed -->
	</xsl:template>


	<xsl:template match="*[not(namespace-uri()='http://www.w3.org/1999/XSL/Format')]" priority="-1">
		<fo:inline color="#FF0000">Unknown Tag (generate-pdf): &lt;<xsl:value-of select="local-name()"/>&gt;</fo:inline>
	</xsl:template>

	<!--  copy all other elements -->
	<xsl:template match="@*|node()" priority="-2">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>