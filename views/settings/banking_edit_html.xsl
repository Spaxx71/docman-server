<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

	<xsl:param name="home-web-gui" required="yes"/>
	<xsl:param name="home-web-api" required="yes"/>
	<xsl:param name="home-views"/> 
	<xsl:param name="home-data"/>                
	<xsl:param name="tenant" required="yes"/>
	<xsl:param name="resource-id" required="yes"/>
	<xsl:param name="year" required="yes"/> 

	<xsl:template match="/">
	<html xmlns="http://www.w3.org/1999/xhtml" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:xf="http://www.w3.org/2002/xforms">
		<head>
			<title>Edit document</title>
			<xf:model schema="" id="M">

				<xf:instance xmlns="" id="accounting">
					<data>
						<xsl:copy-of select="result/BankAccount"/>
					</data>
				</xf:instance>

				<xf:instance xmlns="" id="accounting-new">
					<data>
						<Accounting id="PAYxxx" oid="" saldoTimestamp="2000-01-01T00:00:00" saldoAmount="0.0" isStorno="">
							<BookingDate/>
							<ValueDate/>
							<SalesType key="0">Unknown</SalesType>
							<Recipient>None</Recipient>
							<PaymentDetails>
								<PaymentDetail>None</PaymentDetail>
							</PaymentDetails>
							<Usages/>
							<IBAN/>
							<BIC/>
							<MandantRef/>
							<CustomerRef>NONREF</CustomerRef>
							<EndToEndRef>NOTPROVIDED</EndToEndRef>
							<CreditorID/>
							<ExternalCosts/>
							<Amount type="DEBIT">0.0</Amount>
							<OriginalAmount/>
							<CurrencyUnit>EUR</CurrencyUnit>
						</Accounting>
					</data>
				</xf:instance>

				<xf:instance xmlns="" id="bank-account">
					<data>
						<xsl:copy-of select="result/BankAccount"/>
					</data>
				</xf:instance>


				<xf:bind ref="instance('bank-account')/BankAccount/@kto" type="xs:string" constraint="string-length(.) &gt; 3"/> 

				<xf:bind ref="instance('accounting')/BankAccount/@kto" type="xs:string" constraint="string-length(.) &gt; 3" readonly="true()"/> 
				<xf:bind ref="instance('accounting')/BankAccount/Accountings/Accounting/@id" type="xs:string" constraint="string-length(.) &gt; 3 and starts-with(.,'PAY')" required="true()"/> 
				<xf:bind ref="instance('accounting')/BankAccount/Accountings/Accounting/ValueDate" type="xs:date" required="true()"/> 
				<xf:bind ref="instance('accounting')/BankAccount/Accountings/Accounting/BookingDate" type="xs:date" required="true()"/> 
				<xf:bind ref="instance('accounting')/BankAccount/Accountings/Accounting/Amount/@type" type="xs:string" constraint=".='DEBIT' or .='CREDIT'" required="true()"/>
				<xf:bind ref="instance('accounting')/BankAccount/Accountings/Accounting/Amount" type="xs:decimal" constraint="if(@type='CREDIT', number(.) &gt; 0, number(.) &lt; 0)" required="true()"/>
				<xf:bind ref="instance('accounting')/BankAccount/Accountings/Accounting/@saldoAmount" type="xs:decimal" required="true()"/>
				<xf:bind ref="instance('accounting')/BankAccount/Accountings/Accounting/Recipient" type="xs:string" constraint="string-length(.) != 0" required="true()"/>
				<xf:bind ref="instance('accounting')/BankAccount/Accountings/Accounting/PaymentDetails/PaymentDetail" type="xs:string" constraint="string-length(.) != 0" required="true()"/>
				<xf:bind ref="instance('accounting')/BankAccount/Accountings/Accounting/ExternalCosts" type="xs:decimal" required="false()"/>
				
				<xf:action ev:event="xforms-ready">
					<xf:delete ref="instance('accounting')/BankAccount/@year"/>
					<xf:delete ref="instance('accounting')/BankAccount/Accountings/@kto"/>
					<xf:delete ref="instance('accounting')/BankAccount/Accountings/@hasOnlineBanking"/>
					<xf:delete ref="instance('accounting')/BankAccount/Accountings/Accounting/@booked"/>
					<xf:delete ref="instance('accounting')/BankAccount/Accountings/Accounting/@booked-amount"/>
				</xf:action>
				
				<!-- <xf:bind ref="instance('accounting')/AccountName" type="xs:string" relevance="../@type='ledger_account'"/> -->


				<xf:submission id="save" method="put" instance="accounting" ref="BankAccount" replace="all" validate="true"> <!--  ref="BankAccount/Accountings"  -->
					<xf:resource value="concat('{$home-web-api}','/','{$tenant}','/banks/',instance('bank-account')/BankAccount/@kto,'/','{$year}')"/>
	                		<xf:action ev:event="xforms-submit-done">
						<xf:message>Erfolgreich gespeichert.
							<xf:output value="event('resource-uri')">
								<xf:label>Resource URI: </xf:label>
							</xf:output>
							<xsl:text>
