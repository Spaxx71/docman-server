<!-- 
========================================================================
LICENSE AGREEMENT:
This software is distributed WITHOUT ANY WARRANTY and without even the
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
========================================================================
This copy of Checker (an automated compare tool) is licensed under the
Lesser General Public License (LGPL), version 3 ("the License").

See the License for details about distribution rights, 
modification and transformation of it.

You should have received a copy of the GNU General Public License
along with this program.  If not, see http://www.gnu.org/licenses/.
========================================================================
Copyright:
(c) 2010-2014 by InterSecurity GmbH & Co. KG, Germany
========================================================================
@Author: Eduard Huber
@Version: 1.0
======================================================================== 
--><xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:sm="http://exist-db.org/xquery/securitymanager" xmlns:local="http://localhost/local/" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:xhtml="http://www.w3.org/1999/xhtml" exclude-result-prefixes="local xhtml" version="3.0">
    <xsl:output version="1.1" method="xml" encoding="UTF-8" indent="no" omit-xml-declaration="yes"/>
    <!-- <xsl:namespace-alias stylesheet-prefix="xhtml" result-prefix="" exclude-result-prefixes="xhtml"/> -->
    <xsl:strip-space elements="*"/>
    <xsl:param name="home-web-gui" required="yes"/>
    <xsl:param name="home-web-api" required="yes"/>
    <xsl:param name="home-data"/>
    <xsl:param name="home-views" required="yes"/>
    <xsl:param name="tenant" required="yes"/>
    <xsl:param name="path" required="yes"/>
    <xsl:param name="resource-id" select="''"/>
    <xsl:param name="filename" select="''"/>
    <xsl:param name="year" select="''"/>
    <xsl:param name="binder" select="''"/>
    <xsl:param name="bank-account" select="''"/>
    <xsl:param name="lang" select="'en'"/>
    <xsl:param name="username" select="''"/>

    <xsl:function name="local:replaceVariables">
        <xsl:param name="Replacement" required="yes"/>
        <xsl:value-of select="replace(replace(replace(replace(replace(replace($Replacement,'\$lang', $lang),'\$tenant', $tenant),'\$year', $year),'\$binder', $binder),'\$resource-id', $resource-id),'\$bank-account', $bank-account)"/>
    </xsl:function>
    <xsl:variable name="url" select="concat($path, $filename)"/>
    <xsl:variable name="sitemap" select="doc(concat($home-views,'/sitemap.xml'))"/>
    <xsl:variable name="title">
        <xsl:variable name="t" select="local:replaceVariables($sitemap//page[replace(@url,'\?.*','')=$url]/title)"/>
        <xsl:choose>
            <xsl:when test="$t != ''">
                <xsl:value-of select="$t"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>UNKNOWN</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:template match="/">
        <xsl:if test="exists(//xf:*)">
            <xsl:processing-instruction name="xml-stylesheet">
                <xsl:text>href="</xsl:text>
                <xsl:value-of select="$home-web-gui"/>
                <xsl:text>/xsltforms/xsltforms.xsl" type="text/xsl"</xsl:text>
            </xsl:processing-instruction>
            <xsl:processing-instruction name="xsltforms-options">
                <xsl:text>debug="no" lang="de"</xsl:text>
            </xsl:processing-instruction>
        </xsl:if>
        <xhtml:html xmlns="http://www.w3.org/1999/xhtml" lang="de" xml:lang="de">
            <head>
                <title>
                    <xsl:value-of select="$title"/>
                </title>
                <xsl:if test="not(//*:meta[@http-equiv])">
                    <meta http-equiv="X-UA-Compatible" content="IE=8"/> <!-- IE=edge -->
                </xsl:if>
                <meta charset="UTF-8"/>
                <meta http-equiv="Pragma" content="no-cache"/>
                <meta name="robots" content="noindex, nofollow"/> 
                <meta name="viewport" content="width=device-width, initial-scale=1"/>
                <link rel="stylesheet" type="text/css" href="{$home-web-gui}/resources/docman.css"/>
                <xsl:apply-templates select="page/head/* | html/head/* | xhtml:html/xhtml:head/*"/>

                <script type="text/javascript" src="{$home-web-gui}/resources/docman.js"> </script>	
            </head>
            <body>
