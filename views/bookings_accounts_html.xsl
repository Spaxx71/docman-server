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
					#content div {
						max-width: 49%;
					}
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
				<h1>Übersicht aller Buchungen</h1>
				<xsl:apply-templates/>
			</body>
		</html>
	</xsl:template>

	<xsl:template match="Accounting">
		<div class="Kreditoren" style="float:left">
			<h3>Kreditoren</h3>
			<xsl:apply-templates select="Account[contains-token(@classes,'creditor')]"/>
		</div>
		<div class="Debitoren" style="float:right">
			<h3>Debitoren</h3>
			<xsl:apply-templates select="Account[contains-token(@classes,'debitor')]"/>
		</div>

		<hr style="clear:both"/>

		<div class="Aktiva" style="float:left">
			<h3>Aktiv-Konten</h3>
			<xsl:apply-templates select="Account[contains-token(@classes,'essets')]"/>
		</div>
		<div class="Passiva" style="float:right">
			<h3>Passiv-Konten</h3>
			<xsl:apply-templates select="Account[contains-token(@classes,'liabilities')]"/>
		</div>

		<hr style="clear:both"/>

		<div class="Aufwand" style="float:left">
			<h3>Aufwands-Konten</h3>
			<xsl:apply-templates select="Account[contains-token(@classes,'expenses')]"/>
		</div>	
		<div class="Erfolg" style="float:right">
			<h3>Erfolgs-Konten</h3>
			<xsl:apply-templates select="Account[contains-token(@classes,'revenues')]"/>
		</div>

		<hr style="clear:both"/>
		<div class="Sonstige" style="float:right">
			<h3>Sonstige</h3>
			<xsl:apply-templates select="Account[not(contains-token(@classes,'creditor') or contains-token(@classes,'debitor') or contains-token(@classes,'essets') or contains-token(@classes,'liabilities') or contains-token(@classes,'expenses') or contains-token(@classes,'revenues'))]"/>
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
				<td colspan="7">
					<xsl:text>Konto </xsl:text>
					<xsl:value-of select="@kto"/>
					<xsl:text> – "</xsl:text>
					<xsl:value-of select="@name"/>
					<xsl:text>"</xsl:text>
				</td>
			</tr>
			<tr>
				<th>
					<xsl:value-of select="Notes"/>
				</th>
			</tr>
			<tr>
				<th style="width:10%">#</th>
				<th style="width:45%" colspan="3">
					<xsl:choose>
						<xsl:when test="contains-token(@classes,'essets') or contains-token(@classes,'expenses') or contains-token(@classes,'creditor')">
							<xsl:text>[+] </xsl:text>
						</xsl:when>
						<xsl:when test="contains-token(@classes,'liabilities') or contains-token(@classes,'revenues') or contains-token(@classes,'debitor')">
							<xsl:text>[-] </xsl:text>
						</xsl:when>
					</xsl:choose>
					<xsl:text>Soll</xsl:text>
				</th>
				<th style="width:45%; text-align:right" colspan="3">
					<xsl:text>Haben</xsl:text>
					<xsl:choose>
						<xsl:when test="contains-token(@classes,'essets') or contains-token(@classes,'expenses') or contains-token(@classes,'creditor')">
							<xsl:text> [-]</xsl:text>
						</xsl:when>
						<xsl:when test="contains-token(@classes,'liabilities') or contains-token(@classes,'revenues') or contains-token(@classes,'debitor')">
							<xsl:text> [+]</xsl:text>
						</xsl:when>
					</xsl:choose>
				</th>
			</tr>
			<xsl:for-each select="for $i in (1 to max((count(Credits/Booking), count(Debits/Booking))) ) return $i">
				<xsl:variable name="pos" select="if (. = ()) then 0 else xs:integer(.)"/>
				<xsl:variable name="credit" select="$current/Credits/Booking[$pos]/@debit"/>
				<xsl:variable name="debit" select="$current/Debits/Booking[$pos]/@credit"/>
				<tr>
					<td><xsl:value-of select="number(.)"/></td>
					<!-- Credits -->
					<td><xsl:value-of select="$current/Credits/Booking[$pos]/@description"/></td>
					<td style="text-align:right;" class="{if ($current/Credits/Booking[$pos]/@isStorno='true') then 'storno' else ()}">
						<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/binders/',$current/Credits/Booking[$pos]/@pro,'/search.html')}" title="{$current/Credits/Booking[$pos]/@description}">
							<xsl:value-of select="replace(format-number($current/Credits/Booking[$pos]/@amountValue,'#.##0,00','EU'),'NaN','')"/>
						</a>
					</td>
					<td class="{if ($current/Credits/Booking[$pos]/@isStorno='true') then 'storno' else ()}">
						<a href="{concat($home-web-gui,'/',$tenant,'/accounts/',$current/Credits/Booking[$pos]/@credit,'/details.html')}" title="{$Accounts[@kto=$credit]/@name}">
							<xsl:value-of select="$current/Credits/Booking[$pos]/@debit"/>
						</a>
					</td>

					<!-- Debits -->
					<td><xsl:value-of select="$current/Debits/Booking[$pos]/@description"/></td>
					<td style="text-align:right" class="{if ($current/Debits/Booking[$pos]/@isStorno='true') then 'storno' else ()}">
						<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/binders/',$current/Debits/Booking[$pos]/@pro,'/search.html')}" title="{$current/Debits/Booking[$pos]/@description}">
							<xsl:value-of select="replace(format-number($current/Debits/Booking[$pos]/@amountValue,'#.##0,00','EU'),'NaN','')"/>
						</a>
					</td>
					<td class="{if ($current/Debits/Booking[$pos]/@isStorno='true') then 'storno' else ()}">
						<a href="{concat($home-web-gui,'/',$tenant,'/accounts/',$current/Debits/Booking[$pos]/@debit,'/details.html')}" title="{$Accounts[@kto=$debit]/@name}">
							<xsl:value-of select="$current/Debits/Booking[$pos]/@credit"/>
						</a>
					</td>
				</tr>
			</xsl:for-each>
			<tr style="font-weight:bold">
				<td>Saldo</td>
				<td colspan="3">
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

	<xsl:template match="Bookings">
	</xsl:template>

	<xsl:template match="Booking"/>

</xsl:stylesheet>