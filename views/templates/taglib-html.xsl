<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">
	<xsl:param name="lang"/>
	<xsl:param name="file-path-prefix"/>


	<xsl:template match="*[@xml:lang != $lang]" priority="102">
		<!-- nothingToDo(); -->
	</xsl:template>

	<xsl:template match="@xml:lang" priority="101"/>

	<xsl:template match="table">
		<table summary="">
			<xsl:if test="@border">
				<xsl:attribute name="border">
					<xsl:value-of select="@border"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:if test="@cellpadding">
				<xsl:attribute name="cellpadding">
					<xsl:value-of select="@cellpadding"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:if test="@cellspacing">
				<xsl:attribute name="cellspacing">
					<xsl:value-of select="@cellspacing"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:if test="@class">
				<xsl:attribute name="class">
					<xsl:value-of select="@class"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:if test="@style">
				<xsl:attribute name="style">
					<xsl:value-of select="@style"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:if test="@id">
				<xsl:attribute name="id">
					<xsl:value-of select="@id"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:if test="@name">
				<xsl:attribute name="name">
					<xsl:value-of select="@name"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:if test="@summary">
				<xsl:attribute name="summary">
					<xsl:value-of select="@summary"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates/>
		</table>
	</xsl:template>

	<xsl:template match="sprite">
		<!-- style="font-family:FontAwesomeSolid" -->
		<!--  style="font-family:FontAwesomeRegular" -->
		<xsl:choose>
			<xsl:when test="@type='company'">
				<i aria-hidden="true" class="Sprite far fa-building"> <!-- &#xf1ad; -->
					<xsl:apply-templates select="@style"/>
					<xsl:attribute name="title">
						<xsl:choose>
							<xsl:when test="$lang = 'de'">Unternehmen:</xsl:when>
							<xsl:when test="$lang = 'en'">Company:</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</i>
			</xsl:when>

			<xsl:when test="@type='phone'">
				<i aria-hidden="true" class="Sprite fas fa-phone"> <!-- &#xf095; -->
					<xsl:apply-templates select="@style"/>
					<xsl:attribute name="title">
						<xsl:choose>
							<xsl:when test="$lang = 'de'">Telefon:</xsl:when>
							<xsl:when test="$lang = 'en'">Telephone:</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</i>
			</xsl:when>
			<xsl:when test="@type='fax'">
				<i aria-hidden="true" class="Sprite fas fa-fax"> <!-- &#xf1ac; -->
					<xsl:apply-templates select="@style"/>
					<xsl:attribute name="title">
						<xsl:choose>
							<xsl:when test="$lang = 'de'">Telefax:</xsl:when>
							<xsl:when test="$lang = 'en'">Fax:</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</i>
			</xsl:when>
			<xsl:when test="@type='email'">
				<i aria-hidden="true" class="Sprite fas fa-envelope"> <!-- &#xf2b6; -->
					<xsl:apply-templates select="@style"/>
					<xsl:attribute name="title">
						<xsl:choose>
							<xsl:when test="$lang = 'de'">E-Mail:</xsl:when>
							<xsl:when test="$lang = 'en'">Email:</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</i>
			</xsl:when>
			<xsl:when test="@type='web'">  <!-- browser nur in pro version -->
				<i aria-hidden="true" class="Sprite far fa-window-maximize"> <!-- &#xf2d0; -->
					<xsl:attribute name="style">
						<xsl:apply-templates select="@style"/>
					</xsl:attribute>
					<xsl:attribute name="title">
						<xsl:choose>
							<xsl:when test="$lang = 'de'">Web:</xsl:when>
							<xsl:when test="$lang = 'en'">Web:</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</i>
			</xsl:when>
			<xsl:when test="@type='sms'">
				<i aria-hidden="true" class="Sprite fas fa-sms"> <!-- &#xf7cd; -->
					<xsl:apply-templates select="@style"/>
					<xsl:attribute name="title">
						<xsl:choose>
							<xsl:when test="$lang = 'de'">SMS:</xsl:when>
							<xsl:when test="$lang = 'en'">SMS:</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</i>
			</xsl:when>
			<xsl:when test="@type='pdf'">
				<i aria-hidden="true" class="Sprite fas fa-file-pdf"> <!-- &#xf1c1; -->
					<xsl:attribute name="style">
						<xsl:text>padding:0 0.2em;</xsl:text>
						<xsl:apply-templates select="@style"/>
					</xsl:attribute>
					<xsl:attribute name="title">
						<xsl:choose>
							<xsl:when test="$lang = 'de'">PDF Datei</xsl:when>
							<xsl:when test="$lang = 'en'">PDF file</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</i>
			</xsl:when>
			<xsl:when test="@type='word'">
				<i aria-hidden="true" class="Sprite fas fa-file-word"> <!-- &#xf1c2; -->
					<xsl:attribute name="style">
						<xsl:text>padding:0 0.2em;</xsl:text>
						<xsl:apply-templates select="@style"/>
					</xsl:attribute>
					<xsl:attribute name="title">
						<xsl:choose>
							<xsl:when test="$lang = 'de'">Word Datei</xsl:when>
							<xsl:when test="$lang = 'en'">Word file</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</i>
			</xsl:when>
			<xsl:when test="@type='facebook'">
				<i aria-hidden="true" class="Sprite fab fa-facebook"> <!-- &#xf09a; -->
					<xsl:apply-templates select="@style"/>
					<xsl:attribute name="title">
						<xsl:choose>
							<xsl:when test="$lang = 'de'">Facebook:</xsl:when>
							<xsl:when test="$lang = 'en'">Facebook:</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</i>
			</xsl:when>
			<xsl:when test="@type='twitter'">
				<i aria-hidden="true" class="Sprite fab fa-twitter"> <!-- &#xf7cd; -->
					<xsl:apply-templates select="@style"/>
					<xsl:attribute name="title">
						<xsl:choose>
							<xsl:when test="$lang = 'de'">Twitter:</xsl:when>
							<xsl:when test="$lang = 'en'">Twitter:</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</i>
			</xsl:when>
			<xsl:when test="@type='github'">
				<i aria-hidden="true" class="Sprite fab fa-github"> <!-- &#xf09b; -->
					<xsl:apply-templates select="@style"/>
					<xsl:attribute name="title">
						<xsl:choose>
							<xsl:when test="$lang = 'de'">Github:</xsl:when>
							<xsl:when test="$lang = 'en'">Github:</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</i>
			</xsl:when>
			<xsl:when test="@type='comment'">
				<i aria-hidden="true" class="Sprite far fa-comment-dots"> <!-- &#xf4ad; -->
					<xsl:apply-templates select="@style"/>
					<xsl:attribute name="title">
						<xsl:choose>
							<xsl:when test="$lang = 'de'">SMS:</xsl:when>
							<xsl:when test="$lang = 'en'">SMS:</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</i>
			</xsl:when>
			<xsl:when test="@type='address'">
				<i aria-hidden="true" class="Sprite fas fa-map-marker-alt"> <!-- &#xf3c5; -->
					<xsl:apply-templates select="@style"/>
					<xsl:attribute name="title">
						<xsl:choose>
							<xsl:when test="$lang = 'de'">Anschrift:</xsl:when>
							<xsl:when test="$lang = 'en'">Address:</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</i>
			</xsl:when>
			<xsl:when test="@type='print'">
				<i aria-hidden="true" class="Sprite fas fa-print"> <!-- &#xf02f; -->
					<xsl:apply-templates select="@style"/>
					<xsl:attribute name="title">
						<xsl:choose>
							<xsl:when test="$lang = 'de'">Druckansicht:</xsl:when>
							<xsl:when test="$lang = 'en'">Print view:</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</i>
			</xsl:when>
			<xsl:when test="@type='recommend'">
				<i aria-hidden="true" class="Sprite fas fa-paper-plane"> <!-- &#xf1d8; -->
					<xsl:apply-templates select="@style"/>
					<xsl:attribute name="title">
						<xsl:choose>
							<xsl:when test="$lang = 'de'">Seite empfehlen:</xsl:when>
							<xsl:when test="$lang = 'en'">Recommend page:</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</i>
			</xsl:when>
			<xsl:when test="@type='rate'">
				<i aria-hidden="true" class="Sprite fas fa-star-half-alt"> <!-- &#xf5c0; -->
					<xsl:apply-templates select="@style"/>
					<xsl:attribute name="title">
						<xsl:choose>
							<xsl:when test="$lang = 'de'">Seite bewerten:</xsl:when>
							<xsl:when test="$lang = 'en'">Rate page:</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</i>
			</xsl:when>
			<xsl:when test="@type='success'">
				<i aria-hidden="true" class="Sprite fas fa-check"> <!-- &#xf00c; -->
					<xsl:attribute name="style">
						<xsl:text>color:green;</xsl:text>
						<xsl:apply-templates select="@style"/>
					</xsl:attribute>
					<xsl:attribute name="title">
						<xsl:choose>
							<xsl:when test="$lang = 'de'">erfolgreich</xsl:when>
							<xsl:when test="$lang = 'en'">success</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</i>
			</xsl:when>
			<xsl:when test="@type='fail'">
				<i aria-hidden="true" class="Sprite fas fa-times"> <!-- &#xf00d; -->
					<xsl:attribute name="style">
						<xsl:text>color:red;</xsl:text>
						<xsl:apply-templates select="@style"/>
					</xsl:attribute>
					<xsl:attribute name="title">
						<xsl:choose>
							<xsl:when test="$lang = 'de'">fehlgeschlagen</xsl:when>
							<xsl:when test="$lang = 'en'">fail</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</i>
			</xsl:when>
			<xsl:when test="@type='dont'">
				<i aria-hidden="true" class="Sprite far fa-thumbs-down"> <!-- &#xf165; -->
					<!-- also possible: fa-arrow-cirle-left &#xf0a8; -->
					<xsl:attribute name="style">
						<xsl:text>color:red;</xsl:text>
						<xsl:apply-templates select="@style"/>
					</xsl:attribute>
					<xsl:attribute name="title">
						<xsl:choose>
							<xsl:when test="$lang = 'de'">so nicht machen</xsl:when>
							<xsl:when test="$lang = 'en'">don't</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</i>
			</xsl:when>
			<xsl:when test="@type='do'">
				<i aria-hidden="true" class="Sprite far fa-thumbs-up"> <!-- &#xf164; -->
					<xsl:attribute name="style">
						<xsl:text>color:green;</xsl:text>
						<xsl:apply-templates select="@style"/>
					</xsl:attribute>
					<xsl:attribute name="title">
						<xsl:choose>
							<xsl:when test="$lang = 'de'">so ist es richtig</xsl:when>
							<xsl:when test="$lang = 'en'">do</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</i>
			</xsl:when>
			<xsl:when test="@type='previous'">
				<i aria-hidden="true" class="Sprite fas fa-chevron-circle-left"> <!-- &#xf137; -->
					<!-- also possible: fa-arrow-cirle-right &#xf0a9; -->
					<xsl:attribute name="style">
						<xsl:text>color:inherit;</xsl:text>
						<xsl:apply-templates select="@style"/>
					</xsl:attribute>
					<xsl:attribute name="title">
						<xsl:choose>
							<xsl:when test="$lang = 'de'">zurück</xsl:when>
							<xsl:when test="$lang = 'en'">back</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</i>
			</xsl:when>
			<xsl:when test="@type='next'">
				<i aria-hidden="true" class="Sprite fas fa-chevron-circle-right"> <!-- &#xf138; -->
					<!-- also possible: fa-arrow-cirle-right &#xf0a9; -->
					<xsl:attribute name="style">
						<xsl:text>color:inherit;</xsl:text>
						<xsl:apply-templates select="@style"/>
					</xsl:attribute>
					<xsl:attribute name="title">
						<xsl:choose>
							<xsl:when test="$lang = 'de'">weiter</xsl:when>
							<xsl:when test="$lang = 'en'">next</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</i>
			</xsl:when>
			<xsl:when test="@type='up'">
				<i aria-hidden="true" class="Sprite fas fa-chevron-circle-up"> <!-- &#xf139; -->
					<xsl:attribute name="style">
						<xsl:text>color:inherit;</xsl:text>
						<xsl:apply-templates select="@style"/>
					</xsl:attribute>
					<xsl:attribute name="title">
						<xsl:choose>
							<xsl:when test="$lang = 'de'">hoch</xsl:when>
							<xsl:when test="$lang = 'en'">up</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</i>
			</xsl:when>
			<xsl:when test="@type='down'">
				<i aria-hidden="true" class="Sprite fas fa-chevron-circle-down"> <!-- &#xf13a; -->
					<xsl:attribute name="style">
						<xsl:text>color:inherit;</xsl:text>
						<xsl:apply-templates select="@style"/>
					</xsl:attribute>
					<xsl:attribute name="title">
						<xsl:choose>
							<xsl:when test="$lang = 'de'">runter</xsl:when>
							<xsl:when test="$lang = 'en'">down</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</i>
			</xsl:when>

			<xsl:when test="@type='sub'">
				<i aria-hidden="true" class="Sprite fas fa-angle-right"> <!-- &#xf105; -->
					<xsl:attribute name="style">
						<xsl:text>min-width:1em; color:inherit;</xsl:text>
						<xsl:apply-templates select="@style"/>
					</xsl:attribute>
					<xsl:attribute name="title">
						<xsl:choose>
							<xsl:when test="$lang = 'de'">unter-element</xsl:when>
							<xsl:when test="$lang = 'en'">sub element</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</i>
			</xsl:when>
			<xsl:when test="@type='mandatory'">
				<i aria-hidden="true" class="Sprite fas fa-asterisk"> <!-- &#xf069; -->
					<xsl:attribute name="style">
						<xsl:text>vertical-align:super; font-size:50%; color:red; padding:0 0.3em;</xsl:text>
						<xsl:apply-templates select="@style"/>
					</xsl:attribute>
					<xsl:attribute name="title">
						<xsl:choose>
							<xsl:when test="$lang = 'de'">Pflichtfeld:</xsl:when>
							<xsl:when test="$lang = 'en'">Mandatory:</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</i>
			</xsl:when>
			<xsl:when test="@type='vcard'">
				<i aria-hidden="true" class="Sprite far fa-address-card"> <!-- &#xf2bb; -->
					<xsl:attribute name="style">
						<xsl:apply-templates select="@style"/>
					</xsl:attribute>
					<xsl:attribute name="title">
						<xsl:choose>
							<xsl:when test="$lang = 'de'">Visitenkarte:</xsl:when>
							<xsl:when test="$lang = 'en'">business card:</xsl:when>
						</xsl:choose>
					</xsl:attribute>
				</i>
			</xsl:when>
			<xsl:when test="@type='blank'">
				<i class="Sprite fa"> </i>
			</xsl:when>
			<xsl:otherwise>
				<i style="color:red">Invalid sprite type="<xsl:value-of select="@type"/>"</i>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="left">
		<div>
			<xsl:attribute name="style">
				<xsl:text>text-align:left;</xsl:text>
				<xsl:if test="@style">
					<xsl:apply-templates select="@style"/>
				</xsl:if>
				<xsl:if test="@class">
					<xsl:apply-templates select="@class"/>
				</xsl:if>
			</xsl:attribute>
			<xsl:apply-templates/>
		</div>
	</xsl:template>
	<xsl:template match="center">
		<div class="Center">
			<xsl:attribute name="style">
				<xsl:text>text-align:center;</xsl:text>
				<xsl:if test="@style">
					<xsl:apply-templates select="@style"/>
				</xsl:if>
				<xsl:if test="@class">
					<xsl:apply-templates select="@class"/>
				</xsl:if>
			</xsl:attribute>
			<xsl:apply-templates/> 
		</div>
	</xsl:template>
	<xsl:template match="right">
		<div>
			<xsl:attribute name="style">
				<xsl:text>text-align:right;</xsl:text>
				<xsl:if test="@style">
					<xsl:apply-templates select="@style"/>
				</xsl:if>
				<xsl:if test="@class">
					<xsl:apply-templates select="@class"/>
				</xsl:if>
			</xsl:attribute>
			<xsl:apply-templates/>
		</div>
	</xsl:template>
	<xsl:template match="bold">
		<strong style="font-weight:bold;">
			<xsl:apply-templates/>
		</strong>
	</xsl:template>
	<xsl:template match="headline">
		<h2 class="Headline">
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</h2>
	</xsl:template>
	<xsl:template match="subline">
		<h3 class="Subline">
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</h3>
	</xsl:template>
	<xsl:template match="crosslink">
		<nav class="CrossLinkBox">
			<xsl:choose>
				<xsl:when test="@type='ArticleIndex'">
					<div class="CrossLinkBoxTitle">
						<text xml:lang="de">Seiten-Inhalt:</text>
						<text xml:lang="en">Page-Index:</text>
					</div>
					<ol class="Number">
						<xsl:for-each select="link | ul/li/*">
							<li>
								<xsl:choose>
									<xsl:when test="@level='2'">
										<xsl:attribute name="class" select="'Level2'"/>
									</xsl:when>
									<xsl:when test="@level">
										[<xsl:value-of select="@level"/>]
									</xsl:when>
								</xsl:choose>
								<xsl:apply-templates select="."/>
							</li>
						</xsl:for-each>
					</ol>
				</xsl:when>
				<xsl:when test="@type='ContactInfo'">
					<div class="CrossLinkBoxTitle">
						<text xml:lang="de">Kontakt aufnehmen:</text>
						<text xml:lang="en">Contact us:</text>
					</div>
					<ul>
						<xsl:for-each select="link | ul/li/*">
							<li>
								<xsl:apply-templates select="."/>
							</li>
						</xsl:for-each>
					</ul>
				</xsl:when>
				<xsl:when test="@type='TagCloud'">
					<div class="CrossLinkBoxTitle">
						<text xml:lang="de">Populäre Suchen:</text>
						<text xml:lang="en">Popular searches:</text>
					</div>
					<ol class="TagCloud">
						<xsl:for-each select="link | ul/li/*">
							<li>
								<xsl:copy-of select="../@class"/>
								<xsl:apply-templates select="."/>
							</li>
						</xsl:for-each>
					</ol>
				</xsl:when>
				<xsl:when test="@type='QuickNavi'">
					<div class="CrossLinkBoxTitle">
						<text xml:lang="de">Schnellnavigation:</text>
						<text xml:lang="en">Fastlink:</text>
					</div>

					<xsl:if test="link[@class='Card']">
						<xsl:for-each select="link[@class='Card']">
							<xsl:apply-templates select="."/>
						</xsl:for-each>
					</xsl:if>
					<xsl:if test="link[not(@class='Card')]">
						<ul type="LinkList">
							<xsl:for-each select="link[not(@class='Card')]">
								<li>
									<xsl:apply-templates select="."/>
								</li>
							</xsl:for-each>
						</ul>
					</xsl:if>
				</xsl:when>
				<xsl:when test="@type='FreeStyle'">
					<xsl:apply-templates/>
				</xsl:when>
				<xsl:otherwise>
					<error>Invailid CrossLink type '<xsl:value-of select="@type"/>'</error>
				</xsl:otherwise>
			</xsl:choose>
		</nav>
	</xsl:template>

	<xsl:template match="crosslinkanker">
		<a name="{@id}" style="display:block; position:relative; top:-115px; visibility:hidden;"/>
	</xsl:template>

	<xsl:template match="artikel">
		<div class="Artikel">
			<xsl:apply-templates/>
		</div>
	</xsl:template>
	<xsl:template match="body//title" priority="1">
		<h4>
			<xsl:attribute name="class">
				<xsl:text>Title </xsl:text>
				<xsl:value-of select="@class"/>
			</xsl:attribute>
			<xsl:apply-templates/>
		</h4>
	</xsl:template>
	<xsl:template match="body//box//title" priority="2">
		<span class="Title">
			<xsl:apply-templates/>
		</span>
	</xsl:template>
	<xsl:template match="subtitle" priority="1">
		<div>
			<xsl:attribute name="class">
				<xsl:text>SubTitle </xsl:text>
				<xsl:value-of select="@class"/>
			</xsl:attribute>
			<xsl:apply-templates/>
		</div>
	</xsl:template>
	<xsl:template match="box//subtitle" priority="2">
		<span class="SubTitle">
			<xsl:apply-templates/>
		</span>
	</xsl:template>

	<xsl:template match="ul">
		<xsl:choose>
			<xsl:when test="not(@type)">
				<ul>
					<xsl:copy-of select="@*"/>
					<xsl:apply-templates/>
				</ul>
			</xsl:when>
			<xsl:when test="@type='Caret'">
				<ul class="Caret">
					<xsl:apply-templates/>
				</ul>
			</xsl:when>
			<xsl:when test="@type='Caret+Horizontal'">
				<ul class="Caret Horizontal">
					<xsl:apply-templates/>
				</ul>
			</xsl:when>

			<xsl:when test="@type='Checkmark'">
				<ul class="Checkmark">
					<xsl:apply-templates/>
				</ul>
			</xsl:when>
			<xsl:when test="@type='Icons'">
				<ul class="Icons">
					<xsl:apply-templates/>
				</ul>
			</xsl:when>
			<xsl:when test="@type='Navi'">
				<ul class="Navi">
					<xsl:apply-templates/>
				</ul>
			</xsl:when>
			<xsl:otherwise>
				<error>Unknown type <xsl:value-of select="@type"/></error>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="ol">
		<xsl:choose>
			<xsl:when test="not(@type)">
				<ol>
					<xsl:copy-of select="@*"/>
					<xsl:apply-templates/>
				</ol>
			</xsl:when>
			<xsl:when test="@type='Number'">
				<ol class="Number">
					<xsl:apply-templates/>
				</ol>
			</xsl:when>
			<xsl:otherwise>
				<error>Unknown type <xsl:value-of select="@type"/></error>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="dot">
		<!-- ASCII 254 dot -->
		<span class="Dot">.</span>
	</xsl:template>
	<xsl:template match="link">
		<xsl:if test="@type">
			<xsl:choose>
				<xsl:when test="@type='extern'">
					<span class="SpriteExtern">
						<a href="{@url}" rel="nofollow" target="_blank">
							<xsl:attribute name="class">
								<xsl:text>extern</xsl:text>
								<xsl:if test="@class">
									<xsl:text>, </xsl:text>
								</xsl:if>
								<xsl:value-of select="@class"/>
							</xsl:attribute>
							<xsl:apply-templates/>
						</a>
					</span>
				</xsl:when>
				<xsl:when test="@type='crossite'">
					<a target="_blank">
						<xsl:attribute name="href">
							<xsl:value-of select="@url"/>
						</xsl:attribute>
						<xsl:if test="@class">
							<xsl:attribute name="class">
								<xsl:text>Crossite</xsl:text>
								<xsl:value-of select="@class"/>
							</xsl:attribute>
						</xsl:if>
						<xsl:if test="@style">
							<xsl:attribute name="style">
								<xsl:value-of select="@style"/>
							</xsl:attribute>
						</xsl:if>
						<xsl:apply-templates/>
					</a>
				</xsl:when>
				<xsl:otherwise>
					<error>[Link with wrong type.]</error>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
		<xsl:if test="not(@type)">
			<a href="{@url}">
				<xsl:if test="@class">
					<xsl:attribute name="class">
						<xsl:value-of select="@class"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="@style">
					<xsl:attribute name="style">
						<xsl:value-of select="@style"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="@rel">
					<xsl:attribute name="rel">
						<xsl:value-of select="@rel"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:apply-templates/>
			</a>
		</xsl:if>
	</xsl:template>
	<xsl:template match="div [@class='GroupBoxTitle']">
		<div class="GroupBoxTitle" style="background-color:#E7E7E7;color:#333;font-size:1.2em;font-weight:bold;text-align:left;">
			<xsl:apply-templates/>
		</div>
	</xsl:template>

	<xsl:template match="box">
		<div class="Box">
			<xsl:apply-templates/>
		</div>
	</xsl:template>

	<xsl:template match="input">
		<input>
			<xsl:for-each select="@*">
				<xsl:attribute name="{name()}">
					<xsl:value-of select="."/>
				</xsl:attribute>
			</xsl:for-each>
			<xsl:apply-templates/>
		</input>
	</xsl:template>
	
	
	<xsl:template match="popupmenu">		
		<span class="hov">
				<xsl:if test="popuptext">
					<a href="#">
						<xsl:value-of select="popuptext"/>
						<!--[if IE 7]><!-->
					</a><!--<![endif]-->
					<!--[if lte IE 6]><table><tr><td><![endif]-->
				</xsl:if>
				<b>	
					<xsl:copy-of select="descendant::popupbox"/>
				</b>
			<!--[if lte IE 6]></td></tr></table></a><![endif]-->
		</span>
	</xsl:template>

	<xsl:template match="body//img | body//image">