</xsl:text>
							<xf:output value="event('response-body')">
								<xf:label>Body: </xf:label>
							</xf:output>
						</xf:message>
					</xf:action>
					<xf:action ev:event="xforms-submit-error">
						<xf:message>Es ist ein Fehler aufgetreten: 
							<xsl:text>
</xsl:text>
							<xf:output value="event('error-type')">
								<xf:label>Error type: </xf:label>
							</xf:output>
							<xsl:text>
</xsl:text>
							<xf:output value="event('resource-uri')">
								<xf:label>
Resource URI: </xf:label>
							</xf:output>
							<xsl:text>
</xsl:text>
							<xf:output value="event('response-status-code')">
								<xf:label>
Status Code: </xf:label>
							</xf:output>
							<xsl:text>
</xsl:text>
							<xf:output value="event('response-reason-phrase')">
								<xf:label>
Reason: </xf:label>
							</xf:output>
							<xsl:text>
</xsl:text>
							<xf:output value="event('response-headers')">
								<xf:label>
Headers: </xf:label>
							</xf:output>
							<xsl:text>
</xsl:text>
							<xf:output value="event('response-body')">
								<xf:label>
Body: </xf:label>
							</xf:output>
						</xf:message>
					</xf:action>
				</xf:submission>
			</xf:model>

			<style>