<!-- [url="<xsl:value-of select="$url"/>" path="<xsl:value-of select="$path"/>" filename="<xsl:value-of select="$filename"/>"] -->
                <div id="header">
                    <!-- quick hack to disable menue for online-banking hbci/fints banking_update-process.xqy and banking_update-process_html.xsl -->
                    <xsl:if test="$filename != 'update-process.html'">
                        <div id="menu" class="breadcrump">
                            <div style="float:left;">
                                <!-- [Debug: <xsl:value-of select="$url"/>] -->
                                <span>You are here: </span>
                                <xsl:for-each select="$sitemap//page[descendant-or-self::*/replace(@url,'\?.*','')=$url]">
                                    <xsl:if test="position() != 1">
                                        <xsl:text> &gt; </xsl:text>
                                    </xsl:if>
                                    <xsl:choose>
                                        <xsl:when test="breadcrumb = '$year'">
                                            <div style="display:inline-block; padding: 0px 3px; background-color:#F93;">
                                                <a href="{replace(concat($home-web-gui, local:replaceVariables(@url)),'//','/')}">
                                                    <xsl:attribute name="alt" select="Buchungsjahr"/>
                                                    <xsl:value-of select="local:replaceVariables(breadcrumb)"/>
                                                </a>
                                            </div>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <a href="{replace(concat($home-web-gui, local:replaceVariables(@url)),'//','/')}">
                                                <xsl:attribute name="alt" select="breadcrumb"/>
                                                <xsl:value-of select="local:replaceVariables(breadcrumb)"/>
                                            </a>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:for-each>
                                <xsl:text>  </xsl:text>
                            </div>
                            <xsl:for-each select="//menu/crosslinks/crosslink">
                                <xsl:text>  </xsl:text>
                                <xsl:variable name="url" select="replace(concat($home-web-gui,local:replaceVariables($path),@url),'//','/')"/>
                                <xsl:choose>
                                    <xsl:when test="contains($url,'?')">
                                        <a href="{substring-before($url,'?')}?{substring-after($url,'?')}" class="buttonComp">
                                            <xsl:if test="@external='yes'">
                                                <xsl:attribute name="target" select="'_blank'"/>
                                            </xsl:if>
                                            <xsl:value-of select="@title"/>
                                            <xsl:if test="@external='yes'">
                                                <image src="{$home-web-gui}/base/images/action_extlink.png" title="open in new window" height="10px" width="10px"/>
                                            </xsl:if>
                                        </a>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <a href="{$url}" class="buttonComp">
                                            <xsl:if test="@external='yes'">
                                                <xsl:attribute name="target" select="'_blank'"/>
                                            </xsl:if>
                                            <xsl:value-of select="@title"/>
                                            <xsl:if test="@external='yes'">
                                                <image src="{$home-web-gui}/base/images/action_extlink.png" title="open in new window" height="10px" width="10px"/>
                                            </xsl:if>
                                        </a>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each>


                            <div style="float:right">
                                <span> '</span>
                                <a href="{$home-web-gui}/{$tenant}/user/index.html"><xsl:value-of select="$username"/></a>
                                <span>' </span>
                                <a href="{$home-web-gui}/logout.html">abmelden</a>
                            </div>

                            <div style="float:right">
                                <xsl:text> </xsl:text>
                                <xsl:value-of select="format-date(current-date(),'[D00].[M00].[Y0000]')"/>
                                <xsl:text> </xsl:text>
                            </div>
                        </div>
                        <div id="headline">
                            <xsl:value-of select="$title"/>
                        </div>
                    </xsl:if>
                </div>
                <div id="content">
                    <xsl:apply-templates/>
                </div>
           </body>
        </xhtml:html>
    </xsl:template>

    <xsl:template match="error | xhtml:error">
        <div xmlns="http://www.w3.org/1999/xhtml" class="Error">
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="xhtml:html | html | page">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="xhtml:html/xhtml:head | html/head | page/head">
        <!-- no longer needed as part of root now -->
    </xsl:template>
    <xsl:template match="xhtml:html/xhtml:body | html/body | page/body">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="xhtml:title | title">
        <!-- nothing to do -->
    </xsl:template>
    <xsl:template match="xhtml:subtitle">
        <xhtml:h3>
            <xsl:apply-templates/>
        </xhtml:h3>
    </xsl:template>
    <!-- <xsl:template match="xhtml:menu | menue" priority="1"/> -->
    <xsl:template match="xhtml:error | error" priority="1">
        <div xmlns="http://www.w3.org/1999/xhtml" class="error">
            <xhtml:h3>An error occured:</xhtml:h3>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="*[namespace-uri()='http://www.w3.org/1999/xhtml']" priority="-1">
        <xsl:element name="{local-name()}" namespace="http://www.w3.org/1999/xhtml">
            <xsl:apply-templates select="node() | @*"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="*[namespace-uri()='http://www.w3.org/2002/xforms']" priority="-1">
        <xsl:element name="{concat('xf:', local-name())}" namespace="http://www.w3.org/2002/xforms">
            <xsl:apply-templates select="node() | @*"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="node()|@*" priority="-2">
        <xsl:copy copy-namespaces="yes">
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>