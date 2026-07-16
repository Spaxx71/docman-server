<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="year" required="yes"/>

	<xsl:decimal-format name="EU" decimal-separator="," grouping-separator="."/>

	<xsl:template match="/">
		<html>
			<head>
				<style>
					.AccountChart {
						width: 100%;
					}
					.AccountChart a {
						text-decoration:none;
					}
					.AccountChart .storno a {
						color: #f0f;
					}
				</style>
			</head>
			<body>
				<ul class="nav">
					<li>
						<a href="{$home-web-gui}/{$tenant}/{$year}/bookings/refresh.html">Summen &amp; Salden aktualisieren</a>
					</li>
				</ul>
				<h1>Bilanz für das Geschäftsjahr <xsl:value-of select="$year"/> (TEST)</h1>
				<xsl:apply-templates/>
			</body>
		</html>
	</xsl:template>

	<xsl:template match="AccountingSheet">
		<div class="Account-Chart">
			<h2>Einnahmen-Überschuss</h2>
			<xsl:apply-templates select="Account[@name='Aktiva/Passiva']"/>
		</div>

		<div class="Account-Chart">
			<h2>Gewinn- und Verlust (GuV)</h2>
			<xsl:apply-templates select="Account[@name='Gewinn- und Verlustkonto']"/>
		</div>
	</xsl:template>

	<xsl:template match="Account">
		<xsl:variable name="current" select="."/>
		<xsl:variable name="Accounts" select="/result/Accounting/Account"/>
		<table class="AccountChart">
			<tr>
				<xsl:attribute name="style">
					<xsl:choose>
						<xsl:when test="not(contains-token(@classes,'creditor'))">
							<xsl:text>background-color:#CCC</xsl:text>
						</xsl:when>
						<xsl:when test="format-number(@credit,'#.##0,00','EU') != format-number(@debit,'#.##0,00','EU')">
							<xsl:text>background-color:#F41</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text>background-color:#6e6</xsl:text>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>			
				<td colspan="5">
					<xsl:text>[</xsl:text>
					<xsl:value-of select="@kto"/>
					<xsl:text>] "</xsl:text>
					<xsl:value-of select="@name"/>
					<xsl:text>"</xsl:text>
				</td>
			</tr>
			<tr>
				<th style="width:45%; text-align:left" colspan="2">
					<xsl:text>Aktiva</xsl:text>
				</th>
				<th style="width:45%; text-align:right" colspan="2">
					<xsl:text>Passiva</xsl:text>
				</th>
			</tr>
			<xsl:for-each select="for $i in (1 to max((count(Credits/Booking), count(Debits/Booking))) ) return $i">
				<xsl:variable name="pos" select="if (. = ()) then 0 else xs:integer(.)"/>
				<xsl:variable name="credit" select="$current/Credits/Booking[$pos]/@debit"/>
				<xsl:variable name="debit" select="$current/Debits/Booking[$pos]/@credit"/>
				<tr>
					<!-- Credits -->
					<td>
						<xsl:if test="$current/Credits/Booking[$pos]">
							<xsl:value-of select="$current/Credits/Booking[$pos]/@description"/>
							<a href="{$home-web-gui}/{$tenant}/{$year}/bookings/accounts.html#{$current/Credits/Booking[$pos]/@credit}" style="color:#bbb" target="_blank">
								<xsl:text>  [</xsl:text>
								<xsl:value-of select="$current/Credits/Booking[$pos]/@credit"/>
								<xsl:text>]</xsl:text>
							</a>
						</xsl:if>
					</td>
					<td style="text-align:right;" class="{if ($current/Credits/Booking[$pos]/@isStorno='true') then 'storno' else ()}">
						<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/binders/',$current/Credits/Booking[$pos]/@pro,'/search.html')}" title="{$current/Credits/Booking[$pos]/@description}">
							<xsl:value-of select="replace(format-number($current/Credits/Booking[$pos]/@amountValue,'#.##0,00','EU'),'NaN','')"/>
						</a>
					</td>

					<!-- Debits -->
					<td>
						<xsl:if test="$current/Debits/Booking[$pos]">
							<xsl:value-of select="$current/Debits/Booking[$pos]/@description"/>
							<a href="{$home-web-gui}/{$tenant}/{$year}/bookings/accounts.html#{$current/Debits/Booking[$pos]/@debit}" style="color:#bbb" target="_blank">
								<xsl:text>  [</xsl:text>
								<xsl:value-of select="$current/Debits/Booking[$pos]/@debit"/>
								<xsl:text>]</xsl:text>
							</a>
						</xsl:if>
					</td>
					<td style="text-align:right" class="{if ($current/Debits/Booking[$pos]/@isStorno='true') then 'storno' else ()}">
						<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/binders/',$current/Debits/Booking[$pos]/@pro,'/search.html')}" title="{$current/Debits/Booking[$pos]/@description}">
							<xsl:value-of select="replace(format-number($current/Debits/Booking[$pos]/@amountValue,'#.##0,00','EU'),'NaN','')"/>
						</a>
					</td>
				</tr>
			</xsl:for-each>
			<tr style="font-weight:bold">
				<td colspan="2">
					<xsl:value-of select="format-number(@credit,'#.##0,00','EU')"/>
					<xsl:text> EUR</xsl:text>

					<xsl:if test="@credit != @debit">
						<span style="font-weight:normal">
							<xsl:text> (diff. </xsl:text>
							<xsl:value-of select="format-number(@credit - @debit,'#.##0,00','EU')"/>
							<xsl:text> ) </xsl:text>
						</span>
					</xsl:if>
				</td>
				<td colspan="3">
					<xsl:value-of select="format-number(@debit,'#.##0,00','EU')"/>
					<xsl:text> EUR</xsl:text>
					
					<xsl:if test="@credit != @debit">
						<span style="font-weight:normal">
							<xsl:text> (diff. </xsl:text>
							<xsl:value-of select="format-number(@debit - @credit,'#.##0,00','EU')"/>
							<xsl:text> ) </xsl:text>
						</span>
					</xsl:if>
				</td>
			</tr>
		</table>
		<br/>
	</xsl:template>

</xsl:stylesheet>