<![CDATA[
				.xforms-label {
					width: inherit !important;
				}
]]>


			</style>
		</head>
		<body>
			<xf:group ref="instance('accounting')/BankAccount/BankAccountDetail">
				<table>
					<tr>
						<th>Konto ID</th>
						<td><xf:input ref="../@kto"/></td>
					</tr>
					<tr>
						<th>Lang-Name des Konto</th>
						<td>
							<xf:input ref="AccountName">
								<xf:hint>Frei wählbarer vollständiger Name</xf:hint>
							</xf:input>
						</td>
					</tr>
					<tr>
						<th>Nickname des Konto</th>
						<td>
							<xf:input ref="AccountNick">
								<xf:hint>Frei wählbarer kurzer Name</xf:hint>
							</xf:input>
						</td>
					</tr>					
					<tr>
						<th>Bank Name</th>
						<td>
							<xf:input ref="BankName">
								<xf:hint>Frei wählbarer Bankname</xf:hint>
							</xf:input>
						</td>
					</tr>					
					<tr>
						<th>Kontonummer</th>
						<td>
							<xf:input ref="KTNR"/>
						</td>
					</tr>
					<tr>
						<th>Bankleitzahl</th>
						<td>
							<xf:input ref="BLZ">
								<xf:hint>8 Stellen</xf:hint>
							</xf:input>
						</td>
					</tr>
					<tr>
						<th>IBAN</th>
						<td>
							<xf:input ref="IBAN">
								<xf:hint>xxx Stellen</xf:hint>
							</xf:input>
						</td>
					</tr>
					<tr>
						<th>BIC</th>
						<td>
							<xf:input ref="BIC">
								<xf:hint>xxx Stellen</xf:hint>
							</xf:input>
						</td>
					</tr>
					<tr>
						<th>Währung</th>
						<td>
							<xf:select1 ref="CurrencyUnit">
								<xf:item>
                					<xf:label>EUR</xf:label>
                					<xf:value>EUR</xf:value> 
            					</xf:item>
							</xf:select1>
						</td>
					</tr>
					<tr>
						<th>Notizen</th>
						<td>
							<xf:textarea ref="Notes"/>
						</td>
					</tr>

					<tr>
						<th colspan="2">Online Banking (HBCI / FinTS 3.0)</th>
					</tr>				
					<tr>
						<th>Bank Kunde ID</th>
						<td>
							<xf:input ref="BankUserID">
								<xf:hint>Kunden Identität für online Banking</xf:hint>
							</xf:input>
						</td>
					</tr>
					<tr>
						<th>Customer ID</th>
						<td>
							<xf:input ref="CustomerID">
								<xf:hint>Meist die Kunden ID, kannn bei einigen Banken leer bleiben.</xf:hint>
							</xf:input>
						</td>
					</tr>
					<tr>
						<th>Authenfizierungsart</th>
						<td>
							<xf:select1 ref="OnlineBanking/Auth/@type">
								<xf:item>
                					<xf:label>PIN/TAN</xf:label>
                					<xf:value>901</xf:value> 
            					</xf:item>
								<xf:item>
                					<xf:label>smsTAN</xf:label>
                					<xf:value>911</xf:value> 
            					</xf:item>
								<xf:item>
                					<xf:label>chip-TAN (optisch HHD1.4)</xf:label>
                					<xf:value>912</xf:value> 
            					</xf:item>														
								<xf:item>
                					<xf:label>chip-TAN (manuell HHD1.4)</xf:label>
                					<xf:value>913</xf:value> 
            					</xf:item>														
								<xf:item>
                					<xf:label>chip-TAN</xf:label>
                					<xf:value>920</xf:value>
            					</xf:item>
								<xf:item>
                					<xf:label>mobile-TAN</xf:label>
                					<xf:value>930</xf:value> 
            					</xf:item>								
								<xf:item>
                					<xf:label>photo-TAN</xf:label>
                					<xf:value>955</xf:value> 
            					</xf:item>
							</xf:select1>
						</td>
					</tr>
					<tr>
						<th>Authentifizierung PIN</th>
						<td>
							<xf:secret ref="OnlineBanking/Auth/PIN"/>
						</td>
					</tr>
					<tr>
						<th>Hostname</th>
						<td>
							<xf:input ref="OnlineBanking/Hostname"/>
						</td>
					</tr>
					<tr>
						<th>Port</th>
						<td>
							<xf:input ref="OnlineBanking/Port"/>
						</td>
					</tr>
					<tr>
						<th>Nachrichten (eingehend)</th>
						<td>
							<xf:input ref="OnlineBanking/MessageIn/@url"/>
						</td>
					</tr>
					<tr>
						<th>Nachrichten (ausgehend)</th>
						<td>
							<xf:input ref="OnlineBanking/MessageOut/@url"/>
						</td>
					</tr>
					<tr>
						<th>Passport URI</th>
						<td>
							<xf:input ref="OnlineBanking/Passport/@url"/>
						</td>
					</tr>
				</table>
			</xf:group>

			<table>
				<thead>
					<tr>
						<th>#</th>
						<th>Aktivität</th>
						<th>ID</th>						
						<th>Value Date</th>
						<th>Booking Date</th>
						<th>Betrag</th>						
						<th>Betrag Art</th>
						<th>External Costs</th>						
						<th>Orig.-Betrag</th>						
						<th>@saldoAmount</th> <!-- Kontostand nach Buchung dieser Position-->
						<th>Umsatzart Key</th>
						<th>Umsatzart Descr.</th>						
						<th>Begünstigter / Auftraggeber</th>
						<th>Verwendungszweck</th>
						<th>IBAN</th>
						<th>BIC</th>
						<th>End-to-End Ref</th>
						<th>Customer Ref</th>
						<th>Mandatsreferenz</th>
						<th>Gläubiger ID</th>
					</tr>
				</thead>
				<tbody>
					<xf:repeat id="accounting-repeat" nodeset="instance('accounting')/BankAccount/Accountings/Accounting" appearance="full">
						<tr>
				<!--
							<xsl:attribute name="class">
								<xsl:choose>
									<xsl:when test="count(preceding-sibling::*) mod 2 = 0">
										<xsl:text>even</xsl:text>
									</xsl:when>
									<xsl:otherwise>
										<xsl:text>odd</xsl:text>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:attribute>
				-->

							<td>
								<a href="{concat($home-web-gui,'/',$tenant,'/',$year,'/banking/',$resource-id,'/',@id,'/details.html')}">
									<xf:output value="position()"/> <!-- | <xf:output ref="index('bookings')"/> -->
								</a>
							</td>
							<td>
								<xf:trigger>
									<xf:label>X</xf:label>
									<xf:delete nodeset="." at="1" if="count(//.) &gt; 1" ev:event="DOMActivate"/>
								</xf:trigger>

								<xf:trigger ref=".[following-sibling::*]">
									<xf:label>↓</xf:label>
									<xf:action ev:event="DOMActivate">
										<xf:insert origin="context()" ref="following-sibling::*[1]"/>
										<xf:delete ref="."/>
									</xf:action>
								</xf:trigger>

								<xf:trigger ref=".[preceding-sibling::*]">
									<xf:label>↑</xf:label>
									<xf:action ev:event="DOMActivate">
										<xf:insert origin="context()" ref="preceding-sibling::*[1]" position="before"/>
										<xf:delete ref="."/>
									</xf:action>
								</xf:trigger>
							</td>
							<td>
								<xf:input ref="@id"/>
							</td>
							<td style="background-color:#ccc">
								<xf:input ref="ValueDate"/>
							</td>
							<td>
								<xf:input ref="BookingDate"/>
							</td>						
							<td class="Money">
								<xf:input ref="Amount">
									<xf:action ev:event="DOMActivate">
										<xf:setvalue ref="@saldoAmount" value="instance('accounting')/BankAccount/Accountings/Accounting[index('accounting-repeat')-1]/@saldoAmount + instance('accounting')/BankAccount/Accountings/Accounting[index('accounting-repeat')]/Amount"/>
									</xf:action>
								</xf:input>
							</td>
							<td>
								<xf:select1 ref="Amount/@type">
									<xf:item>
                						<xf:label>CREDIT</xf:label>
                						<xf:value>CREDIT</xf:value> 
            						</xf:item>
									<xf:item>
                						<xf:label>DEBIT</xf:label>
                						<xf:value>DEBIT</xf:value> 
            						</xf:item>
								</xf:select1>
							</td>
							<td>
								<xf:input ref="ExternalCosts"/>
							</td>												
							<td class="Money">
								<xf:input ref="OriginalAmount"/>
							</td>
							<td class="Money" style="background-color:#ccc">
								<xf:input ref="@saldoAmount"/>
								<xf:trigger>
									<xf:label>calc</xf:label>
									<xf:action ev:event="DOMActivate">
										<xf:setvalue ref="@saldoAmount" value="if( instance('accounting')/BankAccount/Accountings/Accounting[index('accounting-repeat')]/ExternalCosts != 0,  number(instance('accounting')/BankAccount/Accountings/Accounting[index('accounting-repeat')-1]/@saldoAmount) + number(instance('accounting')/BankAccount/Accountings/Accounting[index('accounting-repeat')]/Amount) + number(instance('accounting')/BankAccount/Accountings/Accounting[index('accounting-repeat')]/ExternalCosts),  number(instance('accounting')/BankAccount/Accountings/Accounting[index('accounting-repeat')-1]/@saldoAmount) + number(instance('accounting')/BankAccount/Accountings/Accounting[index('accounting-repeat')]/Amount))"/>
									</xf:action>
								</xf:trigger>
							</td>
							<td>
								<xf:input ref="SalesType/@key"/>
							</td>
							<td>
								<xf:input ref="SalesType"/>
							</td>
							<td>
								<xf:input ref="Recipient"/>
							</td>
							<td>
								<xf:repeat id="paymentdetails-repeat" nodeset="PaymentDetails/PaymentDetail" appearance="full">
									<xf:input ref="."/>
								</xf:repeat>
							</td>
							<td>
								<xf:input ref="IBAN"/>
							</td>
							<td>
								<xf:input ref="BIC"/>
							</td>
							<td>
								<xf:input ref="EndToEndRef"/>
							</td>
							<td>
								<xf:input ref="CustomerRef"/>
							</td>							
							<td>
								<xf:input ref="MandantRef"/>
							</td>
							<td>
								<xf:input ref="CreditorID"/>
							</td>
						</tr>
					</xf:repeat>
				</tbody>
				<tfoot>
					<tr>
						<td>
							<xf:trigger>
								<xf:label>Kontobewegung hinzufügen</xf:label>
							
								<xf:insert context="instance('accounting')/BankAccount/Accountings" origin="instance('accounting-new')/Accounting" nodeset="Accounting" at="last()" position="after" ev:event="DOMActivate"/> <!-- index('accounting-repeat') -->
							</xf:trigger>
						</td>
					</tr>
				</tfoot>
			</table>

			<xf:submit submission="save" id="Save">
				<xf:label>Speichern</xf:label>
			</xf:submit>
		</body>
	</html>
	</xsl:template>

	<xsl:template match="result"/>


</xsl:stylesheet>