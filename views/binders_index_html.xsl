<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="home-views"/> 
	<xsl:param name="home-data"/>                
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="path" required="yes"/>

	<xsl:template match="/">
		<page>
			<body>
				<xsl:apply-templates/>
			</body>
		</page>
	</xsl:template>

	<xsl:template match="Years">
		<h3>Liste der Buchungsordner</h3>
		<ul>
			<xsl:apply-templates/>
		</ul>
	</xsl:template>

	<xsl:template match="Year">
		<li>
			<b>
				<xsl:value-of select="@name"/>
			</b>
			<xsl:apply-templates/>
		</li>
		<br/>
	</xsl:template>

	<xsl:template match="Months">
		<ul>
			<xsl:apply-templates/>
		</ul>
	</xsl:template>

	<xsl:template match="Month">
		<li>
			<b>
				<a href="{$home-web-gui||'/'||$tenant||'/binders/'||../../@name||'/'||@name||'/index.html'}">
					<xsl:value-of select="@name"/>
				</a>
			</b>
			<xsl:apply-templates/>
		</li>
	</xsl:template>

	<xsl:template match="BankAccounts">
		<ul>
			<xsl:apply-templates/>
		</ul>
	</xsl:template>

	<xsl:template match="BankAccount">
		<li>
			<a href="{$home-web-gui||'/'||$tenant||'/banking/'||@kto||'/'||../../@name||'/index.html'}">
				<xsl:value-of select="BankAccountDetail/AccountName"/>
				<xsl:text> – </xsl:text>
				<xsl:value-of select="BankAccountDetail/KTNR"/>
			</a>
		</li>
	</xsl:template>
	
</xsl:stylesheet>