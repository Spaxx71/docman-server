<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" version="3.0">

	<!--  overview of XSL-FO Elements: https://www.data2type.de/xml-xslt-xslfo/xsl-fo/xslfo-referenz/ -->

	<xsl:param name="lang"/>
	<xsl:param name="serverName"/>
	<xsl:param name="environment" required="yes"/>

	<xsl:variable name="RootPath" select="'/db/apps/'||$environment"/>

	<xsl:template match="/">
		<xsl:apply-templates/>
	</xsl:template>


	<!-- #################### HTMl Block handling #################### -->
	<xsl:template match="header">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="main">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="body">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="article">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="section">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="footer">
		<xsl:apply-templates/>
	</xsl:template>

	<!-- #################### Page Block handling #################### -->

	<xsl:template match="html">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="pageXXX">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="page/crosslinks">
		<!-- do nothing -->
	</xsl:template>

	<xsl:template match="pageblock">
		<!-- <fo:flow flow-name="xsl-region-body"> -->
		<fo:block margin-left="-20mm" padding-left="20mm" margin-right="-20mm" padding-right="20mm">

			<xsl:choose>
				<xsl:when test="@background-color">
					<xsl:attribute name="background-color" select="@background-color"/>
				</xsl:when>
				<xsl:when test="'BgColorCTA'=tokenize(@class,' ')">
					<xsl:attribute name="background-color" select="'#9f9292'"/>
				</xsl:when>
				<xsl:when test="'BgColorSand'=tokenize(@class,' ')">
					<xsl:attribute name="background-color" select="'#faebd7'"/>
				</xsl:when>
				<xsl:when test="'BgColorSandLight'=tokenize(@class,' ')">
					<xsl:attribute name="background-color" select="'#fef9ef'"/>
				</xsl:when>
				<xsl:when test="'BgColorBlue'=tokenize(@class,' ')">
					<xsl:attribute name="background-color" select="'#0161a3'"/>
				</xsl:when>
			</xsl:choose>

			<xsl:choose>
				<xsl:when test="flexblock">

					<!-- align="right" -->
					<fo:table table-layout="fixed">
						<xsl:for-each select="flexblock">
							<fo:table-column/>
						</xsl:for-each>
						<fo:table-body>
							<fo:table-row>
								<xsl:apply-templates/>
							</fo:table-row>
						</fo:table-body>
					</fo:table>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates/>
				</xsl:otherwise>
			</xsl:choose>
		</fo:block>
	</xsl:template>

	<xsl:template match="flexblock">
		<fo:table-cell>
			<xsl:choose>
				<xsl:when test="@class='BgColorBlueSandLight'">
					<xsl:attribute name="background-color" select="'#e0eefe'"/>
				</xsl:when>
				<xsl:when test="image | img">
					<xsl:attribute name="background-color" select="'#6b5f57'"/>
				</xsl:when>			
			
			</xsl:choose>

			<xsl:if test="../@align='right'">
				<xsl:attribute name="column-number">
					<xsl:value-of select="count(../flexblock) - count(preceding-sibling::flexblock)"/>
				</xsl:attribute>
			</xsl:if>
			<fo:block>
				<xsl:apply-templates/>
			</fo:block>
		</fo:table-cell>
	</xsl:template>

	<xsl:template match="textblock">
		<fo:block margin="10mm">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<!-- #################### no content blocks #################### -->
	<xsl:template match="sitemap">
		<!-- nothing to do -->
	</xsl:template>

	<xsl:template match="nav">
		<!-- nothing to do -->
	</xsl:template>


	<xsl:template match="page">
		<page>
			<xsl:apply-templates/>
		</page>
	</xsl:template>

	<xsl:template match="page/treenode">
		<xsl:copy-of select="treenode"/>
	</xsl:template>

	<xsl:template match="page/tags">
		<xsl:copy-of select="treenode"/>
	</xsl:template>


	<xsl:template match="topics">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="topic">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="content">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="head | menu">
		<!-- nothingToDo(); -->
	</xsl:template>

	<xsl:template match="style">
		<!-- nothingToDo(); -->
	</xsl:template>

	<xsl:template match="crosslinkanker">
		<fo:block id="{@id}"/>
	</xsl:template>

	<!-- #################### taglib handling #################### -->

	<xsl:template match="teasers">
		<!-- nothing to do -->
	</xsl:template>
	<xsl:template match="button">
		<fo:basic-link external-destination="{@url}" color="#00017F" border="1px solid orangered">
			<xsl:value-of select="@url"/>
		</fo:basic-link>
	</xsl:template>
	<xsl:template match="linkbox">
		<!-- nothingToDo(); -->
	</xsl:template>
	<xsl:template match="intro">
		<!-- nothingToDo(); -->
	</xsl:template>
	<xsl:template match="Tree">
		<!-- nothingToDo(); -->
	</xsl:template>
	<xsl:template match="input">
		<!-- nothingToDo(); -->
	</xsl:template>
	<xsl:template match="acronym">
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="form">
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="firm">
		<fo:inline color="#666633" font-weight="bold">
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>
	<!-- <fo:float> wird vom FOP nicht unterstützt -->
	<xsl:template match="float_right">
		<fo:block intrusion-displace="line">
			<!--fo:float float="left"-->
			<fo:block>
				<xsl:apply-templates/>
			</fo:block>
			<!--/fo:float-->
		</fo:block>
	</xsl:template>
	<!-- <fo:float> wird vom FOP nicht unterstützt -->
	<xsl:template match="float_left">
		<fo:block intrusion-displace="line">
			<!--fo:float float="left"-->
			<fo:block>
				<xsl:apply-templates/>
			</fo:block>
			<!--/fo:float-->
		</fo:block>
	</xsl:template>
	<xsl:template match="page-break">
		<fo:block break-before="page"/>
	</xsl:template>
	<xsl:template match="div">
		<fo:block>
			<xsl:choose>
				<xsl:when test="@class = 'Headline' ">
					<xsl:attribute name="font-size">14pt</xsl:attribute>
					<xsl:attribute name="font-weight">bold</xsl:attribute>
					<xsl:attribute name="space-before">6pt</xsl:attribute>
					<xsl:attribute name="space-after">6pt</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'Subline' ">
					<xsl:attribute name="font-size">12pt</xsl:attribute>
					<xsl:attribute name="font-weight">bold</xsl:attribute>
					<xsl:attribute name="space-before">6pt</xsl:attribute>
					<xsl:attribute name="space-after">6pt</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'Title' ">
					<xsl:attribute name="space-before">10pt</xsl:attribute>
					<xsl:attribute name="space-after">8pt</xsl:attribute>
					<xsl:attribute name="font-size">10pt</xsl:attribute>
					<xsl:attribute name="font-weight">bold</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'Consideration' ">
					<xsl:attribute name="font-size">7pt</xsl:attribute>
					<xsl:attribute name="font-style">italic</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'Box' ">
					<xsl:attribute name="border">solid 0.1pt #cccccc</xsl:attribute>
					<xsl:attribute name="padding">2pt 0pt 0pt 2pt</xsl:attribute>
					<xsl:attribute name="space-before">12pt</xsl:attribute>
					<xsl:attribute name="space-after">4pt</xsl:attribute>
					<xsl:attribute name="background-color">#EFEAE0</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'TitleBox' ">
					<xsl:attribute name="border">solid 0.1pt #cccccc</xsl:attribute>
					<xsl:attribute name="padding">2pt 0pt 0pt 2pt</xsl:attribute>
					<xsl:attribute name="space-before">12pt</xsl:attribute>
					<xsl:attribute name="space-after">4pt</xsl:attribute>
					<xsl:attribute name="background-color">#EFEAE0</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'SubTitleBox' ">
					<xsl:attribute name="border">solid 0.1pt #cccccc</xsl:attribute>
					<xsl:attribute name="padding">2pt 0pt 0pt 2pt</xsl:attribute>
					<xsl:attribute name="space-before">12pt</xsl:attribute>
					<xsl:attribute name="space-after">4pt</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'Accent' ">
					<xsl:attribute name="color">#32659C</xsl:attribute>
					<xsl:attribute name="background-color">#EBEFFA</xsl:attribute>
					<xsl:attribute name="padding">10px</xsl:attribute>
					<xsl:attribute name="space-before">1em</xsl:attribute>
					<xsl:attribute name="space-after">1em</xsl:attribute>
					<xsl:attribute name="font-style">italic</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'Saying' ">
					<xsl:attribute name="color">#32659C</xsl:attribute>
					<xsl:attribute name="background-color">#EBEFFA</xsl:attribute>
					<xsl:attribute name="padding">10px</xsl:attribute>
					<xsl:attribute name="space-before">1em</xsl:attribute>
					<xsl:attribute name="space-after">1em</xsl:attribute>
					<xsl:attribute name="font-style">italic</xsl:attribute>
				</xsl:when>
			</xsl:choose>
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>
	<xsl:template match="span">
		<fo:inline>
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>
	<xsl:template match="i">
		<fo:inline font-style="italic">
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>
	<xsl:template match="b">
		<fo:inline font-weight="bold">
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>
	<xsl:template match="p">
		<xsl:choose>
			<xsl:when test="@class='Source'">
				<fo:block space-before="5pt" space-after="15pt" border-color="#DFDFDF" border-style="solid" border-width="0.5pt" background-color="#EFEFEF" color="#333" white-space-collapse="false">
					<xsl:apply-templates/>
				</fo:block>
			</xsl:when>
			<xsl:otherwise>
				<fo:block padding-before="5pt" padding-after="5pt">
					<xsl:apply-templates/>
				</fo:block>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="br">
		<fo:block>
			<xsl:if test="local-name(following::node()[1]) = 'br'">
				<xsl:attribute name="space-after">1em</xsl:attribute>
			</xsl:if>
		</fo:block>
	</xsl:template>
	<xsl:template match="hr">
		<fo:block>
			<fo:leader leader-length="100%" rule-thickness="0.5pt" leader-pattern="dots"/>
		</fo:block>
	</xsl:template>
	<xsl:template match="a | link">
		<!-- issue param $lang funktioniert nicht bei en o. ru -->
		<xsl:if test="@id">
			<!-- link besitzt ggf. eine id und dient dannals in-/external-destination (e.g Lesezeichen, Link) -->
			<fo:block>
				<xsl:attribute name="id">
					<xsl:value-of select="@id"/>
				</xsl:attribute>
			</fo:block>
		</xsl:if>
		<xsl:if test="not(@id)">
			<fo:inline text-decoration="underline">
				<fo:basic-link color="#00017F">
					<xsl:choose>
						<xsl:when test="starts-with(@href, 'mailto:')">
							<xsl:attribute name="external-destination">
								<xsl:value-of select="@href"/>
								<xsl:value-of select="@url"/>
							</xsl:attribute>
						</xsl:when>
						<xsl:when test="contains(@href, '/global/') or contains(@href, '/general/') or contains(@url, '/global/') or contains(@url, '/general/')">
							<xsl:attribute name="external-destination">
								<xsl:value-of select="@href"/>
								<xsl:value-of select="@url"/>
							</xsl:attribute>
						</xsl:when>
						<xsl:otherwise>
							<xsl:attribute name="external-destination">/<xsl:value-of select="$lang"/>/<xsl:value-of select="substring-after(@href, '/lang/')"/>
                                <xsl:value-of select="substring-after(@url, '/lang/')"/>
                            </xsl:attribute>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:apply-templates/>
				</fo:basic-link>
			</fo:inline>
		</xsl:if>
	</xsl:template>
	<xsl:template match="u">
		<fo:inline text-decoration="underline">
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>

	<!-- ********** TABELLEN ************ -->
	<xsl:template match="table">
		<fo:table table-layout="fixed">
			<xsl:choose>
				<xsl:when test="(@border='none') or (@border='0')"/>
				<xsl:otherwise>
					<xsl:attribute name="border-width">
						<xsl:value-of select="@border"/>
					</xsl:attribute>
					<!-- border-style only "solid" works  -->
					<xsl:attribute name="border-style">solid</xsl:attribute>
					<!-- attribute padding="0.1px" sonst Überlagert der Tabellenrahmen mit dem Zellen-Spaltenrahmen -->
					<xsl:attribute name="padding">0.1px</xsl:attribute>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:if test="@width">
				<xsl:attribute name="width">
					<xsl:value-of select="@width"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:if test="@bgcolor">
				<xsl:attribute name="background-color">
					<xsl:value-of select="@bgcolor"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="@class = 'Width-10Proz'">
					<xsl:attribute name="width">10%</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'Width-20Proz'">
					<xsl:attribute name="width">20%</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'Width-25Proz'">
					<xsl:attribute name="width">25%</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'Width-30Proz'">
					<xsl:attribute name="width">30%</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'Width-70Proz'">
					<xsl:attribute name="width">70%</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'Width-80Proz'">
					<xsl:attribute name="width">80%</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'Width-90Proz'">
					<xsl:attribute name="width">90%</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'Price'">
					<xsl:attribute name="text-align">right</xsl:attribute>
					<xsl:attribute name="width">75px</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'PriceSummary'">
					<xsl:attribute name="text-align">right</xsl:attribute>
					<xsl:attribute name="font-weight">bold</xsl:attribute>
				</xsl:when>
			</xsl:choose>
			<!-- fo:table-column must explicitly specify column widths  -->
			<xsl:variable name="columns">
				<xsl:choose>
					<xsl:when test="not(./tr[1]/th/@colspan) and not(./tr[1]/td/@colspan)">
						<xsl:value-of select="count(.//tr[1]/th) + count(.//tr[1]/td)"/>
					</xsl:when>
					<xsl:when test="./tr[1]/th/@colspan and ./tr[1]/td/@colspan">
						<xsl:value-of select="count(./tr[1]/th[not(@colspan)]) + count(./tr[1]/td[not(@colspan)]) + number(./tr[1]/th/@colspan) + number(./tr[1]/td/@colspan)"/>
					</xsl:when>
					<xsl:when test="./tr[1]/th/@colspan">
						<xsl:value-of select="count(./tr[1]/th[not(@colspan)]) + count(./tr[1]/td[not(@colspan)]) + number(./tr[1]/th/@colspan)"/>
					</xsl:when>
					<xsl:when test="./tr[1]/td/@colspan">
						<xsl:value-of select="count(./tr[1]/th[not(@colspan)]) + count(./tr[1]/td[not(@colspan)]) + number(./tr[1]/td/@colspan)"/>
					</xsl:when>
				</xsl:choose>
			</xsl:variable>
			<xsl:call-template name="table_for-loop">
				<xsl:with-param name="i" select="1"/>
				<xsl:with-param name="n" select="$columns"/>
			</xsl:call-template>

			<fo:table-body>
				<xsl:apply-templates/>
			</fo:table-body>
		</fo:table>
	</xsl:template>

	<xsl:template name="table_for-loop">
		<xsl:param name="i" select="1"/>
		<xsl:param name="n" select="1"/>

		<!-- begin of for loop content -->
		<fo:table-column column-width="{100 div number($n)}%"/>
		<!-- end of for loop content -->

		<xsl:if test="$i &lt; $n">
			<xsl:call-template name="table_for-loop">
				<xsl:with-param name="i" select="$i+1"/>
				<xsl:with-param name="n" select="$n"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>

	<xsl:template match="tbody">
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="tr">
		<fo:table-row>
			<xsl:choose>
				<xsl:when test="@class = 'Filled'">
					<xsl:attribute name="background-color">#EFEAE0</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'Filled2'">
					<xsl:attribute name="background-color">#DDDDCC</xsl:attribute>
				</xsl:when>
			</xsl:choose>
			<xsl:apply-templates/>
		</fo:table-row>
	</xsl:template>
	<xsl:template match="td">
		<fo:table-cell>
			<xsl:choose>
				<xsl:when test="@class = 'Width-10Proz'">
					<xsl:attribute name="width">10%</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'Width-20Proz'">
					<xsl:attribute name="width">20%</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'Width-25Proz'">
					<xsl:attribute name="width">25%</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'Width-30Proz'">
					<xsl:attribute name="width">30%</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'Width-70Proz'">
					<xsl:attribute name="width">70%</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'Width-80Proz'">
					<xsl:attribute name="width">80%</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'Width-90Proz'">
					<xsl:attribute name="width">90%</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'Price'">
					<xsl:attribute name="text-align">right</xsl:attribute>
					<xsl:attribute name="width">75px</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'PriceSummary'">
					<xsl:attribute name="text-align">right</xsl:attribute>
					<xsl:attribute name="font-weight">bold</xsl:attribute>
				</xsl:when>
				<xsl:when test="starts-with(ancestor::table/@class, 'Table3D')">
					<xsl:attribute name="background-color">#F0F0F0</xsl:attribute>
					<xsl:attribute name="border-color">#D6D6D6</xsl:attribute>
					<xsl:attribute name="border-style">solid</xsl:attribute>
					<xsl:attribute name="border-width">1px</xsl:attribute>
				</xsl:when>
			</xsl:choose>
			<xsl:if test="@border">
				<xsl:attribute name="border-color">pink</xsl:attribute>
				<xsl:attribute name="border-width">1pt</xsl:attribute>
				<xsl:attribute name="border-style">solid</xsl:attribute>
			</xsl:if>
			<xsl:if test="@colspan">
				<xsl:attribute name="number-columns-spanned">
					<xsl:value-of select="@colspan"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:if test="@rowspan">
				<xsl:attribute name="number-rows-spanned">
					<xsl:value-of select="@rowspan"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:if test="../../@cellpadding">
				<!-- ++++Fehler "../../@cellpadding" der Pfad soll heißen: wenn cellpading im element table oder th oder tr oder td verwendet wird...  -->
				<xsl:attribute name="padding">
					<xsl:value-of select="../../@cellpadding"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:if test="../../@cellspacing">
				<!-- ++++Fehler "../../@cellpadding" der Pfad soll heißen: wenn cellpading im element table oder th oder tr oder td verwendet wird...  -->
				<xsl:attribute name="margin">
					<xsl:value-of select="../../@cellspacing"/>
				</xsl:attribute>
			</xsl:if>
			<fo:block margin="3px">
				<xsl:if test="@bgcolor">
					<xsl:attribute name="background-color">
						<xsl:value-of select="@bgcolor"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="@color">
					<xsl:attribute name="color">
						<xsl:value-of select="@color"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:apply-templates/>
			</fo:block>
		</fo:table-cell>
	</xsl:template>
	<xsl:template match="th">
		<fo:table-cell>
			<xsl:choose>
				<xsl:when test="@class = 'Width-10Proz'">
					<xsl:attribute name="width">10%</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'Width-20Proz'">
					<xsl:attribute name="width">20%</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'Width-25Proz'">
					<xsl:attribute name="width">25%</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'Width-30Proz'">
					<xsl:attribute name="width">30%</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'Width-70Proz'">
					<xsl:attribute name="width">70%</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'Width-80Proz'">
					<xsl:attribute name="width">80%</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'Width-90Proz'">
					<xsl:attribute name="width">90%</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'Price'">
					<xsl:attribute name="text-align">right</xsl:attribute>
					<xsl:attribute name="width">75px</xsl:attribute>
				</xsl:when>
				<xsl:when test="@class = 'PriceSummary'">
					<xsl:attribute name="text-align">right</xsl:attribute>
					<xsl:attribute name="font-weight">bold</xsl:attribute>
				</xsl:when>
				<xsl:when test="starts-with(ancestor::table/@class, 'Table3D')">
					<xsl:attribute name="background-color">#E0E0E0</xsl:attribute>
					<xsl:attribute name="border-after-color">#D6D6D6</xsl:attribute>
					<xsl:attribute name="border-after-style">solid</xsl:attribute>
					<xsl:attribute name="border-after-width">1px</xsl:attribute>
				</xsl:when>
			</xsl:choose>
			<xsl:if test="@colspan">
				<xsl:attribute name="number-columns-spanned">
					<xsl:value-of select="@colspan"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:if test="@rowspan">
				<xsl:attribute name="number-rows-spanned">
					<xsl:value-of select="@rowspan"/>
				</xsl:attribute>
			</xsl:if>
			<fo:block font-size="13pt" font-weight="bold" vertical-align="middle" margin="3px">
				<xsl:if test="@bgcolor">
					<xsl:attribute name="background-color">
						<xsl:value-of select="@bgcolor"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="@color">
					<xsl:attribute name="color">
						<xsl:value-of select="@color"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:apply-templates/>
			</fo:block>
		</fo:table-cell>
	</xsl:template>
	<!-- ********** ende Tabellen ********** -->
	<xsl:template match="left">
		<fo:block text-align="left">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>
	<xsl:template match="center">
		<fo:block text-align="center">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>
	<xsl:template match="right">
		<fo:block text-align="right">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>
	<xsl:template match="bold">
		<fo:inline font-weight="bold">
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>
	<xsl:template match="small">
		<fo:inline font-size="80%">
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>
	<xsl:template match="sup">
		<fo:inline font-size="40%" baseline-shift="super">
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>
	<xsl:template match="headline">
		<xsl:if test="text">
			<fo:block span="all" color="#FF6600" font-size="20pt" margin-top="6mm" margin-bottom="2mm"> <!-- #1F5F9F -->
				<xsl:apply-templates select="text"/>
			</fo:block>
		</xsl:if>
		<xsl:if test="not(text)">
			<fo:block span="all" color="#FF6600" font-size="20pt" margin-top="6mm" margin-bottom="2mm">
				<xsl:apply-templates/>
			</fo:block>
		</xsl:if>
	</xsl:template>
	<xsl:template match="subline">
		<xsl:if test="text">
			<fo:block span="all" color="#f38003" font-size="14pt" margin-top="4mm" margin-bottom="2mm"> <!-- #1F5F9F -->
				<xsl:apply-templates select="text"/>
			</fo:block>
		</xsl:if>
		<xsl:if test="not(text)">
			<fo:block span="all" color="#f38003" font-size="14pt" margin-top="4mm" margin-bottom="2mm">
				<xsl:apply-templates/>
			</fo:block>
		</xsl:if>
	</xsl:template>
	<xsl:template match="box">
		<fo:block font-weight="bold" border-color="#ccc;" border-style="solid" border-width="0.5pt" font-size="9pt">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>
	<xsl:template match="content//title | body//title" priority="1">
		<fo:block font-weight="bold" color="#0161a3" font-size="12pt">
			<xsl:attribute name="space-before">
				<xsl:choose>
					<xsl:when test="false()">0em</xsl:when>
					<xsl:otherwise>1.5em</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			<xsl:attribute name="space-after">
				<xsl:choose>
					<xsl:when test="ancestor::li">0.2em</xsl:when>
					<xsl:otherwise>0.5em</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>
	<xsl:template match="content//box//title | body//box//title" priority="2">
		<fo:inline font-weight="bold" color="#0161a3" space-before="1.5em" space-after="1em" font-size="9pt">
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>
	<xsl:template match="borderbox">
		<fo:block border-style="solid" border-width="0.1pt" border-color="#ccc" margin-bottom="10mm" padding="1mm">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>
	<xsl:template match="subtitle" priority="1">
		<fo:block font-weight="bold" color="#0063c2">
			<xsl:attribute name="space-before">
				<xsl:choose>
					<xsl:when test="false()">0em</xsl:when>
					<xsl:otherwise>1.5em</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			<xsl:attribute name="space-after">
				<xsl:choose>
					<xsl:when test="ancestor::li">0.2em</xsl:when>
					<xsl:otherwise>1em</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>


	<xsl:template match="topic//img | topic//image">
		<!-- scalefit="1" -->
		<fo:external-graphic content-width="scale-to-fit" content-height="100%" width="100%" scaling="uniform"> 
			<xsl:attribute name="src">
				<xsl:text>url(</xsl:text>
				<xsl:value-of select="$RootPath"/>
				<xsl:value-of select="@src"/>
				<xsl:value-of select="@url"/>
				<xsl:text>)</xsl:text>
			</xsl:attribute>
			<xsl:choose>
				<xsl:when test="@height">
					<xsl:attribute name="height">
						<xsl:value-of select="@height"/>
					</xsl:attribute>
					<xsl:attribute name="content-height">scale-to-fit</xsl:attribute>
				</xsl:when>
				<xsl:otherwise>
					<xsl:attribute name="content-height">scale-to-fit</xsl:attribute>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:choose>
				<xsl:when test="@width">
					<xsl:attribute name="width">
						<xsl:value-of select="@width"/>
					</xsl:attribute>
					<xsl:attribute name="content-width">scale-to-fit</xsl:attribute>
				</xsl:when>
				<xsl:otherwise>
					<xsl:attribute name="width">100%</xsl:attribute>
					<xsl:attribute name="content-width">scale-to-fit</xsl:attribute>
				</xsl:otherwise>
			</xsl:choose>
		</fo:external-graphic>
	</xsl:template>

	<xsl:template match="label">
		<fo:block font-weight="bold" space-before="0.75em" space-after="0.25em">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="sprite">
		<!-- style="font-family:FontAwesomeSolid" -->
		<!--  style="font-family:FontAwesomeRegular" -->
		<xsl:choose>
			<xsl:when test="@type='company'">
				<fo:inline font-family="FontAwesomeRegular" padding-right="3px"></fo:inline>
			</xsl:when>
			<xsl:when test="@type='phone'">
				<fo:inline font-family="FontAwesomeSolid" padding-right="3px"></fo:inline>
			</xsl:when>
			<xsl:when test="@type='fax'">
				<fo:inline font-family="FontAwesomeSolid" padding-right="3px"></fo:inline>
			</xsl:when>
			<xsl:when test="@type='email'">
				<fo:inline font-family="FontAwesomeSolid" padding-right="3px"></fo:inline>
			</xsl:when>
			<xsl:when test="@type='web'">
				<fo:inline font-family="FontAwesomeRegular" padding-right="3px"></fo:inline>
			</xsl:when>
			<xsl:when test="@type='sms'">
				<fo:inline font-family="FontAwesomeSolid" padding-right="3px"></fo:inline>
			</xsl:when>
			<xsl:when test="@type='pdf'">
				<fo:inline font-family="FontAwesomeSolid" padding-right="3px"></fo:inline>
			</xsl:when>
			<xsl:when test="@type='facebook'">
				<fo:inline font-family="FontAwesomeBrand" padding-right="3px"></fo:inline>
			</xsl:when>
			<xsl:when test="@type='twitter'">
				<fo:inline font-family="FontAwesomeBrand" padding-right="3px"></fo:inline>
			</xsl:when>
			<xsl:when test="@type='github'">
				<fo:inline font-family="FontAwesomeBrand" padding-right="3px"></fo:inline>
			</xsl:when>
			<xsl:when test="@type='comment'">
				<fo:inline font-family="FontAwesomeRegular" padding-right="3px"></fo:inline>
			</xsl:when>
			<xsl:when test="@type='address'">
				<fo:inline font-family="FontAwesomeSolid" padding-right="3px"></fo:inline>
			</xsl:when>
			<xsl:when test="@type='print'">
				<fo:inline font-family="FontAwesomeSolid" padding-right="3px"></fo:inline>
			</xsl:when>
			<xsl:when test="@type='recommend'">
				<fo:inline font-family="FontAwesomeSolid" padding-right="3px"></fo:inline>
			</xsl:when>
			<xsl:when test="@type='rate'">
				<fo:inline font-family="FontAwesomeSolid" padding-right="3px"></fo:inline>
			</xsl:when>
			<xsl:when test="@type='success'">
				<fo:inline font-family="FontAwesomeSolid" padding-right="3px" color="green"></fo:inline>
			</xsl:when>
			<xsl:when test="@type='fail'">
				<fo:inline font-family="FontAwesomeSolid" padding-right="3px" color="red"></fo:inline>
			</xsl:when>
			<xsl:when test="@type='dont'">
				<fo:inline font-family="FontAwesomeRegular" padding-right="3px" color="red"></fo:inline>
			</xsl:when>
			<xsl:when test="@type='do'">
				<fo:inline font-family="FontAwesomeRegular" padding-right="3px" color="green"></fo:inline>
			</xsl:when>
			<xsl:when test="@type='previous'">
				<fo:inline font-family="FontAwesomeSolid" padding-right="3px"></fo:inline>
			</xsl:when>
			<xsl:when test="@type='next'">
				<fo:inline font-family="FontAwesomeSolid" padding-right="3px"></fo:inline>
			</xsl:when>
			<xsl:when test="@type='sub'">
				<fo:inline font-family="FontAwesomeSolid" padding-right="3px"></fo:inline>
			</xsl:when>
			<xsl:when test="@type='mandatory'">
				<fo:inline font-family="FontAwesomeSolid" vertical-align="super" font-size="50%" color="red"></fo:inline> <!-- padding:0 0.3em; -->
			</xsl:when>
			<xsl:when test="@type='blank'">
				<fo:inline> </fo:inline>
			</xsl:when>
			<xsl:otherwise>
				<fo:inline color="red">Invalid sprite type="<xsl:value-of select="@type"/>"</fo:inline>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="dot">
		<fo:inline font-weight="bold" color="#FF9933" space-before="0" space-after="0">
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>
	<xsl:template match="text | lang">
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="keep-together">
		<fo:block keep-together.within-page="keep" color="green" widows="6" orphans="6">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>
	<xsl:template match="text()">
		<xsl:value-of select="."/>
	</xsl:template>
	<xsl:template match="ol">
		<fo:list-block provisional-distance-between-starts="5mm" provisional-label-separation="5mm"> <!-- space-before="2pt" space-after="2pt" -->
			<xsl:apply-templates/>
		</fo:list-block>
	</xsl:template>
	<xsl:template match="ol/li">
		<xsl:variable name="indention" select="5*count(ancestor::ol)"/>
		<fo:list-item space-after="3mm"> 
			<fo:list-item-label> <!-- start-indent="2mm" end-indent="label-end()" -->
				<fo:block>
					<xsl:choose>
						<xsl:when test="../@type = 'Number'">
							<fo:inline color="#ff6c09"><xsl:number format="1"/>. </fo:inline></xsl:when>

						<xsl:when test="../@type != ''">
							<xsl:number format="{../@type}"/>: </xsl:when>
						<xsl:otherwise>
							<xsl:number format="1"/>. </xsl:otherwise>
					</xsl:choose>
				</fo:block>
			</fo:list-item-label>
			<fo:list-item-body start-indent="body-start()">	<!-- start-indent="body-start()" -->
				<fo:block>
					<xsl:apply-templates/>
				</fo:block>
			</fo:list-item-body>
		</fo:list-item>
	</xsl:template>
	<xsl:template match="ul">
		<xsl:choose>
			<xsl:when test="exists(li)">
				<fo:list-block provisional-distance-between-starts="5mm" provisional-label-separation="5mm"> <!-- space-before="2pt" space-after="2pt" -->
					<xsl:apply-templates/>
				</fo:list-block>
			</xsl:when>
			<xsl:otherwise>
				<fo:block background-color="#F00">Error: Empty UL-List</fo:block>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="ul/li">
		<fo:list-item space-after="3mm">
			<fo:list-item-label> <!--  start-indent="2mm" -->
				<xsl:choose>
					<xsl:when test="'Caret'=tokenize(../@class,' ')">
						<fo:block font-family="ZapfDingbats" color="#ff6c09">■</fo:block>
					</xsl:when>
					<xsl:when test="../@type='Square'">
						<fo:block font-family="ZapfDingbats" color="#ff6c09">■</fo:block>
					</xsl:when>
					<xsl:when test="../@type='Checkmark'"> <!-- &#x2714; \2714 ✔ -->
						<fo:block font-family="ZapfDingbats" color="#ff6c09">✔</fo:block>
					</xsl:when>
					<xsl:when test="../@type='Circle'">
						<fo:block>•</fo:block>
					</xsl:when>
					<xsl:otherwise>
						<xsl:choose>
							<xsl:when test="count(ancestor::ul) = 1">
								<fo:block font-family="ZapfDingbats">■</fo:block>
							</xsl:when>
							<xsl:when test="count(ancestor::ul) = 2">
								<fo:block font-family="ZapfDingbats">•</fo:block>
							</xsl:when>
							<xsl:otherwise>
								<fo:block font-family="ZapfDingbats">-</fo:block>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>
			</fo:list-item-label>
			<fo:list-item-body start-indent="body-start()"> <!-- start-indent="body-start()" -->
				<fo:block>
					<xsl:apply-templates/>
				</fo:block>
			</fo:list-item-body>
		</fo:list-item>
	</xsl:template>

	<!-- document-image -->
	<xsl:template match="page/image">
		<xsl:copy-of select="."/>
	</xsl:template>

	<xsl:template match="text()" priority="-1">
		<xsl:value-of select="."/>
	</xsl:template>

	<xsl:template match="*" priority="-2">
		<fo:inline color="#FF0000">Unknown Tag (taglib-pdf): &lt;<xsl:value-of select="local-name()"/>&gt;</fo:inline>
	</xsl:template>
</xsl:stylesheet>