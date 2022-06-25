<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:err="http://www.w3.org/2005/xqt-errors" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xlink="http://www.w3.org/1999/xlink" exclude-result-prefixes="xs err" version="3.0">

	<xsl:decimal-format name="EU" decimal-separator="," grouping-separator="."/>

	<xsl:template name="BalanceGraph">
		<xsl:param name="Analysis" required="yes"/>
		<xsl:param name="HomeWebGui" select="'/app'"/>
		<xsl:param name="Margin" select="15"/>

		<xsl:variable name="width" select="1000 - 2 * $Margin"/>
		<xsl:variable name="height" select="320 - 2 * $Margin"/>
		<xsl:variable name="min" select="min(($Analysis/Balances/@saldoInitAmount, $Analysis/Balances/Balance/@value))"/>
		<xsl:variable name="max" select="max(($Analysis/Balances/@saldoInitAmount, $Analysis/Balances/Balance/@value))"/>
		<xsl:variable name="range">
			<xsl:choose>
				<xsl:when test="$min &lt; 0">
					<xsl:value-of select="$max - $min"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$max"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="offset">
			<xsl:choose>
				<xsl:when test="$min &lt; 0">
					<xsl:value-of select="$min * -1"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="0"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="stepX" select="$width div 365"/>
		<xsl:variable name="stepY" select="$height div ($max + $offset)"/>


		<xsl:choose>
			<xsl:when test="xs:string($min)='NaN' or xs:string($max)='NaN'">
				<!-- Validation -->
				<error>
					<xsl:for-each select="$Analysis/Balances/Balance">
						<xsl:if test=".[not(@saldoAmount) or not(@saldoAmount castable as xs:double)]">
							<div>Position #<xsl:value-of select="position()"/>
 hat keinen (gültigen) Saldo</div>
						</xsl:if>
					</xsl:for-each>
				</error>
			</xsl:when>
			<xsl:otherwise>
				<xsl:try>

					<svg class="Graph" viewBox="0 0 {$width} {$height + $Margin * 2}" style="font-size:65%" test="{$min}">	<!-- viewBox="0 0 {$width} {$height}" -->
						<xsl:variable name="CurrentDay" select="xs:integer((current-date() - xs:date(concat(year-from-date(current-date()),'-01-01'))) div xs:dayTimeDuration('P1D'))"/>

						<rect class="GraphBackground" width="{$width}" height="{$height + $Margin * 2}" style="fill:#eeeeee"/>

						<g class="GraphMonth">
							<xsl:for-each select="1 to 12">

								<line x1="{. * 365 div 12 * $stepX}" y1="{$Margin}" x2="{. * 365 div 12 * $stepX}" y2="{$height + 2 * $Margin}" style="stroke:rgb(128,128,128);stroke-width:1;stroke-dasharray:1,2"/>
								<text x="{(. - 0.5)  * 365 div 12 * $stepX}" y="{$height + 2 * $Margin - 5}" text-anchor="middle" style="fill:#999">
									<xsl:choose>
										<xsl:when test=". = 1">Januar</xsl:when>
										<xsl:when test=". = 2">Februar</xsl:when>
										<xsl:when test=". = 3">März</xsl:when>
										<xsl:when test=". = 4">April</xsl:when>
										<xsl:when test=". = 5">Mai</xsl:when>
										<xsl:when test=". = 6">Juni</xsl:when>
										<xsl:when test=". = 7">Juli</xsl:when>
										<xsl:when test=". = 8">August</xsl:when>
										<xsl:when test=". = 9">September</xsl:when>
										<xsl:when test=". = 10">Oktober</xsl:when>
										<xsl:when test=". = 11">November</xsl:when>
										<xsl:when test=". = 12">Dezember</xsl:when>
									</xsl:choose>
								</text>
							</xsl:for-each>
						</g>

						<rect class="LegendeBackground" x="0" y="0" width="{$width}" height="{$Margin}" fill="#ccc"/>

						<xsl:for-each select="$Analysis/Balances">
							<g class="Konto{@bank-account}">
								<xsl:variable name="color">
									<xsl:choose>
										<xsl:when test="position()=1">#0074d9</xsl:when>
										<xsl:when test="position()=2">#d97400</xsl:when>
										<xsl:when test="position()=3">#003366</xsl:when>
										<xsl:when test="position()=4">#00d974</xsl:when>
										<xsl:when test="position()=5">#006633</xsl:when>
										<xsl:when test="position()=6">#996633</xsl:when>
										<xsl:when test="position()=7">#663399</xsl:when>
										<xsl:when test="position()=8">#999933</xsl:when>
										<xsl:otherwise>#666666</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>

								<xsl:choose>
									<xsl:when test="not(Balance)">
										<line x1="0" y1="{$height - ((@saldoInitAmount + $offset) * $stepY)}" x2="{$width}" y2="{$height - ((@saldoInitAmount + $offset) * $stepY)}" stroke="{$color}" stroke-width="{if (@bank-account='0') then 2 else 1}"/>
									</xsl:when>
									<xsl:otherwise>
										<polyline class="GraphSaldoLine {@bank-account}" fill-opacity="0.4" fill-rule="nonzero" stroke="{$color}" stroke-width="{if (@bank-account='0') then 0.5 else 1}">
											<xsl:attribute name="fill">
												<xsl:choose>
													<xsl:when test="@bank-account='0'">
														<xsl:text>#ccc</xsl:text>
													</xsl:when>
													<xsl:otherwise>
														<xsl:text>none</xsl:text>
													</xsl:otherwise>
												</xsl:choose>
											</xsl:attribute>
											<xsl:variable name="Balances" select="."/>
											<xsl:attribute name="points">
												<!-- inital point a 0 -->
												<xsl:text>0,</xsl:text>
												<xsl:value-of select="$height - ((0.0 + $offset) * $stepY) + $Margin"/>
												<xsl:text> </xsl:text>

												<!-- inital saldo -->
												<xsl:if test="@saldoInitAmount castable as xs:double">
													<xsl:text>0,</xsl:text>
													<xsl:value-of select="$height - ((@saldoInitAmount + $offset) * $stepY) + $Margin"/>
													<xsl:text> </xsl:text>
												</xsl:if>

												<!-- iterate through all transactions -->
												<!--
									<xsl:for-each select="Balance">
										<xsl:value-of select="xs:integer(@day) * $stepX"/>
										<xsl:text>,</xsl:text>
										<xsl:value-of select="$height - ((@value + $offset) * $stepY) + $Margin"/>
										<xsl:text> </xsl:text>
									</xsl:for-each>
									-->
												<xsl:variable name="last-day">
													<xsl:choose>
														<xsl:when test="@year = format-date(current-date(),'[Y0000]')">
															<xsl:value-of select="$CurrentDay"/>
														</xsl:when>
														<xsl:otherwise>
															<xsl:text>365</xsl:text>
														</xsl:otherwise>
													</xsl:choose>
												</xsl:variable>

												<xsl:for-each select="1 to $last-day">
													<xsl:variable name="amount">
														<xsl:choose>
															<xsl:when test="exists($Balances/Balance[xs:integer(@day) &lt;= current()])">
																<xsl:value-of select="$Balances/Balance[xs:integer(@day) &lt;= current()][last()]/@value"/>
															</xsl:when>
															<xsl:when test="$Balances/@saldoInitAmount castable as xs:double">
																<xsl:value-of select="$Balances/@saldoInitAmount"/>
															</xsl:when>
															<xsl:otherwise>
																<xsl:text>0</xsl:text>
															</xsl:otherwise>
														</xsl:choose>
													</xsl:variable>
													<xsl:value-of select=". * $stepX"/>
													<xsl:text>,</xsl:text>
													<xsl:value-of select="$height - (($amount + $offset) * $stepY) + $Margin"/>
													<xsl:text> </xsl:text>
												</xsl:for-each>

												<xsl:if test="@year != format-date(current-date(),'[Y0000]')">
													<xsl:value-of select="$width"/>
													<xsl:text>,</xsl:text>
													<xsl:value-of select="$height - ((Balance[last()]/@value + $offset) * $stepY) + $Margin"/>
													<xsl:text> </xsl:text>
												</xsl:if>

												<xsl:value-of select="$width"/>
												<xsl:text>,</xsl:text>
												<xsl:value-of select="$height - ((0.0 + $offset) * $stepY) + $Margin"/>
												<xsl:text> </xsl:text>
										
											</xsl:attribute>

											<!--
	<debug>
									<xsl:for-each select="1 to 365">
										<xsl:variable name="amount">
											<xsl:choose>
												<xsl:when test="exists($Balances/Balance[xs:integer(@day) &lt;= current()])">
													<xsl:value-of select="$Balances/Balance[xs:integer(@day) &lt;= current()][last()]/@value"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="$Balances/@saldoInitAmount"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:variable>
										[<xsl:value-of select="position()"/>: <xsl:value-of select="$amount"/>]
									</xsl:for-each>
	</debug>
	-->
										</polyline>


										<xsl:choose>
											<xsl:when test="@year = format-date(current-date(),'[Y0000]')">
												<xsl:variable name="amount" select="Balance[last()]/@value"/>
												<line x1="{$CurrentDay * $stepX}" y1="{$height - (($amount + $offset) * $stepY)}" x2="{$width}" y2="{$height - (($amount + $offset) * $stepY)}" stroke="{$color}" stroke-dasharray="5,5"/>
											</xsl:when>
											<xsl:otherwise/>
										</xsl:choose>
									</xsl:otherwise>
								</xsl:choose>

								<g class="GraphPoint">
									<xsl:choose>
										<xsl:when test="@bank-account='0'">

										</xsl:when>
										<xsl:otherwise>
											<xsl:for-each select="Balance">
												<xsl:choose>
													<xsl:when test="@href">
														<a xlink:href="{concat($HomeWebGui, @href)}" href="{concat($HomeWebGui, @href)}" target="_blank">
															<xsl:choose>
																<xsl:when test="@isBooked=false()">
																	<circle cx="{xs:integer(@day) * $stepX}" cy="{$height - ((@value + $offset) * $stepY) + $Margin}" r="2" stroke="red" stroke-width="0" fill="red"/>
																</xsl:when>
																<xsl:otherwise>
																	<circle cx="{xs:integer(@day) * $stepX}" cy="{$height - ((@value + $offset) * $stepY) + $Margin}" r="2" stroke="red" stroke-width="0.2" fill="{$color}"/>
																</xsl:otherwise>
															</xsl:choose>
														</a>
													</xsl:when>
													<xsl:otherwise>
														<circle cx="{xs:integer(@day) * $stepX}" cy="{$height - ((@value + $offset) * $stepY) + $Margin}" r="2" stroke="red" stroke-width="0" fill="{$color}"/>
													</xsl:otherwise>
												</xsl:choose>
											</xsl:for-each>
										</xsl:otherwise>
									</xsl:choose>
								</g>

								<g class="GraphAgenda">
									<line x1="{(position() -1)*100}" y1="7" x2="{(position() -1)*100 +10}" y2="7" style="stroke:{$color};stroke-width:1"/>

									<a xlink:href="{concat($HomeWebGui, @href)}" href="{concat($HomeWebGui, @href)}" target="_blank">
										<text x="{(position() -1)*100 +15}" y="12" fill="{$color}">
											<xsl:choose>
												<xsl:when test="@name">
													<xsl:value-of select="@name"/>
												</xsl:when>
												<xsl:when test="@bank-account='0'">
													<xsl:text>Bank gesamt</xsl:text>
												</xsl:when>
												<xsl:when test="@bank-account castable as xs:double">
													<xsl:text>Bank </xsl:text>
													<xsl:value-of select="@bank-account"/>
												</xsl:when>
												<xsl:when test="@bank-account">
													<xsl:value-of select="@bank-account"/>
												</xsl:when>
												<xsl:otherwise>Dokumente</xsl:otherwise>
											</xsl:choose>
										</text>
									</a>
								</g>
							</g>
						</xsl:for-each>


						<g class="GraphLabels">

							<line class="GraphMaxLine" x1="0" y1="{$Margin}" x2="{$width}" y2="{$Margin}" style="stroke:rgb(102,102,102);stroke-width:1"/>
							<text x="0" y="{12 + $Margin}" fill="#666">
								<xsl:value-of select="format-number($max,'#.##0,00','EU')"/>
								<xsl:text/>
								<xsl:value-of select="$Analysis/Balances[1]/@unit"/>
							</text>

							<line class="GraphZeroLine" x1="0" y1="{$height - ((0 + $offset) * $stepY) + $Margin}" x2="{$width}" y2="{$height - ((0 + $offset) * $stepY) + $Margin}" style="stroke:rgb(0,0,0);stroke-width:1.5"/>
							<xsl:choose>
								<xsl:when test="$min &lt; 0">
									<text x="0" y="{$height - $offset * $stepY + $Margin}" fill="#000">0 <xsl:value-of select="$Analysis/Balances[1]/@unit"/>
									</text>

									<line class="GraphMinLine" x1="0" y1="{$height + $Margin}" x2="{$width}" y2="{$height + $Margin}" style="stroke:rgb(102,102,102);stroke-width:1.5"/>
									<text x="0" y="{$height + $Margin}" fill="#666">
										<xsl:value-of select="format-number($min,'#.##0,00','EU')"/>
										<xsl:value-of select="$Analysis/Balances[1]/@unit"/>
									</text>
								</xsl:when>
								<xsl:otherwise>
									<text x="0" y="{$height + $Margin}" fill="#666">0 <xsl:value-of select="$Analysis/Balances[1]/@unit"/>
									</text>
								</xsl:otherwise>
							</xsl:choose>

							<!-- <text x="50" y="50" fill="#666"><xsl:value-of select="'test'"/></text> -->
						</g>

					</svg>

					<xsl:catch>
						<error>Beim Erstellen der Verlaufkurve ist es zu einem Ausnahmefehler gekommen:
                            Error code: <xsl:value-of select="$err:code"/>
                            Reason: <xsl:value-of select="$err:description"/>
					</error>
				</xsl:catch>
			</xsl:try>

			<!-- Validation -->
			<xsl:for-each select="$Analysis/Balances/Balance">
				<xsl:if test=".[not(@value) or not(@value castable as xs:double)]">
					<div>Position #<xsl:value-of select="position()"/>
 hat keine Saldo</div>
				</xsl:if>
			</xsl:for-each>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

</xsl:stylesheet>