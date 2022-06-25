<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:err="http://www.w3.org/2005/xqt-errors" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="3.0">
 
	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="home-views"/>
	<xsl:param name="home-data"/>
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="path" required="yes"/>
	<xsl:param name="year" required="yes"/>
	<xsl:param name="resource-id" required="yes"/>
	<xsl:param name="format"/>

	<xsl:import href="templates/banking_templates.xsl"/>
	<xsl:import href="templates/analysis_templates.xsl"/>

	<xsl:template match="/">
		<page>
			<body>
				<xsl:if test="result/BankAccount/@hasOnlineBanking=true()">
					<ul class="Nav">
						<li>
							<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/banking/',$resource-id,'/update.html')}">per Onlinebaning aktualiseren…</a>
						</li>
					</ul>
				</xsl:if>

				<h3>Übersicht Bankbewegungen</h3>
				<xsl:call-template name="BalanceGraph">
					<xsl:with-param name="Analysis" select="result/Analysis"/>
					<xsl:with-param name="HomeWebGui" select="$home-web-gui"/>
				</xsl:call-template>
				<br/>
				<br/>
				<h3>Liste der Bankbewegungen</h3>
				<xsl:apply-templates/>
			</body>
		</page>
	</xsl:template>

	<xsl:template match="result">
		<xsl:apply-templates/> 
	</xsl:template>

	<xsl:template match="BankStatement">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="BankAccounts">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="BankAccount">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="BankAccountDetail">
		<xsl:call-template name="BankAccountDetail">
			<xsl:with-param name="BankAccountDetail" select="."/>
		</xsl:call-template>
		<br/> 
	</xsl:template>
<!--
	<xsl:template name="Accountings">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template name="Accounting">
	</xsl:template>
-->

	<xsl:template match="Accounts"/>

	<xsl:template match="Account"/>

	<xsl:template match="Balances"/>

	<xsl:template match="Balance"/>

	<!--
	<xsl:template match="@*|node()" priority="-1">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
	-->

	<xsl:template name="MoneyGraph-Deprecated">
		<xsl:variable name="width" select="1000"/>
		<xsl:variable name="height" select="300"/>
		<xsl:variable name="min" select="min(//BankAccount/Accountings/Accounting/@saldoAmount)"/>
		<xsl:variable name="max" select="max(//BankAccount/Accountings/Accounting/@saldoAmount)"/>
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
					<xsl:for-each select="//BankAccount/Accountings/Accounting">
						<xsl:if test=".[not(@saldoAmount) or not(@saldoAmount castable as xs:double)]">
							<div>Position #<xsl:value-of select="position()"/> hat keinen (gültigen) Saldo</div>
						</xsl:if>
					</xsl:for-each>
				</error>
			</xsl:when>
			<xsl:otherwise>
		<xsl:try>
		<svg class="chart" viewBox="0 0 {$width} {$height}" style="font-size:80%"> <!-- viewBox="0 0 {$width} {$height}" -->
			<rect width="{$width}" height="{$height}" style="fill:#eeeeee"/>
			<line x1="0" y1="{$height - $offset * $stepY}" x2="{$width}" y2="{$height - $offset * $stepY}" style="stroke:rgb(255,64,64);stroke-width:1"/>

			<xsl:for-each select="1 to 12"> 

				<line x1="{. * 365 div 12 * $stepX}" y1="0" x2="{. * 365 div 12 * $stepX}" y2="{$height}" style="stroke:rgb(128,128,128);stroke-width:1;stroke-dasharray:1,2"/> 
				<text x="{(. - 0.5)  * 365 div 12 * $stepX}" y="{$height - 5}" text-anchor="middle" style="fill:#999">
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
			<text x="0" y="12"><xsl:value-of select="format-number($max,'#.##0,00','EU')"/> EUR</text>

			<polyline fill="none" stroke="#0074d9" stroke-width="1">
				<xsl:attribute name="points">
					<!-- inital saldo -->
					<xsl:text>0,</xsl:text>
					<xsl:value-of select="(//BankAccount/Accountings/@saldoInitAmount + $offset) * $stepY"/>
					<xsl:text> </xsl:text>

					<!-- iterate through all transactions -->
					<xsl:for-each-group select="//BankAccount/Accountings/Accounting[substring(ValueDate,1,4)=$year]" group-by="ValueDate">
						<xsl:sort select="current-grouping-key()"/>
						<xsl:variable name="avg" select="sum(current-group()/@saldoAmount) div count(current-group()/@saldoAmount)"/>
						<xsl:value-of select="xs:integer((xs:date(ValueDate) - xs:date(concat(year-from-date(ValueDate),'-01-01'))) div xs:dayTimeDuration('P1D')) * $stepX"/>
						<xsl:text>,</xsl:text> 
						<xsl:value-of select="$height - (($avg + $offset) * $stepY)"/>
						<xsl:text> </xsl:text>
					</xsl:for-each-group>
				</xsl:attribute>
			</polyline>

			<xsl:for-each-group select="//BankAccount/Accountings/Accounting[substring(ValueDate,1,4)=$year]" group-by="ValueDate">
				<xsl:sort select="current-grouping-key()"/>
				<xsl:variable name="avg" select="sum(current-group()/@saldoAmount) div count(current-group()/@saldoAmount)"/>
				<circle cx="{xs:integer((xs:date(ValueDate) - xs:date(concat(year-from-date(ValueDate),'-01-01'))) div xs:dayTimeDuration('P1D')) * $stepX}" cy="{$height - (($avg + $offset) * $stepY)}" r="2" stroke="red" stroke-width="0.3" fill="#0074d9"/>
			</xsl:for-each-group>

