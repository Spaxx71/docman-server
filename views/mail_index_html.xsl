<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:mail="http://exist-db.org/xquery/mail" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="home-data" required="yes"/>
	<xsl:param name="home-views"/>
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="year" select="''"/>

	<xsl:decimal-format name="european" decimal-separator="," grouping-separator="."/>

	<xsl:template match="/">
		<page>
			<head>
				<style>
					tr.unread td { font-weight: bold; }
					tr.flagged, tr.flagged td { background-color: #ffe566; }
					tr.other-year td, tr.other-year td a { color: #9a9a9a; }
					.done-mark { color: #1b7f3a; font-weight: bold; }
					#mail-list th a { color: #fff; text-decoration: underline; cursor: pointer; }
					#state-dialog, #link-dialog {
						position: fixed;
						top: 6em;
						left: 50%;
						transform: translateX(-50%);
						z-index: 30;
						min-width: 22em;
						max-width: 36em;
						padding: 1em 1.2em;
						background: #fff;
						border: 1px solid #666;
						box-shadow: 0 0.4em 1.2em rgba(0, 0, 0, 0.25);
					}
					#party-results { max-height: 16em; overflow: auto; padding-left: 1.2em; }
					#party-query { width: 100%; margin: 0.4em 0 0.8em; }
				</style>
				<script type="text/javascript" src="{$home-web-gui}/resources/docman-mail.js">&#160;</script>
			</head>
			<body>
				<xsl:apply-templates select="error | result/error"/>
				<table id="mail-list" data-api="{$home-web-api}/tenants/{$tenant}/emails">
					<thead>
						<tr>
							<th><a href="#sort" data-key="number" data-label="#">#</a></th>
							<th><a href="#sort" data-key="erledigt" data-label="Erledigt">Erledigt</a></th>
							<th><a href="#sort" data-key="unread" data-label="Ungelesen">Ungelesen</a></th>
							<th><a href="#sort" data-key="flagged" data-label="Markiert">Markiert</a></th>
							<th><a href="#sort" data-key="subject" data-label="Titel">Titel</a></th>
							<th><a href="#sort" data-key="from" data-label="Absender">Absender</a></th>
							<th><a href="#sort" data-key="sent" data-label="Gesendet">Gesendet</a></th>
							<th><a href="#sort" data-key="received" data-label="Empfangen">Empfangen</a></th>
						</tr>
					</thead>
					<tbody>
						<xsl:apply-templates select="result/mail:messages/mail:message"/>
					</tbody>
				</table>

				<ul id="party-index" hidden="hidden">
					<xsl:for-each select="result/parties/party">
						<li data-id="{@id}" data-name="{@name}" data-role="{@role}" data-search="{.}">
							<xsl:value-of select="@name"/>
						</li>
					</xsl:for-each>
				</ul>

				<div id="state-dialog" hidden="hidden">
					<p id="state-text"/>
					<p>
						<a href="#apply" id="state-apply">Ändern</a>
						&#160;
						<a href="#close" id="state-close">Abbrechen</a>
					</p>
					<p id="state-error"/>
				</div>

				<div id="link-dialog" hidden="hidden">
					<p>Mit Debitor/Kreditor verlinken</p>
					<label for="party-query">Schnellsuche</label>
					<input id="party-query" type="text"/>
					<ul id="party-results"/>
					<p><a href="#close" id="link-close">Abbrechen</a></p>
				</div>
				<form id="link-form" method="post" action="">
					<input type="hidden" name="link-account" id="link-account"/>
					<input type="hidden" name="link-email" id="link-email"/>
				</form>
			</body>
		</page>
	</xsl:template>

	<xsl:template match="error">
		<p class="error"><xsl:value-of select="."/></p>
	</xsl:template>

	<xsl:template match="mail:message">
		<xsl:variable name="index" select="position()"/>
		<xsl:variable name="mail-year" select="
			if (mail:received castable as xs:dateTime) then year-from-dateTime(mail:received)
			else if (mail:sent castable as xs:dateTime) then year-from-dateTime(mail:sent)
			else ()"/>
		<xsl:variable name="in-year" select="exists($mail-year) and string($mail-year) = string($year)"/>
		<tr>
			<xsl:attribute name="class">
				<xsl:choose>
					<xsl:when test="$index mod 2 = 1">even</xsl:when>
					<xsl:otherwise>odd</xsl:otherwise>
				</xsl:choose>
				<xsl:if test="@unread = 'true'"> unread</xsl:if>
				<xsl:if test="@flagged = 'true'"> flagged</xsl:if>
				<xsl:if test="not($in-year)"> other-year</xsl:if>
			</xsl:attribute>
			<xsl:attribute name="data-year" select="if ($in-year) then 'true' else 'false'"/>
			<xsl:attribute name="data-number" select="@number"/>
			<xsl:attribute name="data-seen" select="if (@unread = 'true') then 'false' else 'true'"/>
			<xsl:attribute name="data-flagged" select="if (@flagged = 'true') then 'true' else 'false'"/>
			<xsl:attribute name="data-erledigt" select="if (@erledigt = 'true') then 'true' else 'false'"/>
			<td data-k="number" data-v="{@number}">
				<a href="{@number}/index.html"><xsl:value-of select="@number"/></a>
			</td>
			<td data-k="erledigt" data-v="{if (@erledigt = 'true') then '1' else '0'}">
				<a href="#zustand" class="state-link" data-flag="erledigt">
					<xsl:choose>
						<xsl:when test="@erledigt = 'true'"><span class="done-mark">✓</span></xsl:when>
						<xsl:otherwise>–</xsl:otherwise>
					</xsl:choose>
				</a>
			</td>
			<td data-k="unread" data-v="{if (@unread = 'true') then '1' else '0'}">
				<a href="#zustand" class="state-link" data-flag="seen">
					<xsl:choose>
						<xsl:when test="@unread = 'true'">ungelesen</xsl:when>
						<xsl:otherwise>gelesen</xsl:otherwise>
					</xsl:choose>
				</a>
			</td>
			<td data-k="flagged" data-v="{if (@flagged = 'true') then '1' else '0'}">
				<a href="#zustand" class="state-link" data-flag="flagged">
					<xsl:choose>
						<xsl:when test="@flagged = 'true'">markiert</xsl:when>
						<xsl:otherwise>–</xsl:otherwise>
					</xsl:choose>
				</a>
			</td>
			<td data-k="subject" data-v="{mail:subject}"><xsl:value-of select="mail:subject"/></td>
			<td data-k="from" data-v="{normalize-space(concat(mail:from/@personal, ' ', mail:from))}">
				<xsl:choose>
					<xsl:when test="party/@matched = 'true'">
						<a href="{$home-web-gui}/{$tenant}/{$year}/accounts/{party/@id}/details.html">
							<xsl:value-of select="party/@name"/>
						</a>
						<xsl:text> (</xsl:text>
						<xsl:value-of select="party/@role"/>
						<xsl:text>)</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="normalize-space(concat(mail:from/@personal, ' ', mail:from))"/>
						<xsl:text> </xsl:text>
						<a href="#verlinken" class="link-party" data-email="{party/@email}" data-domain="{party/@domain}">Mit Debitor/Kreditor verlinken…</a>
					</xsl:otherwise>
				</xsl:choose>
			</td>
			<td data-k="sent" data-v="{string(mail:sent)}">
				<xsl:if test="mail:sent castable as xs:dateTime">
					<xsl:value-of select="format-dateTime(mail:sent, '[D01].[M01].[Y0001] [H01]:[m01]')"/>
				</xsl:if>
			</td>
			<td data-k="received" data-v="{string(mail:received)}">
				<xsl:if test="mail:received castable as xs:dateTime">
					<xsl:value-of select="format-dateTime(mail:received, '[D01].[M01].[Y0001] [H01]:[m01]')"/>
				</xsl:if>
			</td>
		</tr>
	</xsl:template>
</xsl:stylesheet>
