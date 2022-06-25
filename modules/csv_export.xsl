<!-- the CSV handling should base on https://www.rfc-editor.org/rfc/rfc4180.txt --><xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="3.1">

	<xsl:output method="text" encoding="UTF-8" indent="no"/>

	<xsl:param name="format-spec-uri" required="yes"/>

	<xsl:param name="format-spec" select="doc($format-spec-uri)"/>

	<xsl:decimal-format name="EU" decimal-separator="," grouping-separator="."/>


	<xsl:template match="/">
		<!-- <xsl:text>Start des Exports</xsl:text> -->
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="Export">
		<xsl:if test="@createHeadline='true'">
			<!-- <xsl:text>Headline</xsl:text> -->
			<xsl:variable name="Part" select="./*"/>

			<xsl:for-each select="$format-spec/Format/Part[@name=$Part/name()]/Column">
				<xsl:text>"</xsl:text>
				<xsl:value-of select="@headline"/>
				<xsl:text>"</xsl:text>
				<xsl:if test="position() != last()">
					<xsl:value-of select="$format-spec/Format/@separator"/>
				</xsl:if>
			</xsl:for-each>
			<xsl:value-of select="$format-spec/Format/@newline"/>
		</xsl:if>
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="Export/*">
		<xsl:if test="exists(*)">
			<!-- <xsl:text>Part</xsl:text> -->
			<xsl:variable name="Part" select="."/>
			<xsl:for-each select="$format-spec/Format/Part[@name=$Part/name()]/Column">
				<xsl:sort select="@nr" data-type="number"/>
				<!-- <xsl:text>Column</xsl:text> -->
				<xsl:variable name="ColName" select="@name"/>

				<xsl:variable name="ColValue">
					<xsl:call-template name="formatValue">
						<xsl:with-param name="Value" select="$Part/*[$ColName=name()]"/>
						<xsl:with-param name="Format" select="."/>
					</xsl:call-template>
				</xsl:variable>

				<xsl:if test="@regex">
					<xsl:try>
						<xsl:if test="string-length($ColValue)=0">
							<!-- nothing to do -->
						</xsl:if>
						<xsl:if test="not(matches($ColValue, @regex))">
							<xsl:text>ERROR: Value '</xsl:text>
							<xsl:value-of select="$ColValue"/>
							<xsl:text>' does not match regex '</xsl:text>
							<xsl:value-of select="@regex"/>
							<xsl:text>'.</xsl:text>
						</xsl:if>
						<xsl:catch>
							<xsl:text>ERROR: Invalid regex pattern '</xsl:text>
							<xsl:value-of select="@regex"/>
							<xsl:text>'.</xsl:text>
						</xsl:catch>
					</xsl:try>						
				</xsl:if>

				<xsl:value-of select="$ColValue"/>

				<xsl:if test="position() != last()">
					<xsl:value-of select="$format-spec/Format/@separator"/>
				</xsl:if>
				<!-- [<xsl:value-of select="@name"/>|<xsl:value-of select="position()"/>|<xsl:value-of select="last()"/>] -->
			</xsl:for-each>
			<xsl:value-of select="$format-spec/Format/@newline"/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="Export/*/*">
		<!-- nothing to do -->
	</xsl:template>

	<xsl:template name="formatValue">
		<xsl:param name="Value"/> 
		<xsl:param name="Format"/> 
 
		<xsl:choose>
			<xsl:when test="$Value/text()">
				<xsl:choose>
					<xsl:when test="$Format/@type='boolean'">
						<xsl:try>
							<xsl:choose>
								<xsl:when test="$Format/@format='0'">
									<xsl:choose>
										<xsl:when test="$Value=true()">
											<xsl:text>1</xsl:text>
										</xsl:when>
										<xsl:otherwise>
											<xsl:text>0</xsl:text>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$Value/text()"/>
								</xsl:otherwise>
							</xsl:choose>
							<xsl:catch>
								<xsl:text>ERROR: Invalid BOOLEAN '</xsl:text>
									<xsl:value-of select="$Value/text()"/>
									<xsl:text>'.</xsl:text>
							</xsl:catch>
						</xsl:try>
					</xsl:when>
					<xsl:when test="$Format/@type='char'">
						<xsl:try>
							<xsl:choose>
								<xsl:when test="$Format/@format">
									<xsl:text>Format for a char is currently not supported</xsl:text>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$Value/text()"/>
								</xsl:otherwise>
							</xsl:choose>
							<xsl:catch>
								<xsl:text>ERROR: Invalid CHAR '</xsl:text>
									<xsl:value-of select="$Value/text()"/>
									<xsl:text>'.</xsl:text>
							</xsl:catch>
						</xsl:try>
					</xsl:when>
					<xsl:when test="$Format/@type='date'">
						<xsl:try>
							<xsl:choose>
								<xsl:when test="$Format/@format">
									<xsl:value-of select="format-date(xs:date($Value/text()),$Format/@format)"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$Value/text()"/>
								</xsl:otherwise>
							</xsl:choose>
							<xsl:catch>
								<xsl:text>ERROR: Invalid DATE '</xsl:text>
									<xsl:value-of select="$Value/text()"/>
									<xsl:text>'.</xsl:text>
							</xsl:catch>
						</xsl:try>
					</xsl:when>
					<xsl:when test="$Format/@type='dateTime'">
						<xsl:try>
							<xsl:choose>
								<xsl:when test="$Format/@format">
									<xsl:value-of select="format-dateTime(xs:dateTime($Value/text()),$Format/@format)"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$Value/text()"/>
								</xsl:otherwise>
							</xsl:choose>
							<xsl:catch>
								<xsl:text>ERROR: Invalid DATETIME '</xsl:text>
									<xsl:value-of select="$Value/text()"/>
									<xsl:text>'.</xsl:text>
							</xsl:catch>
						</xsl:try>
					</xsl:when>
					<xsl:when test="$Format/@type='integer'">
						<xsl:try>
							<xsl:choose>
								<xsl:when test="$Format/@format">
									<xsl:value-of select="format-number($Value,$Format/@format)"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$Value/text()"/>
								</xsl:otherwise>
							</xsl:choose>
							<xsl:catch>
								<xsl:text>ERROR: Invalid INTEGER '</xsl:text>
									<xsl:value-of select="$Value/text()"/>
									<xsl:text>'.</xsl:text>
							</xsl:catch>
						</xsl:try>
					</xsl:when>
					<xsl:when test="$Format/@type='double'">
						<xsl:try>
							<xsl:choose>
								<xsl:when test="$Format/@format='EU'">
									<xsl:value-of select="format-number($Value,'0,00','EU')"/>
								</xsl:when>
								<xsl:when test="$Format/@format">
									<xsl:value-of select="format-number($Value,$Format/@format)"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="format-number($Value/text(),'0.00')"/>
								</xsl:otherwise>
							</xsl:choose>
							<xsl:catch>
								<xsl:text>ERROR: Invalid DOUBLE'</xsl:text>
									<xsl:value-of select="$Value/text()"/>
									<xsl:text>'.</xsl:text>
							</xsl:catch>
						</xsl:try>
					</xsl:when>
					<xsl:when test="$Format/@type='money'">
						<xsl:try>
							<xsl:choose>
								<xsl:when test="$Format/@format='EU'">
									<xsl:value-of select="format-number($Value,'0,00','EU')"/>
								</xsl:when>
								<xsl:when test="$Format/@format">
									<xsl:value-of select="format-number($Value,$Format/@format)"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="format-number($Value/text(),'0.00')"/>
								</xsl:otherwise>
							</xsl:choose>
							<xsl:catch>
								<xsl:text>ERROR: Invalid MONEY '</xsl:text>
									<xsl:value-of select="$Value/text()"/>
									<xsl:text>'.</xsl:text>
							</xsl:catch>
						</xsl:try>
					</xsl:when>					
					<xsl:when test="$Format/@type='string'">
						<xsl:try>
							<!-- escaping characters " ' \ as given by RFC-4180 -->
							<!-- allowing CR/LF in string <xsl:variable name="Data" select="replace($Value/text(),'&#34;','&#34;&#34;')"/> -->
							<xsl:variable name="Data" select="replace(replace($Value/text(),'&#34;','&#34;&#34;'),'(&#xD;&#xA;|&#xD;|&#xA;)',' ')"/>
							<xsl:choose>
								<xsl:when test="$Format/@format">
									<xsl:text>"</xsl:text>
									<xsl:text>ERROR: Format for a string is currently not supported.</xsl:text>
									<xsl:text>"</xsl:text>
								</xsl:when>
								<xsl:otherwise>
									<xsl:text>"</xsl:text>
									<xsl:value-of select="$Data"/>
									<xsl:text>"</xsl:text>
								</xsl:otherwise>
							</xsl:choose>
							<xsl:catch>
								<xsl:text>ERROR: Invalid STRING '</xsl:text>
								<xsl:value-of select="$Value/text()"/>
								<xsl:text>'.</xsl:text>
							</xsl:catch>
						</xsl:try>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>ERROR: invalid type '</xsl:text>
						<xsl:value-of select="$Format/@type"/>
						<xsl:text>'.</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="$Format/@type='string'">
						<xsl:choose>
							<xsl:when test="$Format/@default">
								<xsl:text>"</xsl:text>
								<xsl:value-of select="$Format/@default"/>
								<xsl:text>"</xsl:text>
							</xsl:when>
							<xsl:otherwise>
								<!-- <xsl:text>""</xsl:text> --> <!-- even for an empty field is requested by DATEV -->
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$Format/@default"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>

</xsl:stylesheet>