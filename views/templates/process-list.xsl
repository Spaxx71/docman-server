<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="3.1">

	<xsl:decimal-format name="EU" decimal-separator="," grouping-separator="."/>

<!--
<xsl:choose>
	<xsl:when test="$is-search">

	</xsl:when>
	<xsl:otherwise>
	
	</xsl:otherwise>
</xsl:choose>
-->
	<xsl:template match="Binder">
		<xsl:if test="exists(*)">
			<table>
				<tr>
					<xsl:choose>
						<xsl:when test="$is-search">
							<th>#</th>
							<th>Ablage</th>
							<th>Vorgang</th>
						</xsl:when>
						<xsl:otherwise>
							<th>#</th>
						</xsl:otherwise>
					</xsl:choose>
					<th>Datum</th>
					<th>Halter</th>
					<th>Vorgang Inhalt</th>
					<th>Referenz ID</th>
					<th>Transakt. ID</th>
					<th>Gesamtbetrag</th>
					<!--
					<th>Dokument Name</th>
					-->
					<th>Notizen</th>
					<th>Vorgansart</th>
					<th>Datei-Anhänge</th>
					<xsl:choose>
						<xsl:when test="$is-search">
							<!-- nothing to do -->
						</xsl:when>
						<xsl:otherwise>
							<th>Buchungen</th>
						</xsl:otherwise>
					</xsl:choose>
					<th>Erstellt am</th>
					<th>Benutzer</th>
					<xsl:choose>
						<xsl:when test="$is-search">
							<!-- nothing to to -->
						</xsl:when>
						<xsl:otherwise>
							<th>Aktion</th>
						</xsl:otherwise>
					</xsl:choose>				
				</tr>
				<xsl:apply-templates/>
			</table>
			<br/>
		</xsl:if>
	</xsl:template>


	<xsl:template match="Process">
		<xsl:variable name="Task" select="if ($is-search) then . else Tasks/*[@isMaster=true()]"/>
		<xsl:variable name="Sum" select="if ($is-search) then 0 else sum(.//PaymentTask/Amount/@value)"/>

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
				<xsl:choose>
					<xsl:when test="$is-search">
						<xsl:value-of select="count(preceding::*)+1"/> <!-- not preceding-sibling -->
					</xsl:when>
					<xsl:otherwise>
						<a>
							<xsl:choose>
								<xsl:when test="not(@type='payment_bank')">
									<xsl:attribute name="href">
										<xsl:value-of select="concat($home-web-gui,'/',$tenant,'/',$year,'/binders/',@id,'/search.html')"/>
									</xsl:attribute>
								</xsl:when>
							</xsl:choose>
							<xsl:value-of select="count(preceding-sibling::*)+1"/>
						</a>
						<xsl:if test="$Sum = xs:double(TotalAmount/@value)">
							<xsl:text> ✔</xsl:text>
						</xsl:if>
					</xsl:otherwise>
				</xsl:choose>			
			</td>
			<xsl:choose>
				<xsl:when test="$is-search">
					<td>
						<a href="{$home-web-gui||'/'||$tenant||'/'||$year||'/binders/'||@binder||'/index.html'}">
							[<xsl:value-of select="../@name"/>]
						</a>					
					</td>
					<td>
						<a href="{$home-web-gui||'/'||$tenant||'/'||$year||'/binders/'||@binder||'/'||@id||'/edit/'||replace(@mainTask,'Task$','')||'.html'}{if ($attach) then '?attach='||$attach||'&amp;ref='||$ref else ''}">
							<xsl:value-of select="@name"/>
							<br/>
							<xsl:value-of select="@id"/>
							<xsl:value-of select="name()"/>
						</a>
					</td>
				</xsl:when>
				<xsl:otherwise>
				</xsl:otherwise>
			</xsl:choose>			
			<td>
				<xsl:value-of select="format-date(@date,'[D00].[M00].[Y0000]')"/>
			</td>
			<td>
				<xsl:variable name="Account" select="//Account[@kto=$Task/Owner]"/>
				<xsl:value-of select="$Account/Name"/>
				<br/>
				<a href="{$home-web-gui||'/'||$tenant||'/'||$year||'/accounts/'||$Account/@id||'/details.html'}">
					<xsl:text> (</xsl:text>
					<xsl:value-of select="$Task/Owner"/>
					<xsl:text>)</xsl:text>
				</a>
			</td>
			<td>
				<xsl:value-of select="$Task/Description"/>
			</td>
			<td>
				<xsl:value-of select="$Task/RefID"/>
			</td>
			<td>
				<xsl:value-of select="$Task/TransactionID"/>
			</td>
			<td class="Money">
				<xsl:value-of select="format-number(TotalAmount/@value,'#.##0,00','EU')"/>
				<xsl:text> </xsl:text>
				<xsl:value-of select="TotalAmount/@unit"/>
				<xsl:choose>
					<xsl:when test="$is-search">

					</xsl:when>
					<xsl:otherwise>
						<div>
							<xsl:choose>
								<xsl:when test="$Sum = xs:double(TotalAmount/@value)">
									<xsl:attribute name="style" select="'color:#6c6'"/>
								</xsl:when>
								<xsl:when test="xs:double(TotalAmount/@value) gt 0 and $Sum lt 0">
									<xsl:attribute name="style" select="'color:#f33'"/>
								</xsl:when>
								<xsl:when test="xs:double(TotalAmount/@value) lt 0 and $Sum gt 0">
									<xsl:attribute name="style" select="'color:#f33'"/>
								</xsl:when>
								<xsl:when test="xs:double(TotalAmount/@value) gt 0 and $Sum gt xs:double(TotalAmount/@value)">
									<xsl:attribute name="style" select="'color:#f33'"/>
								</xsl:when>
								<xsl:when test="xs:double(TotalAmount/@value) lt 0 and $Sum lt xs:double(TotalAmount/@value)">
									<xsl:attribute name="style" select="'color:#f33'"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:attribute name="style" select="'color:#bbb'"/>
								</xsl:otherwise>
							</xsl:choose>
							<xsl:text>(</xsl:text>
							<xsl:value-of select="format-number($Sum,'#.##0,00','EU')"/>
							<xsl:text> </xsl:text>
							<xsl:value-of select="TotalAmount/@unit"/>
							<xsl:text>)</xsl:text>
						</div>					
					</xsl:otherwise>
				</xsl:choose>				
			</td>
			<td>
				<xsl:value-of select="Notes"/>
				<xsl:value-of select="$Task/Notes"/>
			</td>
			<!--
			<td>
				<a href="{$home-web-gui}/{$tenant}/{$year}/binders/{$binder}/{@name}/edit.html">
					<xsl:value-of select="@name"/>
				</a>
			</td>
			-->
			<td>
				<xsl:choose>
					<xsl:when test="$is-search">
						<xsl:value-of select="replace(@mainTask,'Task$','')"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="replace(name(Tasks/*[1]),'Task$','')"/>
					</xsl:otherwise>
				</xsl:choose>			
				<xsl:if test="@type">
					<br/>
					<xsl:text>"</xsl:text>
					<xsl:value-of select="@type"/>
					<xsl:text>"</xsl:text>
				</xsl:if>
			</td>
			<td>
				<xsl:choose>
					<xsl:when test="$is-search">
						<xsl:for-each select="Files/File">
							<a href="{$home-web-gui}/{@src}">
								<xsl:call-template name="FileTypes"/>
							</a>
							<br/>
						</xsl:for-each>
					</xsl:when>
					<xsl:otherwise>
						<xsl:for-each select="Tasks/*/Files/File">
							<a href="{$home-web-gui}/{@src}">
								<xsl:call-template name="FileTypes"/>
							</a><br/>
						</xsl:for-each>
					</xsl:otherwise>
				</xsl:choose>					
			</td>
			<xsl:choose>
				<xsl:when test="$is-search">
					<!-- nothing to do -->
				</xsl:when>
				<xsl:otherwise>
					<td style="padding-left:0; padding-right:0">
						<xsl:if test=".//Bookings/Booking">
							<table class="Booking">
								<xsl:for-each select=".//Bookings/Booking">
									<tr>
										<td style="width:22%; text-align:right;">
											<xsl:value-of select="@debit"/>
										</td>
										<td style="width:22%; text-align:right;">
											<xsl:value-of select="@credit"/>
										</td>
										<td style="width:50%; text-align:right;">
											<xsl:value-of select="format-number(@amountValue,'#.##0,00','EU')"/>
											<xsl:text> </xsl:text>
											<xsl:value-of select="@amountUnit"/>
										</td>
										<td style="width:6%; text-align:right;">
											<xsl:value-of select="@taxKey"/>
										</td>
									</tr>
								</xsl:for-each>
							</table>
						</xsl:if>
					</td>
				</xsl:otherwise>
			</xsl:choose>						
			<td>
				<xsl:value-of select="format-dateTime(adjust-dateTime-to-timezone(@created, xs:dayTimeDuration($TimezoneOffset)),'[D00].[M00].[Y0000] [H00]:[m00]')"/>
			</td>
			<td>
				<xsl:value-of select="@user"/>
			</td>
			<xsl:choose>
				<xsl:when test="$is-search">

				</xsl:when>
				<xsl:otherwise>
					<td>
						<ul class="nav">
							<li>
								<a href="{$home-web-gui}/{$tenant}/{$year}/binders/{$binder}/{@id}/delete.html">Löschen...</a>
							</li>
							<xsl:if test="not(contains(@name,'.'))">
								<li>
									<a href="{$home-web-gui}/{$tenant}/{$year}/binders/{$binder}/{@id}/edit/{replace(name(Tasks/*[1]),'Task$','')}.html">Bearbeiten...</a>
								</li>
							</xsl:if>
						</ul>
					</td>				
				</xsl:otherwise>
			</xsl:choose>
		</tr>
	</xsl:template>
	
	<xsl:template name="FileTypes">
		<xsl:choose>
			<xsl:when test="@type='doc-bank-transfer'">
				<xsl:text>Überweisung</xsl:text>
			</xsl:when>
			<xsl:when test="@type='doc-delivery-note'">
				<xsl:text>Lieferschein</xsl:text>
			</xsl:when>
			<xsl:when test="@type='doc-dunning-charge'">
				<xsl:text>Mahnbescheid</xsl:text>
			</xsl:when>
			<xsl:when test="@type='doc-information'">
				<xsl:text>Infoschreiben</xsl:text>
			</xsl:when>
			<xsl:when test="@type='doc-invoice-in'">
				<xsl:text>Rechung (ein)</xsl:text>
			</xsl:when>
			<xsl:when test="@type='doc-invoice-in-storno'">
				<xsl:text>Rechung STORNO</xsl:text>
			</xsl:when>
			<xsl:when test="@type='doc-invoice-out'">
				<xsl:text>Rechung (aus)</xsl:text>
			</xsl:when>
			<xsl:when test="@type='doc-invoice-out-storno'">
				<xsl:text>Rechung STORNO</xsl:text>
			</xsl:when>
			<xsl:when test="@type='doc-undefined'">
				<xsl:text>Sonstiges</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="@type"/>
			</xsl:otherwise>
		</xsl:choose>		
	</xsl:template>
</xsl:stylesheet>