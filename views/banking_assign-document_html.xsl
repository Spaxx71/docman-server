<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="home-views"/> 
	<xsl:param name="home-data"/>                
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="bank-account" required="yes"/>
	<xsl:param name="year" required="yes"/>
	<xsl:param name="resource-id" required="yes"/>
	<xsl:param name="owner" required="no"/>

	<xsl:decimal-format name="EU" decimal-separator="," grouping-separator="."/>

	<xsl:template match="/">
		<page>
			<body>
				<xsl:apply-templates/>
			</body>
		</page>
	</xsl:template>

	<xsl:template match="result">
		<xsl:choose>
			<xsl:when test="not(@owner) or @owner=''">
				<xsl:for-each select="Accounts/Account">
					<ul class="Selection">
						<li>
							<xsl:choose>
								<xsl:when test="Name='Diverse Lieferanten'">
									<xsl:attribute name="style" select="'font-weight:bold;'"/>
								</xsl:when>
							</xsl:choose>
							<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/banking/',$bank-account,'/',$resource-id,'/assign-document.html?owner=',@kto)}">
								<xsl:value-of select="./Name"/>
							</a>
						</li>
					</ul>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<ul class="Nav">
					<li>
						<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/banking/',$bank-account,'/',$resource-id,'/assign-document.html')}">Anderen Halter auswählen</a>
					</li>
				</ul>
				<label>Name:</label>
				<xsl:value-of select="//Account/Name"/>
				<br/>
				<label>Typ:</label>
				<xsl:value-of select="//Account/@type"/>
				<br/>
				<label>Classes:</label>
				<xsl:value-of select="//Account/@classes"/>
				<br/>
				<label>Notizen:</label>
				<xsl:value-of select="//Account/Notes"/>
				<br/>
				<label>CustomerId:</label>
				<xsl:value-of select="//Account/CustomerID"/>

				<table>
					<tr>
						<th>#</th>
						<th>Aktion</th>
						<th>Typ</th>
						<th>Datum</th>
						<th>Halter</th>
						<th>PaymentDetails</th>
						<th>CustomerRef</th>
						<th>MandantRef</th>
						<th>Gesamtbetrag</th>
						<th>Währung</th>
						<th>Creditor ID</th>
						<th>Abw. Empf.</th>
					</tr>
					<xsl:apply-templates/>
				</table>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="Accounting">
		<xsl:variable name="iban" select="IBAN"/>

		<tr>
			<td>
				<a href="{$home-web-gui}/{$tenant}/{$year}/banking/{$bank-account}/{$resource-id}/details.html">
					<xsl:value-of select="count(preceding-sibling::Accounting)+1"/>
				</a>
			</td>
			<td>
				<a href="{$home-web-gui}/{$tenant}/{$year}/banking/{$bank-account}/{$resource-id}.pdf">Ansehen</a><br/>
				<a href="{$home-web-gui}/{$tenant}/{$year}/binders/enter/index.html?ref=/{$tenant}/{$year}/banking/{$bank-account}/{$resource-id}.pdf">Neues Dokument erstellen</a>
			</td>
			<td><xsl:value-of select="SalesType"/></td>
			<td>
				<xsl:value-of select="format-date(ValueDate,'[D01].[M01].[Y0001]')"/><br/>
				<span style="color:#aaa"><xsl:value-of select="format-date(BookingDate,'[D01].[M01].[Y0001]')"/></span>
			</td>
			<td>
				<xsl:choose>
					<xsl:when test="$owner">
						<a href="{$home-web-gui}/{$tenant}/accounts/{$owner}/details.html">
							<xsl:value-of select="Recipient"/>
						</a>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="Recipient"/>
					</xsl:otherwise>
				</xsl:choose>
			</td>
			<td>
				<xsl:call-template name="outputText">
					<xsl:with-param name="text" select="PaymentDetails"/>
				</xsl:call-template>
			</td>
			<td><xsl:value-of select="CustomerRef"/></td>
			<td><xsl:value-of select="MandantRef"/></td>
			<td class="Money">
				<xsl:value-of select="format-number(Amount,'#.#00,00','EU')"/>
			</td>
			<td><xsl:value-of select="CurrencyUnit"/></td>

			<td><xsl:value-of select="CreditorID"/></td>
			<td><xsl:value-of select="DivergentRecepient"/></td>
		</tr>
	</xsl:template>

	<xsl:template match="Binders">
			<tr>
				<th>#</th>
				<th>Aktion</th>
				<th>Typ</th>
				<th>Datum</th>
				<th>Halter</th>
				<th>Beleg Nummer</th>
				<th>Kundennummer</th>
				<th>Beleg Inhalt</th>
				<th>Gesamtbetrag</th>
				<th>Währung</th>
				<th>Notizen</th>
				<th>Anhänge</th>
				<th>Name</th>
			</tr>
			<xsl:apply-templates>
				<xsl:sort select="@date"/>
			</xsl:apply-templates>
	</xsl:template>

	<xsl:template match="Process">
		<tr>
			<td>
				<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/binders/',format-date(current()/@date,'[M00]'),'/',current()/@id,'/edit/',replace(current()/@type,'_','-'),'.html')}">
					<xsl:value-of select="count(preceding::Process)+1"/>
				</a>
			</td>
			<td>
				<xsl:choose>
					<xsl:when test="Payments/Payment">
						<xsl:choose>
							<xsl:when test="Payments/Payment/@refID = $resource-id">
								<xsl:attribute name="class">
									<xsl:text>done</xsl:text>
								</xsl:attribute>
								Dokument bereits mit dieser Zahlung verknüpft.
								<br/>
							</xsl:when>
							<xsl:otherwise>
								Dokument bereits verknüpft:<br/>
								<xsl:for-each select="Payments/Payment/@refID">
									<a href="{$home-web-gui}/{$tenant}/{$year}/banking/{$bank-account}/{.}.pdf"><xsl:value-of select="."/></a><br/>
								</xsl:for-each>
								<br/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
				</xsl:choose>
				<xsl:if test="not(Payments/Payment/@refID = $resource-id)">
					<!-- /app/bintellix/2019/binders/attach/banking.html?ref=/bintellix/2019/banking/222971400/PAYa5311ef7a1794ddc6878114c26234ccc&activity=PRO0ba7e371-c850-4797-a7e3-71c850e79732&owner=70002 -->
					<!-- /app/bintellix/2019/binders/attach/banking.html?activity=PRO0ba7e371-c850-4797-a7e3-71c850e79732&owner=70002 -->
					<xsl:choose>
						<xsl:when test="@mainTask='InvoiceInTask'">
							<form method="get" action="{$home-web-gui}/{$tenant}/{$year}/binders/{@binder}/{@id}/edit/{replace(@mainTask,'Task$','')}.html">
								<input type="hidden" name="attach" value="Payment"/>
								<!-- <input type="hidden" name="ref" value="{concat('/',$tenant,'/',$year,'/banking/',$bank-account,'/',$resource-id)}"/> -->
								<input type="hidden" name="ref" value="{$resource-id}"/>
								<button type="submit">Dieser Rechnung zuordnen</button>
							</form>
						</xsl:when>
						<xsl:when test="@mainTask='InvoiceOutTask'">
							<form method="get" action="{$home-web-gui}/{$tenant}/{$year}/binders/{@binder}/{@id}/edit/{replace(@mainTask,'Task$','')}.html">
								<input type="hidden" name="attach" value="Payment"/>
								<input type="hidden" name="ref" value="{$resource-id}"/>
								<button type="submit">Dieser Rechnung (ausgehend) zuordnen</button>
							</form>
						</xsl:when>
						<xsl:otherwise>
							<form method="get" action="{$home-web-gui}/{$tenant}/{$year}/binders/{@binder}/{@id}/edit/{replace(@mainTask,'Task$','')}.html">
								<input type="hidden" name="attach" value="Payment"/>
								<input type="hidden" name="ref" value="{$resource-id}"/>
								<button type="submit">Diesem Vorgang zuordnen</button>
							</form>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
			</td>
			<td><xsl:value-of select="@mainTask"/></td>
			<td>
				<xsl:attribute name="class">
					<xsl:choose>
						<xsl:when test="@date = ../../../BankAccount/Accounting/ValueDate">
							<xsl:text> done</xsl:text>
						</xsl:when>
						<xsl:when test="xs:date(@date) &lt;= (xs:date(../../../BankAccount/Accounting/ValueDate) + xs:dayTimeDuration('P3D')) and xs:date(@date) &gt;= (xs:date(../../../BankAccount/Accounting/ValueDate) - xs:dayTimeDuration('P3D'))">
							<xsl:text> part</xsl:text>
						</xsl:when>
						<xsl:when test="@date &gt; ../../../BankAccount/Accounting/ValueDate">
							<xsl:text> invalid</xsl:text>
						</xsl:when>
					</xsl:choose>
				</xsl:attribute>
				<xsl:value-of select="format-date(@date,'[D01].[M01].[Y0001]')"/>
			</td>
			<td>
				<a href="{$home-web-gui}/{$tenant}/accounts/{$owner}/details.html">
					<xsl:value-of select="//Account/Name"/>
				</a>
			</td>
			<td>
				<xsl:variable name="RefID" select="RefID"/>
				<xsl:attribute name="class">
					<xsl:choose>
						<xsl:when test="../../../BankAccount/Accounting/PaymentDetails/PaymentDetail[contains(.,$RefID)]">
							<xsl:text> part</xsl:text>
						</xsl:when>
					</xsl:choose>
					<xsl:choose>
						<xsl:when test="$RefID = ../../../BankAccount/Accounting/PaymentDetails/PaymentDetail">
							<xsl:text> done</xsl:text>
						</xsl:when>
					</xsl:choose>
				</xsl:attribute>
				<xsl:value-of select="RefID"/>
			</td>
			<td>
				<xsl:variable name="CustomerRefID" select="//Account/CustomerID"/>
				<xsl:attribute name="class">
					<xsl:choose>
						<xsl:when test="$CustomerRefID=''">
							<xsl:text> </xsl:text>
						</xsl:when>
						<xsl:when test="../../../BankAccount/Accounting/CustomerRef[contains(.,$CustomerRefID)]">
							<xsl:text> part</xsl:text>
						</xsl:when>
						<xsl:when test="../../../BankAccount/Accounting/MandantRef[contains(.,$CustomerRefID)]">
							<xsl:text> part</xsl:text>
						</xsl:when>
						<xsl:when test="$CustomerRefID = ../../../BankAccount/Accounting/PaymentDetails/CustomerRef">
							<xsl:text> done</xsl:text>
						</xsl:when>
						<xsl:when test="../../../BankAccount/Accounting/MandantRef[contains(.,$CustomerRefID)]">
							<xsl:text> done</xsl:text>
						</xsl:when>
					</xsl:choose>
				</xsl:attribute>
				<xsl:value-of select="TransactionID"/>
			</td>
			<td><xsl:value-of select="Description"/></td>
			<td>
				<xsl:attribute name="class">
					<xsl:text>Money</xsl:text>
					<xsl:if test="number(../../../BankAccount/Accounting/Amount) &lt; number(TotalAmount/@value)">
						<xsl:text> invalid</xsl:text>
					</xsl:if>
					<xsl:if test="number(../../../BankAccount/Accounting/Amount) = number(TotalAmount/@value)">
						<xsl:text> done</xsl:text>
					</xsl:if>
				</xsl:attribute>
				<xsl:value-of select="format-number(TotalAmount/@value,'#.#00,00','EU')"/>
			</td>
			<td><xsl:value-of select="TotalAmount/@unit"/></td>
			<td><xsl:value-of select="Notes"/></td>
			<td>
				<xsl:for-each select="Files/File">
					<a href="{concat($home-web-gui,@src)}">
						<xsl:value-of select="@fileName"/>
						<xsl:value-of select="@fileExtension"/>
						(<xsl:value-of select="@type"/>)
					</a>
				</xsl:for-each>
			</td>
			<td><a href="{$home-web-gui}/{$tenant}/{$year}/binders/{format-date(@date,'[M00]')}/{@name}/edit/invoice-in.html"><xsl:value-of select="@name"/></a></td>

		</tr>
	</xsl:template>

	<xsl:template match="Accounts">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="Account">
	</xsl:template>

	<xsl:template name="outputText">
		<xsl:param name="text" select="."/>

		<xsl:choose>
			<xsl:when test="not(contains($text, '&#xA;'))">
				<xsl:copy-of select="$text"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="substring-before($text, '&#xA;')"/>
				<br/>
				<xsl:call-template name="outputText">
					<xsl:with-param name="text" select="substring-after($text, '&#xA;')"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

</xsl:stylesheet>