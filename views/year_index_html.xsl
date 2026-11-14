<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:math="http://www.w3.org/2005/xpath-functions/math" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>             
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="year" required="yes"/>
	<xsl:param name="username" required="yes"/>

	<xsl:import href="templates/analysis_templates.xsl"/>
 
	<xsl:template match="/">
		<page>
			<body>
				<ul class="nav">
					<li>
						<a href="{$home-web-gui}/{$tenant}/{$year}/binders/enter/index.html">Neues Dokument</a>
					</li>
				</ul>

				<div style="float:left; width:auto; padding-right:1rem;">
					<h3>
						<a href="{$home-web-gui||'/'||$tenant||'/'||$year||'/process/search.html'}">Dokumentenablage</a>
					</h3>
					<ul>
						<xsl:for-each select="//Binders/Binder">
							<li>
								<a href="{$home-web-gui||'/'||$tenant||'/'||$year||'/binders/'||@name||'/index.html'}">
									<xsl:value-of select="@name"/>
								</a>
							</li>
						</xsl:for-each>
					</ul>

					<h3>Dokumenten Eingänge</h3>
					<ul>
						<li>
							<a href="{$home-web-gui||'/'||$tenant||'/'||$year||'/mail/index.html'}">E-Mail Posteingang</a>
						</li>

						<li>
							<a href="{$home-web-gui||'/'||$tenant||'/'||$year||'/transfer/index.html'}">Transfer Ordner</a>
						</li>
					</ul>

					<h3><a href="{$home-web-gui||'/'||$tenant||'/'||$year||'/banking/index.html'}">Bankverbindungen</a></h3>
					<ul>
						<xsl:for-each select="//BankAccount">
							<li>
								<a href="{$home-web-gui||'/'||$tenant||'/'||$year||'/banking/'||@kto||'/index.html'}">
									<xsl:choose>
										<xsl:when test="BankAccountDetail/KTNR/text()">								
											<xsl:text>Bank </xsl:text>
											<xsl:value-of select="BankAccountDetail/AccountNick"/>
											<xsl:if test="BankAccountDetail/KTNR/text()">
												<xsl:text> (</xsl:text>
												<xsl:value-of select="BankAccountDetail/KTNR"/>
												<xsl:text>)</xsl:text>
											</xsl:if>
										</xsl:when>
										<xsl:otherwise>
											<xsl:text>Bank </xsl:text>
											<xsl:value-of select="BankAccountDetail/AccountName"/>
										</xsl:otherwise>
									</xsl:choose>
								</a>
							</li>
						</xsl:for-each>
					</ul>

					<h3><a href="{$home-web-gui}/{$tenant}/{$year}/bookings/index.html">Buchhaltung</a></h3>
					<ul>
						<li>
							<a href="{$home-web-gui}/{$tenant}/{$year}/bookings/accounts.html">Buchhaltung Hauptbuch</a>
						</li>
						<li>
							<a href="{$home-web-gui}/{$tenant}/{$year}/bookings/sheet.html">Buchhaltung Bilanz</a>
						</li>
						<li>
							<a href="{$home-web-gui}/{$tenant}/{$year}/bookings/refresh.html">Summen &amp; Salden aktualisieren</a>
						</li>
					</ul>
	
					<h3>Stammdaten Verwaltung</h3>
					<ul>
						<li>
							<a href="{$home-web-gui||'/'||$tenant||'/'||$year||'/accounts/index.html?type=ledger_account'}">Personenkonten (Debitoren / Kreditoren)</a>
						</li>
						<li>
							<a href="{$home-web-gui||'/'||$tenant||'/'||$year||'/accounts/index.html?type=nominal_account'}">Sachkonten</a>
						</li>
						<xsl:if test="$username=lower-case('eduard.huber') or $username=lower-case('extern.friederike.pfaffinger')">
							<li>
								<a href="{$home-web-gui||'/'||$tenant||'/'||$year||'/banking/index.html'}">Bankkonten</a>
							</li>
						</xsl:if>
						<li>
							<a href="{$home-web-gui||'/'||$tenant||'/'||$year||'/categories/index.html'}">Budget-Kategorien</a>
						</li>
					</ul>

					<h3>Tools</h3>
					<ul>
						<!-- wiederkehrende Zahlungen erstellen und Verküpfen -->
						<!-- /rest/db/apps/docman/modules/functions/automatic/automatic_periodic-payments.xqy -->
						<li>
							<a href="{$home-web-gui||'/'||$tenant||'/'||$year||'/test.html'}">Konstistenz und Validität der Daten</a>
						</li>
					</ul>
				</div>

				<div style="float:right; width:max-content; max-width:75%; border-left:1rem;">
					<h3>Dashboard</h3>
					<xsl:apply-templates select="result/Dashboard"/>
					<br/>
					<div>
						<br/>
						<h3>Übersicht Ein/Ausgaben</h3>
						<xsl:choose>
							<xsl:when test="result/Analysis/Balances/*">
								<xsl:call-template name="BalanceGraph">
									<xsl:with-param name="Analysis" select="result/Analysis"/>
								</xsl:call-template>
							</xsl:when>
							<xsl:otherwise>
								Keine Bankbeweungen vorhanden.
							</xsl:otherwise>
						</xsl:choose>
					</div>
				</div>

				<div style="clear:both"> </div>
			</body>
		</page>
	</xsl:template>

	<xsl:template match="result"/>

	<xsl:template match="Dashboard">
		<xsl:choose>
			<xsl:when test="OverallCount/@count castable as xs:positiveInteger and OverallCount/Mapped castable as xs:nonNegativeInteger and OverallCount/DocumentsOpen castable as xs:nonNegativeInteger and OverallCount/BankingsOpen castable as xs:nonNegativeInteger and OverallCount/Transfer castable as xs:nonNegativeInteger and OverallCount/Email castable as xs:nonNegativeInteger">
				<xsl:variable name="Segments">
					<Segments count="{OverallCount/@count}">
						<Segment index="1" percent="{OverallCount/Mapped * 100 div OverallCount/@count}" name="Verbucht" count="{OverallCount/Mapped}"/>
						<Segment index="2" percent="{OverallCount/DocumentsOpen * 100 div OverallCount/@count}" name="Vorgänge ohne Verknüpfung" count="{OverallCount/DocumentsOpen}"/>
						<Segment index="3" percent="{OverallCount/BankingsOpen * 100 div OverallCount/@count}" name="Unverknüpfte Bankbewegungen" count="{OverallCount/BankingsOpen}"/>
						<Segment index="4" percent="{OverallCount/Transfer * 100 div OverallCount/@count}" name="Transfer-Ordner" count="{OverallCount/Transfer}"/>
						<Segment index="5" percent="{OverallCount/Email * 100 div OverallCount/@count}" name="E-Mails unerledigt" count="{OverallCount/Email}"/>
					</Segments>
				</xsl:variable>

				<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" id="head" version="1.1" font-family="Helvetica, Arial" width="750" height="424">

					<style id="styles" type="text/css"> <![CDATA[
					.series-areas-general {
						stroke-width: 0;
					}
					#segment1,
					#legend-area1 {
						fill: rgb(0, 192, 0);
					}
					#segment2,
					#legend-area2 {
						fill: rgb(255, 204, 80);
					}
					#segment3,
					#legend-area3 {
						fill: rgb(255, 204, 170);
					}
					#segment4,
					#legend-area4 {
						fill: rgb(255, 100, 0);
					}
					#segment5,
					#legend-area5 {
						fill: rgb(192, 64, 0);
					}
					]]>
					</style>

					<style id="styles" type="text/css"> <![CDATA[
					.legendbox {
						stroke:       black;
						stroke-width: 1;
						fill:         white;
					}
					.legendtext {
						font-size:   15px;
						text-anchor: start;
					}
					]]>
					</style>

					<!-- Tortendiagram -->
					<g id="segments" class="series-areas-general"> <!-- transform="scale(1, 1) translate(12, -412)" -->
						<xsl:for-each select="$Segments/Segments/Segment">
							<xsl:call-template name="pie">
								<xsl:with-param name="index" select="@index"/>
								<xsl:with-param name="percentStart" select="sum(preceding-sibling::Segment/@percent)"/>
								<xsl:with-param name="percent" select="@percent"/>
							</xsl:call-template>
						</xsl:for-each>
					</g>

					<!-- Legende -->
					<g id="legend" transform="translate(280, 52)">
						<rect id="legend-background" class="legendbox" x="0" y="0" width="370" height="{(count($Segments/Segments/Segment)+1) * 20 + 15}"/>

						<xsl:for-each select="$Segments/Segments/Segment">
							<rect id="legend-area{@index}" class="series-area" x="10" y="{-10 + (20 * @index)}" width="30" height="15"/>
							<text id="legend-text{@index}" class="legendtext" x="50" y="{(20 * @index)}"><xsl:value-of select="@name"/>  [<xsl:value-of select="@count"/>]</text>
						</xsl:for-each>

						<text id="legend-text{@index}" class="legendtext" x="50" y="{(20 * (count($Segments/Segments/Segment)+1) )}">Gesamt: [<xsl:value-of select="$Segments/Segments/@count"/>] Stück</text>
					</g>
				</svg>
			</xsl:when>
			<xsl:otherwise>
				<div>No Dashbord</div>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>	

	<xsl:template match="Balances"/>
	<xsl:template match="Balance"/>
	
	<xsl:template match="node()|@*" priority="-1"/>

	<xsl:template name="pie">
		<xsl:param name="radius" select="100"/>
		<xsl:param name="index" required="yes"/>
		<xsl:param name="percentStart" required="yes"/>
		<xsl:param name="percent" required="yes"/>
		<xsl:variable name="angS" select="2 * math:pi() * $percentStart div 100"/>
		<xsl:variable name="angE" select="2 * math:pi() * $percent div 100"/>

		<xsl:variable name="centre" select="120"/>
		
		<xsl:variable name="largeArcFlag">
			<xsl:choose>
				<xsl:when test="$percent &gt; 50">
					<xsl:value-of select="1"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="0"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<!-- <text x="100" y="{100+$index*20}">[<xsl:value-of select="$percentStart"/>|<xsl:value-of select="$percent"/>]</text>  -->
		<!-- rotate() -->
		<path id="segment{$index}" class="segment" transform="translate({$centre} {$centre}) rotate({360 * $percentStart div 100})" d="M {$radius},0 A {$radius},{$radius} 0 {$largeArcFlag} 1 {xs:integer(math:cos($angE) * $radius)},{xs:integer(math:sin($angE) * $radius)} L 0,0 z"/>
		<text transform="translate({$centre} {$centre})" text-anchor="middle" x="{xs:integer(math:cos($angS + $angE div 2) * $radius div 1.6)}" y="{xs:integer(math:sin($angS + $angE div 2) * $radius div 1.6)}"><xsl:value-of select="format-number($percent,'0.00')"/>%</text>

	</xsl:template>
</xsl:stylesheet>