<!-- support to serve future image formats (https://web.dev/serve-images-webp/):
<picture>
  <source type="image/webp" srcset="bridge.webp">
  <source type="image/jpeg" srcset="bridge.jpg">
  <img src="flower.bridge" alt="">
</picture>
-->
		<xsl:choose>
			<xsl:when test="@type='extern'">
				<img src="{@src}" rel="nofollow">
					<xsl:copy-of select="@*[not(name()='src') and not(name()='type') and not(name()='class')]"/>
					<xsl:attribute name="class">
						<xsl:text>extern</xsl:text>
						<xsl:if test="@class">
							<xsl:text>, </xsl:text>
						</xsl:if>
						<xsl:value-of select="@class"/>
					</xsl:attribute>
				</img>
			</xsl:when>
			<xsl:when test="@type='crossite'">
				<img src="{@src}">
					<xsl:copy-of select="@*[not(name()='src')]"/>
				</img>
			</xsl:when>
			<xsl:otherwise>
				<img src="{concat($file-path-prefix, @src)}">
					<xsl:copy-of select="@*[not(name()='src')]"/>
				</img>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>


	<xsl:template match="button[not(@type='submit')]">
		<a class="Button" href="{@url}">
			<xsl:apply-templates select="@*[name() != 'url']"/>
			<xsl:apply-templates/>
		</a>
	</xsl:template>


	<xsl:template match="pageblock">
		<div>
			<xsl:attribute name="class">
				<xsl:choose>
					<xsl:when test="flexblock">
						<xsl:text>PageBlockFlex </xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>PageBlock </xsl:text>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:value-of select="@class"/>
			</xsl:attribute> 
			<xsl:if test="@*">
				<xsl:attribute name="style">
					<xsl:if test="@background-color">
						<xsl:text>background-color:</xsl:text>
						<xsl:value-of select="@background-color"/>
						<xsl:text>;</xsl:text>
					</xsl:if>
					<xsl:choose>
						<xsl:when test="@align='left'">
							<xsl:text>flex-direction: row;</xsl:text>
						</xsl:when>
					</xsl:choose>

					<xsl:choose>
						<xsl:when test="@align='right'">
							<xsl:text>flex-direction: row-reverse;</xsl:text>
						</xsl:when>
					</xsl:choose>
					<xsl:choose>
						<xsl:when test="@align='center'">
							<xsl:text>flex-direction: column;</xsl:text>
							<xsl:text>align-items:center;</xsl:text>
						</xsl:when>
					</xsl:choose>
				</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates select="node()"/>
		</div>
	</xsl:template>

	<xsl:template match="flexblock">
		<div class="FlexBlock">
			<xsl:attribute name="class">
				<xsl:text>FlexBlock </xsl:text>
				<xsl:choose>
					<xsl:when test="image | img">
						<xsl:text>FlexBlockImage</xsl:text>
					</xsl:when>
					<xsl:when test="(a | link)/(image | img)">
						<xsl:text>FlexBlockImage</xsl:text>
					</xsl:when>

					<xsl:otherwise>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:text> </xsl:text>
				<xsl:copy-of select="@class"/>
			</xsl:attribute>
			<xsl:copy-of select="@style"/>
			<xsl:apply-templates/>
		</div>
	</xsl:template>


	<xsl:template match="textblock">
		<div class="TextBlock">
			<xsl:copy-of select="@style"/>
			<xsl:apply-templates/>
		</div>
	</xsl:template>

	<xsl:template match="teasers">
		<div class="Teasers">
			<xsl:apply-templates select="@*"/>
			<ul>
				<xsl:apply-templates/>
			</ul>
		</div>
	</xsl:template>

	<xsl:template match="teaser">
		<li class="Teaser">
			<xsl:apply-templates select="@*[name()!='url']"/>
			<xsl:choose>
				<xsl:when test="header-image">		
					<div class="TeaserHeaderImage" style="background-image:url(/global/images/docimage/{header-image/image-src})">
						<xsl:apply-templates select="header-image/title/node()"/>
						<div class="Text">
							<xsl:apply-templates select="header-text/node()"/>
						</div>
					</div>
				</xsl:when>
				<xsl:when test="header-text">		
					<div class="TeaserHeaderText">
						<div class="Text">
							<xsl:apply-templates select="header-text/node()"/>
						</div>
					</div>
				</xsl:when>
			</xsl:choose>
			<div class="Content">
				<xsl:apply-templates select="node()[name()!='header-image' and name()!='header-text']"/>
			</div>
			<xsl:if test="@url">
				<div class="Footer">
					<a class="ButtonMore" href="{@url}">
						<xsl:choose>
							<xsl:when test="$lang='de'">Mehr erfahren…</xsl:when>
							<xsl:when test="$lang='en'">Learn more…</xsl:when>
							<xsl:otherwise>XXX</xsl:otherwise>
						</xsl:choose>
					</a>
				</div>
			</xsl:if>
		</li>
	</xsl:template>

	<xsl:template match="details">
    		<div class="DetailsBox">
      			<input id="ch-{count(preceding::details)}" type="checkbox"/>

      			<label for="ch-{count(preceding::details)}" class="title">
				<xsl:attribute name="title">
					<xsl:choose>
						<xsl:when test="$lang = 'de'">
							<xsl:text>Details anzeigen…</xsl:text>
						</xsl:when>
						<xsl:when test="$lang = 'en'">
							<xsl:text>show more…</xsl:text>
						</xsl:when>
					</xsl:choose>
				</xsl:attribute>
				<xsl:copy-of select="title/node()"/>
			</label>
      			<div class="details">
				<xsl:copy-of select="node()[name() != 'title']"/>
			</div>
    		</div>
	</xsl:template>

	<!-- copy all other elements -->
	<xsl:template match="node()|@*" priority="-1">
		<xsl:copy>
			<xsl:apply-templates select="node()|@*"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>