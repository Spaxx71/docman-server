<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:xf="http://www.w3.org/2002/xforms" version="3.1">

	<xsl:template name="Attachments">
		<xsl:param name="new-document" select="true"/>
		<div style="min-width:800px">
			<xf:repeat id="files-task" nodeset="instance('document')/Process/Tasks/*/Files/File" appearance="full"> <!--  [@type=('invoice_in','invoice_in_storno')] -->
				<xsl:call-template name="Attachment">
					<xsl:with-param name="name" select="'task'"/>
					<xsl:with-param name="new-document" select="$new-document"/>
				</xsl:call-template>
			</xf:repeat>
		</div>
	</xsl:template>


	<xsl:template name="Attachment">
		<xsl:param name="new-document" select="true"/>	
		<xsl:param name="name"/> <!-- required true -->

		<a href="/app{{@src}}" style="font-size:60%">
			<xf:output ref="@fileName">
				<xf:label>Name:</xf:label>
			</xf:output>
			<xf:output ref="@fileExtension"/>
			<xsl:text> (</xsl:text>
			<xf:output ref="@uploadName"/>
			<xsl:text>)</xsl:text>
		</a>
		<br/>
		<xf:select1 ref="@doctype" appearance="minimal">
			<xf:label>Dokument Typ</xf:label>
			<xf:item>
				<xf:label>          </xf:label>
				<xf:value/> 
			</xf:item>
			<xf:item>
				<xf:label>Elektronischer Beleg</xf:label>
				<xf:value>digital</xf:value> 
			</xf:item>
			<xf:item>
				<xf:label>Papier-Beleg</xf:label>
				<xf:value>paper</xf:value> 
			</xf:item>
		</xf:select1>

		<xf:output ref="@mimeType">
			<xf:label>MIME-Type:</xf:label>
		</xf:output>

		<div style="font-size:70%">
			<xf:output ref="@hashcode">
				<xf:label>Hashcode:</xf:label>
			</xf:output>
		</div>

		<xf:select1 ref="@type" appearance="minimal">
			<xf:label>Dokument Inhalt</xf:label>
			<xf:item>
				<xf:label>          </xf:label>
				<xf:value/> 
			</xf:item>
			<xf:item>
				<xf:label>Bankauszug</xf:label>
				<xf:value>doc-bank-statement</xf:value> 
			</xf:item>			
			<xf:item>
				<xf:label>Banküberweisung</xf:label>
				<xf:value>doc-bank-transfer</xf:value> 
			</xf:item>
			<xf:item>
				<xf:label>Bezahlung per Bank/EC</xf:label>
				<xf:value>doc-payment-bank</xf:value> 
			</xf:item>
			<xf:item>
				<xf:label>Bezahlung in Bar</xf:label>
				<xf:value>doc-payment-cash</xf:value> 
			</xf:item>
			<xf:item>
				<xf:label>Dauerauftrag / Abbonement</xf:label>
				<xf:value>doc-periodic-payment</xf:value> 
			</xf:item>
			<xf:item>
				<xf:label>Rechnung (eingehend)</xf:label>
				<xf:value>doc-invoice-in</xf:value> 
			</xf:item>
			<xf:item>
				<xf:label>Rechnung (eingehend) STORNO</xf:label>
				<xf:value>doc-invoice-in-storno</xf:value> 
			</xf:item>
			<xf:item>
				<xf:label>Rechnungs (ausgehend)</xf:label>
				<xf:value>doc-invoice-out</xf:value> 
			</xf:item>
			<xf:item>
				<xf:label>Rechnungs (ausgehend) STRONO</xf:label>
				<xf:value>doc-invoice-out-storno</xf:value> 
			</xf:item>
			<xf:item>
				<xf:label>Gehaltszettel</xf:label>
				<xf:value>doc-payslip</xf:value> 
			</xf:item>
			<xf:item>
				<xf:label>Information</xf:label>
				<xf:value>doc-information</xf:value> 
			</xf:item>			
			<xf:item>
				<xf:label>Lieferschein</xf:label>
				<xf:value>doc-delivery-note</xf:value> 
			</xf:item>
			<xf:item>
				<xf:label>Mahngebühr / Verspätungsz.</xf:label>
				<xf:value>doc-dunning-charge</xf:value> 
			</xf:item>
			<xf:item>
				<xf:label>Kontoauszug</xf:label>
				<xf:value>doc-bank-statement</xf:value>
			</xf:item>
			<xf:item>
				<xf:label>Steuerbeleg</xf:label>
				<xf:value>doc-tax</xf:value>
			</xf:item>
			<xf:item>
				<xf:label>Vertrag</xf:label>
				<xf:value>doc-contract</xf:value>
			</xf:item>							
			<xf:item>
				<xf:label>Sonstiges</xf:label>
				<xf:value>doc-undefined</xf:value> 
			</xf:item>
		</xf:select1>

		<!-- <xf:output value="instance('document')/Process/Tasks/*/Files/File[index('files')]/@uploadSrc!=''"/> -->

		<xf:switch>
			<xf:case id="upload-{$name}">
				<xsl:if test="$new-document">
					<xsl:attribute name="selected">true</xsl:attribute>
				</xsl:if>
				<iframe src="{{@uploadSrc}}" width="100%" height="550px"/>
				<xsl:if test="$new-document">
					<xf:trigger>
						<xf:label>Ansicht Transfer</xf:label>
						<xf:toggle case="source-{$name}" ev:event="DOMActivate"/>
					</xf:trigger>
				</xsl:if>
			</xf:case>
			<xf:case id="source-{$name}">
				<xsl:if test="not($new-document)">
					<xsl:attribute name="selected">true</xsl:attribute>
				</xsl:if>
				<iframe src="/app{{@src}}" width="100%" height="550px"/>
				<xsl:if test="$new-document">
					<xf:trigger>
						<xf:label>Ansicht Ablage</xf:label>
						<xf:toggle case="upload-{$name}" ev:event="DOMActivate"/>
					</xf:trigger>
				</xsl:if>
			</xf:case>
		</xf:switch>

		<!--
			<embed src="{{@uploadSrc}}" width="100%" height="550px">&#160;</embed>
		-->
		<!--
			<object data="{{@uploadSrc}}" style="width:100%; height:550px">
				<a href="{{@uploadSrc}}">Download Dokument</a>
			</object>
		-->
	</xsl:template>
	
</xsl:stylesheet>