<!-- DEBUG ONLY:
			<text x="50" y="50">
				<xsl:for-each-group select="//BankAccount/Accountings/Accounting" group-by="ValueDate">
					<xsl:sort select="current-grouping-key()" data-type="text"/>
					<xsl:variable name="avg" select="sum(current-group()/@saldoAmount) div count(current-group()/@ saldoAmount)"/>

					<xsl:text> </xsl:text>
					<xsl:value-of select="current-grouping-key()"/>
					<xsl:text>=</xsl:text>
					<xsl:value-of select="$avg"/>
					<xsl:value-of select="'&#xA;&#xD;'"/>
				</xsl:for-each-group>
			</text>
-->
			<xsl:choose>
				<xsl:when test="$min &lt; 0">
					<text x="0" y="{$height - $offset * $stepY}">0,00 EUR</text>
					<text x="0" y="{$height}"><xsl:value-of select="format-number($min,'#.##0,00','EU')"/> EUR</text>
				</xsl:when>
				<xsl:otherwise>
					<text x="0" y="{$height}">0 EUR</text>
				</xsl:otherwise>
			</xsl:choose>
			<!-- <text x="50" y="50"><xsl:value-of select="'test'"/></text> -->

		</svg>
			<xsl:catch>
      				<error>Beim Erstellen der Verlaufkurve ist es zu einem Ausnahmefehler gekommen:
         			 Error code: <xsl:value-of select="$err:code"/>
         			 Reason: <xsl:value-of select="$err:description"/>
				 <!-- At: <xsl:value-of select="$err:module"/>,<xsl:value-of select="$err:line-number"/>,<xsl:value-of select="$err:column-number"/> -->
     				</error>
			</xsl:catch>
		</xsl:try>

		<!-- Validation -->
		<xsl:for-each select="//BankAccount/Accountings/Accounting">
				<xsl:if test=".[not(@saldoAmount) or not(@saldoAmount castable as xs:double)]">
					<div>Position #<xsl:value-of select="position()"/> hat keine Saldo</div>
				</xsl:if>
		</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>


</xsl:stylesheet>